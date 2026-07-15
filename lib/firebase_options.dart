import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase config for DTS Driver (project dtsdrop-85330).
/// Android/iOS package: com.osedhelu.dtsdriver
abstract final class DefaultFirebaseOptions {
  /// Web OAuth client (type 3) — required by google_sign_in for ID token.
  static const String googleServerClientId =
      '1015036938407-3b42tv87mauud225f3vfett7c5rtogof.apps.googleusercontent.com';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web no está soportado en DTS Driver.');
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
          'Plataforma no soportada: $defaultTargetPlatform',
        ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBj-DmYwHfG6kvSKoCF-kqC4tvt3v9pQBI',
    appId: '1:1015036938407:android:041cc4084dd2a93008b382',
    messagingSenderId: '1015036938407',
    projectId: 'dtsdrop-85330',
    storageBucket: 'dtsdrop-85330.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAy9TvSRYhYg83Gx9aBaafGNZaTzGTe1Z4',
    appId: '1:1015036938407:ios:659a99afcda1b3cf08b382',
    messagingSenderId: '1015036938407',
    projectId: 'dtsdrop-85330',
    storageBucket: 'dtsdrop-85330.firebasestorage.app',
    iosBundleId: 'com.osedhelu.dtsdriver',
    iosClientId: '1015036938407-8fvoe01ns93vce534lgseo9knquiqq68.apps.googleusercontent.com',
  );
}
