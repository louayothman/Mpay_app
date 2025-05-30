// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD_mmUHXM3had5NDFDejogVzTlt4QyZSKg',
    appId: '1:811382017462:web:ca115cd79ea21522af8517',
    messagingSenderId: '811382017462',
    projectId: 'mopay-pro',
    authDomain: 'mopay-pro.firebaseapp.com',
    storageBucket: 'mopay-pro.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD_mmUHXM3had5NDFDejogVzTlt4QyZSKg',
    appId: '1:811382017462:android:ca115cd79ea21522af8517',
    messagingSenderId: '811382017462',
    projectId: 'mopay-pro',
    storageBucket: 'mopay-pro.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD_mmUHXM3had5NDFDejogVzTlt4QyZSKg',
    appId: '1:811382017462:ios:ca115cd79ea21522af8517',
    messagingSenderId: '811382017462',
    projectId: 'mopay-pro',
    storageBucket: 'mopay-pro.firebasestorage.app',
    iosClientId: '811382017462-ibmff2159g6hijkl4fdsa4c9e8p7vhbk.apps.googleusercontent.com',
    iosBundleId: 'com.mpay.android',
  );
}
