import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/publication_controller.dart';
import 'controllers/analysis_controller.dart';
import 'screens/home_screen.dart';
import 'utils/app_colors.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const JournalTrendAnalyzerApp());
}

/// Lớp gốc của ứng dụng, thiết lập quản lý trạng thái và giao diện chính
class JournalTrendAnalyzerApp extends StatelessWidget {
  const JournalTrendAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Quản lý trạng thái bài báo và tìm kiếm
        ChangeNotifierProvider(create: (_) => PublicationController()),
        // Quản lý trạng thái phân tích xu hướng
        ChangeNotifierProvider(create: (_) => AnalysisController()),
      ],
      child: MaterialApp(
        title: 'Journal Trend Analyzer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          if (!kIsWeb) {
            return child ?? const SizedBox.shrink();
          }
          return _WebPhoneFrame(child: child ?? const SizedBox.shrink());
        },
        home: const HomeScreen(),
      ),
    );
  }
}

/// Khung hiển thị mô phỏng điện thoại khi chạy trên trình duyệt web
class _WebPhoneFrame extends StatelessWidget {
  const _WebPhoneFrame({required this.child});

  static const Size _phoneSize = Size(390, 844);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return ColoredBox(
      color: const Color(0xFFE5E7EB),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: _phoneSize.width,
            height: _phoneSize.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: MediaQuery(
                  data: mediaQuery.copyWith(
                    size: _phoneSize,
                    padding: const EdgeInsets.only(top: 24, bottom: 16),
                    viewPadding: const EdgeInsets.only(top: 24, bottom: 16),
                    viewInsets: EdgeInsets.zero,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
