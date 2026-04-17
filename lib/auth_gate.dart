import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sbg_profesores/home_screen_director.dart';
import 'package:sbg_profesores/home_screen_profesor.dart';
import 'package:sbg_profesores/home_screen_student.dart';
import 'package:sbg_profesores/role_selection_screen.dart';
import 'package:sbg_profesores/services/notification_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _configuredUid;

  void _syncNotifications(User? user) {
    final nextUid = user?.uid;
    if (_configuredUid == nextUid) return;
    _configuredUid = nextUid;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (user == null) {
        await NotificationService.instance.clearUserContext();
        return;
      }
      await NotificationService.instance.configureForUser(user);
    });
  }

  Widget _homeForUser(User user) {
    final email = (user.email ?? '').toLowerCase();

    if (email.endsWith('@sbgalumno.com')) {
      return const HomeAlumno();
    }
    if (email.endsWith('@sbgprofesor.com')) {
      return const HomeProfesor();
    }
    if (email.endsWith('@sbgdirector.com')) {
      return const HomeDirector();
    }

    return const RoleSelectionScreen();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        _syncNotifications(user);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return const RoleSelectionScreen();
        }

        return _homeForUser(user);
      },
    );
  }
}
