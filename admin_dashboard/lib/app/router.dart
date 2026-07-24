import 'package:flutter/material.dart';

import '../core/auth/auth_guard.dart';
import '../features/analytics/analytics_page.dart';
import '../features/app_config/app_config_page.dart';
import '../features/audit_logs/audit_logs_page.dart';
import '../features/auth/login_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/firestore_manager/collections_page.dart';
import '../features/firestore_manager/document_detail_page.dart';
import '../features/firestore_manager/documents_page.dart';
import '../features/messaging/messaging_page.dart';
import '../features/storage_manager/storage_detail_page.dart';
import '../features/storage_manager/storage_page.dart';
import '../features/users/user_detail_page.dart';
import '../features/users/users_page.dart';

class AdminRoutes {
  const AdminRoutes._();

  static const login = '/login';
  static const dashboard = '/';
  static const users = '/users';
  static const userDetail = '/users/detail';
  static const firestoreCollections = '/firestore';
  static const firestoreDocuments = '/firestore/documents';
  static const firestoreDocumentDetail = '/firestore/documents/detail';
  static const storage = '/storage';
  static const storageDetail = '/storage/detail';
  static const appConfig = '/app-config';
  static const analytics = '/analytics';
  static const messaging = '/messaging';
  static const auditLogs = '/audit-logs';
}

Map<String, WidgetBuilder> buildAdminRoutes() {
  return {
    AdminRoutes.login: (_) => const LoginPage(),
    AdminRoutes.dashboard: (_) => AuthGuard(child: const DashboardPage()),
    AdminRoutes.users: (_) => AuthGuard(child: const UsersPage()),
    AdminRoutes.userDetail: (_) => AuthGuard(child: const UserDetailPage()),
    AdminRoutes.firestoreCollections: (_) =>
        AuthGuard(child: const CollectionsPage()),
    AdminRoutes.firestoreDocuments: (_) =>
        AuthGuard(child: const DocumentsPage()),
    AdminRoutes.firestoreDocumentDetail: (_) =>
        AuthGuard(child: const DocumentDetailPage()),
    AdminRoutes.storage: (_) => AuthGuard(child: const StoragePage()),
    AdminRoutes.storageDetail: (_) =>
        AuthGuard(child: const StorageDetailPage()),
    AdminRoutes.appConfig: (_) => AuthGuard(child: const AppConfigPage()),
    AdminRoutes.analytics: (_) => AuthGuard(child: const AnalyticsPage()),
    AdminRoutes.messaging: (_) => AuthGuard(child: const MessagingPage()),
    AdminRoutes.auditLogs: (_) => AuthGuard(child: const AuditLogsPage()),
  };
}
