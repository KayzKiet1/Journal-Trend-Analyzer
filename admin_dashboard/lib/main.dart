import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/firebase/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const AdminDashboardApp());
}
