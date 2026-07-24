const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldPath, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getStorage } = require('firebase-admin/storage');
const { HttpsError, onCall } = require('firebase-functions/v2/https');

initializeApp();

const region = 'asia-southeast1';
const auditCollection = 'auditLogs';
const appConfigCollection = 'app_config';
const appConfigDocument = 'main';
const analyticsEventsCollection = 'analytics_events';
const managedCollections = [
  'users',
  'journals',
  'trends',
  'configs',
  'app_config',
  'analytics_events',
  'auditLogs',
  'audit_logs',
  'publications',
];
const dashboardCollections = ['users', 'journals', 'trends', 'publications', appConfigCollection];

function assertAdmin(request) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in is required.');
  }

  if (request.auth.token.admin !== true) {
    throw new HttpsError('permission-denied', 'Admin access is required.');
  }

  return request.auth;
}

function toAdminUser(userRecord) {
  return {
    uid: userRecord.uid,
    email: userRecord.email || '',
    displayName: userRecord.displayName || '',
    photoURL: userRecord.photoURL || '',
    disabled: userRecord.disabled,
    emailVerified: userRecord.emailVerified,
    creationTime: userRecord.metadata.creationTime || '',
    lastSignInTime: userRecord.metadata.lastSignInTime || '',
    providerIds: userRecord.providerData.map((provider) => provider.providerId),
    isAdmin: userRecord.customClaims?.admin === true,
  };
}

async function writeAuditLog(authContext, action, target, before, after) {
  await getFirestore().collection(auditCollection).add({
    adminUid: authContext.uid,
    adminEmail: authContext.token.email || '',
    action,
    target,
    before,
    after,
    createdAt: FieldValue.serverTimestamp(),
  });
}

function assertManagedCollection(collectionName) {
  if (!managedCollections.includes(collectionName)) {
    throw new HttpsError('invalid-argument', 'This collection is not managed by the admin dashboard.');
  }
}

function assertDocumentInput(collectionName, documentId) {
  assertManagedCollection(collectionName);
  if (!documentId || typeof documentId !== 'string' || documentId.includes('/')) {
    throw new HttpsError('invalid-argument', 'A valid document id is required.');
  }
}

function serializeFirestoreValue(value) {
  if (value == null) {
    return null;
  }

  if (typeof value.toDate === 'function') {
    return value.toDate().toISOString();
  }

  if (Array.isArray(value)) {
    return value.map(serializeFirestoreValue);
  }

  if (typeof value === 'object') {
    const serialized = {};
    Object.entries(value).forEach(([key, nestedValue]) => {
      serialized[key] = serializeFirestoreValue(nestedValue);
    });
    return serialized;
  }

  return value;
}

function toFirestoreDocument(snapshot) {
  return {
    id: snapshot.id,
    path: snapshot.ref.path,
    exists: snapshot.exists,
    data: snapshot.exists ? serializeFirestoreValue(snapshot.data()) : {},
  };
}

function parsePlainObject(value, label) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpsError('invalid-argument', `${label} must be a plain object.`);
  }

  return value;
}

async function countAuthUsers() {
  const auth = getAuth();
  let count = 0;
  let pageToken;

  do {
    const result = await auth.listUsers(1000, pageToken);
    count += result.users.length;
    pageToken = result.pageToken;
  } while (pageToken);

  return count;
}

async function countFirestoreCollection(collectionName) {
  const snapshot = await getFirestore().collection(collectionName).count().get();
  return snapshot.data().count || 0;
}

async function countStorageFiles() {
  const [files] = await getStorage().bucket().getFiles();
  return files.length;
}

exports.getAdminDashboardSummary = onCall({ region }, async (request) => {
  assertAdmin(request);

  const collectionCounts = {};
  await Promise.all(
    dashboardCollections.map(async (collectionName) => {
      collectionCounts[collectionName] =
        await countFirestoreCollection(collectionName);
    }),
  );

  const [userCount, storageFileCount] = await Promise.all([
    countAuthUsers(),
    countStorageFiles(),
  ]);

  return {
    userCount,
    storageFileCount,
    collectionCounts,
    generatedAt: new Date().toISOString(),
  };
});

exports.listManagedCollections = onCall({ region }, async (request) => {
  assertAdmin(request);

  const collections = await Promise.all(
    managedCollections.map(async (name) => ({
      name,
      count: await countFirestoreCollection(name),
    })),
  );

  return { collections };
});

exports.listManagedDocuments = onCall({ region }, async (request) => {
  assertAdmin(request);

  const collectionName = request.data?.collectionName;
  assertManagedCollection(collectionName);

  const limit = Math.min(Number(request.data?.limit) || 25, 50);
  const startAfterId = request.data?.startAfterId;
  let query = getFirestore()
    .collection(collectionName)
    .orderBy(FieldPath.documentId())
    .limit(limit);

  if (startAfterId) {
    const cursor = await getFirestore()
      .collection(collectionName)
      .doc(startAfterId)
      .get();
    if (cursor.exists) {
      query = query.startAfter(cursor);
    }
  }

  const snapshot = await query.get();
  const documents = snapshot.docs.map(toFirestoreDocument);
  const lastDocument = snapshot.docs[snapshot.docs.length - 1];

  return {
    documents,
    nextPageToken: snapshot.docs.length === limit && lastDocument ? lastDocument.id : '',
  };
});

exports.getManagedDocument = onCall({ region }, async (request) => {
  assertAdmin(request);

  const collectionName = request.data?.collectionName;
  const documentId = request.data?.documentId;
  assertDocumentInput(collectionName, documentId);

  const snapshot = await getFirestore().collection(collectionName).doc(documentId).get();
  return { document: toFirestoreDocument(snapshot) };
});

exports.saveManagedDocument = onCall({ region }, async (request) => {
  const authContext = assertAdmin(request);
  const collectionName = request.data?.collectionName;
  const documentId = request.data?.documentId;
  const data = parsePlainObject(request.data?.data, 'Document data');
  assertDocumentInput(collectionName, documentId);

  const reference = getFirestore().collection(collectionName).doc(documentId);
  const beforeSnapshot = await reference.get();
  const before = toFirestoreDocument(beforeSnapshot);

  await reference.set({
    ...data,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  const after = toFirestoreDocument(await reference.get());
  await writeAuditLog(authContext, 'saveDocument', reference.path, before, after);

  return { document: after };
});

exports.deleteManagedDocument = onCall({ region }, async (request) => {
  const authContext = assertAdmin(request);
  const collectionName = request.data?.collectionName;
  const documentId = request.data?.documentId;
  assertDocumentInput(collectionName, documentId);

  if (collectionName === auditCollection) {
    throw new HttpsError('failed-precondition', 'Audit logs cannot be deleted from the admin dashboard.');
  }

  const reference = getFirestore().collection(collectionName).doc(documentId);
  const before = toFirestoreDocument(await reference.get());
  await reference.delete();
  await writeAuditLog(authContext, 'deleteDocument', reference.path, before, { exists: false });

  return { deleted: true };
});

exports.getAppConfig = onCall({ region }, async (request) => {
  assertAdmin(request);

  const snapshot = await getFirestore()
    .collection(appConfigCollection)
    .doc(appConfigDocument)
    .get();

  return {
    config: snapshot.exists ? serializeFirestoreValue(snapshot.data()) : {},
  };
});

exports.saveAppConfig = onCall({ region }, async (request) => {
  const authContext = assertAdmin(request);
  const config = parsePlainObject(request.data?.config, 'App config');
  const reference = getFirestore()
    .collection(appConfigCollection)
    .doc(appConfigDocument);

  const before = toFirestoreDocument(await reference.get());
  await reference.set({
    ...config,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  const after = toFirestoreDocument(await reference.get());

  await writeAuditLog(authContext, 'saveAppConfig', reference.path, before, after);

  return { config: after.data };
});

exports.listStorageFiles = onCall({ region }, async (request) => {
  assertAdmin(request);

  const prefix = request.data?.prefix || '';
  const maxResults = Math.min(Number(request.data?.maxResults) || 50, 100);
  const pageToken = request.data?.pageToken || undefined;
  const [files, nextQuery] = await getStorage().bucket().getFiles({
    prefix,
    maxResults,
    pageToken,
  });

  const items = await Promise.all(
    files.map(async (file) => {
      const [metadata] = await file.getMetadata();
      const [downloadUrl] = await file.getSignedUrl({
        action: 'read',
        expires: Date.now() + 15 * 60 * 1000,
      });

      return {
        name: file.name,
        bucket: metadata.bucket || '',
        contentType: metadata.contentType || '',
        size: Number(metadata.size || 0),
        updated: metadata.updated || '',
        downloadUrl,
      };
    }),
  );

  return {
    files: items,
    nextPageToken: nextQuery?.pageToken || '',
  };
});

exports.deleteStorageFile = onCall({ region }, async (request) => {
  const authContext = assertAdmin(request);
  const path = request.data?.path;

  if (!path || typeof path !== 'string') {
    throw new HttpsError('invalid-argument', 'A storage file path is required.');
  }

  const file = getStorage().bucket().file(path);
  const [exists] = await file.exists();
  const before = exists ? { path } : { path, exists: false };

  if (!exists) {
    throw new HttpsError('not-found', 'Storage file was not found.');
  }

  await file.delete();
  await writeAuditLog(authContext, 'deleteStorageFile', path, before, { exists: false });

  return { deleted: true };
});

exports.listAuditLogs = onCall({ region }, async (request) => {
  assertAdmin(request);

  const limit = Math.min(Number(request.data?.limit) || 50, 100);
  const startAfterId = request.data?.startAfterId;
  let query = getFirestore()
    .collection(auditCollection)
    .orderBy('createdAt', 'desc')
    .limit(limit);

  if (startAfterId) {
    const cursor = await getFirestore().collection(auditCollection).doc(startAfterId).get();
    if (cursor.exists) {
      query = query.startAfter(cursor);
    }
  }

  const snapshot = await query.get();
  const logs = snapshot.docs.map(toFirestoreDocument);
  const lastDocument = snapshot.docs[snapshot.docs.length - 1];

  return {
    logs,
    nextPageToken: snapshot.docs.length === limit && lastDocument ? lastDocument.id : '',
  };
});

exports.sendTopicMessage = onCall({ region }, async (request) => {
  const authContext = assertAdmin(request);
  const topic = request.data?.topic;
  const title = request.data?.title;
  const body = request.data?.body;

  if (!topic || typeof topic !== 'string' || !title || !body) {
    throw new HttpsError('invalid-argument', 'Topic, title, and body are required.');
  }

  const messageId = await getMessaging().send({
    topic,
    notification: { title, body },
    data: {
      source: 'admin_dashboard',
    },
  });

  await writeAuditLog(authContext, 'sendTopicMessage', topic, null, {
    messageId,
    title,
    body,
  });

  return { messageId };
});

exports.sendUserMessage = onCall({ region }, async (request) => {
  const authContext = assertAdmin(request);
  const uid = request.data?.uid;
  const email = request.data?.email;
  const title = request.data?.title;
  const body = request.data?.body;

  if ((!uid && !email) || !title || !body) {
    throw new HttpsError('invalid-argument', 'User uid/email, title, and body are required.');
  }

  const userRecord = uid
    ? await getAuth().getUser(uid)
    : await getAuth().getUserByEmail(email);

  const tokenSnapshot = await getFirestore()
    .collection('users')
    .doc(userRecord.uid)
    .collection('fcmTokens')
    .get();

  const tokens = tokenSnapshot.docs
    .map((document) => document.data().token)
    .filter((token) => typeof token === 'string' && token.length > 0);

  if (tokens.length === 0) {
    throw new HttpsError('failed-precondition', 'This user has no registered FCM tokens.');
  }

  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: {
      source: 'admin_dashboard',
      type: 'direct',
    },
  });

  await writeAuditLog(authContext, 'sendUserMessage', userRecord.uid, null, {
    email: userRecord.email || '',
    successCount: response.successCount,
    failureCount: response.failureCount,
    title,
    body,
  });

  return {
    successCount: response.successCount,
    failureCount: response.failureCount,
  };
});

exports.sendAllUsersMessage = onCall({ region }, async (request) => {
  const authContext = assertAdmin(request);
  const title = request.data?.title;
  const body = request.data?.body;

  if (!title || !body) {
    throw new HttpsError('invalid-argument', 'Title and body are required.');
  }

  const messageId = await getMessaging().send({
    topic: 'announcements',
    notification: { title, body },
    data: {
      source: 'admin_dashboard',
      type: 'announcement',
    },
  });

  await writeAuditLog(authContext, 'sendAllUsersMessage', 'announcements', null, {
    messageId,
    title,
    body,
  });

  return { messageId };
});

exports.getAnalyticsSummary = onCall({ region }, async (request) => {
  assertAdmin(request);

  const days = Math.min(Number(request.data?.days) || 30, 90);
  const now = new Date();
  const todayKey = now.toISOString().slice(0, 10);
  const since = new Date(now);
  since.setDate(since.getDate() - days + 1);
  since.setHours(0, 0, 0, 0);

  const sevenDaysAgo = new Date(now);
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6);
  sevenDaysAgo.setHours(0, 0, 0, 0);

  const snapshot = await getFirestore()
    .collection(analyticsEventsCollection)
    .where('createdAt', '>=', since)
    .orderBy('createdAt', 'desc')
    .limit(5000)
    .get();

  const dailyEvents = {};
  const topEvents = {};
  const topJournals = {};
  const activeUsersToday = new Set();
  const activeUsers7d = new Set();
  const activeUsers = new Set();

  snapshot.docs.forEach((document) => {
    const data = document.data();
    const createdAt = data.createdAt?.toDate?.();
    if (!createdAt) return;

    const dateKey = createdAt.toISOString().slice(0, 10);
    const eventName = data.eventName || 'unknown';
    const metadata = data.metadata || {};
    const userKey = data.userId || data.userEmail || '';

    dailyEvents[dateKey] = (dailyEvents[dateKey] || 0) + 1;
    topEvents[eventName] = (topEvents[eventName] || 0) + 1;

    if (eventName === 'view_journal' || eventName === 'search_journal') {
      const journalName = metadata.journal_name || metadata.query || '';
      if (journalName) {
        topJournals[journalName] = (topJournals[journalName] || 0) + 1;
      }
    }

    if (userKey) {
      activeUsers.add(userKey);
      if (dateKey === todayKey) {
        activeUsersToday.add(userKey);
      }
      if (createdAt >= sevenDaysAgo) {
        activeUsers7d.add(userKey);
      }
    }
  });

  return {
    days,
    totalEvents: snapshot.size,
    activeUsers: activeUsers.size,
    activeUsersToday: activeUsersToday.size,
    activeUsers7d: activeUsers7d.size,
    dailyEvents: Object.entries(dailyEvents)
      .map(([date, count]) => ({ date, count }))
      .sort((a, b) => a.date.localeCompare(b.date)),
    topEvents: rankCounts(topEvents),
    topJournals: rankCounts(topJournals),
    generatedAt: now.toISOString(),
  };
});

function rankCounts(values) {
  return Object.entries(values)
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count || a.name.localeCompare(b.name))
    .slice(0, 10);
}

exports.listUsers = onCall({ region }, async (request) => {
  assertAdmin(request);

  const maxResults = Math.min(Number(request.data?.maxResults) || 50, 100);
  const pageToken = request.data?.pageToken || undefined;
  const result = await getAuth().listUsers(maxResults, pageToken);

  return {
    users: result.users.map(toAdminUser),
    nextPageToken: result.pageToken || '',
  };
});

exports.getUser = onCall({ region }, async (request) => {
  assertAdmin(request);

  const uid = request.data?.uid;
  if (!uid || typeof uid !== 'string') {
    throw new HttpsError('invalid-argument', 'A user uid is required.');
  }

  const user = await getAuth().getUser(uid);
  return { user: toAdminUser(user) };
});

exports.setUserDisabled = onCall({ region }, async (request) => {
  const authContext = assertAdmin(request);
  const uid = request.data?.uid;
  const disabled = request.data?.disabled;

  if (!uid || typeof uid !== 'string' || typeof disabled !== 'boolean') {
    throw new HttpsError('invalid-argument', 'A uid and disabled flag are required.');
  }

  if (uid === authContext.uid && disabled) {
    throw new HttpsError('failed-precondition', 'You cannot disable your own admin account.');
  }

  const auth = getAuth();
  const before = toAdminUser(await auth.getUser(uid));
  const updated = toAdminUser(await auth.updateUser(uid, { disabled }));

  await writeAuditLog(authContext, disabled ? 'disableUser' : 'enableUser', uid, before, updated);

  return { user: updated };
});

exports.setUserAdminClaim = onCall({ region }, async (request) => {
  const authContext = assertAdmin(request);
  const uid = request.data?.uid;
  const isAdmin = request.data?.isAdmin;

  if (!uid || typeof uid !== 'string' || typeof isAdmin !== 'boolean') {
    throw new HttpsError('invalid-argument', 'A uid and isAdmin flag are required.');
  }

  if (uid === authContext.uid && !isAdmin) {
    throw new HttpsError('failed-precondition', 'You cannot remove admin access from your own account.');
  }

  const auth = getAuth();
  const existing = await auth.getUser(uid);
  const before = toAdminUser(existing);
  const claims = { ...(existing.customClaims || {}) };

  if (isAdmin) {
    claims.admin = true;
  } else {
    delete claims.admin;
  }

  await auth.setCustomUserClaims(uid, claims);
  const updated = toAdminUser(await auth.getUser(uid));

  await writeAuditLog(authContext, isAdmin ? 'grantAdmin' : 'revokeAdmin', uid, before, updated);

  return { user: updated };
});
