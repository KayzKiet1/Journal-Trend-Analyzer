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

  bool get hasSignedInUser => _auth.currentUser != null;

  Future<void> saveJournal(Journal journal) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const SavedItemsSyncException(
        'Sign in before saving bookmarks to Firestore.',
      );
    }
    if (journal.id.isEmpty) return;

    final batch = _firestore.batch();
    final userDocument = _userDocument(user.uid);
    final savedDocument = userDocument
        .collection('savedJournals')
        .doc(_documentId(journal.id));

    batch.set(userDocument, _userProfileData(user), SetOptions(merge: true));
    batch.set(savedDocument, {
      ...journal.toStoredJson(),
      'itemId': journal.id,
      'type': 'journal',
      'savedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
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

    final batch = _firestore.batch();
    final userDocument = _userDocument(user.uid);
    batch.set(userDocument, _userProfileData(user), SetOptions(merge: true));
    batch.delete(
      userDocument.collection('savedJournals').doc(_documentId(journalId)),
    );
    await batch.commit();
  }

  Future<void> savePublication(Publication publication) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const SavedItemsSyncException(
        'Sign in before saving bookmarks to Firestore.',
      );
    }
    if (publication.id.isEmpty) return;

    final batch = _firestore.batch();
    final userDocument = _userDocument(user.uid);
    final savedDocument = userDocument
        .collection('savedPublications')
        .doc(_documentId(publication.id));

    batch.set(userDocument, _userProfileData(user), SetOptions(merge: true));
    batch.set(savedDocument, {
      ...publication.toStoredJson(),
      'itemId': publication.id,
      'type': 'publication',
      'savedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
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

    final batch = _firestore.batch();
    final userDocument = _userDocument(user.uid);
    batch.set(userDocument, _userProfileData(user), SetOptions(merge: true));
    batch.delete(
      userDocument
          .collection('savedPublications')
          .doc(_documentId(publicationId)),
    );
    await batch.commit();
  }

  Future<void> saveJournals(Iterable<Journal> journals) async {
    for (final journal in journals) {
      if (journal.id.isNotEmpty) {
        await saveJournal(journal);
      }
    }
  }

  Future<void> savePublications(Iterable<Publication> publications) async {
    for (final publication in publications) {
      if (publication.id.isNotEmpty) {
        await savePublication(publication);
      }
    }
  }

  CollectionReference<Map<String, dynamic>> _userCollection(
    String uid,
    String collectionName,
  ) {
    return _userDocument(uid).collection(collectionName);
  }

  DocumentReference<Map<String, dynamic>> _userDocument(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Map<String, dynamic> _userProfileData(User user) {
    return {
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'photoUrl': user.photoURL ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
      'lastBookmarkSyncAt': FieldValue.serverTimestamp(),
    };
  }

  String _documentId(String value) {
    return base64Url.encode(utf8.encode(value));
  }
}
