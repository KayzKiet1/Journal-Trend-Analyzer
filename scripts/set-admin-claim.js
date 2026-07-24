const path = require('path');
const { cert, initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

const serviceAccountPath = path.resolve(
  __dirname,
  '..',
  'journal-trend-analyzer-d7705-firebase-adminsdk-fbsvc-4992a99299.json',
);

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const emailArgument = process.argv.find((argument) =>
  emailPattern.test(argument),
);
const adminEmail =
  process.env.ADMIN_EMAIL || emailArgument || 'TODO_ADMIN_EMAIL@example.com';

if (adminEmail === 'TODO_ADMIN_EMAIL@example.com') {
  console.error('Please pass the admin email:');
  console.error('  node scripts/set-admin-claim.js your-admin-email@example.com');
  process.exit(1);
}

initializeApp({
  credential: cert(serviceAccountPath),
});

async function main() {
  const auth = getAuth();
  const user = await auth.getUserByEmail(adminEmail);

  await auth.setCustomUserClaims(user.uid, {
    admin: true,
  });

  console.log(`Admin claim set for ${adminEmail}`);
  console.log('Sign out and sign in again so the account receives a fresh ID token.');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
