import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sbg_profesores/firebase_options.dart';
import 'package:sbg_profesores/services/notification_service.dart';
import 'package:sbg_profesores/splash_screen.dart';

const kPrimary = Color.fromARGB(255, 71, 76, 223);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es_ES', null);
  await NotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'SBG Profesores',
      home: SplashScreen(),
    );
  }
}
