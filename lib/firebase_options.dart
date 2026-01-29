// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web has not been configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS has not been configured yet.');
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS has not been configured yet.');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows has not been configured yet.');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux has not been configured yet.');
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ✅ This matches the company backend (sarri-ride-7aced)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAXQ1WizVy0J_LmYIg8Fxwr5X0MKx2Uhm0',
    appId: '1:566802818676:android:7b6eb385ba740529169321',
    messagingSenderId: '566802818676',
    projectId: 'sarri-ride-7aced',
    storageBucket: 'sarri-ride-7aced.firebasestorage.app',
  );
}
