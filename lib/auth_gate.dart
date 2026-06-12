import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sbg_profesores/home_screen_director.dart';
import 'package:sbg_profesores/home_screen_profesor.dart';
import 'package:sbg_profesores/home_screen_student.dart';
import 'package:sbg_profesores/role_selection_screen.dart';
import 'package:sbg_profesores/services/notification_service.dart';
import 'package:sbg_profesores/theme/app_theme.dart';

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

  bool _isDirector(User user) {
    final email = (user.email ?? '').toLowerCase();
    return email.endsWith('@sbgdirector.com');
  }

  bool _isInactive(DocumentSnapshot<Map<String, dynamic>>? doc) {
    final data = doc?.data() ?? {};
    final estado = (data['estado'] ?? 'activo').toString().trim().toLowerCase();
    return estado == 'inactivo';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          _syncNotifications(null);
          return const RoleSelectionScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting &&
                !userSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!_isDirector(user) && _isInactive(userSnapshot.data)) {
              _syncNotifications(null);
              return const _UsuarioInactivoScreen();
            }

            _syncNotifications(user);
            return _homeForUser(user);
          },
        );
      },
    );
  }
}

class _UsuarioInactivoScreen extends StatelessWidget {
  const _UsuarioInactivoScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPrimaryBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.appPanel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.appBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block, color: Colors.red, size: 44),
                  const SizedBox(height: 12),
                  const Text(
                    'Usuario inactivo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu acceso esta desactivado. El Director puede volver a activarlo desde Perfil > Ver usuarios.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appMutedText,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesion'),
                      onPressed: () => FirebaseAuth.instance.signOut(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
