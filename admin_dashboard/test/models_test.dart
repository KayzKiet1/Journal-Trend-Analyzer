import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_admin_dashboard/data/models/admin_user.dart';
import 'package:journal_trend_admin_dashboard/data/models/dashboard_summary.dart';

void main() {
  test('AdminUser parses callable function data', () {
    final user = AdminUser.fromMap({
      'uid': 'user-1',
      'email': 'admin@gmail.com',
      'displayName': 'Admin',
      'photoURL': '',
      'disabled': false,
      'emailVerified': true,
      'creationTime': 'Fri, 24 Jul 2026 10:00:00 GMT',
      'lastSignInTime': 'Fri, 24 Jul 2026 11:00:00 GMT',
      'providerIds': ['password'],
      'isAdmin': true,
    });

    expect(user.uid, 'user-1');
    expect(user.email, 'admin@gmail.com');
    expect(user.role, 'Admin');
    expect(user.status, 'Active');
    expect(user.providerIds, ['password']);
  });

  test('DashboardSummary parses collection counts', () {
    final summary = DashboardSummary.fromMap({
      'userCount': 2,
      'storageFileCount': 3,
      'collectionCounts': {'journals': 4, 'publications': 5, 'appConfig': 1},
      'generatedAt': '2026-07-24T10:00:00.000Z',
    });

    expect(summary.userCount, 2);
    expect(summary.storageFileCount, 3);
    expect(summary.journalCount, 4);
    expect(summary.publicationCount, 5);
    expect(summary.appConfigCount, 1);
    expect(summary.generatedAt, isNotNull);
  });
}
