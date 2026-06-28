import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/controllers/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserController', () {
    test('updates email and API key', () async {
      final controller = UserController();
      await Future<void>.delayed(Duration.zero);

      await controller.updateEmail('student@example.com');
      await controller.updateApiKey('api-key');

      expect(controller.email, 'student@example.com');
      expect(controller.apiKey, 'api-key');
      expect(controller.hasEmail, isTrue);
    });

    test('keeps recent searches unique and limited to five items', () async {
      final controller = UserController();
      await Future<void>.delayed(Duration.zero);

      for (final query in ['a', 'b', 'c', 'd', 'e', 'f']) {
        await controller.addSearch(query);
      }
      await controller.addSearch('c');

      expect(controller.recentSearches, ['c', 'f', 'e', 'd', 'b']);
    });

    test('clears search history', () async {
      final controller = UserController();
      await Future<void>.delayed(Duration.zero);

      await controller.addSearch('journals');
      await controller.clearHistory();

      expect(controller.recentSearches, isEmpty);
    });
  });
}
