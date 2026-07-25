const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldPath, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getRemoteConfig } = require('firebase-admin/remote-config');
const { getStorage } = require('firebase-admin/storage');
const { HttpsError, onCall } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');

initializeApp();

const region = 'asia-southeast1';
const auditCollection = 'auditLogs';
const appConfigCollection = 'app_config';
const appConfigDocument = 'main';
const analyticsEventsCollection = 'analytics_events';
const notificationLogsCollection = 'notificationLogs';
const notificationSchedulesCollection = 'notificationSchedules';
const storageUploadsCollection = 'storageUploads';
const healthCollections = ['app_errors', 'function_errors', 'system_health'];
const managedCollections = [
  'users',
  'journals',
  'publications',
  'app_config',
  'analytics_events',
  'notificationLogs',
  'notificationSchedules',
  'auditLogs',
  'app_errors',
  'function_errors',
  'system_health',
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

async function writeNotificationLog(authContext, payload) {
  await getFirestore().collection(notificationLogsCollection).add({
    adminUid: authContext.uid,
    adminEmail: authContext.token.email || '',
    createdAt: FieldValue.serverTimestamp(),
    ...payload,
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
  let newUsers7d = 0;
  let newUsers30d = 0;
  let pageToken;
  const now = Date.now();
  const sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);
  const thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);

  do {
    const result = await auth.listUsers(1000, pageToken);
    count += result.users.length;
    result.users.forEach((user) => {
      const createdAt = Date.parse(user.metadata.creationTime || '');
      if (!Number.isNaN(createdAt)) {
        if (createdAt >= sevenDaysAgo) newUsers7d += 1;
        if (createdAt >= thirtyDaysAgo) newUsers30d += 1;
      }
    });
    pageToken = result.pageToken;
  } while (pageToken);

  return { total: count, newUsers7d, newUsers30d };
}

async function countFirestoreCollection(collectionName) {
  const snapshot = await getFirestore().collection(collectionName).count().get();
  return snapshot.data().count || 0;
}

async function getStorageSummary() {
  const [files] = await getStorage().bucket().getFiles();
  let totalBytes = 0;
  const folderCounts = {};

  await Promise.all(
    files.map(async (file) => {
      const [metadata] = await file.getMetadata();
      totalBytes += Number(metadata.size || 0);
      const folder = file.name.split('/')[0] || '(root)';
      folderCounts[folder] = (folderCounts[folder] || 0) + 1;
    }),
  );

  return {
    fileCount: files.length,
    totalBytes,
    folderCounts,
  };
}

async function getRecentSystemHealthCount() {
  const since = new Date();
  since.setDate(since.getDate() - 7);
  since.setHours(0, 0, 0, 0);

  const snapshots = await Promise.all(
    healthCollections.map((collectionName) =>
      getFirestore()
        .collection(collectionName)
        .where('createdAt', '>=', since)
        .count()
        .get()),
  );

  return snapshots.reduce(
    (total, snapshot) => total + (snapshot.data().count || 0),
    0,
  );
}

async function getDashboardAnalyticsSummary() {
  const since = new Date();
  since.setDate(since.getDate() - 7);
  since.setHours(0, 0, 0, 0);

  const snapshot = await getFirestore()
    .collection(analyticsEventsCollection)
    .where('createdAt', '>=', since)
    .orderBy('createdAt', 'desc')
    .limit(2000)
    .get();
  const activeUsers = new Set();

  snapshot.docs.forEach((document) => {
    const data = document.data();
    const userKey = data.userId || data.userEmail || '';
    if (userKey) activeUsers.add(userKey);
  });

  return {
    events7d: snapshot.size,
    activeUsers7d: activeUsers.size,
  };
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

  const [
    authSummary,
    storageSummary,
    recentSystemHealthCount,
    analyticsSummary,
  ] = await Promise.all([
    countAuthUsers(),
    getStorageSummary(),
    getRecentSystemHealthCount(),
    getDashboardAnalyticsSummary(),
  ]);

  return {
    userCount: authSummary.total,
    newUsers7d: authSummary.newUsers7d,
    newUsers30d: authSummary.newUsers30d,
    storageFileCount: storageSummary.fileCount,
    storageTotalBytes: storageSummary.totalBytes,
    storageFolderCounts: storageSummary.folderCounts,
    recentSystemHealthCount,
    analyticsEvents7d: analyticsSummary.events7d,
    activeUsers7d: analyticsSummary.activeUsers7d,
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

exports.getRemoteAppConfig = onCall({ region }, async (request) => {
  assertAdmin(request);

  const template = await getRemoteConfig().getTemplate();
  return {
    config: readRemoteAppConfig(template),
    version: template.version || null,
  };
});

exports.saveRemoteAppConfig = onCall({ region }, async (request) => {
  const authContext = assertAdmin(request);
  const config = parsePlainObject(request.data?.config, 'Remote app config');
  const remoteConfig = getRemoteConfig();
  const template = await remoteConfig.getTemplate();
  template.parameters = template.parameters || {};
  const before = readRemoteAppConfig(template);
  const nextConfig = normalizeRemoteAppConfig(config);

  template.parameters.max_journals_display = remoteParameter({
    value: String(nextConfig.maxJournalsDisplay),
    valueType: 'NUMBER',
    description: 'Maximum journals shown in topic dashboards.',
  });
  template.parameters.max_keywords_display = remoteParameter({
    value: String(nextConfig.maxKeywordsDisplay),
    valueType: 'NUMBER',
    description: 'Maximum keywords shown in keyword dashboards.',
  });
  template.parameters.enable_report_export = remoteParameter({
    value: String(nextConfig.enableReportExport),
    valueType: 'BOOLEAN',
    description: 'Enable report export features in the mobile app.',
  });

  const published = await remoteConfig.publishTemplate(template);
  const after = readRemoteAppConfig(published);

  await writeAuditLog(
    authContext,
    'saveRemoteAppConfig',
    'remote_config/mobile_runtime',
    before,
    after,
  );

  return {
    config: after,
    version: published.version || null,
  };
});

function readRemoteAppConfig(template) {
  const parameters = template.parameters || {};
  return {
    maxJournalsDisplay: readRemoteNumber(
      parameters.max_journals_display,
      10,
    ),
    maxKeywordsDisplay: readRemoteNumber(
      parameters.max_keywords_display,
      10,
    ),
    enableReportExport: readRemoteBoolean(
      parameters.enable_report_export,
      true,
    ),
  };
}

function normalizeRemoteAppConfig(config) {
  const maxJournalsDisplay = positiveInteger(
    config.maxJournalsDisplay,
    'maxJournalsDisplay',
  );
  const maxKeywordsDisplay = positiveInteger(
    config.maxKeywordsDisplay,
    'maxKeywordsDisplay',
  );

  if (typeof config.enableReportExport !== 'boolean') {
    throw new HttpsError('invalid-argument', 'enableReportExport must be a boolean.');
  }

  return {
    maxJournalsDisplay,
    maxKeywordsDisplay,
    enableReportExport: config.enableReportExport,
  };
}

function readRemoteNumber(parameter, fallback) {
  const value = Number(parameter?.defaultValue?.value);
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

function readRemoteBoolean(parameter, fallback) {
  const rawValue = parameter?.defaultValue?.value;
  if (rawValue === 'true') return true;
  if (rawValue === 'false') return false;
  return fallback;
}

function positiveInteger(value, fieldName) {
  const numberValue = Number(value);
  if (!Number.isInteger(numberValue) || numberValue < 1 || numberValue > 100) {
    throw new HttpsError('invalid-argument', `${fieldName} must be an integer from 1 to 100.`);
  }
  return numberValue;
}

function remoteParameter({ value, valueType, description }) {
  return {
    defaultValue: { value },
    valueType,
    description,
  };
}

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
      const originalFileName =
        metadata.metadata?.originalFileName ||
        file.name.split('/').pop() ||
        'download';
      const viewUrl = await createSignedReadUrl(file);
      const downloadUrl = await createSignedReadUrl(file, {
        responseDisposition: `attachment; filename="${safeDownloadFileName(originalFileName)}"`,
      });

      return {
        name: file.name,
        bucket: metadata.bucket || '',
        contentType: metadata.contentType || '',
        size: Number(metadata.size || 0),
        updated: metadata.updated || '',
        customMetadata: metadata.metadata || {},
        viewUrl,
        downloadUrl,
      };
    }),
  );

  return {
    files: items,
    nextPageToken: nextQuery?.pageToken || '',
  };
});

async function createSignedReadUrl(file, options = {}) {
  try {
    const [downloadUrl] = await file.getSignedUrl({
      action: 'read',
      expires: Date.now() + 15 * 60 * 1000,
      ...options,
    });
    return downloadUrl;
  } catch (error) {
    console.warn(`Unable to create signed URL for ${file.name}:`, error.message);
    return '';
  }
}

function safeDownloadFileName(value) {
  const normalized = String(value)
    .trim()
    .replace(/["\\\r\n]+/g, '')
    .replace(/[/:*?<>|]+/g, '_');
  return normalized || 'download';
}

exports.uploadStorageFile = onCall({ region }, async (request) => {
  const authContext = assertAdmin(request);
  const fileName = request.data?.fileName;
  const contentType = request.data?.contentType || 'application/octet-stream';
  const folder = safeStorageFolder(request.data?.folder || 'admin_uploads');
  const base64Data = request.data?.base64Data;

  if (!fileName || typeof fileName !== 'string') {
    throw new HttpsError('invalid-argument', 'A file name is required.');
  }

  if (!base64Data || typeof base64Data !== 'string') {
    throw new HttpsError('invalid-argument', 'File content is required.');
  }

  const buffer = Buffer.from(base64Data, 'base64');
  if (buffer.length === 0) {
    throw new HttpsError('invalid-argument', 'File content cannot be empty.');
  }

  const safeName = safeStorageFileName(fileName);
  const path = `${folder}/${authContext.uid}/${Date.now()}_${safeName}`;
  const metadata = {
    contentType,
    metadata: {
      folder,
      originalFileName: fileName,
      uploadedByUid: authContext.uid,
      uploadedByEmail: authContext.token.email || '',
      uploadedFrom: 'admin_dashboard',
    },
  };
  const file = getStorage().bucket().file(path);

  await file.save(buffer, {
    contentType,
    metadata,
    resumable: false,
  });

  const payload = {
    path,
    fileName,
    folder,
    contentType,
    size: buffer.length,
    uploadedByUid: authContext.uid,
    uploadedByEmail: authContext.token.email || '',
    createdAt: FieldValue.serverTimestamp(),
  };

  await getFirestore().collection(storageUploadsCollection).add(payload);
  await writeAuditLog(authContext, 'uploadStorageFile', path, null, payload);

  return { path };
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

exports.recordStorageUpload = onCall({ region }, async (request) => {
  const authContext = assertAdmin(request);
  const path = request.data?.path;
  const fileName = request.data?.fileName;
  const contentType = request.data?.contentType || '';
  const size = Number(request.data?.size || 0);

  if (!path || typeof path !== 'string' || !fileName) {
    throw new HttpsError('invalid-argument', 'Uploaded file path and file name are required.');
  }

  const payload = {
    path,
    fileName,
    contentType,
    size,
    uploadedByUid: authContext.uid,
    uploadedByEmail: authContext.token.email || '',
    createdAt: FieldValue.serverTimestamp(),
  };

  await getFirestore().collection(storageUploadsCollection).add(payload);
  await writeAuditLog(authContext, 'uploadStorageFile', path, null, payload);

  return { recorded: true };
});

function safeStorageFolder(value) {
  const normalized = String(value)
    .trim()
    .replace(/[^a-zA-Z0-9_/-]+/g, '_')
    .replace(/\/+/g, '/')
    .replace(/_+/g, '_')
    .replace(/^\/+|\/+$/g, '');
  return normalized || 'admin_uploads';
}

function safeStorageFileName(value) {
  const normalized = String(value)
    .trim()
    .replace(/[^a-zA-Z0-9._-]+/g, '_')
    .replace(/_+/g, '_');
  return normalized || 'upload.bin';
}

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
  await writeNotificationLog(authContext, {
    mode: 'topic',
    target: topic,
    title,
    body,
    successCount: 1,
    failureCount: 0,
    messageId,
  });

  return { messageId };
});

async function sendDirectUserNotification({ uid, email, title, body }) {
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

  return {
    userRecord,
    successCount: response.successCount,
    failureCount: response.failureCount,
  };
}

async function sendAllUsersNotification({ title, body }) {
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

  return { messageId };
}

exports.sendUserMessage = onCall({ region }, async (request) => {
  const authContext = assertAdmin(request);
  const uid = request.data?.uid;
  const email = request.data?.email;
  const title = request.data?.title;
  const body = request.data?.body;

  const result = await sendDirectUserNotification({ uid, email, title, body });

  await writeAuditLog(authContext, 'sendUserMessage', result.userRecord.uid, null, {
    email: result.userRecord.email || '',
    successCount: result.successCount,
    failureCount: result.failureCount,
    title,
    body,
  });
  await writeNotificationLog(authContext, {
    mode: 'user',
    target: result.userRecord.uid,
    targetEmail: result.userRecord.email || '',
    title,
    body,
    successCount: result.successCount,
    failureCount: result.failureCount,
  });

  return {
    successCount: result.successCount,
    failureCount: result.failureCount,
  };
});

exports.sendAllUsersMessage = onCall({ region }, async (request) => {
  const authContext = assertAdmin(request);
  const title = request.data?.title;
  const body = request.data?.body;

  const result = await sendAllUsersNotification({ title, body });

  await writeAuditLog(authContext, 'sendAllUsersMessage', 'announcements', null, {
    messageId: result.messageId,
    title,
    body,
  });
  await writeNotificationLog(authContext, {
    mode: 'allUsers',
    target: 'announcements',
    title,
    body,
    successCount: 1,
    failureCount: 0,
    messageId: result.messageId,
  });

  return { messageId: result.messageId };
});

exports.scheduleNotification = onCall({ region }, async (request) => {
  const authContext = assertAdmin(request);
  const mode = request.data?.mode;
  const recipient = request.data?.recipient || '';
  const title = request.data?.title;
  const body = request.data?.body;
  const scheduledAtText = request.data?.scheduledAt;
  const scheduledAt = new Date(scheduledAtText);

  if (!['allUsers', 'user'].includes(mode)) {
    throw new HttpsError('invalid-argument', 'Mode must be allUsers or user.');
  }
  if (!title || !body || Number.isNaN(scheduledAt.getTime())) {
    throw new HttpsError('invalid-argument', 'Title, body, and scheduledAt are required.');
  }
  if (scheduledAt.getTime() <= Date.now() + 30 * 1000) {
    throw new HttpsError('invalid-argument', 'Scheduled time must be at least 30 seconds in the future.');
  }
  if (mode === 'user' && !recipient) {
    throw new HttpsError('invalid-argument', 'Recipient email or uid is required for user notifications.');
  }

  const payload = {
    mode,
    target: mode === 'allUsers' ? 'announcements' : recipient,
    title,
    body,
    status: 'scheduled',
    scheduledAt,
    createdAt: FieldValue.serverTimestamp(),
    adminUid: authContext.uid,
    adminEmail: authContext.token.email || '',
  };

  const document = await getFirestore()
    .collection(notificationSchedulesCollection)
    .add(payload);

  await writeAuditLog(authContext, 'scheduleNotification', document.id, null, payload);
  await writeNotificationLog(authContext, {
    mode,
    target: payload.target,
    title,
    body,
    successCount: 0,
    failureCount: 0,
    status: 'scheduled',
    scheduleId: document.id,
    scheduledAt,
  });

  return { scheduleId: document.id };
});

exports.processScheduledNotifications = onSchedule(
  {
    region,
    schedule: 'every 1 minutes',
    timeZone: 'Asia/Ho_Chi_Minh',
  },
  async () => {
    const firestore = getFirestore();
    const snapshot = await firestore
      .collection(notificationSchedulesCollection)
      .where('status', '==', 'scheduled')
      .where('scheduledAt', '<=', new Date())
      .orderBy('scheduledAt', 'asc')
      .limit(20)
      .get();

    await Promise.all(
      snapshot.docs.map(async (document) => {
        const data = document.data();
        await document.ref.update({
          status: 'processing',
          processingStartedAt: FieldValue.serverTimestamp(),
        });

        const systemAuthContext = {
          uid: data.adminUid || 'system',
          token: { email: data.adminEmail || 'system' },
        };

        try {
          if (data.mode === 'user') {
            const target = data.target || '';
            const result = await sendDirectUserNotification({
              uid: target.includes('@') ? '' : target,
              email: target.includes('@') ? target : '',
              title: data.title,
              body: data.body,
            });
            await writeNotificationLog(systemAuthContext, {
              mode: 'user',
              target: result.userRecord.uid,
              targetEmail: result.userRecord.email || '',
              title: data.title,
              body: data.body,
              successCount: result.successCount,
              failureCount: result.failureCount,
              status: 'sent',
              scheduleId: document.id,
              scheduledAt: data.scheduledAt || '',
            });
          } else {
            const result = await sendAllUsersNotification({
              title: data.title,
              body: data.body,
            });
            await writeNotificationLog(systemAuthContext, {
              mode: 'allUsers',
              target: 'announcements',
              title: data.title,
              body: data.body,
              successCount: 1,
              failureCount: 0,
              messageId: result.messageId,
              status: 'sent',
              scheduleId: document.id,
              scheduledAt: data.scheduledAt || '',
            });
          }

          await document.ref.update({
            status: 'sent',
            sentAt: FieldValue.serverTimestamp(),
          });
        } catch (error) {
          await document.ref.update({
            status: 'failed',
            failureReason: error.message || String(error),
            failedAt: FieldValue.serverTimestamp(),
          });
          await writeNotificationLog(systemAuthContext, {
            mode: data.mode || 'unknown',
            target: data.target || '',
            title: data.title || '',
            body: data.body || '',
            successCount: 0,
            failureCount: 1,
            status: 'failed',
            scheduleId: document.id,
            scheduledAt: data.scheduledAt || '',
            error: error.message || String(error),
          });
        }
      }),
    );
  },
);

exports.listNotificationLogs = onCall({ region }, async (request) => {
  assertAdmin(request);

  const limit = Math.min(Number(request.data?.limit) || 50, 100);
  const startAfterId = request.data?.startAfterId;
  let query = getFirestore()
    .collection(notificationLogsCollection)
    .orderBy('createdAt', 'desc')
    .limit(limit);

  if (startAfterId) {
    const cursor = await getFirestore()
      .collection(notificationLogsCollection)
      .doc(startAfterId)
      .get();
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

exports.listSystemHealth = onCall({ region }, async (request) => {
  assertAdmin(request);

  const limit = Math.min(Number(request.data?.limit) || 25, 50);
  const firestore = getFirestore();

  const snapshots = await Promise.all(
    healthCollections.map(async (collectionName) => {
      const snapshot = await firestore
        .collection(collectionName)
        .orderBy('createdAt', 'desc')
        .limit(limit)
        .get();

      return snapshot.docs.map((document) => ({
        source: collectionName,
        ...toFirestoreDocument(document),
      }));
    }),
  );

  const items = snapshots
    .flat()
    .sort((a, b) => {
      const aDate = a.data.createdAt || '';
      const bDate = b.data.createdAt || '';
      return bDate.localeCompare(aDate);
    })
    .slice(0, limit);

  const openIssueCount = items.filter((item) => {
    const status = String(item.data.status || '').toLowerCase();
    return status !== 'resolved' && status !== 'closed';
  }).length;

  return {
    items,
    openIssueCount,
    generatedAt: new Date().toISOString(),
  };
});

exports.getUserProfileSummary = onCall({ region }, async (request) => {
  assertAdmin(request);

  const uid = request.data?.uid;
  if (!uid || typeof uid !== 'string') {
    throw new HttpsError('invalid-argument', 'A user uid is required.');
  }

  const firestore = getFirestore();
  const userRef = firestore.collection('users').doc(uid);

  const [
    tokenSnapshot,
    analyticsSnapshot,
    savedJournalsSnapshot,
    savedPublicationsSnapshot,
    reports,
  ] = await Promise.all([
    userRef.collection('fcmTokens').limit(20).get(),
    firestore.collection(analyticsEventsCollection).where('userId', '==', uid).limit(50).get(),
    userRef.collection('savedJournals').orderBy('savedAt', 'desc').limit(50).get(),
    userRef.collection('savedPublications').orderBy('savedAt', 'desc').limit(50).get(),
    listReportFiles(uid),
  ]);

  const activity = analyticsSnapshot.docs
    .map(toFirestoreDocument)
    .sort((a, b) => {
      const aDate = a.data.createdAt || '';
      const bDate = b.data.createdAt || '';
      return bDate.localeCompare(aDate);
    })
    .slice(0, 20);

  return {
    fcmTokens: tokenSnapshot.docs.map(toFirestoreDocument),
    activity,
    reports,
    savedJournals: savedJournalsSnapshot.docs.map(toFirestoreDocument),
    savedPublications: savedPublicationsSnapshot.docs.map(toFirestoreDocument),
  };
});

async function listReportFiles(uid) {
  const [files] = await getStorage().bucket().getFiles({
    prefix: `reports/${uid}/`,
    maxResults: 50,
  });

  return Promise.all(
    files.map(async (file) => {
      const [metadata] = await file.getMetadata();
      const downloadUrl = await createSignedReadUrl(file);
      return {
        name: file.name,
        contentType: metadata.contentType || '',
        size: Number(metadata.size || 0),
        updated: metadata.updated || '',
        customMetadata: metadata.metadata || {},
        downloadUrl,
      };
    }),
  );
}

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
