import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sbg_profesores/widgets/classcard.dart';
import 'package:sbg_profesores/theme/app_colors.dart';
import 'package:sbg_profesores/widgets/animated_role_button.dart';
import 'package:sbg_profesores/views/perfil_view.dart';

int _durToMin(String d) {
  switch (d) {
    case "45": return 45;
    case "60": return 60;
    case "90": return 90;
    case "120": return 120;
    default: return 60;
  }
}

TimeOfDay _addMinutes(TimeOfDay t, int minutes) {
  final total = t.hour * 60 + t.minute + minutes;
  final h = (total ~/ 60) % 24;
  final m = total % 60;
  return TimeOfDay(hour: h, minute: m);
}

Future<String?> _pickDuracion(BuildContext context, {required String actual}) async {
  const opciones = ["45", "60", "90", "120"];

  return showDialog<String>(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("Elige duración"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: opciones.map((v) {
            final selected = v == actual;
            return ListTile(
              title: Text("$v min"),
              trailing: Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? kPrimary : Colors.grey,
              ),
              onTap: () => Navigator.pop(context, v),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
        ],
      );
    },
  );
}

Future<T?> showPopDialog<T>({
  required BuildContext context,
  required Widget child,
  bool dismissible = true,
}) 
{
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: "dialog",
    barrierColor: Colors.black.withValues(),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) {
      return SafeArea(
        child: Center(child: child),
      );
    },
    transitionBuilder: (_, anim, _, widget) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: widget,
        ),
      );
    },
  );
}

/// ---------- App ----------

class NotificacionesProfesorView extends StatelessWidget {
  final String profesorId;
  const NotificacionesProfesorView({super.key, required this.profesorId});

  Widget _fila(String t, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text("$t:", style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );
}

TimeOfDay _parseHora(String hhmm) {
  try {
    final parts = hhmm.split(":");
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return TimeOfDay(hour: h, minute: m);
  } catch (_) {
    return const TimeOfDay(hour: 8, minute: 0);
  }
}

  void _rechazarConMotivo(BuildContext context, QueryDocumentSnapshot solicitud) {
  final motivoCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("Motivo de rechazo"),
        content: TextField(
          controller: motivoCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Ej: Ese día no estoy disponible / horario ocupado / etc.",
          ),
        ),
        actions: [
          TextButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:kPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Volver"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red),
            onPressed: () async {
              final motivo = motivoCtrl.text.trim();

              await solicitud.reference.update({
                "estado": "rechazada",
                "motivoRechazo": motivo,
                "respondedAt": Timestamp.now(),
              });

              if (context.mounted) Navigator.pop(context);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Solicitud rechazada ❌")),
                );
              }
            },
            child: const Text("Enviar y rechazar"),
          ),
        ],
      );
    },
  );
}
  void _abrirDetalleSolicitud(
  BuildContext context,
  QueryDocumentSnapshot solicitud,
  String profesorId,
) async {
  final data = solicitud.data() as Map<String, dynamic>;

  final alumnoNombre = (data["alumnoNombre"] ?? "Alumno").toString();
  final alumnoId = (data["alumnoId"] ?? "").toString();

  final materia = (data["materia"] ?? "Materia").toString();
  final mensaje = (data["mensaje"] ?? "").toString();

  DateTime fecha = DateTime.now();
  final ts = data["fecha"];
  if (ts is Timestamp) fecha = ts.toDate();

  // ✅ Hora inicio desde solicitud
  TimeOfDay horaIni = _parseHora(data["horaInicio"]?.toString() ?? "08:00");

  // ✅ Duración (si ya la guardas en solicitudes, la usa; si no, default 60)
  String duracion = "60";
  final durMinDb = data["duracionMin"];
  if (durMinDb is int) duracion = durMinDb.toString();

  String tipoClase = (data["tipoClase"] ?? "presencial").toString();

  String txtFecha() =>
      "${fecha.day.toString().padLeft(2, "0")}/${fecha.month.toString().padLeft(2, "0")}/${fecha.year}";

  String txtHora(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}";

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            // ✅ calcular hora fin automático según duración
            final minutos = _durToMin(duracion);
            final horaFinCalc = _addMinutes(horaIni, minutos);
            final textoFin = txtHora(horaFinCalc);

            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Detalle de solicitud",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),

                    _fila("Materia", materia),
                    _fila("Alumno", alumnoNombre),
                    if (mensaje.isNotEmpty) _fila("Mensaje", mensaje),

                    const SizedBox(height: 12),
                    const Divider(),

                    // Fecha
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Fecha: ${txtFecha()}"),
                        TextButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: fecha,
                              firstDate: DateTime(2023),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) setModalState(() => fecha = picked);
                          },
                          child: const Text("Cambiar"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ✅ Hora inicio
                    InkWell(
                      onTap: () async {
                        final picked = await mostrarPickerHoraIOS(context, inicial: horaIni);
                        if (picked != null) setModalState(() => horaIni = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Hora inicio: ${txtHora(horaIni)}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ✅ Duración (cuadro clickeable)
                    InkWell(
                      onTap: () async {
                        final picked = await _pickDuracion(context, actual: duracion);
                        if (picked != null) setModalState(() => duracion = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Duración: $duracion min",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Tipo (presencial/virtual)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ChoiceChip(
                            label: const Text("Presencial"),
                            selected: tipoClase == "presencial",
                            selectedColor: kPrimary,
                            backgroundColor: Colors.grey.shade800,
                            labelStyle: const TextStyle(color: Colors.white),
                            onSelected: (_) => setModalState(() => tipoClase = "presencial"),
                          ),
                          ChoiceChip(
                            label: const Text("Virtual"),
                            selected: tipoClase == "virtual",
                            selectedColor: kPrimary,
                            backgroundColor: Colors.grey.shade800,
                            labelStyle: const TextStyle(color: Colors.white),
                            onSelected: (_) => setModalState(() => tipoClase = "virtual"),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ✅ ACEPTAR
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text("Aceptar y crear clase"),
                      onPressed: () async {
                        // ✅ bloqueo si pasa al día siguiente (opcional, recomendado)
                        final iniMin = horaIni.hour * 60 + horaIni.minute;
                        if (iniMin + minutos >= 24 * 60) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("La duración pasa al día siguiente. Elige otra hora.")),
                          );
                          return;
                        }

                        final batch = FirebaseFirestore.instance.batch();

                        // 1) Marcar solicitud aceptada + guardar edición profe
                        batch.update(solicitud.reference, {
                          "estado": "aceptada",
                          "fecha": Timestamp.fromDate(fecha),
                          "horaInicio": txtHora(horaIni),
                          "horaFin": textoFin, // ✅ calculada
                          "duracionMin": minutos, // ✅ guardamos duración
                          "tipoClase": tipoClase,
                          "respondedAt": Timestamp.now(),
                        });

                        // 2) Crear clase
                        final claseRef = FirebaseFirestore.instance.collection("clases").doc();
                        batch.set(claseRef, {
                          "materia": materia,
                          "fecha": Timestamp.fromDate(fecha),
                          "horaInicio": txtHora(horaIni),
                          "horaFin": textoFin, // ✅ calculada
                          "duracionMin": minutos, // ✅
                          "tipoClase": tipoClase,
                          "profesorId": profesorId,
                          "alumnosId": [alumnoId],
                          "asistieron": [],
                          "estado": "activa",
                          "createdAt": Timestamp.now(),
                          "solicitudId": solicitud.id,
                        });

                        await batch.commit();

                        if (context.mounted) Navigator.pop(context);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Clase creada ✅")),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    // RECHAZAR con motivo
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text("Rechazar (con motivo)"),
                      onPressed: () async {
                        Navigator.pop(context);
                        _rechazarConMotivo(context, solicitud);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("solicitudes_clase")
                    .where("profesorId", isEqualTo: profesorId)
                    .where("estado", isEqualTo: "pendiente")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No hay solicitudes pendientes",
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final s = docs[i];
                      final data = s.data() as Map<String, dynamic>;

                      final alumnoNombre = (data["alumnoNombre"] ?? "Alumno").toString();
                      final materia = (data["materia"] ?? "Materia").toString();
                      final mensaje = (data["mensaje"] ?? "").toString();

                      return InkWell(
  borderRadius: BorderRadius.circular(16),
  onTap: () => _abrirDetalleSolicitud(context, s, profesorId),
  child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          materia,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text("Alumno: $alumnoNombre"),
        if (mensaje.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text("Mensaje: $mensaje", style: const TextStyle(color: Colors.black54)),
        ],
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check),
                label: const Text("Aceptar"),
                onPressed: () async {
                  // si quieres, aquí también podrías abrir el detalle
                  _abrirDetalleSolicitud(context, s, profesorId);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.close),
                label: const Text("Rechazar"),
                onPressed: () => _rechazarConMotivo(context, s),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeProfesor extends StatefulWidget {
  const HomeProfesor({super.key});

  @override
  State<HomeProfesor> createState() => _HomeProfesorState();
}

class PerfilProfesorView extends StatelessWidget {
  final String profesorId;
  const PerfilProfesorView({super.key, required this.profesorId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        top: false, // porque tu AppHeader ya usa SafeArea arriba
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _ContenidoPerfilProfesor(profesorId: profesorId),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContenidoPerfilProfesor extends StatelessWidget {
  final String profesorId;
  const _ContenidoPerfilProfesor({required this.profesorId});

  @override
  Widget build(BuildContext context) {
    // 1) Nombre del profe
    final profeDocStream = FirebaseFirestore.instance
        .collection("usuarios")
        .doc(profesorId)
        .snapshots();

    // 2) Clases del profe
    final clasesStream = FirebaseFirestore.instance
        .collection("clases")
        .where("profesorId", isEqualTo: profesorId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: profeDocStream,
      builder: (context, profSnap) {
        final nombre = (profSnap.data?.data() as Map<String, dynamic>?)?["nombre"]
                ?.toString() ??
            "Profesor";

        return StreamBuilder<QuerySnapshot>(
          stream: clasesStream,
          builder: (context, clasesSnap) {
            if (!clasesSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final clases = clasesSnap.data!.docs;

            int total = clases.length;
            int hechas = 0;
            int canceladas = 0;
            int reprogramadas = 0;
            int activas = 0;
            int virtuales = 0;
            int presenciales = 0;

            for (final c in clases) {
              final d = c.data() as Map<String, dynamic>;

              final estado = (d["estado"] ?? "activa").toString();
              final tipo = (d["tipoClase"] ?? "presencial").toString();

              if (estado == "hecha") hechas++;
              else if (estado == "cancelada") canceladas++;
              else if (estado == "reprogramada") reprogramadas++;
              else activas++;

              if (tipo == "virtual") virtuales++;
              else presenciales++;
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 6),

                // ✅ BIENVENIDA
                Text(
                  "Bienvenido profesor, $nombre",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Tu resumen/estadistica de clases",
                  style: TextStyle(color: Colors.black54),
                ),

                // ✅ TARJETAS (2 columnas)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    _StatCard(
                      titulo: "Total clases",
                      valor: "$total",
                      icono: Icons.calendar_month,
                      borderColor: const Color.fromARGB(255, 93, 97, 231),
                      bgColor: Color(0xFFF3E5F5),
                      iconColor: const Color.fromARGB(255, 63, 68, 211),
                    ),
                    _StatCard(
                      titulo: "Activas",
                      valor: "$activas",
                      icono: Icons.play_circle_fill,
                      borderColor: const Color.fromARGB(255, 93, 97, 231),
                      bgColor: Color(0xFFF3E5F5),
                      iconColor: const Color.fromARGB(255, 63, 68, 211),
                    ),
                    _StatCard(
                      titulo: "Hechas",
                      valor: "$hechas",
                      icono: Icons.check_circle,
                      borderColor: const Color(0xFF4CAF50),
                      bgColor: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                    ),
                    _StatCard(
                      titulo: "Canceladas",
                      valor: "$canceladas",
                      icono: Icons.cancel,
                      borderColor: const Color(0xFFE57373),
                      bgColor: const Color(0xFFFFEBEE),
                      iconColor: const Color(0xFFC62828),
                    ),
                    _StatCard(
                      titulo: "Reprogramadas",
                      valor: "$reprogramadas",
                      icono: Icons.warning_amber_rounded,
                      borderColor: const Color(0xFFFFEE58),
                      bgColor: const Color(0xFFFFF9C4),
                      iconColor: const Color(0xFFF9A825),
                    ),
                    _StatCard(
                      titulo: "Virtuales",
                      valor: "$virtuales",
                      icono: Icons.laptop,
                      borderColor: const Color.fromARGB(255, 93, 97, 231),
                      bgColor: Color(0xFFF3E5F5),
                      iconColor: const Color.fromARGB(255, 63, 68, 211),
                    ),
                    _StatCard(
                      titulo: "Presenciales",
                      valor: "$presenciales",
                      icono: Icons.school,
                      borderColor: const Color.fromARGB(255, 93, 97, 231),
                      bgColor: Color(0xFFF3E5F5),
                      iconColor: const Color.fromARGB(255, 63, 68, 211),
                    ),
                  ],
                ),


                const SizedBox(height: 18),

                // ✅ BLOQUE EXTRA (opcional)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    "Tip: Mantén tus clases hechas al día para que el historial quede ordenado ✅",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color borderColor;
  final Color bgColor;
  final Color iconColor;

  const _StatCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.borderColor,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 22, color: iconColor),
          const Spacer(),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class HorarioView extends StatelessWidget {
  
  Widget _contenidoHorario(BuildContext context) {
  DateTime inicioSemana =
      semanaActual.subtract(Duration(days: semanaActual.weekday - 1));
  inicioSemana = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
  final siguienteSemana = inicioSemana.add(const Duration(days: 7));

  return Column(
    children: [
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () =>
                onSemanaChange(semanaActual.subtract(const Duration(days: 7)), -1),
          ),
          Text("Semana ${_numeroSemana(semanaActual)}"),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () =>
                onSemanaChange(semanaActual.add(const Duration(days: 7)), 1),
          ),
        ],
      ),

      Expanded(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: StreamBuilder<QuerySnapshot>(
            key: ValueKey(inicioSemana),
            stream: FirebaseFirestore.instance
                .collection("clases")
                .where("profesorId", isEqualTo: profesorId)
                .where("fecha", isGreaterThanOrEqualTo: Timestamp.fromDate(inicioSemana))
                .where("fecha", isLessThan: Timestamp.fromDate(siguienteSemana))
                .orderBy("fecha")
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final clases = snapshot.data!.docs;

              final clasesPorDia = <String, List<QueryDocumentSnapshot>>{
                "Lunes": [],
                "Martes": [],
                "Miércoles": [],
                "Jueves": [],
                "Viernes": [],
                "Sábado": [],
                "Domingo": [],
              };

              for (final clase in clases) {
                final fecha = (clase["fecha"] as Timestamp).toDate();
                const dias = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
                clasesPorDia[dias[fecha.weekday - 1]]!.add(clase);
              }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                children: clasesPorDia.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        entry.key.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...entry.value.map((clase) {
                        final data = clase.data() as Map<String, dynamic>;
                        final horaInicio = data["horaInicio"]?.toString() ?? "";
                        final horaFin = data["horaFin"]?.toString() ?? "";
                        final materia = data["materia"]?.toString() ?? "Sin materia";
                        final estado = data["estado"]?.toString() ?? "activa";
                        final tipoClase = data["tipoClase"]?.toString() ?? "presencial";

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _mostrarOpcionesClase(context, clase),
                            child: ClaseCard(
                              hora: (horaInicio.isNotEmpty && horaFin.isNotEmpty) ? "$horaInicio - $horaFin" : "Hora no definida",
                              materia: materia,
                              profesor: "Tú",
                              estado: estado,
                              tipoClase: tipoClase,
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    ],
  );
}
  final String profesorId;
  final DateTime semanaActual;
  final int direccionAnimacion;
  final Function(DateTime, int) onSemanaChange;

  const HorarioView({
    super.key,
    required this.profesorId,
    required this.semanaActual,
    required this.direccionAnimacion,
    required this.onSemanaChange,
  });

  @override
@override

@override
Widget build(BuildContext context) {
  return Container(
    color: kPrimary,
    child: SafeArea(
      top: false, // ✅ porque el header ya tiene SafeArea
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 6), // ✅ más largo (menos padding)
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7FF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _contenidoHorario(context),
          ),
        ),
      ),
    ),
  );
}


  static int _numeroSemana(DateTime fecha) {
    final inicioAnio = DateTime(fecha.year, 1, 1);
    final dias = fecha.difference(inicioAnio).inDays;
    return ((dias + inicioAnio.weekday) / 7).ceil();
  }

  /// Opciones de clase

void _mostrarOpcionesClase(BuildContext context, QueryDocumentSnapshot clase) {
  final data = clase.data() as Map<String, dynamic>;

  final materia = (data["materia"] ?? "Sin materia").toString();
  final horaInicio = (data["horaInicio"] ?? "--:--").toString();
  final horaFin = (data["horaFin"] ?? "--:--").toString();
  final estado = (data["estado"] ?? "activa").toString();
  

  final tipo = (data["tipoClase"] ?? "presencial").toString(); // presencial | virtual
  final bool bloqueada = (estado == "hecha" || estado == "cancelada");

  DateTime? fecha;
  final f = data["fecha"];
  if (f is Timestamp) fecha = f.toDate();

  final fechaTxt = (fecha == null)
      ? "Sin fecha"
      : "${fecha.day.toString().padLeft(2, "0")}/${fecha.month.toString().padLeft(2, "0")}/${fecha.year}";

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "detalle_clase",
    barrierColor: Colors.black.withOpacity(0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Detalle de clase",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                _infoFila("Materia", materia),
                _infoFila("Horario", "$horaInicio - $horaFin"),
                _infoFila("Fecha", fechaTxt),
                _infoFila("Estado", estado),
                _infoFila("Tipo", tipo),

                const SizedBox(height: 18),

                if (!bloqueada) ...[
                  botonPrimario(
                    texto: "Tomar asistencia",
                    icono: Icons.checklist,
                    onTap: () {
                      Navigator.pop(context);
                      _tomarAsistencia(context, clase);
                    },
                  ),
                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: () async {
                      await clase.reference.update({"estado": "cancelada"});
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text("Cancelar clase"),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estado == "hecha"
                          ? "✅ Esta clase ya está marcada como hecha."
                          : "❌ Esta clase fue cancelada.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  // ✅ SOLO si fue cancelada: botón Reprogramar
                  if (estado == "cancelada") ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 190, 92), // amarillo
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.schedule),
                      label: const Text("Reprogramar"),
                      onPressed: () {
                        Navigator.pop(context);
                        _mostrarModalReprogramarClase(context, clase);
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);

      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
}
  /// Tomar asistencia
void _tomarAsistencia(BuildContext context, QueryDocumentSnapshot clase) async {
  final alumnosIds = List<String>.from(clase["alumnosId"]);
  final asistieron = <String>[];

  final alumnosDocs = await FirebaseFirestore.instance
      .collection("usuarios")
      .where(FieldPath.documentId, whereIn: alumnosIds)
      .get();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateModal) {
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                const ListTile(
                  title: Text("Asistencia"),
                ),

                ...alumnosDocs.docs.map((alumno) {
                  final id = alumno.id;
                  final nombre = (alumno["nombre"] ?? "Sin nombre").toString();

                  return CheckboxListTile(
                    title: Text(nombre),
                    value: asistieron.contains(id),
                    onChanged: (_) {
                      setStateModal(() {
                        asistieron.contains(id)
                            ? asistieron.remove(id)
                            : asistieron.add(id);
                      });
                    },
                  );
                }),

                const SizedBox(height: 10),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await clase.reference.update({
                      "asistieron": asistieron,
                      "estado": "hecha", // ✅ cambia estado
                      "asistenciaTomadaAt": Timestamp.now(),
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Guardar asistencia"),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> _mostrarModalReprogramarClase(
  BuildContext context,
  QueryDocumentSnapshot clase,
) async {
  final data = clase.data() as Map<String, dynamic>;

  // ✅ No se cambian
  final String materia = (data["materia"] ?? "Sin materia").toString();
  final List<String> alumnosIds = List<String>.from(data["alumnosId"] ?? []);
  final String profesorId = (data["profesorId"] ?? FirebaseAuth.instance.currentUser!.uid).toString();

  // (si usas tipoClase en tu app)
  final String tipoClase = (data["tipoClase"] ?? "presencial").toString(); // se mantiene igual

  // ✅ Solo se cambian
  DateTime fechaSeleccionada = DateTime.now();
  TimeOfDay? horaInicio;
  TimeOfDay? horaFin;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            final textoHoraInicio = horaInicio == null ? "Hora inicio" : fmt24(horaInicio!);
            final textoHoraFin = horaFin == null ? "Hora fin" : fmt24(horaFin!);

            return Padding(
              padding: const EdgeInsets.all(18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Reprogramar clase",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),

                    // ✅ Materia fija (solo lectura)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.book, color: Colors.black54),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              materia,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ✅ Alumnos fijos (solo info)
                    Text(
                      "Alumnos: ${alumnosIds.length}",
                      style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 14),

                    // ✅ Hora inicio
                    InkWell(
                      onTap: () async {
                        final picked = await mostrarPickerHoraIOS(context, inicial: horaInicio);
                        if (picked != null) setModalState(() => horaInicio = picked);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.white70),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                textoHoraInicio,
                                style: TextStyle(
                                  color: horaInicio == null ? Colors.white54 : Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ✅ Hora fin
                    InkWell(
                      onTap: () async {
                        final picked = await mostrarPickerHoraIOS(context, inicial: horaFin ?? horaInicio);
                        if (picked != null) setModalState(() => horaFin = picked);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled, color: Colors.white70),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                textoHoraFin,
                                style: TextStyle(
                                  color: horaFin == null ? Colors.white54 : Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ✅ Fecha
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Fecha: ${fechaSeleccionada.day.toString().padLeft(2, "0")}/${fechaSeleccionada.month.toString().padLeft(2, "0")}/${fechaSeleccionada.year}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: fechaSeleccionada,
                              firstDate: DateTime(2023),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setModalState(() => fechaSeleccionada = picked);
                          },
                          child: const Text("Cambiar"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ✅ Guardar reprogramación
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 190, 92),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text("Guardar reprogramación"),
                      onPressed: () async {
                        if (horaInicio == null || horaFin == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Completa hora inicio y hora fin")),
                          );
                          return;
                        }

                        // ✅ crea una NUEVA clase reprogramada
                        await FirebaseFirestore.instance.collection("clases").add({
                          "materia": materia,
                          "horaInicio": fmt24(horaInicio!),
                          "horaFin": fmt24(horaFin!),
                          "fecha": Timestamp.fromDate(fechaSeleccionada),
                          "profesorId": profesorId,
                          "alumnosId": alumnosIds,
                          "asistieron": [],
                          "estado": "reprogramada", // ✅ guarda así en minúscula
                          "tipoClase": tipoClase,    // ✅ se mantiene
                          "reprogramadaDe": clase.id, // opcional pero RECOMENDADO
                          "createdAt": Timestamp.now(),
                        });

                        if (context.mounted) Navigator.pop(context);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Clase reprogramada ✅")),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}


Widget _infoFila(String titulo, String valor) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            "$titulo:",
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ),
        Expanded(child: Text(valor)),
      ],
    ),
  );
}

class _HomeProfesorState extends State<HomeProfesor> {
  int _currentIndex = 3;
  DateTime semanaActual = DateTime.now();
  int direccionAnimacion = 1;

   Widget _chipTipo(
  String value,
  String label,
  String tipoActual,
  Function(String) onChanged,
) {
  final selected = tipoActual == value;

  return ChoiceChip(
    label: Text(label),
    selected: selected,
    selectedColor: kPrimary,
    backgroundColor: Colors.grey.shade800,
    labelStyle: TextStyle(
      color: selected ? Colors.white : Colors.white70,
      fontWeight: FontWeight.w600,
    ),
    onSelected: (_) => onChanged(value),
  );
}

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Usuario no autenticado")));
    }

final paginas = [
  HorarioView(
    profesorId: user.uid,
    semanaActual: semanaActual,
    direccionAnimacion: direccionAnimacion,
    onSemanaChange: (nuevaSemana, dir) {
      setState(() {
        semanaActual = nuevaSemana;
        direccionAnimacion = dir;
      });
    },
  ),

  // Notificaciones
  Container(
    color: kPrimary,
    child: const Center(
      child: Text("Notificaciones", style: TextStyle(color: Colors.white)),
    ),
  ),
  NotificacionesProfesorView(profesorId: user.uid),
  // Perfil
  PerfilProfesorView(profesorId: user.uid,),
];


String tituloActual() {
  switch (_currentIndex) {
    case 0: return "Horario";
    case 2: return "Notificaciones";
    case 3: return "Perfil";
    default: return "";
  }
}

return Scaffold(
  backgroundColor: kPrimary,
  body: Column(
    children: [
      AppHeader(titulo: tituloActual()), // ✅ ya no es const
      Expanded(child: paginas[_currentIndex]),
    ],
  ),

  floatingActionButton: (_currentIndex == 0)
      ? FloatingActionButton(
          backgroundColor: kPrimary,
          onPressed: () => _mostrarModalCrearClase(context, user.uid),
          child: const Icon(Icons.add, color: Colors.white, size: 34),
        )
      : null,

  floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

  bottomNavigationBar: BottomAppBar(
    color: kPrimary,
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _tabItem(icon: Icons.calendar_today, label: "Horario", index: 0),
            _tabItem(icon: Icons.notifications_none, label: "Notificaciones", index: 2),
            _tabItem(icon: Icons.person_outline, label: "Perfil", index: 3),
            _logoutTabItem(),
          ],
        ),
      ),
    ),
  ),
);
}

Widget _tabItem({
  required IconData icon,
  required String label,
  required int index,
  bool isLogout = false,
}) {
  final selected = _currentIndex == index;

  return InkWell(
    borderRadius: BorderRadius.circular(30),
    onTap: () async {
      if (isLogout) {
        await FirebaseAuth.instance.signOut();
        return;
      }
      setState(() => _currentIndex = index);
    },
    child: Column(
  mainAxisSize: MainAxisSize.min,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text(
      label,
      style: TextStyle(
        fontSize: 10,
        height: 1.0,
        color: Colors.white,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
    const SizedBox(height: 4),
    AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: selected ? kPrimary : Colors.white,
        size: 20,
      ),
    ),
  ],
),
  );
}

Widget _logoutTabItem() {
  return InkWell(
    borderRadius: BorderRadius.circular(30),
    onTap: () async {
      await FirebaseAuth.instance.signOut();
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text(
          "Cerrar sesión",
          style: TextStyle(
            fontSize: 10,
            height: 1.0,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Icon(Icons.logout, color: Colors.white, size: 20),
      ],
    ),
  );
}

int _durToMin(String d) {
  switch (d) {
    case "45": return 45;
    case "60": return 60;
    case "90": return 90;
    case "120": return 120;
    default: return 60;
  }
}

TimeOfDay _addMinutes(TimeOfDay t, int minutes) {
  final total = t.hour * 60 + t.minute + minutes;
  final h = (total ~/ 60) % 24;
  final m = total % 60;
  return TimeOfDay(hour: h, minute: m);
}

Future<String?> _pickDuracion(BuildContext context, {required String actual}) async {
  const opciones = ["45", "60", "90", "120"];

  return showDialog<String>(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("Elige duración"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: opciones.map((v) {
            final selected = v == actual;
            return ListTile(
              title: Text("$v min"),
              trailing: Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? kPrimary : Colors.grey,
              ),
              onTap: () => Navigator.pop(context, v),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
        ],
      );
    },
  );
}

  /// Modal crear clase (con picker iOS ruedita)
  void _mostrarModalCrearClase(BuildContext context, String profesorId) {
    
    String tipoClase = "presencial";

    final materiaController = TextEditingController();
    TimeOfDay? horaInicio;
    String duracion = "60"; // 45|60|90|120

    DateTime fechaSeleccionada = DateTime.now();
    final alumnosSeleccionados = <String>[];

    String filtroAlumno = "";

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final textoHoraInicio = horaInicio == null ? "Hora inicio" : fmt24(horaInicio!);

              final minutos = _durToMin(duracion);
              final horaFinCalc = (horaInicio == null) ? null : _addMinutes(horaInicio!, minutos);

               return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      const Text(
                        "Nueva Clase",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: materiaController,
                        obscureText: false, // ✅ NO es contraseña
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Materia",
                          hintStyle: const TextStyle(color: Colors.white54),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          prefixIcon: const Icon(Icons.book, color: Colors.white),
                          filled: true,
                          fillColor: Colors.grey.shade900,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Hora inicio (ruedita iOS)
                      InkWell(
                        onTap: () async {
                          final picked = await mostrarPickerHoraIOS(context, inicial: horaInicio);
                          if (picked != null) setModalState(() => horaInicio = picked);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.white70),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  textoHoraInicio,
                                  style: TextStyle(
                                    color: horaInicio == null ? Colors.white54 : Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Hora fin (ruedita iOS)
                     const SizedBox(height: 12),

InkWell(
  onTap: () async {
    final picked = await _pickDuracion(context, actual: duracion);
    if (picked != null) setModalState(() => duracion = picked);
  },
  borderRadius: BorderRadius.circular(12),
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.grey.shade900,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.timer, color: Colors.white70),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "Duración: $duracion min",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
      ],
    ),
  ),
),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Fecha: ${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}"),
                          TextButton(
                            style: ElevatedButton.styleFrom(
                            backgroundColor:kPrimary,
                            foregroundColor: Colors.white,
                            ),  
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: fechaSeleccionada,
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) setModalState(() => fechaSeleccionada = picked);
                            },
                            child: const Text("Cambiar"),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ------- Alumnos -------
const SizedBox(height: 12),

Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      _chipTipo(
  "presencial",
  "Presencial",
  tipoClase,
  (v) => setModalState(() => tipoClase = v),
),

_chipTipo(
  "virtual",
  "Virtual",
  tipoClase,
  (v) => setModalState(() => tipoClase = v),
),

    ],
  ),
),

// ---------- Alumnos (lista + buscador + botón check) ----------
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      "Alumnos (${alumnosSeleccionados.length})",
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    TextButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:kPrimary,
        foregroundColor: Colors.white,
      ),  
      onPressed: () => setModalState(() => alumnosSeleccionados.clear()),
      child: const Text("Limpiar"),
    ),
  ],
),

const SizedBox(height: 8),

TextField(
  onChanged: (v) => setModalState(() => filtroAlumno = v.trim().toLowerCase()),
  obscureText: false, // ✅
  style: const TextStyle(color: Colors.white),
  decoration: InputDecoration(
    hintText: "Buscar alumno...",
    prefixIcon: const Icon(Icons.search, color: Colors.white70),
    hintStyle: const TextStyle(color: Colors.white54),
    filled: true,
    fillColor: Colors.grey.shade900,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
),

const SizedBox(height: 10),

SizedBox(
  height: 120,
  child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("usuarios")
        .where("rol", isEqualTo: "alumno")
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      // Lista completa, pero filtrada por búsqueda
      final alumnos = snapshot.data!.docs.where((doc) {
        final nombre = (doc["nombre"] ?? "").toString().toLowerCase();
        if (filtroAlumno.isEmpty) return true;
        return nombre.contains(filtroAlumno);
      }).toList();

      if (alumnos.isEmpty) {
        return const Center(child: Text("No se encontró ese alumno"));
      }

      return ListView.separated(
        itemCount: alumnos.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final alumno = alumnos[i];
          final id = alumno.id;
          final nombre = (alumno["nombre"] ?? "Sin nombre").toString();

          final seleccionado = alumnosSeleccionados.contains(id);

          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(nombre),
            trailing: IconButton(
              onPressed: () {
                setModalState(() {
                  if (seleccionado) {
                    alumnosSeleccionados.remove(id);
                  } else {
                    alumnosSeleccionados.add(id);
                  }
                });
              },
              icon: Icon(
                seleccionado ? Icons.check_circle : Icons.add_circle_outline,
                color: seleccionado ? kPrimary : Colors.grey,
              ),
            ),
          );
        },
      );
    },
  ),
),

                      const SizedBox(height: 14),

                      botonPrimario(
                        texto: "Guardar clase",

                        icono: Icons.school, // opcional, puedes quitarlo
                        onTap: () async {
                          if (materiaController.text.trim().isEmpty || horaInicio == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Completa materia y hora inicio")),
                            );
                            return;
                          }
                          if (alumnosSeleccionados.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Selecciona al menos 1 alumno")),
                            );
                            return;
                          }

                          await FirebaseFirestore.instance.collection("clases").add({
                            "materia": materiaController.text.trim(),
                            "horaInicio": fmt24(horaInicio!),
                            "horaFin": fmt24(horaFinCalc!),
                            "duracionMin": minutos,
                            "fecha": Timestamp.fromDate(fechaSeleccionada),
                            "profesorId": profesorId,
                            "alumnosId": alumnosSeleccionados,
                            "asistieron": [],
                            "estado": "activa",
                            "tipo": tipoClase, // ✅ presencial | virtual
                            "createdAt": Timestamp.now(),
                          });
                      
                          if (context.mounted) Navigator.pop(context);
  },
),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class AppHeader extends StatelessWidget {
  final String titulo;
  const AppHeader({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Image.asset(
                "assets/images/logo.png",
                height: 44, // ✅ logo grande
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}