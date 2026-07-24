import 'package:flutter/material.dart';
import 'package:sbg_profesores/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

import 'login_screen.dart';
import 'widgets/animated_role_button.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPrimaryBackground,
      body: Stack(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: context.appCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: context.appBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/logoapp.png',
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "¿Cómo deseas ingresar?",
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 25),
                  AnimatedRoleButton(
                    texto: "Profesor",
                    icono: Icons.school,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const LoginScreen(role: "Profesor"),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  AnimatedRoleButton(
                    texto: "Alumno",
                    icono: Icons.person,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const LoginScreen(role: "Alumno"),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  GestureDetector(
                    onTap: () => _mostrarOpcionesContacto(context),
                    child: Text(
                      "¿Consultas? Haz clic aquí",
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appMutedText,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            right: 20,
            bottom: 24,
            child: SafeArea(child: ThemeToggleButton()),
          ),
        ],
      ),
    );
  }

  void _mostrarOpcionesContacto(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Contáctanos"),
          content:
              const Text("Elige cualquier opción de como desees contactarnos."),
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.call),
              label: const Text("Llamar"),
              onPressed: () async {
                Navigator.pop(context);
                await _llamarSoporte(context);
              },
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.message),
              label: const Text("WhatsApp"),
              onPressed: () async {
                Navigator.pop(context);
                await _abrirWhatsApp(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _llamarSoporte(BuildContext context) async {
    final uri = Uri.parse("tel:+51933838734");
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir la llamada")),
      );
    }
  }

  Future<void> _abrirWhatsApp(BuildContext context) async {
    final uri = Uri.parse("https://wa.link/88bhl1");
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir WhatsApp")),
      );
    }
  }
}
