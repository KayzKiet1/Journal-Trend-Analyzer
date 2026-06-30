import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/publication_controller.dart';
import 'controllers/journal_library_controller.dart';
import 'controllers/firebase_demo_controller.dart';
import 'controllers/user_controller.dart';
import 'screens/main_screen.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      runApp(const JournalTrendAnalyzerApp());
    },
    (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    },
  );
}

/// Lớp gốc của ứng dụng, thiết lập quản lý trạng thái và giao diện chính.
/// Đã gỡ bỏ khung điện thoại ép buộc trên Web để tối ưu cho màn hình lớn.
class JournalTrendAnalyzerApp extends StatelessWidget {
  const JournalTrendAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PublicationController()),
        ChangeNotifierProvider(create: (_) => JournalLibraryController()),
        ChangeNotifierProvider(create: (_) => UserController()),
        ChangeNotifierProvider(create: (_) => FirebaseDemoController()),
      ],
      child: MaterialApp(
        title: 'Journal Trend Analyzer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainScreen(),
      ),
    );
  }
}
