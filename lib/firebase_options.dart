// GENERADO AUTOMÁTICAMENTE — este archivo es un placeholder.
//
// Ejecuta lo siguiente en la raíz del proyecto para generarlo de verdad,
// conectado a TU proyecto de Firebase (ver README.md, sección "Firebase"):
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Ese comando sobrescribe este archivo con las credenciales reales de tu
// proyecto (Android/iOS/Web) y no requiere que edites nada a mano.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions no está configurado para Web. '
        'Ejecuta `flutterfire configure`.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no soporta esta plataforma todavía. '
          'Ejecuta `flutterfire configure`.',
        );
    }
  }

  // Valores de ejemplo — REEMPLAZA ejecutando `flutterfire configure`.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDQrSkBUBEbWa0J35G7DhIZGI74WQBjXQ',
    appId: '1:354558851311:android:cbbbc5185639225cbcc31a',
    messagingSenderId: '354558851311',
    projectId: 'ultima-tanda-u-94678',
    storageBucket: 'ultima-tanda-u-94678.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: 'demo-app-id',
    messagingSenderId: 'demo-sender-id',
    projectId: 'demo-ultima-tanda',
    storageBucket: 'demo-ultima-tanda.appspot.com',
    iosBundleId: 'com.ultimatanda.app',
  );
}
