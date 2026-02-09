import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      apiKey: "AIzaSyAQDfH6Z56xdMjoUVDnsBV_IJZKNCImNdI",
      authDomain: "speak-sharp-6bd84.firebaseapp.com",
      projectId: "speak-sharp-6bd84",
      storageBucket: "speak-sharp-6bd84.firebasestorage.app",
      messagingSenderId: "501197118454",
      appId: "1:501197118454:web:5e92b08fe54ac21a0ac5d7",
      measurementId: "G-CNXGRB9E7K"
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyADtcjX2N9Mgs3BjEBRHF6LN9k1MeH9uRs',
    appId: '1:501197118454:android:ce363fb3f005e22b0ac5d7',
    messagingSenderId: '501197118454',
    projectId: 'speak-sharp-6bd84',
    storageBucket: 'speak-sharp-6bd84.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAjmRqlY2ytkhHWyFbLyVyGkslmKP3djfo',
    appId: '1:501197118454:ios:8d03244f7e828f6e0ac5d7',
    messagingSenderId: '501197118454',
    projectId: 'speak-sharp-6bd84',
    storageBucket: 'speak-sharp-6bd84.firebasestorage.app',
    iosBundleId: 'com.example.frontend',
  );

}