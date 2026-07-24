import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class AdminFirebaseOptions {
  const AdminFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    throw UnsupportedError(
      'Admin dashboard is configured for Flutter Web only.',
    );
  }

  // Fill these values from the Firebase Console web app config.
  // Project settings -> General -> Your apps -> Web app.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAw2TSmiMPWpblhPIaI7YwfD25I9gGcMKk',
    appId: '1:419524520507:web:b1a4d5c47d95d0ec5c4a1e',
    messagingSenderId: '419524520507',
    projectId: 'journal-trend-analyzer-d7705',
    authDomain: 'journal-trend-analyzer-d7705.firebaseapp.com',
    storageBucket: 'journal-trend-analyzer-d7705.firebasestorage.app',
    measurementId: 'G-NNMSRHZ7CJ',
  );

  static bool get isSupportedPlatform {
    return kIsWeb || defaultTargetPlatform == TargetPlatform.windows;
  }
}
