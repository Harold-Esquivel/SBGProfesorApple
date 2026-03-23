import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

const kPrimary = Color.fromARGB(255, 71, 76, 223);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'SBG Profesores', home: SplashScreen());
  }
}

class PushService {
  static final _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    // iOS: pedir permiso (en Android también sirve)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Token del dispositivo (guárdalo en Firestore si quieres)
    final token = await _fcm.getToken();
    print("FCM TOKEN: $token");

    // Opcional: escuchar mensajes con app abierta
    FirebaseMessaging.onMessage.listen((message) {
      print("Mensaje en foreground: ${message.notification?.title}");
    });
  }
}
