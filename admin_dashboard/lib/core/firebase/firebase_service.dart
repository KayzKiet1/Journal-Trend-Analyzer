import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_options.dart';

class FirebaseService {
  const FirebaseService();

  static Future<void> initialize() async {
    await Firebase.initializeApp(options: AdminFirebaseOptions.currentPlatform);
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;

  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static FirebaseStorage get storage => FirebaseStorage.instance;

  static FirebaseFunctions get functions =>
      FirebaseFunctions.instanceFor(region: 'asia-southeast1');
}
