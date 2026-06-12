import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/vendedor/tarjeta_tutorial.dart';
import '../../widgets/vendedor/tarjeta_mi_video.dart';
import '../../widgets/vendedor/chip_categoria_tutorial.dart';
import '../../widgets/vendedor/dialogo_subir_video.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATOS MOCK – reemplazar con llamadas HTTP reales al conectar el backend
// 🔌 GET /api/tutoriales?categoria=&pagina=1&limite=8
// 🔌 GET /api/tutoriales/mis-videos  (solo para usuarios con rol artesano/vendedor)
// ─────────────────────────────────────────────────────────────────────────────
final List<ModeloTutorial> _tutorialesMock = [
  ModeloTutorial(
    id: '1',
    titulo: 'Técnica de Temblores en Mostacilla',
    nombreArtesano: 'Rosa Martínez',
    avatarArtesano: 'assets/avatars/rosa.jpg',
    miniatura: 'assets/tutoriales/temblores.jpg',
    duracion: '24:15',
    vistas: 12400,
    publicadoHace: 'Hace 3 días',
    categoria: 'Joyería',
  ),
  ModeloTutorial(
    id: '2',
    titulo: 'Cómo hacer cerámica artesanal',
    nombreArtesano: 'Carlos Ruiz',
    avatarArtesano: 'assets/avatars/carlos.jpg',
    miniatura: 'assets/tutoriales/ceramica.jpg',
    duracion: '18:42',
    vistas: 8700,
    publicadoHace: 'Hace 1 semana',
    categoria: 'Cerámica',
  ),
  ModeloTutorial(
    id: '3',
    titulo: 'Bordado Mola Paso a Paso',
    nombreArtesano: 'Ana Santos',
    avatarArtesano: 'assets/avatars/ana.jpg',
    miniatura: 'assets/tutoriales/mola.jpg',
    duracion: '16:33',
    vistas: 15100,
    publicadoHace: 'Hace 5 días',
    categoria: 'Textiles',
  ),
  ModeloTutorial(
    id: '4',
    titulo: 'Tallado en madera tradicional',
    nombreArtesano: 'Pedro Díaz',
    avatarArtesano: 'assets/avatars/pedro.jpg',
    miniatura: 'assets/tutoriales/madera.jpg',
    duracion: '22:10',
    vistas: 9600,
    publicadoHace: 'Hace 2 semanas',
    categoria: 'Madera',
  ),
  ModeloTutorial(
    id: '5',
    titulo: 'Tejido de bolsas tradicionales',
    nombreArtesano: 'Elena García',
    avatarArtesano: 'assets/avatars/elena.jpg',
    miniatura: 'assets/tutoriales/bolsas.jpg',
    duracion: '20:18',
    vistas: 11300,
    publicadoHace: 'Hace 1 semana',
    categoria: 'Textiles',
  ),
  ModeloTutorial(
    id: '6',
    titulo: "Joyería Emberá: Collares",
    nombreArtesano: 'Miguel Torres',
    avatarArtesano: 'assets/avatars/miguel.jpg',
    miniatura: 'assets/tutoriales/collares.jpg',
    duracion: '14:22',
    vistas: 7800,
    publicadoHace: 'Hace 3 semanas',
    categoria: 'Joyería',
  ),
  ModeloTutorial(
    id: '7',
    titulo: 'Pintura en máscaras tradicionales',
    nombreArtesano: 'José Morales',
    avatarArtesano: 'assets/avatars/jose.jpg',
    miniatura: 'assets/tutoriales/mascaras.jpg',
    duracion: '19:07',
    vistas: 6200,
    publicadoHace: 'Hace 1 mes',
    categoria: 'Pintura',
  ),
  ModeloTutorial(
    id: '8',
    titulo: 'Telar de cintura Ngäbe',
    nombreArtesano: 'Lucía Pérez',
    avatarArtesano: 'assets/avatars/lucia.jpg',
    miniatura: 'assets/tutoriales/telar.jpg',
    duracion: '17:45',
    vistas: 5400,
    publicadoHace: 'Hace 1 mes',
    categoria: 'Textiles',
  ),
];

// Mis videos del artesano autenticado (mock)
// 🔌 GET /api/tutoriales/mis-videos → solo visible para rol vendedor/artesano
final List<ModeloTutorial> _misVideosMock = [
  ModeloTutorial(
    id: 'mv1',
    titulo: 'Técnica de flores en mostacilla',
    nombreArtesano: 'Yo',
    avatarArtesano: 'assets/avatars/yo.jpg',
    miniatura: 'assets/tutoriales/flores.jpg',
    duracion: '21:34',
    vistas: 1200,
    publicadoHace: 'Publicado hace 5 días',
    categoria: 'Joyería',
  ),
  ModeloTutorial(
    id: 'mv2',
    titulo: 'Cerámica: vasijas decorativas',
    nombreArtesano: 'Yo',
    avatarArtesano: 'assets/avatars/yo.jpg',
    miniatura: 'assets/tutoriales/vasijas.jpg',
    duracion: '18:10',
    vistas: 2400,
    publicadoHace: 'Publicado hace 2 semanas',
    categoria: 'Cerámica',
  ),
  ModeloTutorial(
    id: 'mv3',
    titulo: 'Bolso tejido tradicional',
    nombreArtesano: 'Yo',
    avatarArtesano: 'assets/avatars/yo.jpg',
    miniatura: 'assets/tutoriales/bolso.jpg',
    duracion: '15:45',
    vistas: 1700,
    publicadoHace: 'Publicado hace 3 semanas',
    categoria: 'Textiles',
  ),
  ModeloTutorial(
    id: 'mv4',
    titulo: 'Tallado en madera: técnicas',
    nombreArtesano: 'Yo',
    avatarArtesano: 'assets/avatars/yo.jpg',
    miniatura: 'assets/tutoriales/tallado2.jpg',
    duracion: '19:22',
    vistas: 1100,
    publicadoHace: 'Publicado hace 1 mes',
    categoria: 'Madera',
  ),
  ModeloTutorial(
    id: 'mv5',
    titulo: 'Bordado Mola avanzado',
    nombreArtesano: 'Yo',
    avatarArtesano: 'assets/avatars/yo.jpg',
    miniatura: 'assets/tutoriales/mola2.jpg',
    duracion: '16:05',
    vistas: 1500,
    publicadoHace: 'Publicado hace 1 mes',
    categoria: 'Textiles',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Categorías con íconos
// ─────────────────────────────────────────────────────────────────────────────
const List<Map<String, dynamic>> _categoriasDisponibles = [
  {'etiqueta': 'Joyería', 'icono': Icons.diamond_outlined},
  {'etiqueta': 'Cerámica', 'icono': Icons.water_drop_outlined},
  {'etiqueta': 'Textiles', 'icono': Icons.style_outlined},
  {'etiqueta': 'Madera', 'icono': Icons.forest_outlined},
  {'etiqueta': 'Pintura', 'icono': Icons.brush_outlined},
  {'etiqueta': 'Accesorios', 'icono': Icons.watch_outlined},
  {'etiqueta': 'Decoración', 'icono': Icons.home_outlined},
  {'etiqueta': 'Todas', 'icono': Icons.apps_rounded},
];

/// Pantalla de tutoriales artesanales.
/// Entregar únicamente como panel de contenido a [HomeComprador._obtenerPantallaActual].
/// NO incluye Scaffold, TopBar ni Sidebar.
class PantallaTutoriales extends StatefulWidget {
  const PantallaTutoriales({super.key});

  @override
  State<PantallaTutoriales> createState() => _PantallaTutorialesState();
}

class _PantallaTutorialesState extends State<PantallaTutoriales> {
  String _categoriaActiva = 'Todas';
  bool _cargando = false; // 🔌 Poner en true mientras se espera la respuesta del backend

  List<ModeloTutorial> get _tutorialesFiltrados {
    if (_categoriaActiva == 'Todas') return _tutorialesMock;
    return _tutorialesMock
        .where((t) => t.categoria == _categoriaActiva)
        .toList();
  }

  Future<void> _cargarTutoriales() async {
    setState(() => _cargando = true);
    // 🔌 INTEGRACIÓN API:
    // final response = await http.get(
    //   Uri.parse('https://TU_BACKEND/api/tutoriales'
    //     '?categoria=${_categoriaActiva == "Todas" ? "" : _categoriaActiva}'
    //     '&pagina=1&limite=8'),
    //   headers: {'Authorization': 'Bearer $tokenDelUsuario'},
    // );
    // if (response.statusCode == 200) {
    //   final List data = jsonDecode(response.body)['tutoriales'];
    //   setState(() {
    //     _tutorialesMock.clear();
    //     _tutorialesMock.addAll(data.map(ModeloTutorial.fromJson));
    //   });
    // }
    await Future.delayed(const Duration(milliseconds: 300)); // simulación
    setState(() => _cargando = false);
  }

  void _abrirDialogoSubirVideo() {
    showDialog(
      context: context,
      builder: (_) => const DialogoSubirVideo(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = CraftHubColors.fondo(esOscuro);
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);
    final colorPanel = CraftHubColors.panel(esOscuro);
    final colorBorde = CraftHubColors.borde(esOscuro);

    return ColoredBox(
      color: colorFondo,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Contenido principal ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner de bienvenida
                  _BannerTutoriales(
                    colorPanel: colorPanel,
                    colorBorde: colorBorde,
                    colorTexto: colorTexto,
                    colorSec: colorSec,
                    alPresionarSubir: _abrirDialogoSubirVideo,
                  ),
                  const SizedBox(height: 24),

                  // Chips de categorías
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categoriasDisponibles.map((cat) {
                        final etiqueta = cat['etiqueta'] as String;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChipCategoriaTutorial(
                            etiqueta: etiqueta,
                            icono: cat['icono'] as IconData,
                            seleccionado: _categoriaActiva == etiqueta,
                            alPresionar: () {
                              setState(() => _categoriaActiva = etiqueta);
                              _cargarTutoriales();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título sección
                  Text(
                    'Tutoriales destacados',
                    style: TextStyle(
                      color: colorTexto,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid de tutoriales
                  if (_cargando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: CraftHubColors.vinoTinto,
                        ),
                      ),
                    )
                  else if (_tutorialesFiltrados.isEmpty)
                    _EstadoVacio(colorSec: colorSec)
                  else
                    _GridTutoriales(tutoriales: _tutorialesFiltrados),
                ],
              ),
            ),
          ),

          // ── Panel lateral "Mis videos" ───────────────────────────────────────
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: colorPanel,
              border: Border(
                left: BorderSide(color: colorBorde),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis videos',
                        style: TextStyle(
                          color: colorTexto,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Administra y revisa el rendimiento\nde tus tutoriales publicados.',
                        style: TextStyle(
                          color: colorSec,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    itemCount: _misVideosMock.length,
                    itemBuilder: (_, i) => TarjetaMiVideo(
                      tutorial: _misVideosMock[i],
                      alPresionar: () {
                        // 🔌 Navegar al detalle del video
                        // GET /api/tutoriales/{id}/estadisticas
                      },
                      alPresionarOpciones: () {
                        // 🔌 Abrir menú: editar, eliminar, ver estadísticas
                        // DELETE /api/tutoriales/{id}
                        // PATCH /api/tutoriales/{id}
                        _mostrarMenuOpciones(context, _misVideosMock[i]);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
        ],
      ),
    );
  }

  void _mostrarMenuOpciones(BuildContext context, ModeloTutorial tutorial) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: CraftHubColors.panel(esOscuro),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  color: CraftHubColors.vinoTinto),
              title: Text('Editar video',
                  style: TextStyle(
                      color: CraftHubColors.textoPrincipal(esOscuro),
                      fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(context);
                // 🔌 PATCH /api/tutoriales/{tutorial.id}
                // Abrir formulario de edición con los datos precargados
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded,
                  color: CraftHubColors.vinoTinto),
              title: Text('Ver estadísticas',
                  style: TextStyle(
                      color: CraftHubColors.textoPrincipal(esOscuro),
                      fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(context);
                // 🔌 GET /api/tutoriales/{tutorial.id}/estadisticas
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: CraftHubColors.error),
              title: const Text('Eliminar video',
                  style: TextStyle(
                      color: CraftHubColors.error, fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(context);
                // 🔌 DELETE /api/tutoriales/{tutorial.id}
                // Mostrar confirmación antes de eliminar
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subwidgets internos
// ─────────────────────────────────────────────────────────────────────────────

/// Banner de bienvenida con acceso rápido a subir video.
class _BannerTutoriales extends StatelessWidget {
  final Color colorPanel;
  final Color colorBorde;
  final Color colorTexto;
  final Color colorSec;
  final VoidCallback alPresionarSubir;

  const _BannerTutoriales({
    required this.colorPanel,
    required this.colorBorde,
    required this.colorTexto,
    required this.colorSec,
    required this.alPresionarSubir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBorde),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: CraftHubColors.vinoTintoSuave,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.play_circle_outline_rounded,
              color: CraftHubColors.vinoTinto,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aprende sin límites, crea con tus manos.',
                  style: TextStyle(
                    color: colorTexto,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Descubre técnicas tradicionales, aprende de artesanos expertos\ny transforma tu creatividad en piezas únicas.',
                  style: TextStyle(
                    color: colorSec,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Botón "Subir mi video"
          Column(
            children: [
              GestureDetector(
                onTap: alPresionarSubir,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: CraftHubColors.vinoTinto,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Subir mi video',
                style: TextStyle(
                  color: colorSec,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Comparte tu conocimiento',
                style: TextStyle(
                  color: colorSec,
                  fontSize: 10,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.03, end: 0);
  }
}

/// Grid responsivo de tarjetas de tutorial.
class _GridTutoriales extends StatelessWidget {
  final List<ModeloTutorial> tutoriales;

  const _GridTutoriales({required this.tutoriales});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Columnas adaptativas según el ancho disponible
        int columnas = 2;
        if (constraints.maxWidth >= 900) {
          columnas = 4;
        } else if (constraints.maxWidth >= 600) {
          columnas = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: tutoriales.length,
          itemBuilder: (_, i) => TarjetaTutorial(
            tutorial: tutoriales[i],
            alPresionar: () {
              // 🔌 Navegar a pantalla de reproducción del tutorial
              // GET /api/tutoriales/{tutoriales[i].id}
              // Luego abrir PantallaReproductorVideo pasando el modelo
            },
          ),
        );
      },
    );
  }
}

/// Estado vacío cuando no hay tutoriales para la categoría seleccionada.
class _EstadoVacio extends StatelessWidget {
  final Color colorSec;

  const _EstadoVacio({required this.colorSec});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.video_library_outlined, size: 56, color: colorSec),
            const SizedBox(height: 16),
            Text(
              'No hay tutoriales en esta categoría.',
              style: TextStyle(
                color: colorSec,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '¡Sé el primero en publicar uno!',
              style: TextStyle(
                color: colorSec,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}