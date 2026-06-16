import 'package:flutter/material.dart';
import 'package:sbg_profesores/theme/app_theme.dart';
import 'package:sbg_profesores/widgets/liquid_glass_bottom_nav.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sbg_profesores/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sbg_profesores/firebase_options.dart';
import 'package:sbg_profesores/services/auth_navigation_service.dart';

String _emailUsuarioDesdeCodigo(String codigo, String rol) {
  final limpio = codigo.trim();
  if (rol == "profesor") return "$limpio@sbgprofesor.com";
  return "$limpio@sbgalumno.com";
}

String _rolLegible(String rol) {
  if (rol == "profesor") return "Profesor";
  return "Alumno";
}

String _estadoUsuario(Map<String, dynamic> data) {
  final estado = (data["estado"] ?? "activo").toString().trim().toLowerCase();
  return estado == "inactivo" ? "inactivo" : "activo";
}

bool _usuarioActivo(Map<String, dynamic> data) {
  return _estadoUsuario(data) == "activo";
}

class HomeDirector extends StatefulWidget {
  const HomeDirector({super.key});

  @override
  State<HomeDirector> createState() => _HomeDirectorState();
}

class _HomeDirectorState extends State<HomeDirector> {
  int _currentIndex = 3;

  // ---- TÃ­tulo dinÃ¡mico para el header ----
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
      extendBody: true,
      backgroundColor: context.appPrimaryBackground,
      body: Column(
        children: [
          // âœ… Header como tu profesor (si ya tienes AppHeader, Ãºsalo)
          AppHeader(titulo: _tituloActual()),

          Expanded(child: paginas[_currentIndex]),
        ],
      ),

      bottomNavigationBar: LiquidGlassBottomNav(
        currentIndex: _currentIndex,
        destinations: const [
          LiquidGlassNavDestination(
            icon: Icons.description_outlined,
            label: "Informes",
            index: 0,
          ),
          LiquidGlassNavDestination(
            icon: Icons.bar_chart,
            label: "Estadísticas",
            index: 1,
          ),
          LiquidGlassNavDestination(
            icon: Icons.payments_outlined,
            label: "Pagos",
            index: 2,
          ),
          LiquidGlassNavDestination(
            icon: Icons.person_outline,
            label: "Perfil",
            index: 3,
          ),
        ],
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        onLogoutPressed: () =>
            AuthNavigationService.signOutAndReturnToLogin(context),
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
        const SnackBar(content: Text("La URL del informe es invÃ¡lida")),
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
      backgroundColor: context.appPrimaryBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text("Informes de $alumnoNombre"),
      ),
      body: Container(
        color: context.appPrimaryBackground,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Container(
              decoration: BoxDecoration(
                color: context.appPanel,
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
                    return Center(
                      child: Text(
                        "Este alumno no tiene informes",
                        style: TextStyle(color: context.appMutedText),
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
                            color: context.appCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.appBorder),
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
                                child: const Icon(
                                  Icons.picture_as_pdf,
                                  color: kPrimary,
                                ),
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
                                          ? "Fecha: â€”"
                                          : "Fecha: ${fecha.day.toString().padLeft(2, "0")}/${fecha.month.toString().padLeft(2, "0")}/${fecha.year}",
                                      style: TextStyle(
                                        color: context.appMutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.open_in_new,
                                color: context.appMutedText,
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
        const SnackBar(content: Text("Escribe el titulo del informe")),
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Informe enviado âœ…")));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPrimaryBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: const Text("Nuevo informe"),
      ),
      body: Container(
        color: context.appPrimaryBackground,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Container(
              decoration: BoxDecoration(
                color: context.appPanel,
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
                    style: TextStyle(
                      color: context.appMutedText,
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
                      fillColor: context.appInputFill,
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
                      fillColor: context.appInputFill,
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

  const SeleccionarAlumnoInformeView({super.key, required this.modo});

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
      backgroundColor: context.appPrimaryBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text(esCrear ? "Elige a un estudiante" : "Elige a un alumno"),
      ),
      body: Container(
        color: context.appPrimaryBackground,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Container(
              decoration: BoxDecoration(
                color: context.appPanel,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: TextField(
                      onChanged: (v) =>
                          setState(() => filtro = v.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "Buscar alumno...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: context.appInputFill,
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
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final alumnos = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          if (!_usuarioActivo(data)) return false;
                          final nombre = (data["nombre"] ?? "")
                              .toString()
                              .toLowerCase();
                          if (filtro.isEmpty) return true;
                          return nombre.contains(filtro);
                        }).toList();

                        if (alumnos.isEmpty) {
                          return const Center(
                            child: Text("No se encontrÃ³ ningÃºn alumno"),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          itemCount: alumnos.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final alumno = alumnos[i];
                            final alumnoId = alumno.id;
                            final nombre = (alumno["nombre"] ?? "Alumno")
                                .toString();

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
                                      builder: (_) =>
                                          ListaInformesAlumnoDirectorView(
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
                                  color: context.appCard,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: context.appBorder),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: context.appMutedText,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: context.appMutedText,
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
      color: context.appPrimaryBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            decoration: BoxDecoration(
              color: context.appPanel,
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
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 22),

                _DirectorActionCard(
                  titulo: "Crear informes",
                  subtitulo: "Selecciona un alumno y enviale un nuevo informe",
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
                  subtitulo:
                      "Selecciona un alumno y revisa sus informes anteriores",
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
          color: context.appCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.appBorder),
          boxShadow: [
            BoxShadow(
              color: context.appShadow,
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
                    style: TextStyle(color: context.appMutedText),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.appMutedText),
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
      color: context.appPrimaryBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            decoration: BoxDecoration(
              color: context.appPanel,
              borderRadius: BorderRadius.circular(18),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("clases")
                  .snapshots(),
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

                    const SizedBox(height: 12),

                    const Text(
                      "Resumen general",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Estadísticas generales de toda la institución.",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // âœ… 2 cuadros grandes
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

                    // âœ… Texto + botÃ³n
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.people),
                              label: const Text("Ver Profesores"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ListaProfesoresView(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimary,
                                side: const BorderSide(color: kPrimary),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.calendar_month),
                              label: const Text("Ver horario general"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const HorarioGeneralProfesoresView(),
                                  ),
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
    final cardColor = context.isDarkMode
        ? Color.alphaBlend(border.withOpacity(0.18), context.appCard)
        : bg;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.6),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: context.appCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icono, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HorarioGeneralProfesoresView extends StatelessWidget {
  const HorarioGeneralProfesoresView({super.key});

  DateTime? _fechaClase(Map<String, dynamic> data) {
    final fecha = data["fecha"];
    if (fecha is Timestamp) return fecha.toDate();
    if (fecha is DateTime) return fecha;
    return null;
  }

  String _fechaTexto(DateTime? fecha) {
    if (fecha == null) return "Fecha sin definir";
    final dia = fecha.day.toString().padLeft(2, "0");
    final mes = fecha.month.toString().padLeft(2, "0");
    return "$dia/$mes/${fecha.year}";
  }

  int _alumnosCount(Map<String, dynamic> data) {
    final alumnos = data["alumnosId"];
    if (alumnos is Iterable) return alumnos.length;
    return 0;
  }

  List<QueryDocumentSnapshot> _clasesOrdenadas(
    List<QueryDocumentSnapshot> docs,
  ) {
    final clases = List<QueryDocumentSnapshot>.from(docs);
    clases.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      final fechaA = _fechaClase(dataA) ?? DateTime(9999);
      final fechaB = _fechaClase(dataB) ?? DateTime(9999);
      final porFecha = fechaA.compareTo(fechaB);
      if (porFecha != 0) return porFecha;

      final horaA = (dataA["horaInicio"] ?? "").toString();
      final horaB = (dataB["horaInicio"] ?? "").toString();
      return horaA.compareTo(horaB);
    });
    return clases;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPrimaryBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: const Text("Horario general"),
      ),
      body: Container(
        color: context.appPrimaryBackground,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Container(
              decoration: BoxDecoration(
                color: context.appPanel,
                borderRadius: BorderRadius.circular(18),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("usuarios")
                    .where("rol", isEqualTo: "profesor")
                    .snapshots(),
                builder: (context, profesoresSnap) {
                  if (!profesoresSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final profesoresActivos = <String, String>{};
                  for (final profesor in profesoresSnap.data!.docs) {
                    final data = profesor.data() as Map<String, dynamic>;
                    if (!_usuarioActivo(data)) continue;
                    profesoresActivos[profesor.id] =
                        (data["nombre"] ?? "Profesor").toString();
                  }

                  if (profesoresActivos.isEmpty) {
                    return const Center(
                      child: Text("No hay profesores activos"),
                    );
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("clases")
                        .snapshots(),
                    builder: (context, clasesSnap) {
                      if (!clasesSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final clases = _clasesOrdenadas(
                        clasesSnap.data!.docs.where((clase) {
                          final data = clase.data() as Map<String, dynamic>;
                          final profesorId = (data["profesorId"] ?? "")
                              .toString();
                          return profesoresActivos.containsKey(profesorId);
                        }).toList(),
                      );

                      if (clases.isEmpty) {
                        return const Center(
                          child: Text("No hay clases en el horario"),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: clases.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final data =
                              clases[index].data() as Map<String, dynamic>;
                          final profesorId = (data["profesorId"] ?? "")
                              .toString();
                          final horaInicio = (data["horaInicio"] ?? "--:--")
                              .toString();
                          final horaFin = (data["horaFin"] ?? "").toString();
                          final horario = horaFin.isEmpty
                              ? horaInicio
                              : "$horaInicio - $horaFin";

                          return _HorarioClaseDirectorCard(
                            fecha: _fechaTexto(_fechaClase(data)),
                            horario: horario,
                            materia: (data["materia"] ?? "Clase").toString(),
                            profesor:
                                profesoresActivos[profesorId] ?? "Profesor",
                            estado: (data["estado"] ?? "activa").toString(),
                            tipoClase:
                                (data["tipoClase"] ??
                                        data["tipo"] ??
                                        "presencial")
                                    .toString(),
                            alumnos: _alumnosCount(data),
                          );
                        },
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

class _HorarioClaseDirectorCard extends StatelessWidget {
  final String fecha;
  final String horario;
  final String materia;
  final String profesor;
  final String estado;
  final String tipoClase;
  final int alumnos;

  const _HorarioClaseDirectorCard({
    required this.fecha,
    required this.horario,
    required this.materia,
    required this.profesor,
    required this.estado,
    required this.tipoClase,
    required this.alumnos,
  });

  Color _estadoColor(String value) {
    switch (value.toLowerCase()) {
      case "cancelada":
        return Colors.red;
      case "hecha":
        return Colors.green;
      case "reprogramada":
        return const Color(0xFFF9A825);
      default:
        return kPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorEstado = _estadoColor(estado);
    final tipo = tipoClase.toLowerCase() == "virtual"
        ? "Virtual"
        : "Presencial";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.calendar_month, color: kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      materia,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profesor,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorEstado.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colorEstado.withValues(alpha: 0.5)),
                ),
                child: Text(
                  estado,
                  style: TextStyle(
                    color: colorEstado,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HorarioInfoChip(icon: Icons.event, text: fecha),
              _HorarioInfoChip(icon: Icons.schedule, text: horario),
              _HorarioInfoChip(icon: Icons.school, text: tipo),
              _HorarioInfoChip(icon: Icons.groups, text: "$alumnos alumno(s)"),
            ],
          ),
        ],
      ),
    );
  }
}

class _HorarioInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HorarioInfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: context.appSoftFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.appMutedText),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: context.appText,
              fontWeight: FontWeight.w700,
              fontSize: 12,
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
                color: context.appPanel,
                borderRadius: BorderRadius.circular(18),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("usuarios")
                    .where("rol", isEqualTo: "profesor")
                    .orderBy("nombre")
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final profes = snap.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _usuarioActivo(data);
                  }).toList();
                  if (profes.isEmpty)
                    return const Center(
                      child: Text("No hay profesores activos"),
                    );

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
                            color: context.appCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.appBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person, color: context.appMutedText),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: context.appMutedText,
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
                color: context.appPanel,
                borderRadius: BorderRadius.circular(18),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("clases")
                    .where("profesorId", isEqualTo: profesorId)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final clases = snap.data!.docs;

                  int hechas = 0;
                  int canceladas = 0;
                  int reprogramadas = 0;
                  int virtuales = 0;

                  for (final c in clases) {
                    final d = c.data() as Map<String, dynamic>;
                    final estado = (d["estado"] ?? "activa").toString();
                    final tipo = (d["tipoClase"] ?? d["tipo"] ?? "presencial")
                        .toString();

                    if (estado == "hecha") hechas++;
                    if (estado == "cancelada") canceladas++;
                    if (estado == "reprogramada") reprogramadas++;
                    if (tipo == "virtual") virtuales++;
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 6),

                      // âœ… INFO PROFESOR
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.appCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.appBorder),
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
                                    "Información del profesor(@)",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profesorNombre,
                                    style: TextStyle(
                                      color: context.appText,
                                      fontWeight: FontWeight.w700,
                                    ),
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
    final cardColor = context.isDarkMode
        ? Color.alphaBlend(border.withOpacity(0.18), context.appCard)
        : bg;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
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
            style: TextStyle(
              color: context.appMutedText,
              fontWeight: FontWeight.w700,
            ),
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
      color: context.appPrimaryBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            decoration: BoxDecoration(
              color: context.appPanel,
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
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 22),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      _BigActionCard(
                        title: "Crear nuevos pagos",
                        subtitle: "Crea un pago y asignalo a alumnos o a todos",
                        icon: Icons.add_card,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CrearPagoDirectorView(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _BigActionCard(
                        title: "Ver pagos",
                        subtitle:
                            "Lista de alumnos â†’ ver pagos pendientes/atrasados",
                        icon: Icons.search,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ListaAlumnosPagosView(),
                            ),
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
      color: context.appPrimaryBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            decoration: BoxDecoration(
              color: context.appPanel,
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

                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final nombre = (data["nombre"] ?? "Director").toString();
                final contacto = (data["contacto"] ?? "â€”").toString();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 6),

                    const SizedBox(height: 12),
                    Text(
                      "Bienvenido, $nombre",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 6),
                    Text(
                      "Perfil del director",
                      style: TextStyle(color: context.appMutedText),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.appCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.appBorder),
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
                        color: context.appSoftFill,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        "Entraste como Modo Director, aqui puedes modificar, agregar o ver todo sobre los usuarios (alumnos y profesor). Además de eso, si tienes alguna duda, ves algúm error o quieres que en la aplicación tenga una nueva actualización, puedes pedirla a nuestro contacto de soporte.",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text(
                        "Crear profesor o alumno",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CrearUsuarioDirectorView(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.manage_accounts),
                      label: const Text(
                        "Ver usuarios",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GestionUsuariosDirectorView(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

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
                    const Align(
                      alignment: Alignment.centerRight,
                      child: ThemeToggleButton(),
                    ),
                    const SizedBox(height: 12),
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

// ====== REEMPLAZA LA CLASE GestionUsuariosDirectorView Y _GestionUsuariosDirectorViewState ======

class GestionUsuariosDirectorView extends StatefulWidget {
  const GestionUsuariosDirectorView({super.key});

  @override
  State<GestionUsuariosDirectorView> createState() =>
      _GestionUsuariosDirectorViewState();
}

class _GestionUsuariosDirectorViewState
    extends State<GestionUsuariosDirectorView> {
  String _busqueda = "";
  String _rolFiltro = "todos";
  final Set<String> _actualizando = {};

  List<QueryDocumentSnapshot> _filtrarUsuarios(
    List<QueryDocumentSnapshot> docs,
  ) {
    final filtrados = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final rol = (data["rol"] ?? "").toString();
      if (rol != "profesor" && rol != "alumno") return false;
      if (_rolFiltro != "todos" && rol != _rolFiltro) return false;

      final texto = [
        data["nombre"],
        data["codigo"],
        data["email"],
        data["telefono"],
      ].whereType<Object>().join(" ").toLowerCase();

      if (_busqueda.isEmpty) return true;
      return texto.contains(_busqueda);
    }).toList();

    filtrados.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      final nombreA = (dataA["nombre"] ?? "").toString().toLowerCase();
      final nombreB = (dataB["nombre"] ?? "").toString().toLowerCase();
      return nombreA.compareTo(nombreB);
    });

    return filtrados;
  }

  Future<void> _cambiarEstado(
    QueryDocumentSnapshot usuario,
    bool activo,
  ) async {
    final data = usuario.data() as Map<String, dynamic>;
    final nombre = (data["nombre"] ?? "Usuario").toString();
    final nuevoEstado = activo ? "activo" : "inactivo";

    setState(() => _actualizando.add(usuario.id));
    try {
      await usuario.reference.update({
        "estado": nuevoEstado,
        "updatedAt": Timestamp.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "$nombre esta $nuevoEstado",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo actualizar el usuario: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _actualizando.remove(usuario.id));
      }
    }
  }

  /// ✅ Nuevo método para cambiar el grupo del alumno
  Future<void> _cambiarGrupo(QueryDocumentSnapshot usuario) async {
    final data = usuario.data() as Map<String, dynamic>;
    final nombre = (data["nombre"] ?? "Alumno").toString();
    final grupoActual = (data["grupo"] ?? "").toString();

    final grupoCtrl = TextEditingController(text: grupoActual);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("Cambiar grupo - $nombre"),
          content: TextField(
            controller: grupoCtrl,
            decoration: InputDecoration(
              hintText: "Ej: 306, 307, etc.",
              prefixIcon: const Icon(Icons.class_),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.text,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final nuevoGrupo = grupoCtrl.text.trim();

                if (nuevoGrupo.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Ingresa un grupo válido")),
                    );
                  }
                  return;
                }

                try {
                  await usuario.reference.update({
                    "grupo": nuevoGrupo,
                    "updatedAt": Timestamp.now(),
                  });

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Grupo actualizado a $nuevoGrupo ✓"),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  Widget _filtroRolChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _rolFiltro == value,
      selectedColor: kPrimary.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        color: _rolFiltro == value ? kPrimary : context.appText,
        fontWeight: FontWeight.w800,
      ),
      onSelected: (_) => setState(() => _rolFiltro = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPrimaryBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: const Text("Usuarios"),
      ),
      body: Container(
        color: context.appPrimaryBackground,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Container(
              decoration: BoxDecoration(
                color: context.appPanel,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                    child: TextField(
                      onChanged: (value) {
                        setState(() => _busqueda = value.trim().toLowerCase());
                      },
                      decoration: InputDecoration(
                        hintText: "Buscar usuario...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: context.appInputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _filtroRolChip("todos", "Todos"),
                          _filtroRolChip("profesor", "Profesores"),
                          _filtroRolChip("alumno", "Alumnos"),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("usuarios")
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final usuarios = _filtrarUsuarios(snapshot.data!.docs);

                        if (usuarios.isEmpty) {
                          return const Center(
                            child: Text("No hay usuarios para mostrar"),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          itemCount: usuarios.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final usuario = usuarios[index];
                            final data = usuario.data() as Map<String, dynamic>;
                            final nombre = (data["nombre"] ?? "Usuario")
                                .toString();
                            final rol = (data["rol"] ?? "").toString();
                            final codigo = (data["codigo"] ?? "Sin codigo")
                                .toString();
                            final telefono =
                                (data["telefono"] ?? data["contacto"] ?? "")
                                    .toString();
                            final grupo = (data["grupo"] ?? "").toString();
                            final activo = _usuarioActivo(data);
                            final actualizando = _actualizando.contains(
                              usuario.id,
                            );
                            final estadoColor = activo
                                ? Colors.green
                                : Colors.red;
                            final esAlumno = rol == "alumno";

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: context.appCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.appBorder),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        height: 44,
                                        width: 44,
                                        decoration: BoxDecoration(
                                          color: kPrimary.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Icon(
                                          rol == "profesor"
                                              ? Icons.school
                                              : Icons.person,
                                          color: kPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nombre,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${_rolLegible(rol)} - Codigo: $codigo",
                                              style: TextStyle(
                                                color: context.appMutedText,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (telefono.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                telefono,
                                                style: TextStyle(
                                                  color: context.appMutedText,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: estadoColor.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                activo ? "Activo" : "Inactivo",
                                                style: TextStyle(
                                                  color: estadoColor,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      actualizando
                                          ? const SizedBox(
                                              height: 26,
                                              width: 26,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Switch.adaptive(
                                              value: activo,
                                              activeThumbColor: kPrimary,
                                              onChanged: (value) =>
                                                  _cambiarEstado(
                                                    usuario,
                                                    value,
                                                  ),
                                            ),
                                    ],
                                  ),
                                  // ✅ Si es alumno, mostrar el grupo y botón para editarlo
                                  if (esAlumno) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kPrimary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: kPrimary.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.class_,
                                            color: kPrimary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "Grupo",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  grupo.isEmpty
                                                      ? "Sin asignar"
                                                      : grupo,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: kPrimary,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: () =>
                                                _cambiarGrupo(usuario),
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              "Cambiar",
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
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

class CrearUsuarioDirectorView extends StatefulWidget {
  const CrearUsuarioDirectorView({super.key});

  @override
  State<CrearUsuarioDirectorView> createState() =>
      _CrearUsuarioDirectorViewState();
}

class _CrearUsuarioDirectorViewState extends State<CrearUsuarioDirectorView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _apoderadoCtrl = TextEditingController();

  String _rol = "alumno";
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    _passwordCtrl.dispose();
    _telefonoCtrl.dispose();
    _apoderadoCtrl.dispose();
    super.dispose();
  }

  String get _emailGenerado => _emailUsuarioDesdeCodigo(_codigoCtrl.text, _rol);

  Future<void> _crearUsuario() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final director = FirebaseAuth.instance.currentUser;
    final codigo = _codigoCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final telefono = _telefonoCtrl.text.trim();
    final apoderado = _apoderadoCtrl.text.trim();
    final email = _emailUsuarioDesdeCodigo(codigo, _rol);
    final nombreAppSecundaria =
        "director-create-${DateTime.now().microsecondsSinceEpoch}";

    FirebaseApp? appSecundaria;

    try {
      appSecundaria = await Firebase.initializeApp(
        name: nombreAppSecundaria,
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final authSecundario = FirebaseAuth.instanceFor(app: appSecundaria);
      final cred = await authSecundario.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(cred.user!.uid)
          .set({
            "uid": cred.user!.uid,
            "nombre": nombre,
            "codigo": codigo,
            "email": email,
            "telefono": telefono,
            "contacto": telefono,
            "apoderado": _rol == "alumno" ? apoderado : "",
            "rol": _rol,
            "estado": "activo",
            "createdAt": Timestamp.now(),
            "updatedAt": Timestamp.now(),
            "createdBy": director?.uid ?? "",
          });

      await authSecundario.signOut();
      await appSecundaria.delete();
      appSecundaria = null;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${_rolLegible(_rol)} creado correctamente. CÃ³digo: $codigo",
          ),
        ),
      );

      _formKey.currentState!.reset();
      _nombreCtrl.clear();
      _codigoCtrl.clear();
      _passwordCtrl.clear();
      _telefonoCtrl.clear();
      _apoderadoCtrl.clear();
      setState(() => _rol = "alumno");
    } on FirebaseAuthException catch (e) {
      String mensaje = "No se pudo crear el usuario.";

      if (e.code == "email-already-in-use") {
        mensaje = "Ese cÃ³digo ya estÃ¡ registrado.";
      } else if (e.code == "weak-password") {
        mensaje = "La contraseÃ±a debe tener al menos 6 caracteres.";
      } else if (e.code == "invalid-email") {
        mensaje = "El cÃ³digo generado no es vÃ¡lido.";
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al crear usuario: $e")));
    } finally {
      if (appSecundaria != null) {
        await FirebaseAuth.instanceFor(app: appSecundaria).signOut();
        await appSecundaria.delete();
      }

      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.appMutedText),
      prefixIcon: Icon(icon, color: context.appMutedText),
      filled: true,
      fillColor: context.appInputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: const Text("Crear usuario"),
      ),
      body: Container(
        color: kPrimary,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Container(
              decoration: BoxDecoration(
                color: context.appPanel,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 6),
                    const Text(
                      "Alta de profesor o alumno",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Crea su cuenta, contraseÃ±a y datos principales para que luego pueda iniciar sesiÃ³n con su cÃ³digo.",
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: _rol,
                      decoration: _inputDecoration(
                        context,
                        "Rol",
                        Icons.badge_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "alumno",
                          child: Text("Alumno"),
                        ),
                        DropdownMenuItem(
                          value: "profesor",
                          child: Text("Profesor"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _rol = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nombreCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        context,
                        "Nombre completo",
                        Icons.person,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Ingresa el nombre";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _codigoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        context,
                        "CÃ³digo de ingreso",
                        Icons.numbers,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final limpio = value?.trim() ?? "";
                        if (limpio.isEmpty) return "Ingresa el cÃ³digo";
                        if (limpio.contains(" "))
                          return "El cÃ³digo no debe tener espacios";
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.appSoftFill,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "Correo interno generado: $_emailGenerado",
                        style: TextStyle(
                          color: context.appText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: _inputDecoration(
                        context,
                        "ContraseÃ±a",
                        Icons.lock_outline,
                      ),
                      validator: (value) {
                        final limpio = value?.trim() ?? "";
                        if (limpio.isEmpty) return "Ingresa la contraseÃ±a";
                        if (limpio.length < 6) return "MÃ­nimo 6 caracteres";
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        context,
                        "TelÃ©fono",
                        Icons.phone,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Ingresa el telÃ©fono";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _apoderadoCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        context,
                        _rol == "alumno" ? "Apoderado" : "Apoderado (opcional)",
                        Icons.family_restroom,
                      ),
                      validator: (value) {
                        if (_rol == "alumno" &&
                            (value == null || value.trim().isEmpty)) {
                          return "Ingresa el apoderado";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _guardando ? null : _crearUsuario,
                      icon: _guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_guardando ? "Creando..." : "Crear usuario"),
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
              Text(label, style: TextStyle(color: context.appMutedText)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
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
          color: context.appCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appBorder),
          boxShadow: [
            BoxShadow(
              color: context.appShadow,
              blurRadius: 14,
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
              child: Icon(icon, color: kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: context.appMutedText)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.appMutedText),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Monto invÃ¡lido")));
      return;
    }

    final directorId = FirebaseAuth.instance.currentUser?.uid ?? "";

    // 1) Obtener alumnos destino
    List<QueryDocumentSnapshot> alumnosDocs = [];

    final alumnosQuery = await FirebaseFirestore.instance
        .collection("usuarios")
        .where("rol", isEqualTo: "alumno")
        .get();

    if (!mounted) return;

    final alumnosActivos = alumnosQuery.docs.where((doc) {
      final data = doc.data();
      return _usuarioActivo(data);
    }).toList();

    if (_paraTodos) {
      alumnosDocs = alumnosActivos;
    } else {
      alumnosDocs = alumnosActivos
          .where((d) => _alumnosSeleccionados.contains(d.id))
          .toList();

      if (alumnosDocs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Selecciona al menos 1 alumno o usa 'Todos'"),
          ),
        );
        return;
      }
    }

    // 2) Crear pagos en batch (Firestore tiene lÃ­mite 500 escrituras por batch)
    final now = Timestamp.now();
    final vencTs = Timestamp.fromDate(_vencimiento);

    final chunks = <List<QueryDocumentSnapshot>>[];
    const maxBatch = 450; // margen seguro
    for (int i = 0; i < alumnosDocs.length; i += maxBatch) {
      chunks.add(
        alumnosDocs.sublist(
          i,
          (i + maxBatch > alumnosDocs.length)
              ? alumnosDocs.length
              : i + maxBatch,
        ),
      );
    }

    for (final chunk in chunks) {
      final batch = FirebaseFirestore.instance.batch();
      for (final alumno in chunk) {
        final alumnoId = alumno.id;
        final alumnoNombre =
            (alumno.data() as Map<String, dynamic>)["nombre"]?.toString() ??
            "Alumno";

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
      SnackBar(
        content: Text("Pago creado âœ… (${alumnosDocs.length} alumno(s))"),
      ),
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
                color: context.appPanel,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  const Text(
                    "Nombre del pago",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _conceptoCtrl,
                    decoration: InputDecoration(
                      hintText: "Ej: Mensualidad Marzo",
                      filled: true,
                      fillColor: context.appInputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    "Monto (S/)",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _montoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Ej: 150",
                      filled: true,
                      fillColor: context.appInputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Fecha de vencimiento",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _vencimiento,
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null)
                            setState(() => _vencimiento = picked);
                        },
                        child: const Text("Cambiar"),
                      ),
                    ],
                  ),
                  Text(
                    "${_vencimiento.day.toString().padLeft(2, "0")}/${_vencimiento.month.toString().padLeft(2, "0")}/${_vencimiento.year}",
                    style: TextStyle(
                      color: context.appMutedText,
                      fontWeight: FontWeight.w700,
                    ),
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
                    subtitle: const Text(
                      "Si lo apagas, podrás seleccionar alumnos específicos a los que se les asignará este pago.",
                    ),
                    activeColor: kPrimary,
                  ),

                  if (!_paraTodos) ...[
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (v) =>
                          setState(() => _filtro = v.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "Buscar alumno...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: context.appInputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
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
                          if (!snapshot.hasData)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );

                          final alumnos = snapshot.data!.docs.where((d) {
                            final data = d.data() as Map<String, dynamic>;
                            if (!_usuarioActivo(data)) return false;
                            final nombre = (data["nombre"] ?? "")
                                .toString()
                                .toLowerCase();
                            if (_filtro.isEmpty) return true;
                            return nombre.contains(_filtro);
                          }).toList();

                          return ListView.separated(
                            itemCount: alumnos.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final a = alumnos[i];
                              final id = a.id;
                              final nombre = (a["nombre"] ?? "Alumno")
                                  .toString();
                              final selected = _alumnosSeleccionados.contains(
                                id,
                              );

                              return ListTile(
                                title: Text(nombre),
                                trailing: Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.add_circle_outline,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
/// 3) VER PAGOS â†’ LISTA DE ALUMNOS
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
                color: context.appPanel,
                borderRadius: BorderRadius.circular(18),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("usuarios")
                    .where("rol", isEqualTo: "alumno")
                    .orderBy("nombre")
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final alumnos = snap.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _usuarioActivo(data);
                  }).toList();
                  if (alumnos.isEmpty) {
                    return const Center(child: Text("No hay alumnos activos"));
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
                            color: context.appCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.appBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person, color: context.appMutedText),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: context.appMutedText,
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

/// ------------------------------
/// 4) PAGOS DEL ALUMNO (DIRECTOR)
///     Tabs: Pendientes / Atrasados
///     BotÃ³n: Marcar pagado
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

  Future<void> _marcarPagado(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) async {
    await doc.reference.update({
      "estado": "pagado",
      "pagadoAt": Timestamp.now(),
      "updatedAt": Timestamp.now(),
      "updatedBy": FirebaseAuth.instance.currentUser?.uid ?? "",
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Marcado como pagado âœ…")));
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
                color: context.appPanel,
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
                          if (!snap.hasData)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );

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

  Widget _lista(
    BuildContext context,
    List<QueryDocumentSnapshot> docs, {
    required bool isAtrasados,
  }) {
    if (docs.isEmpty) {
      return Center(
        child: Text(
          isAtrasados ? "No tiene atrasados" : "No tiene pendientes",
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
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
        final monto = (d["monto"] is num)
            ? (d["monto"] as num).toDouble()
            : 0.0;

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
              Icon(
                isAtrasados ? Icons.error_outline : Icons.schedule,
                color: border,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      concepto,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Monto: $moneda ${monto.toStringAsFixed(monto % 1 == 0 ? 0 : 2)}",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Vence: ${venc == null ? "â€”" : _fmtFecha(venc)}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                    if (isAtrasados)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          "ATRASADO",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  ),
                ],
              ),
              child: Image.asset(
                "assets/images/logo.png",
                height: 44, // âœ… logo grande
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
