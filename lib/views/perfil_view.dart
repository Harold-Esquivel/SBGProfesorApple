import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class PerfilView extends StatelessWidget {
  final String userId;
  const PerfilView({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Perfil de $userId")),
    );
  }
}

TimeOfDay _normalizarMinutosCadaCinco(TimeOfDay time) {
  final totalMinutes = time.hour * 60 + time.minute;
  final normalizedTotal = ((totalMinutes / 5).round() * 5) % (24 * 60);
  return TimeOfDay(
    hour: normalizedTotal ~/ 60,
    minute: normalizedTotal % 60,
  );
}

Future<TimeOfDay?> mostrarPickerHoraIOS(BuildContext context, {TimeOfDay? inicial}) async {
  final initialTime = _normalizarMinutosCadaCinco(inicial ?? TimeOfDay.now());
  TimeOfDay selected = initialTime;

  final result = await showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: 320,
        padding: const EdgeInsets.only(top: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF1F1F1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
                  ),
                  const Text(
                    "Selecciona hora",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, selected),
                    child: const Text("Listo", style: TextStyle(color: Colors.blueAccent)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: CupertinoTheme(
                data: const CupertinoThemeData(brightness: Brightness.dark),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  minuteInterval: 5,
                  use24hFormat: false, // se ve AM/PM
                  initialDateTime: DateTime(
                    2026,
                    1,
                    1,
                    initialTime.hour,
                    initialTime.minute,
                  ),
                  onDateTimeChanged: (dt) {
                    selected = TimeOfDay(hour: dt.hour, minute: dt.minute);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  return result;
}

String fmt24(TimeOfDay t) {
  final h = t.hour.toString().padLeft(2, "0");
  final m = t.minute.toString().padLeft(2, "0");
  return "$h:$m";
}

InputDecoration darkInput({
  required String hint,
  IconData? icon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white54),
    prefixIcon: icon == null ? null : Icon(icon, color: Colors.white70),
    filled: true,
    fillColor: const Color(0xFF1F1F1F), // 🔥 oscuro
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.white24),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}
