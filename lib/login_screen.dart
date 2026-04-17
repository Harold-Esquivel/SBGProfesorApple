import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sbg_profesores/auth_gate.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  double _scale = 1.0;
  bool isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // --- FUNCIÓN CORREGIDA ---
  Future<void> login() async {
    FocusScope.of(context).unfocus(); // Ocultar teclado

    final codigo = emailController.text.trim();
    final password = passwordController.text.trim();

    // Validación básica
    if (codigo.isEmpty || password.isEmpty) {
      _showErrorDialog("Complete todos los apartados");
      return;
    }

    // 1. Encendemos el círculo de carga
    setState(() => isLoading = true);

    try {


if (widget.role == "Alumno") {

  final emailFalso = "$codigo@sbgalumno.com";

  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: emailFalso,
    password: password,
  );

} else if (widget.role == "Profesor") {

  try {
    // 🔥 Primero intenta como profesor
    final emailProfesor = "$codigo@sbgprofesor.com";

    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailProfesor,
      password: password,
    );

  } on FirebaseAuthException {
    // 🔥 Si falla, intenta como director automáticamente
    final emailDirector = "$codigo@sbgdirector.com";

    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailDirector,
      password: password,
    );
  }

} else {

  final emailFalso = "$codigo@sbg.com";

  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: emailFalso,
    password: password,
  );
}

if (!mounted) return;

final user = FirebaseAuth.instance.currentUser;

if (!mounted || user == null) return;

Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const AuthGate()),
  (route) => false,
);

} 
on FirebaseAuthException catch (e) {
      print("Error de Firebase: ${e.code}");
      
      String mensaje = "Código o contraseña incorrectos";
      
      if (e.code == 'network-request-failed') {
        mensaje = "Revisa tu conexión a internet";
      }
      _showErrorDialog(mensaje);
} 
catch (e) {
      
      print("Error desconocido: $e");
      _showErrorDialog("Ocurrió un error inesperado");
    } 
    finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // --- TU DIÁLOGO CON ANIMACIÓN BLOP ---
  void _showErrorDialog(String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Error",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 600),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
          reverseCurve: Curves.easeOut,
        );

        return ScaleTransition(
          scale: curvedAnimation,
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          backgroundColor: Colors.red.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Error",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              )
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 71, 76, 223),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Asegúrate de que esta imagen exista en tus assets
                Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    // Si no encuentra la imagen, muestra un ícono para que no truene
                    return const Icon(Icons.school, size: 80, color: Colors.blue);
                  },
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Código",
                    hintStyle: const TextStyle(color: Colors.white54),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    prefixIcon: const Icon(Icons.badge, color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Contraseña",
                    hintStyle: const TextStyle(color: Colors.white54),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    prefixIcon: const Icon(Icons.lock, color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                GestureDetector(
                  onTapDown: (_) {
                    if (!isLoading) setState(() => _scale = 0.96);
                  },
                  onTapUp: (_) {
                    if (!isLoading) setState(() => _scale = 1.0);
                  },
                  onTapCancel: () {
                    if (!isLoading) setState(() => _scale = 1.0);
                  },
                  onTap: isLoading ? null : login,
                  child: AnimatedScale(
                    scale: _scale,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4B4FE3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "Iniciar Sesión",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
