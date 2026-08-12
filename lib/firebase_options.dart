// lib/firebase/firebase_options.dart
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
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ============ WEB CONFIGURATION (UPDATED WITH YOUR VALUES) ============
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDvRPkZuoUvyVZRM8Wz3OAkFAyu3KjQjyI',
    appId: '1:625827773182:web:1348caa7ae5ec15b3083af',
    messagingSenderId: '625827773182',
    projectId: 'canteen-ordering-app-1cecf',
    authDomain: 'canteen-ordering-app-1cecf.firebaseapp.com',
    storageBucket: 'canteen-ordering-app-1cecf.firebasestorage.app',
  );

  // ============ ANDROID CONFIGURATION ============
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDact3fyf6by1RzPTdqPY3xhpoHKkKDgJM',
    appId: '1:625827773182:android:f8806e93bbc1fdfa3083af',
    messagingSenderId: '625827773182',
    projectId: 'canteen-ordering-app-1cecf',
    storageBucket: 'canteen-ordering-app-1cecf.firebasestorage.app',
  );

  // ============ iOS CONFIGURATION ============
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDact3fyf6by1RzPTdqPY3xhpoHKkKDgJM',
    appId: '1:625827773182:ios:YOUR_IOS_APP_ID', // Add iOS app ID if you have one
    messagingSenderId: '625827773182',
    projectId: 'canteen-ordering-app-1cecf',
    storageBucket: 'canteen-ordering-app-1cecf.firebasestorage.app',
    iosBundleId: 'com.example.canteen_ordering_app',
  );

  // ============ MACOS CONFIGURATION ============
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDact3fyf6by1RzPTdqPY3xhpoHKkKDgJM',
    appId: '1:625827773182:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '625827773182',
    projectId: 'canteen-ordering-app-1cecf',
    storageBucket: 'canteen-ordering-app-1cecf.firebasestorage.app',
    iosBundleId: 'com.example.canteen_ordering_app',
  );

  // ============ WINDOWS CONFIGURATION ============
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDvRPkZuoUvyVZRM8Wz3OAkFAyu3KjQjyI',
    appId: '1:625827773182:web:1348caa7ae5ec15b3083af',
    messagingSenderId: '625827773182',
    projectId: 'canteen-ordering-app-1cecf',
    authDomain: 'canteen-ordering-app-1cecf.firebaseapp.com',
    storageBucket: 'canteen-ordering-app-1cecf.firebasestorage.app',
  );

  // ============ LINUX CONFIGURATION ============
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDvRPkZuoUvyVZRM8Wz3OAkFAyu3KjQjyI',
    appId: '1:625827773182:web:1348caa7ae5ec15b3083af',
    messagingSenderId: '625827773182',
    projectId: 'canteen-ordering-app-1cecf',
    authDomain: 'canteen-ordering-app-1cecf.firebaseapp.com',
    storageBucket: 'canteen-ordering-app-1cecf.firebasestorage.app',
  );
}