import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sbg_profesores/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';


class HomeDirector extends StatefulWidget {
  const HomeDirector({super.key});

  @override
  State<HomeDirector> createState() => _HomeDirectorState();
}

class _HomeDirectorState extends State<HomeDirector> {
  int _currentIndex = 0;

  // ---- Título dinámico para el header ----
  String _tituloActual() {
    switch (_currentIndex) {
      case 0:
        return "Informes";
      case 1:
        return "Estadísticas";
      case 2:
        return "Pagos";
      case 3:
        return "Mi perfil";
      default:
        return "";
    }
  }

  // ---- Páginas ----
  List<Widget> _paginas() {
  final user = FirebaseAuth.instance.currentUser;

  return [
    const InformesDirectorSectionView(),
    const EstadisticasDirectorView(),
    const PagosDirectorSectionView(),
    PerfilDirectorView(directorId: user!.uid),
  ];
}

  @override
  Widget build(BuildContext context) {
    final paginas = _paginas();

    return Scaffold(
      backgroundColor: kPrimary,
      body: Column(
        children: [
          // ✅ Header como tu profesor (si ya tienes AppHeader, úsalo)
          AppHeader(titulo: _tituloActual()),

          Expanded(
            child: paginas[_currentIndex],
          ),
        ],
      ),

      bottomNavigationBar: BottomAppBar(
        color: kPrimary,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _tabItem(icon: Icons.description_outlined, label: "Informes", index: 0),
                _tabItem(icon: Icons.bar_chart, label: "Estadísticas", index: 1),
                _tabItem(icon: Icons.payments_outlined, label: "Pagos", index: 2),
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
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        if (mounted) Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            "Salir",
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

class CrearInformeAlumnoView extends StatefulWidget {
  final String alumnoId;
  final String alumnoNombre;

  const CrearInformeAlumnoView({
    super.key,
    required this.alumnoId,
    required this.alumnoNombre,
  });

  @override
  State<CrearInformeAlumnoView> createState() => _CrearInformeAlumnoViewState();
}

class ListaInformesAlumnoDirectorView extends StatelessWidget {
  final String alumnoId;
  final String alumnoNombre;

  const ListaInformesAlumnoDirectorView({
    super.key,
    required this.alumnoId,
    required this.alumnoNombre,
  });

  Future<void> _abrirPdf(String url, BuildContext context) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Este informe no tiene URL")),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La URL del informe es inválida")),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir el informe")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text("Informes de $alumnoNombre"),
      ),
      body: Container(
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
                    .where("alumnoId", isEqualTo: alumnoId)
                    .orderBy("fecha", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final informes = snapshot.data!.docs;

                  if (informes.isEmpty) {
                    return const Center(
                      child: Text(
                        "Este alumno no tiene informes",
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: informes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final d = informes[i].data() as Map<String, dynamic>;
                      final titulo = (d["titulo"] ?? "Informe").toString();
                      final url = (d["pdfUrl"] ?? "").toString();

                      DateTime? fecha;
                      final ts = d["fecha"];
                      if (ts is Timestamp) fecha = ts.toDate();

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _abrirPdf(url, context),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
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
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      fecha == null
                                          ? "Fecha: —"
                                          : "Fecha: ${fecha.day.toString().padLeft(2, "0")}/${fecha.month.toString().padLeft(2, "0")}/${fecha.year}",
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.open_in_new, color: Colors.black54),
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

class _CrearInformeAlumnoViewState extends State<CrearInformeAlumnoView> {
  final tituloCtrl = TextEditingController();
  final urlCtrl = TextEditingController();

  @override
  void dispose() {
    tituloCtrl.dispose();
    urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarInforme() async {
    final titulo = tituloCtrl.text.trim();
    final url = urlCtrl.text.trim();

    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escribe el título del informe")),
      );
      return;
    }

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escribe la URL del informe")),
      );
      return;
    }

    final directorId = FirebaseAuth.instance.currentUser?.uid ?? "";

    await FirebaseFirestore.instance.collection("informes").add({
      "alumnoId": widget.alumnoId,
      "alumnoNombre": widget.alumnoNombre,
      "titulo": titulo,
      "pdfUrl": url,
      "estado": "activo",
      "fecha": Timestamp.now(),
      "createdAt": Timestamp.now(),
      "createdBy": directorId,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Informe enviado ✅")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: const Text("Nuevo informe"),
      ),
      body: Container(
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 6),
                  const Text(
                    "Elige los datos del informe",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Alumno: ${widget.alumnoNombre}",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: tituloCtrl,
                    decoration: InputDecoration(
                      hintText: "Título",
                      prefixIcon: const Icon(Icons.title),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: urlCtrl,
                    decoration: InputDecoration(
                      hintText: "URL del informe (PDF)",
                      prefixIcon: const Icon(Icons.link),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.send),
                    label: const Text("Enviar"),
                    onPressed: _enviarInforme,
                  ),

                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text("Cancelar"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum InformeModo { crear, ver }

class SeleccionarAlumnoInformeView extends StatefulWidget {
  final InformeModo modo;

  const SeleccionarAlumnoInformeView({
    super.key,
    required this.modo,
  });

  @override
  State<SeleccionarAlumnoInformeView> createState() =>
      _SeleccionarAlumnoInformeViewState();
}

class _SeleccionarAlumnoInformeViewState
    extends State<SeleccionarAlumnoInformeView> {
  String filtro = "";

  @override
  Widget build(BuildContext context) {
    final esCrear = widget.modo == InformeModo.crear;

    return Scaffold(
      backgroundColor: kPrimary,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text(esCrear ? "Elige a un estudiante" : "Elige a un alumno"),
      ),
      body: Container(
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: TextField(
                      onChanged: (v) => setState(() => filtro = v.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "Buscar alumno...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("usuarios")
                          .where("rol", isEqualTo: "alumno")
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final alumnos = snapshot.data!.docs.where((doc) {
                          final nombre = (doc["nombre"] ?? "")
                              .toString()
                              .toLowerCase();
                          if (filtro.isEmpty) return true;
                          return nombre.contains(filtro);
                        }).toList();

                        if (alumnos.isEmpty) {
                          return const Center(
                            child: Text("No se encontró ningún alumno"),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          itemCount: alumnos.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final alumno = alumnos[i];
                            final alumnoId = alumno.id;
                            final nombre = (alumno["nombre"] ?? "Alumno").toString();

                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                if (esCrear) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CrearInformeAlumnoView(
                                        alumnoId: alumnoId,
                                        alumnoNombre: nombre,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ListaInformesAlumnoDirectorView(
                                        alumnoId: alumnoId,
                                        alumnoNombre: nombre,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.06),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, color: Colors.black54),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.black54),
                                  ],
                                ),
                              ),
                            );
                          },
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
    );
  }
}

class InformesDirectorSectionView extends StatelessWidget {
  const InformesDirectorSectionView({super.key});

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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 6),
                const Text(
                  "Informes",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Aquí puedes crear nuevos informes o revisar los informes ya enviados.",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 22),

                _DirectorActionCard(
                  titulo: "Crear informes",
                  subtitulo: "Selecciona un alumno y envíale un nuevo informe",
                  icono: Icons.add_box_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SeleccionarAlumnoInformeView(
                          modo: InformeModo.crear,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _DirectorActionCard(
                  titulo: "Ver informes",
                  subtitulo: "Selecciona un alumno y revisa sus informes anteriores",
                  icono: Icons.description_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SeleccionarAlumnoInformeView(
                          modo: InformeModo.ver,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _DirectorActionCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final VoidCallback onTap;

  const _DirectorActionCard({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icono, color: kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
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
  }
}

class EstadisticasDirectorView extends StatelessWidget {
  const EstadisticasDirectorView({super.key});

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
              stream: FirebaseFirestore.instance.collection("clases").snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clases = snap.data!.docs;

                int hechas = 0;
                int canceladas = 0;

                for (final c in clases) {
                  final d = c.data() as Map<String, dynamic>;
                  final estado = (d["estado"] ?? "").toString();

                  if (estado == "hecha") hechas++;
                  if (estado == "cancelada") canceladas++;
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 6),

                    const Text(
                      "Resumen general",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Estadísticas generales de toda la institución.",
                      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 16),

                    // ✅ 2 cuadros grandes
                    _BigStatCard(
                      titulo: "Clases hechas (total)",
                      valor: "$hechas",
                      icono: Icons.check_circle,
                      // Verde pastel
                      bg: const Color(0xFFE9FBEF),
                      border: const Color(0xFF7CD89A),
                      iconColor: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 12),
                    _BigStatCard(
                      titulo: "Clases canceladas (total)",
                      valor: "$canceladas",
                      icono: Icons.cancel,
                      // Rojo pastel
                      bg: const Color(0xFFFFECEC),
                      border: const Color(0xFFFF7F8C),
                      iconColor: const Color(0xFFD32F2F),
                    ),

                    const SizedBox(height: 20),

                    // ✅ Texto + botón
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "¿Quieres ver la estadística de cada profesor?",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.people),
                              label: const Text("Ver Profesores"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ListaProfesoresView()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}



class _BigStatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color bg;
  final Color border;
  final Color iconColor;

  const _BigStatCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.bg,
    required this.border,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.6),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icono, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  valor,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------
/// 2) LISTA DE PROFESORES
/// ------------------------------
class ListaProfesoresView extends StatelessWidget {
  const ListaProfesoresView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: const Text("Profesores"),
      ),
      body: Container(
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
                    .collection("usuarios")
                    .where("rol", isEqualTo: "profesor")
                    .orderBy("nombre")
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                  final profes = snap.data!.docs;
                  if (profes.isEmpty) return const Center(child: Text("No hay profesores"));

                  return ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: profes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = profes[i];
                      final id = p.id;
                      final nombre = (p["nombre"] ?? "Profesor").toString();

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EstadisticasProfesorView(
                                profesorId: id,
                                profesorNombre: nombre,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: Colors.black54),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  nombre,
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.black54),
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

/// ------------------------------------
/// 3) ESTADÍSTICAS POR PROFESOR (DETALLE)
/// ------------------------------------
class EstadisticasProfesorView extends StatelessWidget {
  final String profesorId;
  final String profesorNombre;

  const EstadisticasProfesorView({
    super.key,
    required this.profesorId,
    required this.profesorNombre,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: const Text("Detalle del profesor"),
      ),
      body: Container(
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
                    .collection("clases")
                    .where("profesorId", isEqualTo: profesorId)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                  final clases = snap.data!.docs;

                  int hechas = 0;
                  int canceladas = 0;
                  int reprogramadas = 0;
                  int virtuales = 0;

                  for (final c in clases) {
                    final d = c.data() as Map<String, dynamic>;
                    final estado = (d["estado"] ?? "activa").toString();
                    final tipo = (d["tipoClase"] ?? d["tipo"] ?? "presencial").toString();

                    if (estado == "hecha") hechas++;
                    if (estado == "cancelada") canceladas++;
                    if (estado == "reprogramada") reprogramadas++;
                    if (tipo == "virtual") virtuales++;
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 6),

                      // ✅ INFO PROFESOR
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black.withOpacity(0.06)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 42,
                              width: 42,
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.school, color: kPrimary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Información del profesor",
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profesorNombre,
                                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        "Clases del profesor",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.25,
                        children: [
                          _SmallStatCard(
                            titulo: "Hechas",
                            valor: "$hechas",
                            icono: Icons.check_circle,
                            bg: const Color(0xFFE9FBEF),
                            border: const Color(0xFF7CD89A),
                            iconColor: const Color(0xFF2E7D32),
                          ),
                          _SmallStatCard(
                            titulo: "Canceladas",
                            valor: "$canceladas",
                            icono: Icons.cancel,
                            bg: const Color(0xFFFFECEC),
                            border: const Color(0xFFFF7F8C),
                            iconColor: const Color(0xFFD32F2F),
                          ),
                          _SmallStatCard(
                            titulo: "Virtuales",
                            valor: "$virtuales",
                            icono: Icons.laptop,
                            bg: const Color(0xFFEAF2FF),
                            border: const Color(0xFF90CAF9),
                            iconColor: const Color(0xFF1565C0),
                          ),
                          _SmallStatCard(
                            titulo: "Reprogramadas",
                            valor: "$reprogramadas",
                            icono: Icons.schedule,
                            bg: const Color(0xFFFFF7E6),
                            border: const Color(0xFFFFE082),
                            iconColor: const Color(0xFFF9A825),
                          ),
                        ],
                      ),
                    ],
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

class _SmallStatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color bg;
  final Color border;
  final Color iconColor;

  const _SmallStatCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.bg,
    required this.border,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: iconColor),
          const Spacer(),
          Text(
            valor,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class PagosDirectorSectionView extends StatelessWidget {
  const PagosDirectorSectionView({super.key});

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
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Text(
                  "Sección de pagos",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Elige qué deseas hacer",
                  style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 22),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      _BigActionCard(
                        title: "Crear nuevos pagos",
                        subtitle: "Crea un pago y asígnalo a alumnos o a todos",
                        icon: Icons.add_card,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CrearPagoDirectorView()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _BigActionCard(
                        title: "Ver pagos",
                        subtitle: "Lista de alumnos → ver pagos pendientes/atrasados",
                        icon: Icons.search,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ListaAlumnosPagosView()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PerfilDirectorView extends StatelessWidget {
  final String directorId;
  const PerfilDirectorView({super.key, required this.directorId});

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
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("usuarios")
                  .doc(directorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final nombre = (data["nombre"] ?? "Director").toString();
                final contacto = (data["contacto"] ?? "—").toString();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 6),

                    Text(
                      "Bienvenido, $nombre",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Perfil del director",
                      style: TextStyle(color: Colors.black54),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Column(
                        children: [
                          _DirectorInfoRow(
                            icon: Icons.person,
                            label: "Nombre",
                            value: nombre,
                          ),
                          const Divider(height: 18),
                          _DirectorInfoRow(
                            icon: Icons.phone,
                            label: "Contacto",
                            value: contacto,
                          ),
                          const Divider(height: 18),
                          const _DirectorInfoRow(
                            icon: Icons.admin_panel_settings,
                            label: "Rol",
                            value: "Director",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        "Entraste como Modo Director, aquí podrás modificar, agregar o ver todo sobre los usuarios (alumnos y profesor). Además de eso, si tienes alguna duda, ves algún error o quieres que en la aplicación tenga una nueva actualización, puedes pedirla a nuestro contacto de soporte.",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.support_agent),
                      label: const Text(
                        "Soporte",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _mostrarOpcionesSoporte(context),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarOpcionesSoporte(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Soporte"),
          content: const Text("Elige una opción de contacto."),
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
    final uri = Uri.parse("tel:+51971135384");
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir la llamada")),
      );
    }
  }

  Future<void> _abrirWhatsApp(BuildContext context) async {
    final uri = Uri.parse("https://wa.link/jgvvd9");
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir WhatsApp")),
      );
    }
  }
}

class _DirectorInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DirectorInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BigActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _BigActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            )
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
              child: Icon(icon, color: kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------
/// 2) CREAR PAGO (DIRECTOR)
/// ------------------------------
class CrearPagoDirectorView extends StatefulWidget {
  const CrearPagoDirectorView({super.key});

  @override
  State<CrearPagoDirectorView> createState() => _CrearPagoDirectorViewState();
}

class _CrearPagoDirectorViewState extends State<CrearPagoDirectorView> {
  final _conceptoCtrl = TextEditingController();
  final _montoCtrl = TextEditingController(text: "150");
  DateTime _vencimiento = DateTime.now().add(const Duration(days: 7));

  bool _paraTodos = true;
  final Set<String> _alumnosSeleccionados = {};
  String _filtro = "";

  @override
  void dispose() {
    _conceptoCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearPago() async {
    final concepto = _conceptoCtrl.text.trim();
    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0;

    if (concepto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escribe el nombre del pago (concepto)")),
      );
      return;
    }
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Monto inválido")),
      );
      return;
    }

    final directorId = FirebaseAuth.instance.currentUser?.uid ?? "";

    // 1) Obtener alumnos destino
    List<QueryDocumentSnapshot> alumnosDocs = [];

    final alumnosQuery = await FirebaseFirestore.instance
        .collection("usuarios")
        .where("rol", isEqualTo: "alumno")
        .get();

    if (_paraTodos) {
      alumnosDocs = alumnosQuery.docs;
    } else {
      alumnosDocs = alumnosQuery.docs
          .where((d) => _alumnosSeleccionados.contains(d.id))
          .toList();

      if (alumnosDocs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona al menos 1 alumno o usa 'Todos'")),
        );
        return;
      }
    }

    // 2) Crear pagos en batch (Firestore tiene límite 500 escrituras por batch)
    final now = Timestamp.now();
    final vencTs = Timestamp.fromDate(_vencimiento);

    final chunks = <List<QueryDocumentSnapshot>>[];
    const maxBatch = 450; // margen seguro
    for (int i = 0; i < alumnosDocs.length; i += maxBatch) {
      chunks.add(alumnosDocs.sublist(i, (i + maxBatch > alumnosDocs.length) ? alumnosDocs.length : i + maxBatch));
    }

    for (final chunk in chunks) {
      final batch = FirebaseFirestore.instance.batch();
      for (final alumno in chunk) {
        final alumnoId = alumno.id;
        final alumnoNombre = (alumno.data() as Map<String, dynamic>)["nombre"]?.toString() ?? "Alumno";

        final ref = FirebaseFirestore.instance.collection("pagos").doc();
        batch.set(ref, {
          "alumnoId": alumnoId,
          "alumnoNombre": alumnoNombre,
          "concepto": concepto,
          "monto": monto,
          "moneda": "PEN",
          "fechaVencimiento": vencTs,
          "estado": "pendiente",
          "createdAt": now,
          "createdBy": directorId,
        });
      }
      await batch.commit();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Pago creado ✅ (${alumnosDocs.length} alumno(s))")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: const Text("Crear pago"),
      ),
      body: Container(
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
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  const Text("Nombre del pago", style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _conceptoCtrl,
                    decoration: InputDecoration(
                      hintText: "Ej: Mensualidad Marzo",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Text("Monto (S/)", style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _montoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Ej: 150",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(
                        child: Text("Fecha de vencimiento", style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _vencimiento,
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) setState(() => _vencimiento = picked);
                        },
                        child: const Text("Cambiar"),
                      )
                    ],
                  ),
                  Text(
                    "${_vencimiento.day.toString().padLeft(2, "0")}/${_vencimiento.month.toString().padLeft(2, "0")}/${_vencimiento.year}",
                    style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 18),
                  SwitchListTile(
                    value: _paraTodos,
                    onChanged: (v) {
                      setState(() {
                        _paraTodos = v;
                        _alumnosSeleccionados.clear();
                      });
                    },
                    title: const Text("Asignar a TODOS los alumnos"),
                    subtitle: const Text("Si lo apagas, podrás seleccionar alumnos específicos"),
                    activeColor: kPrimary,
                  ),

                  if (!_paraTodos) ...[
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (v) => setState(() => _filtro = v.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "Buscar alumno...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 260,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("usuarios")
                            .where("rol", isEqualTo: "alumno")
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                          final alumnos = snapshot.data!.docs.where((d) {
                            final nombre = (d["nombre"] ?? "").toString().toLowerCase();
                            if (_filtro.isEmpty) return true;
                            return nombre.contains(_filtro);
                          }).toList();

                          return ListView.separated(
                            itemCount: alumnos.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final a = alumnos[i];
                              final id = a.id;
                              final nombre = (a["nombre"] ?? "Alumno").toString();
                              final selected = _alumnosSeleccionados.contains(id);

                              return ListTile(
                                title: Text(nombre),
                                trailing: Icon(
                                  selected ? Icons.check_circle : Icons.add_circle_outline,
                                  color: selected ? kPrimary : Colors.grey,
                                ),
                                onTap: () {
                                  setState(() {
                                    if (selected) {
                                      _alumnosSeleccionados.remove(id);
                                    } else {
                                      _alumnosSeleccionados.add(id);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text("Crear pago"),
                    onPressed: _crearPago,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ------------------------------
/// 3) VER PAGOS → LISTA DE ALUMNOS
/// ------------------------------
class ListaAlumnosPagosView extends StatelessWidget {
  const ListaAlumnosPagosView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: const Text("Alumnos"),
      ),
      body: Container(
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
                    .collection("usuarios")
                    .where("rol", isEqualTo: "alumno")
                    .orderBy("nombre")
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                  final alumnos = snap.data!.docs;
                  if (alumnos.isEmpty) {
                    return const Center(child: Text("No hay alumnos"));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: alumnos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final a = alumnos[i];
                      final id = a.id;
                      final nombre = (a["nombre"] ?? "Alumno").toString();

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PagosAlumnoDirectorView(
                                alumnoId: id,
                                alumnoNombre: nombre,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: Colors.black54),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w900)),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.black54),
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

/// ------------------------------
/// 4) PAGOS DEL ALUMNO (DIRECTOR)
///     Tabs: Pendientes / Atrasados
///     Botón: Marcar pagado
/// ------------------------------
class PagosAlumnoDirectorView extends StatelessWidget {
  final String alumnoId;
  final String alumnoNombre;

  const PagosAlumnoDirectorView({
    super.key,
    required this.alumnoId,
    required this.alumnoNombre,
  });

  bool _esAtrasado(Map<String, dynamic> d) {
    final estado = (d["estado"] ?? "pendiente").toString();
    if (estado == "pagado") return false;

    final ts = d["fechaVencimiento"];
    if (ts is! Timestamp) return false;

    final venc = ts.toDate();
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final due = DateTime(venc.year, venc.month, venc.day);

    return due.isBefore(hoy);
  }

  String _fmtFecha(DateTime f) =>
      "${f.day.toString().padLeft(2, "0")}/${f.month.toString().padLeft(2, "0")}/${f.year}";

  Future<void> _marcarPagado(BuildContext context, QueryDocumentSnapshot doc) async {
    await doc.reference.update({
      "estado": "pagado",
      "pagadoAt": Timestamp.now(),
      "updatedAt": Timestamp.now(),
      "updatedBy": FirebaseAuth.instance.currentUser?.uid ?? "",
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Marcado como pagado ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text("Pagos - $alumnoNombre"),
      ),
      body: Container(
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
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
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
                        tabs: const [
                          Tab(text: "Pendientes"),
                          Tab(text: "Atrasados"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("pagos")
                            .where("alumnoId", isEqualTo: alumnoId)
                            .where("estado", isNotEqualTo: "pagado")
                            .orderBy("estado") // requerido si usas isNotEqualTo
                            .orderBy("fechaVencimiento", descending: false)
                            .snapshots(),
                        builder: (context, snap) {
                          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                          final docs = snap.data!.docs;

                          final pendientes = <QueryDocumentSnapshot>[];
                          final atrasados = <QueryDocumentSnapshot>[];

                          for (final doc in docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            if (_esAtrasado(data)) {
                              atrasados.add(doc);
                            } else {
                              pendientes.add(doc);
                            }
                          }

                          return TabBarView(
                            children: [
                              _lista(context, pendientes, isAtrasados: false),
                              _lista(context, atrasados, isAtrasados: true),
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

  Widget _lista(BuildContext context, List<QueryDocumentSnapshot> docs, {required bool isAtrasados}) {
    if (docs.isEmpty) {
      return Center(
        child: Text(
          isAtrasados ? "No tiene atrasados" : "No tiene pendientes",
          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final doc = docs[i];
        final d = doc.data() as Map<String, dynamic>;

        final concepto = (d["concepto"] ?? "Pago").toString();
        final moneda = (d["moneda"] ?? "PEN").toString();
        final monto = (d["monto"] is num) ? (d["monto"] as num).toDouble() : 0.0;

        DateTime? venc;
        final ts = d["fechaVencimiento"];
        if (ts is Timestamp) venc = ts.toDate();

        final border = isAtrasados ? Colors.red.shade400 : Colors.blue.shade300;
        final bg = isAtrasados ? Colors.red.shade50 : Colors.blue.shade50;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(isAtrasados ? Icons.error_outline : Icons.schedule, color: border),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(concepto, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text("Monto: $moneda ${monto.toStringAsFixed(monto % 1 == 0 ? 0 : 2)}",
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text("Vence: ${venc == null ? "—" : _fmtFecha(venc)}",
                        style: const TextStyle(color: Colors.black54)),
                    if (isAtrasados)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text("ATRASADO", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _marcarPagado(context, doc),
                child: const Text("Marcar pagado"),
              ),
            ],
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

