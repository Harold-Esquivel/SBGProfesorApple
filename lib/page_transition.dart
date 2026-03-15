import 'package:flutter/material.dart';

Route createRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {

      // La nueva pantalla entra desde la derecha
      final inAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0), // derecha
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      // La pantalla actual sale hacia la izquierda
      final outAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.3, 0.0), // izquierda
      ).animate(CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
      ));

      return SlideTransition(
        position: inAnimation,
        child: SlideTransition(
          position: outAnimation,
          child: child,
        ),
      );
    },
  );
}
