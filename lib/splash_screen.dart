import 'dart:math';

import 'package:flutter/material.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const List<String> _loadingMessages = [
    'Profesor bienvenido, espere un ratito...',
    'Tus horarios en la palma de tu mano',
    'Haz tus pagos a tiempo',
    'Preparando tu informacion academica',
    'Organizando tus clases del dia',
  ];

  late AnimationController _controller;
  late AnimationController _dotsController;
  late Animation<Offset> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _fadeOutAnimation;
  late Duration _splashDuration;
  late String _loadingMessage;

  @override
  void initState() {
    super.initState();

    final random = Random();
    _splashDuration = Duration(seconds: 5 + random.nextInt(6));
    _loadingMessage =
        _loadingMessages[random.nextInt(_loadingMessages.length)];

    _controller = AnimationController(
      vsync: this,
      duration: _splashDuration,
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    // Logo sube
    _logoAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.6),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Texto aparece
    _textAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.75, curve: Curves.easeIn),
      ),
    );

    // Fade out final
    _fadeOutAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1, curve: Curves.easeOut),
      ),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _controller.forward();

    await Future.delayed(_splashDuration);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AuthGate(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, _) {
        final activeDot = (_dotsController.value * 3).floor() % 3;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isActive = index == activeDot;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: isActive ? 12 : 8,
              height: isActive ? 12 : 8,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color.fromARGB(255, 71, 76, 223)
                    : const Color.fromARGB(90, 71, 76, 223),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: FadeTransition(
        opacity: _fadeOutAnimation,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    SlideTransition(
                      position: _logoAnimation,
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 120,
                      ),
                    ),

                    const SizedBox(height: 20),

                    FadeTransition(
                      opacity: _textAnimation,
                      child: const Text(
                        "BIENVENIDO",
                        style: TextStyle(
                          color: Color.fromARGB(255, 37, 37, 37),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 36,
                child: FadeTransition(
                  opacity: _textAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLoadingDots(),
                      const SizedBox(height: 18),
                      Text(
                        _loadingMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 78, 78, 78),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
