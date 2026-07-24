# Journal Trend Analyzer Admin Dashboard

Flutter Web admin dashboard for managing Firebase-backed services without using Firebase Console directly.

This project is intentionally separated from the mobile app in the repository root. Do not place admin dashboard code in the root `lib/` folder.

## Planned Stack

- Frontend: Flutter Web and Dart
- Backend services: Firebase Authentication, Cloud Firestore, Firebase Storage
- Admin-only operations: Firebase Cloud Functions or server-side Firebase Admin SDK
- Deployment target: Vercel

## Vercel Settings

- Root Directory: `admin_dashboard`
- Build Command: `flutter build web`
- Output Directory: `build/web`

