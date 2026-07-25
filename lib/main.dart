import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase/firebase_initializer.dart';
import 'screens/main_screen.dart';
import 'utils/app_theme.dart';
import 'viewmodels/firebase_view_model.dart';
import 'viewmodels/journal_library_view_model.dart';
import 'viewmodels/keywords_view_model.dart';
import 'viewmodels/notification_view_model.dart';
import 'viewmodels/publication_bookmark_view_model.dart';
import 'viewmodels/publication_view_model.dart';
import 'viewmodels/user_view_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:journal_trend_analyzer/firebase_options.dart';
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await initializeFirebase();
//   runApp(const JournalTrendAnalyzerApp());
// }
Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options:
    DefaultFirebaseOptions.currentPlatform, 
  );
 runApp(const JournalTrendAnalyzerApp());
}

/// Lớp gốc của ứng dụng, thiết lập quản lý trạng thái và giao diện chính.

class JournalTrendAnalyzerApp extends StatelessWidget {
  const JournalTrendAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProxyProvider<UserViewModel, PublicationViewModel>(
          create: (_) => PublicationViewModel(),
          update: (_, userViewModel, publicationViewModel) {
            final controller = publicationViewModel ?? PublicationViewModel();
            final contactEmail = userViewModel.authEmail.isNotEmpty
                ? userViewModel.authEmail
                : userViewModel.email;
            controller.syncApiService(
              contactEmail,
              apiKey: userViewModel.apiKey,
            );
            return controller;
          },
        ),
        ChangeNotifierProxyProvider<UserViewModel, KeywordsViewModel>(
          create: (_) => KeywordsViewModel(),
          update: (_, userViewModel, keywordsViewModel) {
            final controller = keywordsViewModel ?? KeywordsViewModel();
            final contactEmail = userViewModel.authEmail.isNotEmpty
                ? userViewModel.authEmail
                : userViewModel.email;
            controller.syncApiService(contactEmail);
            return controller;
          },
        ),
        ChangeNotifierProxyProvider<UserViewModel, JournalLibraryViewModel>(
          create: (_) => JournalLibraryViewModel(),
          update: (_, userViewModel, journalLibraryViewModel) {
            final controller =
                journalLibraryViewModel ?? JournalLibraryViewModel();
            unawaited(
              controller.syncForSignedInUser(userViewModel.firebaseUser?.uid),
            );
            return controller;
          },
        ),
        ChangeNotifierProxyProvider<
          UserViewModel,
          PublicationBookmarkViewModel
        >(
          create: (_) => PublicationBookmarkViewModel(),
          update: (_, userViewModel, publicationBookmarkViewModel) {
            final controller =
                publicationBookmarkViewModel ?? PublicationBookmarkViewModel();
            unawaited(
              controller.syncForSignedInUser(userViewModel.firebaseUser?.uid),
            );
            return controller;
          },
        ),
        ChangeNotifierProvider(create: (_) => FirebaseViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
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
