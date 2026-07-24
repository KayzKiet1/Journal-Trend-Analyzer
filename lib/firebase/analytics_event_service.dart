import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsEventService {
  AnalyticsEventService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> logEvent({
    required String eventName,
    Map<String, Object?> metadata = const {},
  }) async {
    final user = _auth.currentUser;

    await _firestore.collection('analytics_events').add({
      'eventName': eventName,
      'userId': user?.uid,
      'userEmail': user?.email,
      'createdAt': FieldValue.serverTimestamp(),
      'metadata': _sanitizeMap(metadata),
    });
  }

  Map<String, Object?> _sanitizeMap(Map<String, Object?> values) {
    return values.map((key, value) {
      if (value == null || value is num || value is bool) {
        return MapEntry(key, value);
      }

      if (value is Iterable) {
        return MapEntry(
          key,
          value.map((item) => item?.toString() ?? '').take(20).toList(),
        );
      }

      final text = value.toString();
      return MapEntry(key, text.length <= 500 ? text : text.substring(0, 500));
    });
  }
}
