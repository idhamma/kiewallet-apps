// Nilai diinjek saat build via: flutter run --dart-define-from-file=.env.json
// Jangan hardcode secrets di sini. Salin .env.json.example → .env.json lalu isi.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const String _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
const String _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const String _storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
const String _messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
const String _appId = String.fromEnvironment('FIREBASE_APP_ID');
const String _measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKey,
    authDomain: _authDomain,
    projectId: _projectId,
    storageBucket: _storageBucket,
    messagingSenderId: _messagingSenderId,
    appId: _appId,
    measurementId: _measurementId,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: 'com.kiezu.kiewallet',
  );

  static const FirebaseOptions macos = ios;
}

const String appId = 'retrofin-app-pribadi';
const bool enableRegistration = false;
