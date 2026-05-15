// Firebase projekt MSaSS (msass-b2ec1) — rovnaký ako Gemini API (286978506686).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBYssLrEXjx4zQnfAkoN4FKemBzeQ2Pim0',
    appId: '1:286978506686:web:b87e520cad80a7d90dc3ef',
    messagingSenderId: '286978506686',
    projectId: 'msass-b2ec1',
    authDomain: 'msass-b2ec1.firebaseapp.com',
    storageBucket: 'msass-b2ec1.firebasestorage.app',
    measurementId: 'G-D59BGN8C0J',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYssLrEXjx4zQnfAkoN4FKemBzeQ2Pim0',
    appId: '1:286978506686:web:b87e520cad80a7d90dc3ef',
    messagingSenderId: '286978506686',
    projectId: 'msass-b2ec1',
    authDomain: 'msass-b2ec1.firebaseapp.com',
    storageBucket: 'msass-b2ec1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBYssLrEXjx4zQnfAkoN4FKemBzeQ2Pim0',
    appId: '1:286978506686:web:b87e520cad80a7d90dc3ef',
    messagingSenderId: '286978506686',
    projectId: 'msass-b2ec1',
    authDomain: 'msass-b2ec1.firebaseapp.com',
    storageBucket: 'msass-b2ec1.firebasestorage.app',
  );

  static const FirebaseOptions macos = ios;
  static const FirebaseOptions windows = web;
}
