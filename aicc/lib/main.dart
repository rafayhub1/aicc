/// Starts the AICC app: prepares Flutter, loads saved preferences, then
/// connects Firebase before the first screen is shown.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase_bootstrap.dart';

/// Boots widgets, shared preferences, and Firebase, then runs [AiccApp].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final firebaseReady = await FirebaseBootstrap.initialize();
  runApp(AiccApp(firebaseReady: firebaseReady, preferences: preferences));
}
