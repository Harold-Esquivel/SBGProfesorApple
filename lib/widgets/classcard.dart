import 'package:flutter/material.dart';

class ClaseCard extends StatelessWidget {
  final String hora;
  final String materia;
  final String profesor;

  /// estado: activa | cancelada | hecha | reprogramada
  final String? estado;

  /// tipoClase: presencial | virtual
  final String? tipoClase;

  const ClaseCard({
    super.key,
    required this.hora,
    required this.materia,
    required this.profesor,
    this.estado,
    this.tipoClase,
  });

  // --- Helpers ---
  String _norm(String? v, String def) => (v ?? def).toString().trim().toLowerCase();

  Color _colorEstado(String e) {
    switch (e) {
      case "cancelada":
        return Colors.red;
      case "hecha":
        return Colors.green;
      case "reprogramada":
        return const Color(0xFFFFC107); // amarillo
      default:
        return Colors.blue; // activa
    }
  }

  Color _pastel(Color base) => base.withOpacity(0.12);

  IconData? _iconoEstado(String e) {
    switch (e) {
      case "cancelada":
        return Icons.close; // ❌
      case "hecha":
        return Icons.check; // ✅
      case "reprogramada":
        return Icons.priority_high_rounded; // ⚠️
      default:
        return null; // activa: sin icono estado
    }
  }

  IconData _iconoTipo(String t) {
    // siempre mostramos uno u otro
    return (t == "virtual") ? Icons.laptop : Icons.person; // 💻 o 🧑‍🏫
  }

  @override
  Widget build(BuildContext context) {
    final e = _norm(estado, "activa");
    final t = _norm(tipoClase, "presencial");

    final colorBase = _colorEstado(e);
    final iconEstado = _iconoEstado(e);
    final iconTipo = _iconoTipo(t);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _pastel(colorBase),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBase, width: 1.5),
      ),
      child: Row(
        children: [
          // Hora pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorBase,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              hora,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(materia, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(profesor, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),

          // Iconos derecha (solo los que quieres)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono tipo (siempre)
              Icon(iconTipo, size: 20, color: Colors.black87),

              if (iconEstado != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorBase.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconEstado, size: 18, color: colorBase),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}