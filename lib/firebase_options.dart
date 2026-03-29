import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS. '
          'Register a dedicated macOS Firebase app before enabling Firebase on macOS.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAzOcgsAJ7ig21GupyxXzk7jqB7bdSeM20',
    appId: '1:659082815757:web:259dd388485f1fef4fa844',
    messagingSenderId: '659082815757',
    projectId: 'drivesafe-e6049',
    authDomain: 'drivesafe-e6049.firebaseapp.com',
    storageBucket: 'drivesafe-e6049.firebasestorage.app',
    measurementId: 'G-KPGMFH938D',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA0xbdpM0p5Y3kn7oVBBNoCCcsJk-WPqvQ',
    appId: '1:659082815757:android:d12295b7adbe62a44fa844',
    messagingSenderId: '659082815757',
    projectId: 'drivesafe-e6049',
    storageBucket: 'drivesafe-e6049.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCSORC5cAiWTEWVrYOOBTGZ8jBanKNOato',
    appId: '1:659082815757:ios:2775e9d3cd8e91384fa844',
    messagingSenderId: '659082815757',
    projectId: 'drivesafe-e6049',
    storageBucket: 'drivesafe-e6049.firebasestorage.app',
    iosBundleId: 'com.example.driveSafeApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAzOcgsAJ7ig21GupyxXzk7jqB7bdSeM20',
    appId: '1:659082815757:web:041633ea789efc074fa844',
    messagingSenderId: '659082815757',
    projectId: 'drivesafe-e6049',
    authDomain: 'drivesafe-e6049.firebaseapp.com',
    storageBucket: 'drivesafe-e6049.firebasestorage.app',
    measurementId: 'G-X2MSMFXCWH',
  );
}
