import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sbg_profesores/auth_gate.dart';
import 'package:sbg_profesores/services/notification_service.dart';

class AuthNavigationService {
  const AuthNavigationService._();

  static Future<void> signOutAndReturnToLogin(BuildContext context) async {
    await NotificationService.instance.clearUserContext();
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }
}
