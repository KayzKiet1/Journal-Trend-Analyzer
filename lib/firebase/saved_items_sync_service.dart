import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/journal_model.dart';
import '../models/publication_model.dart';

class SavedItemsSyncService {
  SavedItemsSyncService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> saveJournal(Journal journal) async {
    final user = _auth.currentUser;
    if (user == null || journal.id.isEmpty) return;

    await _userCollection(
      user.uid,
      'savedJournals',
    ).doc(_documentId(journal.id)).set({
      ...journal.toStoredJson(),
      'itemId': journal.id,
      'savedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeJournal(String journalId) async {
    final user = _auth.currentUser;
    if (user == null || journalId.isEmpty) return;

    await _userCollection(
      user.uid,
      'savedJournals',
    ).doc(_documentId(journalId)).delete();
  }

  Future<void> savePublication(Publication publication) async {
    final user = _auth.currentUser;
    if (user == null || publication.id.isEmpty) return;

    await _userCollection(
      user.uid,
      'savedPublications',
    ).doc(_documentId(publication.id)).set({
      ...publication.toStoredJson(),
      'itemId': publication.id,
      'savedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removePublication(String publicationId) async {
    final user = _auth.currentUser;
    if (user == null || publicationId.isEmpty) return;

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
