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
        return ios; // ✅ This is now fixed
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAXQ1WizVy0J_LmYIg8Fxwr5X0MKx2Uhm0',
    appId: '1:566802818676:android:7b6eb385ba740529169321',
    messagingSenderId: '566802818676',
    projectId: 'sarri-ride-7aced',
    storageBucket: 'sarri-ride-7aced.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAOcGWJwmFU43ydECj-musq59uE5Wtnx-w',
    appId: '1:566802818676:ios:ab316fe512256646169321',
    messagingSenderId: '566802818676',
    projectId: 'sarri-ride-7aced',
    storageBucket: 'sarri-ride-7aced.firebasestorage.app',
    iosBundleId: 'com.sarri.sarri-ride', // ✅ Ensure this matches Xcode
  );
}