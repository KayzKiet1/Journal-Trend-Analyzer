import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/controllers/user_controller.dart';
import 'package:journal_trend_analyzer/firebase/firebase_auth_service.dart';
import 'package:journal_trend_analyzer/models/research_topic_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserController', () {
    test('updates email and API key', () async {
      final controller = UserController(authService: _FakeAuthService());
      await Future<void>.delayed(Duration.zero);

      await controller.updateEmail('student@example.com');
      await controller.updateApiKey('api-key');

      expect(controller.email, 'student@example.com');
      expect(controller.apiKey, 'api-key');
      expect(controller.hasEmail, isTrue);
    });

    test('keeps recent searches unique and limited to five items', () async {
      final controller = UserController(authService: _FakeAuthService());
      await Future<void>.delayed(Duration.zero);

      for (final query in ['a', 'b', 'c', 'd', 'e', 'f']) {
        await controller.addSearch(query);
      }
      await controller.addSearch('c');

      expect(controller.recentSearches.map((item) => item.label), [
        'c',
        'f',
        'e',
        'd',
        'b',
      ]);
    });

    test('stores topic ids for recent topic searches', () async {
      final controller = UserController(authService: _FakeAuthService());
      await Future<void>.delayed(Duration.zero);

      await controller.addTopicSearch([
        const ResearchTopic(id: 'https://openalex.org/T1', name: 'AI'),
        const ResearchTopic(id: 'https://openalex.org/T2', name: 'Health'),
      ]);

      expect(controller.recentSearches.single.label, 'AI, Health');
      expect(controller.recentSearches.single.topicIds, [
        'https://openalex.org/T1',
        'https://openalex.org/T2',
      ]);
      expect(controller.recentSearches.single.topicNames, ['AI', 'Health']);
    });

    test('clears search history', () async {
      final controller = UserController(authService: _FakeAuthService());
      await Future<void>.delayed(Duration.zero);

      await controller.addSearch('journals');
      await controller.clearHistory();

      expect(controller.recentSearches, isEmpty);
    });
  });
}

class _FakeAuthService implements FirebaseAuthService {
  @override
  AuthenticatedUser? get currentUser => null;

  @override
  Stream<AuthenticatedUser?> authStateChanges() => const Stream.empty();

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}
