import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDact3fyf6by1RzPTdqPY3xhpoHKkKDgJM',
    appId: '1:625827773182:android:f8806e93bbc1fdfa3083af',
    messagingSenderId: '625827773182',
    projectId: 'canteen-ordering-app-1cecf',
    storageBucket: 'canteen-ordering-app-1cecf.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDact3fyf6by1RzPTdqPY3xhpoHKkKDgJM',
    appId: '1:625827773182:android:f8806e93bbc1fdfa3083af',
    messagingSenderId: '625827773182',
    projectId: 'canteen-ordering-app-1cecf',
    storageBucket: 'canteen-ordering-app-1cecf.firebasestorage.app',
    iosBundleId: 'YOUR_IOS_BUNDLE_ID',
  );
}