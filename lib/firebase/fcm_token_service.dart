import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FcmTokenService {
  FcmTokenService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> saveToken(String? token) async {
    final user = _auth.currentUser;
    if (user == null || token == null || token.isEmpty) {
      return;
    }

    final tokenId = base64Url.encode(utf8.encode(token));
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('fcmTokens')
        .doc(tokenId)
        .set({
          'token': token,
          'platform': _platformLabel(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userEmail': user.email,
        }, SetOptions(merge: true));
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
