import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart'; // Giúp nhận biết kIsWeb tự động
import 'package:flutter/widgets.dart';

Future<void> initializeFirebase() async {
  if (kIsWeb) {
    // Cấu hình CHỈ CHẠY TRÊN WEB (Đã điền thông số chính xác của bạn)
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAxrRnSeB-70_4DsCmnncJpFlHL2XsFJfk",
        authDomain: "journal-trend-analyzer-bc875.firebaseapp.com",
        projectId: "journal-trend-analyzer-bc875",
        storageBucket: "journal-trend-analyzer-bc875.firebasestorage.app",
        messagingSenderId: "262511216560",
        appId: "1:262511216560:web:dfd2c979b4e3bac81fb875",
        measurementId: "G-CGLH2MQLJ0",
      ),
    );
  } else {
    // Cấu hình cũ CHỈ CHẠY TRÊN MOBILE (Giữ nguyên của bạn để không lỗi code)
    await Firebase.initializeApp();
    
    // Crashlytics chỉ hoạt động trên Mobile
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }
}