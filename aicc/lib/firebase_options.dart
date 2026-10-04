import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Placeholder until `flutterfire configure --project=aicc-mobile` overwrites
/// this file. [FirebaseBootstrap] treats an API key containing `REPLACE` as
/// "not connected yet".
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('AICC is configured for Android only.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'AICC is configured for Android only.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD333fGOwbdejOuiRJmgwPD67Bm3C3l1oI',
    appId: '1:210376358380:android:9c622b01a7a72c6d0128c9',
    messagingSenderId: '210376358380',
    projectId: 'aicc-mobile-48ed6',
    storageBucket: 'aicc-mobile-48ed6.firebasestorage.app',
  );
}
