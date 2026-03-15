import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/animated_role_button.dart'; // Tu widget personalizado

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B4FE3),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // LOGO
              Image.asset(
                'assets/images/logo.png',
                height: 120,
              ),

              const SizedBox(height: 30),

              const Text(
                "¿Cómo deseas ingresar?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 25),

              // BOTÓN PROFESOR (Ahora animado y limpio)
              AnimatedRoleButton(
                texto: "Profesor",
                icono: Icons.school,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen(role: "Profesor")),
                  );
                },
              ),

              const SizedBox(height: 15),

              // BOTÓN ALUMNO (Ahora animado y limpio)
              AnimatedRoleButton(
                texto: "Alumno",
                icono: Icons.person,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen(role: "Alumno")),
                  );
                },
              ),

              const SizedBox(height: 25),

              // CONSULTAS
              GestureDetector(
                onTap: () => _mostrarOpcionesContacto(context),
                child: const Text(
                  "¿Consultas? Haz clic aquí",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // He extraído el BottomSheet a una función para que el código sea más legible
  void _mostrarOpcionesContacto(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Contactanos"),
          content: const Text("Elige cualquier opción de como desees contactarnos."),
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