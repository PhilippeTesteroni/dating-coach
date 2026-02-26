// File generated manually from google-services.json
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyCm4uzZ1d66pJanuhBtaFq2ynm0yhoLLzM',
    appId: '1:469648498872:android:924901fbbb252eb51e944d',
    messagingSenderId: '469648498872',
    projectId: 'dating-coach-4faa0',
    storageBucket: 'dating-coach-4faa0.firebasestorage.app',
  );
}
