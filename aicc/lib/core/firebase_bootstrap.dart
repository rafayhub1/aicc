import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class FirebaseBootstrap {
  static Future<bool> initialize() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      if (options.apiKey.contains('REPLACE') || options.projectId.isEmpty) {
        debugPrint('Firebase is not configured yet.');
        return false;
      }
      await Firebase.initializeApp(options: options);
      debugPrint('Firebase initialized');
      return true;
    } catch (error, stack) {
      debugPrint('Firebase init failed: $error\n$stack');
      return false;
    }
  }
}
