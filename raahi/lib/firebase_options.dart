import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDfgZcLIF8SGaBBZs0JLX1FwlGl1R914w4',
    appId: '1:313987257887:android:c42feab1896c9befa1a72a',
    messagingSenderId: '313987257887',
    projectId: 'raahi-d3564',
    storageBucket: 'raahi-d3564.appspot.com',
  );
}
