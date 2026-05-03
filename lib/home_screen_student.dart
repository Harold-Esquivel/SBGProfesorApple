import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sbg_profesores/theme/app_colors.dart'; // tu kPrimary
import 'package:sbg_profesores/views/perfil_view.dart'; // si tienes un PerfilAlumno ya, úsalo
import 'package:sbg_profesores/widgets/classcard.dart'; // tu ClaseCard
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sbg_profesores/services/auth_navigation_service.dart';

class HomeAlumno extends StatefulWidget {
  const HomeAlumno({super.key});

  @override
  State<HomeAlumno> createState() => _HomeAlumnoState();
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

Future<void> _mostrarModalSolicitarClase(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final alumnoId = user.uid;

  // ✅ Nombre del alumno
  final alumnoDoc = await FirebaseFirestore.instance
      .collection("usuarios")
      .doc(alumnoId)
      .get();

  final alumnoNombre = (alumnoDoc.data()?["nombre"] ?? "Alumno").toString();

  // ✅ Controllers
  final materiaController = TextEditingController();
  final mensajeController = TextEditingController();

  // ✅ Campos
  DateTime fechaSeleccionada = DateTime.now();
  TimeOfDay? horaInicio;
  String duracion = "60"; // 45 | 60 | 90 | 120

  String tipoClase = "presencial"; // presencial | virtual

  String filtroProfe = "";
  String? profesorIdSeleccionado;
  String profesorNombreSeleccionado = "";

  // Helper: validar horaFin > horaInicio
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
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            final textoInicio = horaInicio == null ? "Hora inicio" : fmt24(horaInicio!);

            final minutos = _durToMin(duracion);
            final horaFinCalc = (horaInicio == null) ? null : _addMinutes(horaInicio!, minutos);

            return Padding(
              padding: const EdgeInsets.all(18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Solicitar clase",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),

                    // Materia
                    TextField(
                      controller: materiaController,
                      style: const TextStyle(color: Colors.white),
                      decoration: darkInput(
                        hint: "Materia (ej: Matemática)",
                        icon: Icons.book,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Fecha
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Fecha: ${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: fechaSeleccionada,
                              firstDate: DateTime(2023),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setModalState(() => fechaSeleccionada = picked);
                            }
                          },
                          child: const Text("Cambiar"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Hora inicio
                    InkWell(
                      onTap: () async {
                        final picked = await mostrarPickerHoraIOS(
                          context,
                          inicial: horaInicio,
                        );
                        if (picked != null) {
                          setModalState(() => horaInicio = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F1F),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: Colors.white70),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                textoInicio,
                                style: TextStyle(
                                  color: horaInicio == null
                                      ? Colors.white54
                                      : Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    InkWell(
  onTap: () async {
    final picked = await _pickDuracion(context, actual: duracion);
    if (picked != null) {
      setModalState(() => duracion = picked);
    }
  },
  borderRadius: BorderRadius.circular(14),
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFF1F1F1F),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.timer, color: Colors.white70),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "Duración: ${duracion} min",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
      ],
    ),
  ),
),
          
const SizedBox(height: 10),                      

                    // Tipo clase
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ChoiceChip(
                          label: const Text("Presencial"),
                          selected: tipoClase == "presencial",
                          onSelected: (_) =>
                              setModalState(() => tipoClase = "presencial"),
                          selectedColor: kPrimary,
                          backgroundColor: const Color(0xFF1F1F1F),
                          labelStyle: TextStyle(
                            color: tipoClase == "presencial"
                                ? Colors.white
                                : Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: tipoClase == "presencial"
                                  ? kPrimary
                                  : Colors.white24,
                            ),
                          ),
                        ),
                        ChoiceChip(
                          label: const Text("Virtual"),
                          selected: tipoClase == "virtual",
                          onSelected: (_) =>
                              setModalState(() => tipoClase = "virtual"),
                          selectedColor: kPrimary,
                          backgroundColor: const Color(0xFF1F1F1F),
                          labelStyle: TextStyle(
                            color: tipoClase == "virtual"
                                ? Colors.white
                                : Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color:
                                  tipoClase == "virtual" ? kPrimary : Colors.white24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Buscar profe
                    TextField(
                      onChanged: (v) => setModalState(
                        () => filtroProfe = v.trim().toLowerCase(),
                      ),
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          darkInput(hint: "Buscar profesor...", icon: Icons.search),
                    ),
                    const SizedBox(height: 6),

                    // Lista profes
                    SizedBox(
                      height: 200,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("usuarios")
                            .where("rol", isEqualTo: "profesor")
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final profes = snapshot.data!.docs.where((doc) {
                            final n =
                                (doc["nombre"] ?? "").toString().toLowerCase();
                            if (filtroProfe.isEmpty) return true;
                            return n.contains(filtroProfe);
                          }).toList();

                          if (profes.isEmpty) {
                            return const Center(
                              child: Text("No se encontró profesor"),
                            );
                          }

                          return ListView.separated(
                            itemCount: profes.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final p = profes[i];
                              final pid = p.id;
                              final nombre =
                                  (p["nombre"] ?? "Sin nombre").toString();
                              final seleccionado = profesorIdSeleccionado == pid;

                              return ListTile(
                                title: Text(nombre),
                                trailing: Icon(
                                  seleccionado
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: seleccionado ? kPrimary : Colors.grey,
                                ),
                                onTap: () {
                                  setModalState(() {
                                    profesorIdSeleccionado = pid;
                                    profesorNombreSeleccionado = nombre;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mensaje
                    TextField(
                      controller: mensajeController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: darkInput(
                        hint: "Mensaje (opcional)...",
                        icon: Icons.message,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // BOTÓN SOLICITAR
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.send),
                      label: const Text("Solicitar clase"),
                      onPressed: () async {
                        final materia = materiaController.text.trim();
                        final mensaje = mensajeController.text.trim();

                        if (materia.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Escribe la materia")),
                          );
                          return;
                        }

                        if (horaInicio == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Elige la hora de inicio")),
  );
  return;
}
                        if (profesorIdSeleccionado == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Elige un profesor")),
                          );
                          return;
                        }

                        await FirebaseFirestore.instance
                            .collection("solicitudes_clase")
                            .add({
                          "alumnoId": alumnoId,
                          "alumnoNombre": alumnoNombre,
                          "profesorId": profesorIdSeleccionado,
                          "profesorNombre": profesorNombreSeleccionado,
                          "materia": materia,
                          "mensaje": mensaje,
                          "fecha": Timestamp.fromDate(fechaSeleccionada),
                          "horaInicio": fmt24(horaInicio!),
                          "horaFin": fmt24(horaFinCalc!),
                          "duracionMin": minutos,
                          "tipoClase": tipoClase, // presencial | virtual
                          "estado": "pendiente",
                          "createdAt": Timestamp.now(),
                        });

                        if (context.mounted) Navigator.pop(context);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Solicitud enviada ✅")),
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


class _HomeAlumnoState extends State<HomeAlumno> {
  int _currentIndex = 2;
  DateTime semanaActual = DateTime.now();
  int direccionAnimacion = 1;

  String tituloActual() {
    switch (_currentIndex) {
      case 0:
        return "Horario";
      case 1:
        return "Pagos";
      case 2:
        return "Perfil";
      case 3:
        return "Informes";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Usuario no autenticado")));
    }

    final paginas = [
      HorarioAlumnoView(
        alumnoId: user.uid,
        semanaActual: semanaActual,
        direccionAnimacion: direccionAnimacion,
        onSemanaChange: (nuevaSemana, dir) {
          setState(() {
            semanaActual = nuevaSemana;
            direccionAnimacion = dir;
          });
        },
      ),
      PagosAlumnoView(alumnoId: user.uid),
      PerfilAlumnoView(alumnoId: user.uid),
      InformesAlumnoView(alumnoId: user.uid),
    ];

    return Scaffold(
      backgroundColor: kPrimary,
      body: Column(
        children: [
          AppHeader(titulo: tituloActual()),
          Expanded(child: paginas[_currentIndex]),
        ],
      ),
      floatingActionButton: (_currentIndex == 0)
    ? FloatingActionButton(
        backgroundColor: kPrimary, // o el color que uses en la app
        onPressed: () => _mostrarModalSolicitarClase(context),
        child: const Icon(Icons.add, color: Colors.white, size: 34),
      )
    : null,
floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // ✅ SIN FAB (alumno no crea clases)
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
                _tabItem(icon: Icons.payments_outlined, label: "Pagos", index: 1),
                _tabItem(icon: Icons.person_outline, label: "Perfil", index: 2),
                _tabItem(icon: Icons.article_rounded, label: "Informes", index: 3),
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
  }) {
    final selected = _currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () => setState(() => _currentIndex = index),
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
      onTap: () async =>
          AuthNavigationService.signOutAndReturnToLogin(context),
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
}

class HorarioAlumnoView extends StatefulWidget {
  final String alumnoId;
  final DateTime semanaActual;
  final int direccionAnimacion;
  final Function(DateTime, int) onSemanaChange;

  const HorarioAlumnoView({
    super.key,
    required this.alumnoId,
    required this.semanaActual,
    required this.direccionAnimacion,
    required this.onSemanaChange,
  });

  @override
  State<HorarioAlumnoView> createState() => _HorarioAlumnoViewState();
}

class _HorarioAlumnoViewState extends State<HorarioAlumnoView> {
  static int _numeroSemana(DateTime fecha) {
    final inicioAnio = DateTime(fecha.year, 1, 1);
    final dias = fecha.difference(inicioAnio).inDays;
    return ((dias + inicioAnio.weekday) / 7).ceil();
  }

  void _mostrarDetalleClaseSoloLectura(BuildContext context, QueryDocumentSnapshot clase) {
    final data = clase.data() as Map<String, dynamic>;

    final materia = (data["materia"] ?? "Sin materia").toString();
    final horaInicio = (data["horaInicio"] ?? "--:--").toString();
    final horaFin = (data["horaFin"] ?? "--:--").toString();
    final estado = (data["estado"] ?? "activa").toString();
    final tipo = (data["tipoClase"] ?? data["tipo"] ?? "presencial").toString();

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
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cerrar"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
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

  Widget _contenidoHorario(BuildContext context) {
    DateTime inicioSemana =
        widget.semanaActual.subtract(Duration(days: widget.semanaActual.weekday - 1));
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
              onPressed: () => widget.onSemanaChange(
                widget.semanaActual.subtract(const Duration(days: 7)),
                -1,
              ),
            ),
            Text("Semana ${_numeroSemana(widget.semanaActual)}"),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () => widget.onSemanaChange(
                widget.semanaActual.add(const Duration(days: 7)),
                1,
              ),
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
                  .where("alumnosId", arrayContains: widget.alumnoId)
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
                  const dias = [
                    "Lunes",
                    "Martes",
                    "Miércoles",
                    "Jueves",
                    "Viernes",
                    "Sábado",
                    "Domingo"
                  ];
                  clasesPorDia[dias[fecha.weekday - 1]]!.add(clase);
                }

                return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                children: clasesPorDia.entries.map((entry) {
                  final dia = entry.key;
                  final lista = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // 🔹 Título del día (siempre visible)
                      Text(
                        dia.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 🔹 Solo muestra clases si existen
                      ...lista.map((clase) {
                        final data = clase.data() as Map<String, dynamic>;
                        final horaInicio = data["horaInicio"]?.toString() ?? "";
                        final horaFin = data["horaFin"]?.toString() ?? "";
                        final materia = data["materia"]?.toString() ?? "Sin materia";
                        final estado = data["estado"]?.toString() ?? "activa";
                        final tipoClase =
                            (data["tipoClase"] ?? data["tipo"] ?? "presencial").toString();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _mostrarDetalleClaseSoloLectura(context, clase),
                            child: ClaseCard(
                              hora: (horaInicio.isNotEmpty && horaFin.isNotEmpty)
                                  ? "$horaInicio - $horaFin"
                                  : "Hora no definida",
                              materia: materia,
                              profesor: "Profesor",
                              estado: estado,
                              tipoClase: tipoClase,
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 6),
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
              child: _contenidoHorario(context),
            ),
          ),
        ),
      ),
    );
  }
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


class PagosAlumnoView extends StatelessWidget {
  final String alumnoId;
  const PagosAlumnoView({super.key, required this.alumnoId});

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
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // ✅ Tabs
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.black54,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        tabs: const [
                          Tab(text: "Deudas"),
                          Tab(text: "Atrasadas"),
                          Tab(text: "Pagadas"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("pagos")
                            .where("alumnoId", isEqualTo: alumnoId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  "Error: ${snapshot.error}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final docs = snapshot.data!.docs;
                          final List<QueryDocumentSnapshot> deudas = [];
                          final List<QueryDocumentSnapshot> atrasadas = [];
                          final List<QueryDocumentSnapshot> pagadas = [];

                          final ahora = DateTime.now();
                          final hoy = DateTime(ahora.year, ahora.month, ahora.day);

                          for (final d in docs) {
                            final data = d.data() as Map<String, dynamic>;
                            final estado = (data["estado"] ?? "pendiente").toString();

                            DateTime? venc;
                            final ts = data["fechaVencimiento"];
                            if (ts is Timestamp) venc = ts.toDate();

                            // si no tienes estado "vencido", lo tratamos como atrasado por fecha
                            final bool vencidoPorFecha = (estado != "pagado") &&
                                (venc != null) &&
                                DateTime(venc.year, venc.month, venc.day).isBefore(hoy);

                            if (estado == "pagado") {
                              pagadas.add(d);
                            } else if (estado == "vencido" || vencidoPorFecha) {
                              atrasadas.add(d);
                            } else {
                              deudas.add(d);
                            }
                          }

                          return TabBarView(
                            children: [
                              _ListaPagos(
                                tituloVacio: "No tienes deudas",
                                items: deudas,
                                tipo: _PagoTipo.deuda,
                              ),
                              _ListaPagos(
                                tituloVacio: "No tienes deudas atrasadas",
                                items: atrasadas,
                                tipo: _PagoTipo.atrasada,
                              ),
                              _ListaPagos(
                                tituloVacio: "No tienes deudas pagadas",
                                items: pagadas,
                                tipo: _PagoTipo.pagada,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ListaPagos extends StatelessWidget {
  final String tituloVacio;
  final List<QueryDocumentSnapshot> items;
  final _PagoTipo tipo;

  const _ListaPagos({
    required this.tituloVacio,
    required this.items,
    required this.tipo,
  });

  // ✅ Datos BCP (los tuyos)
  static const String bcpCuentaSoles = "21593111196008";
  static const String bcpCci = "00221519311119600829";

  // ✅ QR Yape (ajusta el nombre si tu archivo es distinto)
  static const String yapeQrAsset = "assets/images/Yape.png";

  String _fmtFecha(DateTime d) =>
      "${d.day.toString().padLeft(2, "0")}/${d.month.toString().padLeft(2, "0")}/${d.year}";

  bool _isBeforeToday(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return d.isBefore(today);
  }

  int _diasMora(DateTime venc) {
    // Mora por días posteriores al vencimiento (sin contar el día de vencimiento)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(venc.year, venc.month, venc.day);
    final diff = today.difference(due).inDays;
    return diff > 0 ? diff : 0;
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? "0") ?? 0.0;
  }

  String _montoTxt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 2);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          tituloVacio,
          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final doc = items[i];
        final p = doc.data() as Map<String, dynamic>;

        final concepto = (p["concepto"] ?? "Pago").toString();
        final moneda = (p["moneda"] ?? "PEN").toString();
        final estado = (p["estado"] ?? "pendiente").toString();

        final double montoBase = _toDouble(p["monto"]);

        DateTime? venc;
        final ts = p["fechaVencimiento"];
        if (ts is Timestamp) venc = ts.toDate();

        // ✅ Mora: S/ 5 por día SOLO si NO está pagado y ya pasó el vencimiento
        int diasMora = 0;
        if (estado != "pagado" && venc != null && _isBeforeToday(venc)) {
          diasMora = _diasMora(venc);
        }
        final double mora = (estado != "pagado") ? diasMora * 5.0 : 0.0;
        final double montoFinal = montoBase + mora;

        // 🎨 Colores pastel por tipo
        Color bg, border, icon;
        IconData ico;

        if (tipo == _PagoTipo.deuda) {
          bg = const Color(0xFFE3F2FD);
          border = const Color(0xFF64B5F6);
          icon = const Color(0xFF1E88E5);
          ico = Icons.schedule;
        } else if (tipo == _PagoTipo.atrasada) {
          bg = const Color(0xFFFFF9C4);
          border = const Color(0xFFFFEE58);
          icon = const Color(0xFFF9A825);
          ico = Icons.error_outline;
        } else {
          bg = const Color(0xFFE8F5E9);
          border = const Color(0xFF81C784);
          icon = const Color(0xFF2E7D32);
          ico = Icons.check_circle;
        }

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (tipo == _PagoTipo.pagada) {
              _mostrarPagoPagado(context);
            } else {
              _mostrarOpcionesPago(
                context,
                concepto: concepto,
                moneda: moneda,
                montoFinal: montoFinal,
                diasMora: diasMora,
                mora: mora,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 1.4),
            ),
            child: Row(
              children: [
                Icon(ico, color: icon, size: 24),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        concepto,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Monto: $moneda ${_montoTxt(montoFinal)}",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (mora > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          "Incluye mora: $moneda ${_montoTxt(mora)} (${diasMora} día(s) × S/5)",
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        "Vence: ${venc == null ? "—" : _fmtFecha(venc)}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right, color: Colors.black54),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ POPUP: PAGADA
  void _mostrarPagoPagado(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("✅ Bien Hecho"),
        content: const Text("Tu deuda ha sido pagada."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  // ✅ POPUP: PENDIENTE/ATRASADA -> Elegir método (Yape/BCP)
  void _mostrarOpcionesPago(
    BuildContext context, {
    required String concepto,
    required String moneda,
    required double montoFinal,
    required int diasMora,
    required double mora,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pagar deuda"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Concepto: $concepto"),
            const SizedBox(height: 6),
            Text(
              "Total a pagar: $moneda ${_montoTxt(montoFinal)}",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (mora > 0) ...[
              const SizedBox(height: 4),
              Text("Mora: $moneda ${_montoTxt(mora)} ($diasMora día(s))",
                  style: const TextStyle(color: Colors.black54)),
            ],
            const SizedBox(height: 12),
            const Text(
              "Elige un método de pago de preferencia:",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.qr_code),
            label: const Text("Yape"),
            onPressed: () {
              Navigator.pop(context);
              _mostrarYape(context, concepto: concepto, moneda: moneda, montoFinal: montoFinal);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.account_balance),
            label: const Text("BCP"),
            onPressed: () {
              Navigator.pop(context);
              _mostrarBCP(context, concepto: concepto, moneda: moneda, montoFinal: montoFinal);
            },
          ),
        ],
      ),
    );
  }

  // ✅ Detalle Yape (QR desde assets)
  void _mostrarYape(
    BuildContext context, {
    required String concepto,
    required String moneda,
    required double montoFinal,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pagar con Yape"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Concepto: $concepto"),
            const SizedBox(height: 6),
            Text(
              "Monto: $moneda ${_montoTxt(montoFinal)}",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                yapeQrAsset,
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Escanea el QR y realiza el pago.\nLuego puedes enviar el comprobante a administración.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:kPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  // ✅ Detalle BCP (Cuenta + CCI con copiar)
  void _mostrarBCP(
    BuildContext context, {
    required String concepto,
    required String moneda,
    required double montoFinal,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pagar con BCP"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Concepto: $concepto"),
            const SizedBox(height: 6),
            Text(
              "Monto: $moneda ${_montoTxt(montoFinal)}",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),

            const Text("Cuenta BCP (Soles)", style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            _copyRow(context, bcpCuentaSoles),

            const SizedBox(height: 12),
            const Text("CCI", style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            _copyRow(context, bcpCci),

            const SizedBox(height: 10),
            const Text(
              "Realiza la transferencia y guarda tu comprobante.\nLuego envíalo a administración.",
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:kPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  Widget _copyRow(BuildContext context, String value) {
    return Row(
      children: [
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: "Copiar",
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Copiado ✅")),
              );
            }
          },
          icon: const Icon(Icons.copy),
        ),
      ],
    );
  }
}

enum _PagoTipo { deuda, atrasada, pagada }


class PerfilAlumnoView extends StatelessWidget {
  final String alumnoId;
  const PerfilAlumnoView({super.key, required this.alumnoId});

  Future<Map<String, int>> _cargarAsistenciaStats() async {
    // Trae clases "hecha" donde el alumno estaba inscrito
    final snap = await FirebaseFirestore.instance
        .collection("clases")
        .where("estado", isEqualTo: "hecha")
        .where("alumnosId", arrayContains: alumnoId)
        .get();

    int asistencias = 0;
    int inasistencias = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      final asistieron = List<String>.from(data["asistieron"] ?? []);
      if (asistieron.contains(alumnoId)) {
        asistencias++;
      } else {
        inasistencias++;
      }
    }

    return {
      "asistencias": asistencias,
      "inasistencias": inasistencias,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("usuarios")
                    .doc(alumnoId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data?.data() as Map<String, dynamic>?;
                  if (data == null) {
                    return const Center(child: Text("No se encontró el perfil del alumno"));
                  }

                  final nombre = (data["nombre"] ?? "Sin nombre").toString();
                  final apoderado = (data["apoderado"] ?? "—").toString();
                  final contacto = (data["contacto"] ?? "—").toString();

                  return FutureBuilder<Map<String, int>>(
                    future: _cargarAsistenciaStats(),
                    builder: (context, statsSnap) {
                      final asistencias = statsSnap.data?["asistencias"] ?? 0;
                      final inasistencias = statsSnap.data?["inasistencias"] ?? 0;

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const SizedBox(height: 6),

                          Text(
                            "Bienvenido alumno, $nombre",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          const Text("Tu Información",
                              style: TextStyle(color: Colors.black54)),

                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.35,
                            children: [
                              _StatCard(
                                titulo: "Asistencias",
                                valor: "$asistencias",
                                icono: Icons.check_circle,
                                borderColor: const Color(0xFF4CAF50), // verde
                                bgColor: const Color(0xFFE8F5E9),     // verde pastel
                                iconColor: const Color(0xFF2E7D32),   // verde fuerte
                              ),
                              _StatCard(
                                titulo: "Inasistencias",
                                valor: "$inasistencias",
                                icono: Icons.cancel,
                                borderColor: const Color(0xFFE57373),
                                bgColor: const Color(0xFFFFEBEE),
                                iconColor: const Color(0xFFC62828),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ✅ Tarjeta info personal
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black.withOpacity(0.06)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _PerfilInfoRow(
                                  icon: Icons.person,
                                  label: "Nombre completo",
                                  value: nombre,
                                ),
                                const Divider(height: 18),
                                _PerfilInfoRow(
                                  icon: Icons.badge,
                                  label: "Apoderado",
                                  value: apoderado,
                                ),
                                const Divider(height: 18),
                                _PerfilInfoRow(
                                  icon: Icons.phone,
                                  label: "Contacto",
                                  value: contacto,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              "Si algún dato está mal, avisa a administración para que lo actualicen.",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
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

class InformesAlumnoView extends StatelessWidget {
  final String alumnoId;
  const InformesAlumnoView({super.key, required this.alumnoId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("informes")
                  .where("alumnoId", isEqualTo: alumnoId) // ✅ solo los suyos
                  .where("estado", isEqualTo: "activo")   // opcional (si lo usas)
                  .orderBy("fecha", descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snap.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final informes = snap.data!.docs;

                if (informes.isEmpty) {
                  return const Center(
                    child: Text(
                      "No tienes informes nuevos",
                      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    const SizedBox(height: 6),
                    const Text(
                      "Estos son tus informes",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 14),

                    ...informes.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final titulo = (d["titulo"] ?? "Informe").toString();
                      final url = (d["pdfUrl"] ?? "").toString();

                      DateTime? fecha;
                      final ts = d["fecha"];
                      if (ts is Timestamp) fecha = ts.toDate();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _mostrarDetalleInforme(context, titulo, url, fecha),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.black.withOpacity(0.06)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 46,
                                  width: 46,
                                  decoration: BoxDecoration(
                                    color: kPrimary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.picture_as_pdf, color: kPrimary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        titulo,
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        fecha == null
                                            ? "Fecha: —"
                                            : "Fecha: ${fecha.day.toString().padLeft(2, "0")}/${fecha.month.toString().padLeft(2, "0")}/${fecha.year}",
                                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleInforme(
    BuildContext context,
    String titulo,
    String url,
    DateTime? fecha,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fecha == null
                    ? "Fecha: —"
                    : "Fecha: ${fecha.day.toString().padLeft(2, "0")}/${fecha.month.toString().padLeft(2, "0")}/${fecha.year}",
              ),
              const SizedBox(height: 10),
              const Text(
                "Este informe está en PDF. Presiona el botón para abrirlo.",
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text("Abrir PDF"),
              onPressed: () async {
                Navigator.pop(context);
                await _abrirPdf(url, context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _abrirPdf(String url, BuildContext context) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay link de PDF en este informe")),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Link inválido")),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir el PDF")),
      );
    }
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

class _PerfilInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PerfilInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kPrimary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
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
