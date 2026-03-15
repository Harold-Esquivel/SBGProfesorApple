import 'package:flutter/material.dart';
import 'package:sbg_profesores/theme/app_colors.dart';



class AnimatedRoleButton extends StatefulWidget {
  final String texto;
  final IconData icono;
  final VoidCallback onTap;
  final Color color;

  const AnimatedRoleButton({
    super.key,
    required this.texto,
    required this.icono,
    required this.onTap,
    this.color = const Color(0xFF4B4FE3),
  });

  @override
  State<AnimatedRoleButton> createState() => _BotonMenuAnimadoState();
}

class _BotonMenuAnimadoState extends State<AnimatedRoleButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icono, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                widget.texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// imports...

Widget botonPrimario({
  required String texto,
  required VoidCallback onTap,
  IconData? icono,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(50)),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              kPrimary,
              Color.fromARGB(255, 90, 95, 255),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icono != null) ...[
              Icon(icono, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              texto,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
