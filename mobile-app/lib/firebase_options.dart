import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for MindSpend.
///
/// The web config is complete. Android and iOS configs use the same
/// project but will need their own registered apps in Firebase Console
/// to get platform-specific API keys and app IDs.
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ─── Web ───
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDZ8XFtKVHPT5tJDnw6QPpux3LpyzKITuI',
    appId: '1:96965570872:web:f2439f927bd7d0858711cd',
    messagingSenderId: '96965570872',
    projectId: 'mindspend-f94e7',
    authDomain: 'mindspend-f94e7.firebaseapp.com',
    storageBucket: 'mindspend-f94e7.firebasestorage.app',
    measurementId: 'G-B5CLXESW7S',
  );

  // ─── Android ───
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBhDG9ALP8V5m6-OcYmzhq0OtbnndeGA3Q',
    appId: '1:96965570872:android:587f36dcaf144fc98711cd',
    messagingSenderId: '96965570872',
    projectId: 'mindspend-f94e7',
    storageBucket: 'mindspend-f94e7.firebasestorage.app',
  );

  // ─── iOS ───
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCLu7jOoiUXrZlUCanuM6U0JdQt_ol0lyw',
    appId: '1:96965570872:ios:45a00f3c46b1165b8711cd',
    messagingSenderId: '96965570872',
    projectId: 'mindspend-f94e7',
    storageBucket: 'mindspend-f94e7.firebasestorage.app',
    iosBundleId: 'mindspend.ios',
  );
}
