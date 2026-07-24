const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { HttpsError, onCall } = require('firebase-functions/v2/https');

initializeApp();

const region = 'asia-southeast1';
const auditCollection = 'auditLogs';
const dashboardCollections = ['users', 'journals', 'publications', 'appConfig'];

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
