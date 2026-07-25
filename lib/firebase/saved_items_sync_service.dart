import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/journal_model.dart';
import '../models/publication_model.dart';

class SavedItemsSyncException implements Exception {
  const SavedItemsSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SavedItemsSyncService {
  SavedItemsSyncService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static bool get canUseDefaultFirebase => Firebase.apps.isNotEmpty;

  Future<void> saveJournal(Journal journal) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const SavedItemsSyncException(
        'Sign in before saving bookmarks to Firestore.',
      );
    }
    if (journal.id.isEmpty) return;

    await _userCollection(
      user.uid,
      'savedJournals',
    ).doc(_documentId(journal.id)).set({
      ...journal.toStoredJson(),
      'itemId': journal.id,
      'savedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Journal>> fetchSavedJournals({int limit = 100}) async {
    final user = _auth.currentUser;
    if (user == null) return const [];

    final snapshot = await _userCollection(
      user.uid,
      'savedJournals',
    ).orderBy('savedAt', descending: true).limit(limit).get();

    return snapshot.docs
        .map((document) {
          final data = Map<String, dynamic>.from(document.data());
          data['id'] ??= data['itemId'];
          try {
            return Journal.fromStoredJson(data);
          } catch (_) {
            return null;
          }
        })
        .whereType<Journal>()
        .where((journal) => journal.id.isNotEmpty)
        .toList();
  }

  Future<void> removeJournal(String journalId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const SavedItemsSyncException(
        'Sign in before removing bookmarks from Firestore.',
      );
    }
    if (journalId.isEmpty) return;

    await _userCollection(
      user.uid,
      'savedJournals',
    ).doc(_documentId(journalId)).delete();
  }

  Future<void> savePublication(Publication publication) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const SavedItemsSyncException(
        'Sign in before saving bookmarks to Firestore.',
      );
    }
    if (publication.id.isEmpty) return;

    await _userCollection(
      user.uid,
      'savedPublications',
    ).doc(_documentId(publication.id)).set({
      ...publication.toStoredJson(),
      'itemId': publication.id,
      'savedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Publication>> fetchSavedPublications({int limit = 100}) async {
    final user = _auth.currentUser;
    if (user == null) return const [];

    final snapshot = await _userCollection(
      user.uid,
      'savedPublications',
    ).orderBy('savedAt', descending: true).limit(limit).get();

    return snapshot.docs
        .map((document) {
          final data = Map<String, dynamic>.from(document.data());
          data['id'] ??= data['itemId'];
          try {
            return Publication.fromStoredJson(data);
          } catch (_) {
            return null;
          }
        })
        .whereType<Publication>()
        .where((publication) => publication.id.isNotEmpty)
        .toList();
  }

  Future<void> removePublication(String publicationId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const SavedItemsSyncException(
        'Sign in before removing bookmarks from Firestore.',
      );
    }
    if (publicationId.isEmpty) return;

    await _userCollection(
      user.uid,
      'savedPublications',
    ).doc(_documentId(publicationId)).delete();
  }

  CollectionReference<Map<String, dynamic>> _userCollection(
    String uid,
    String collectionName,
  ) {
    return _firestore.collection('users').doc(uid).collection(collectionName);
  }

  String _documentId(String value) {
    return base64Url.encode(utf8.encode(value));
  }
}
