import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/firebase/firebase_auth_service.dart';
import 'package:journal_trend_analyzer/models/recent_search_model.dart';
import 'package:journal_trend_analyzer/models/research_topic_model.dart';
import 'package:journal_trend_analyzer/viewmodels/user_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserViewModel', () {
    test('updates email and API key', () async {
      final controller = UserViewModel(authService: _FakeAuthService());
      await Future<void>.delayed(Duration.zero);

      await controller.updateEmail('student@example.com');
      await controller.updateApiKey('api-key');

      expect(controller.email, 'student@example.com');
      expect(controller.apiKey, 'api-key');
      expect(controller.hasEmail, isTrue);
    });

    test('keeps recent searches unique and limited to five items', () async {
      final controller = UserViewModel(authService: _FakeAuthService());
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
        'a',
      ]);
    });

    test('stores topic ids for recent topic searches', () async {
      final controller = UserViewModel(authService: _FakeAuthService());
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
      final controller = UserViewModel(authService: _FakeAuthService());
      await Future<void>.delayed(Duration.zero);

      await controller.addSearch('journals');
      await controller.clearHistory();

      expect(controller.recentSearches, isEmpty);
    });

    test('loads stored profile and recent searches from preferences', () async {
      SharedPreferences.setMockInitialValues({
        'user_email': 'stored@example.com',
        'openalex_api_key': 'stored-key',
        'recent_searches': [
          '{"label":"AI","topic_ids":["T1"],"topic_names":["Artificial Intelligence"]}',
          'legacy search',
          '{"label":""}',
        ],
      });

      final controller = UserViewModel(authService: _FakeAuthService());
      await Future<void>.delayed(Duration.zero);

      expect(controller.email, 'stored@example.com');
      expect(controller.apiKey, 'stored-key');
      expect(controller.recentSearches.map((item) => item.label), [
        'AI',
        'legacy search',
      ]);
      expect(controller.recentSearches.first.topicNames, [
        'Artificial Intelligence',
      ]);
    });

    test('auth stream updates signed-in state and default email', () async {
      final auth = _FakeAuthService();
      final controller = UserViewModel(authService: auth);
      await Future<void>.delayed(Duration.zero);

      auth.emit(
        const AuthenticatedUser(
          uid: 'U1',
          email: 'google@example.com',
          displayName: 'Google User',
          photoUrl: 'https://example.com/avatar.png',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.isSignedIn, isTrue);
      expect(controller.authEmail, 'google@example.com');
      expect(controller.authDisplayName, 'Google User');
      expect(controller.authPhotoUrl, 'https://example.com/avatar.png');
      expect(controller.email, 'google@example.com');

      controller.dispose();
      await auth.close();
    });

    test('sign in and sign out expose auth loading and errors', () async {
      final auth = _FakeAuthService(
        signInError: const AuthServiceException('sign in failed'),
        signOutError: const AuthServiceException('sign out failed'),
      );
      final controller = UserViewModel(authService: auth);
      await Future<void>.delayed(Duration.zero);

      await controller.signInWithGoogle();
      expect(controller.isAuthLoading, isFalse);
      expect(controller.authError, 'sign in failed');

      await controller.signOut();
      expect(controller.isAuthLoading, isFalse);
      expect(controller.authError, 'sign out failed');

      controller.dispose();
      await auth.close();
    });

    test(
      'removes exact recent search and stores work search as plain query',
      () async {
        final controller = UserViewModel(authService: _FakeAuthService());
        await Future<void>.delayed(Duration.zero);

        await controller.addWorkSearch('machine learning', [
          const ResearchTopic(id: 'T1', name: 'AI'),
        ]);
        await controller.addSearch('plain');
        await controller.removeRecentSearch(controller.recentSearches.first);

        expect(controller.recentSearches.single.label, 'machine learning');
        expect(controller.recentSearches.single.topicIds, isEmpty);
        expect(RecentSearch(label: 'x').toStored(), 'x');
      },
    );
  });
}

class _FakeAuthService implements FirebaseAuthService {
  _FakeAuthService({this.signInError, this.signOutError});

  final AuthServiceException? signInError;
  final AuthServiceException? signOutError;
  final _controller = StreamController<AuthenticatedUser?>.broadcast();

  @override
  AuthenticatedUser? get currentUser => null;

  @override
  Stream<AuthenticatedUser?> authStateChanges() => _controller.stream;

  @override
  Future<void> signInWithGoogle() async {
    final error = signInError;
    if (error != null) throw error;
  }

  @override
  Future<void> signOut() async {
    final error = signOutError;
    if (error != null) throw error;
  }

  void emit(AuthenticatedUser? user) {
    _controller.add(user);
  }

  Future<void> close() => _controller.close();
}
