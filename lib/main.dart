import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/publication_controller.dart';
import 'controllers/journal_library_controller.dart';
import 'controllers/firebase_demo_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/user_controller.dart';
import 'firebase/firebase_initializer.dart';
import 'screens/main_screen.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const JournalTrendAnalyzerApp());
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
        ChangeNotifierProvider(create: (_) => NotificationController()),
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
