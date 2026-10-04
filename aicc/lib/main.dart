import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final firebaseReady = await FirebaseBootstrap.initialize();
  runApp(AiccApp(firebaseReady: firebaseReady, preferences: preferences));
}
