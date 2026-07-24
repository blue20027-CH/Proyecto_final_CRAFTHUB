import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';
import '../../services/api_service.dart';
import '../../widgets/vendedor/tarjeta_tutorial.dart';
import '../../widgets/vendedor/tarjeta_mi_video.dart';
import '../../widgets/vendedor/chip_categoria_tutorial.dart';
import '../../widgets/vendedor/dialogo_subir_video.dart';
import '../comprador/pantalla_detalle_video.dart';

// Alineadas con las categorías de productos (vestir, joyería, muebles…)
// para que un tutorial de "cómo hacer un collar" caiga en "Joyería" — la
// misma categoría que sus productos. "General" queda para lo transversal
// (marketing, empaque, etc).
const List<Map<String, dynamic>> _categoriasDisponibles = [
  {'etiqueta': 'Todas', 'icono': Icons.apps_rounded},
  {'etiqueta': 'Vestir', 'icono': Icons.checkroom_outlined},
  {'etiqueta': 'Artesanía', 'icono': Icons.palette_outlined},
  {'etiqueta': 'Muebles', 'icono': Icons.chair_outlined},
  {'etiqueta': 'Joyería', 'icono': Icons.diamond_outlined},
  {'etiqueta': 'Alimentos', 'icono': Icons.restaurant_outlined},
  {'etiqueta': 'Accesorios', 'icono': Icons.watch_outlined},
  {'etiqueta': 'Calzado', 'icono': Icons.hiking_outlined},
  {'etiqueta': 'General', 'icono': Icons.lightbulb_outline_rounded},
];

class PantallaTutoriales extends StatefulWidget {
  final String userId;
  final bool esVendedor; // true = vendedor (puede subir y ver "Mis videos"), false = comprador

  const PantallaTutoriales({
    super.key,
    required this.userId,
    this.esVendedor = true,
  });

  @override
  State<PantallaTutoriales> createState() => _PantallaTutorialesState();
}

class _PantallaTutorialesState extends State<PantallaTutoriales> {
  String _categoriaActiva = 'Todas';

  List<ModeloTutorial> _tutoriales = [];
  bool _cargando = true;
  String? _error;

  List<ModeloTutorial> _misVideos = [];
  bool _cargandoMisVideos = true;

  @override
  void initState() {
    super.initState();
    _cargarTutoriales();
    if (widget.esVendedor) _cargarMisVideos();
  }

  Future<void> _cargarTutoriales() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final tutoriales = await ApiService.getTutoriales(
        categoria: _categoriaActiva,
      );
      if (mounted) setState(() => _tutoriales = tutoriales);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cargarMisVideos() async {
    if (widget.userId.isEmpty) {
      setState(() => _cargandoMisVideos = false);
      return;
    }
    setState(() => _cargandoMisVideos = true);
    try {
      final videos = await ApiService.getMisVideos(widget.userId);
      if (mounted) setState(() => _misVideos = videos);
    } catch (e) {
      debugPrint('Error cargando mis videos: $e');
    } finally {
      if (mounted) setState(() => _cargandoMisVideos = false);
    }
  }

  void _abrirDialogoSubirVideo() {
    showDialog<bool>(
      context: context,
      builder: (_) => DialogoSubirVideo(userId: widget.userId),
    ).then((publicado) {
      _cargarMisVideos();
      if (publicado == true) _cargarTutoriales();
    });
  }

  // Punto único de navegación al detalle del video: usado tanto desde la
  // grilla principal como desde el panel "Mis videos", para que la
  // información se vea igual (lineal) sin importar de dónde se abra.
  void _abrirDetalleVideo(ModeloTutorial tutorial) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PantallaDetalleVideo(tutorial: tutorial)),
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
                  // Banner — solo muestra botón subir si es vendedor
                  _BannerTutoriales(
                    colorPanel: colorPanel,
                    colorBorde: colorBorde,
                    colorTexto: colorTexto,
                    colorSec: colorSec,
                    esVendedor: widget.esVendedor,
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

                  Text(
                    tr(context, 'comprador_social.tutoriales_destacados_titulo'),
                    style: TextStyle(
                      color: colorTexto,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_cargando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: CraftHubColors.vinoTinto,
                        ),
                      ),
                    )
                  else if (_error != null)
                    _EstadoError(colorSec: colorSec, mensaje: _error!)
                  else if (_tutoriales.isEmpty)
                    _EstadoVacio(colorSec: colorSec)
                  else
                    _GridTutoriales(
                      tutoriales: _tutoriales,
                      alPresionarVideo: _abrirDetalleVideo,
                    ),
                ],
              ),
            ),
          ),

          // ── Panel lateral "Mis videos" — solo para vendedor ─────────────────
          if (widget.esVendedor)
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
                          tr(context, 'comprador_social.tutoriales_mis_videos_titulo'),
                          style: TextStyle(
                            color: colorTexto,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr(context, 'comprador_social.tutoriales_mis_videos_subtitulo'),
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
                    child: _cargandoMisVideos
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(
                                color: CraftHubColors.vinoTinto,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : _misVideos.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 24),
                                child: Text(
                                  tr(context, 'comprador_social.tutoriales_sin_videos'),
                                  style: TextStyle(
                                    color: colorSec,
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                itemCount: _misVideos.length,
                                itemBuilder: (_, i) => TarjetaMiVideo(
                                  tutorial: _misVideos[i],
                                  alPresionar: () => _abrirDetalleVideo(_misVideos[i]),
                                  alPresionarOpciones: () {
                                    _mostrarMenuOpciones(context, _misVideos[i]);
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
              leading: const Icon(Icons.edit_outlined, color: CraftHubColors.vinoTinto),
              title: Text(tr(context, 'comprador_social.tutoriales_editar_video'),
                  style: TextStyle(
                      color: CraftHubColors.textoPrincipal(esOscuro),
                      fontFamily: 'Poppins')),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded, color: CraftHubColors.vinoTinto),
              title: Text(tr(context, 'comprador_social.tutoriales_ver_estadisticas'),
                  style: TextStyle(
                      color: CraftHubColors.textoPrincipal(esOscuro),
                      fontFamily: 'Poppins')),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: CraftHubColors.error),
              title: Text(tr(context, 'comprador_social.tutoriales_eliminar_video'),
                  style: const TextStyle(color: CraftHubColors.error, fontFamily: 'Poppins')),
              onTap: () async {
                Navigator.pop(context);
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(tr(ctx, 'comprador_social.tutoriales_eliminar_video')),
                    content: Text('${tr(ctx, 'comprador_social.tutoriales_confirmar_eliminar_pregunta')} "${tutorial.titulo}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(tr(ctx, 'comprador_social.cancelar')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(tr(ctx, 'comprador_social.eliminar'),
                            style: const TextStyle(color: CraftHubColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirmar == true) {
                  try {
                    await ApiService.eliminarTutorial(tutorial.id);
                    _cargarMisVideos();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${tr(context, 'comprador_social.tutoriales_error_eliminar')}$e')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subwidgets
// ─────────────────────────────────────────────────────────────────────────────

class _BannerTutoriales extends StatelessWidget {
  final Color colorPanel;
  final Color colorBorde;
  final Color colorTexto;
  final Color colorSec;
  final bool esVendedor;
  final VoidCallback alPresionarSubir;

  const _BannerTutoriales({
    required this.colorPanel,
    required this.colorBorde,
    required this.colorTexto,
    required this.colorSec,
    required this.esVendedor,
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
              Icons.video_library_outlined,
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
                  tr(context, 'comprador_social.tutoriales_banner_titulo'),
                  style: TextStyle(
                    color: colorTexto,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(context, 'comprador_social.tutoriales_banner_subtitulo'),
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
          if (esVendedor) ...[
            const SizedBox(width: 20),
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
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(height: 6),
                Text(tr(context, 'comprador_social.tutoriales_subir_mi_video'),
                    style: TextStyle(color: colorSec, fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                Text(tr(context, 'comprador_social.tutoriales_comparte_conocimiento'),
                    style: TextStyle(color: colorSec, fontSize: 10, fontFamily: 'Poppins')),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.03, end: 0);
  }
}

class _GridTutoriales extends StatelessWidget {
  final List<ModeloTutorial> tutoriales;
  final ValueChanged<ModeloTutorial> alPresionarVideo;
  const _GridTutoriales({required this.tutoriales, required this.alPresionarVideo});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Antes eran hasta 4 columnas; ahora un máximo de 3 para que cada
        // miniatura de video se note más grande. Sigue siendo responsive
        // para tablets y móviles.
        int columnas;
        if (constraints.maxWidth >= 900) {
          columnas = 3;
        } else if (constraints.maxWidth >= 560) {
          columnas = 2;
        } else {
          columnas = 1;
        }

        const espaciado = 18.0;
        // Alto fijo aproximado del bloque de texto bajo el video (título +
        // artesano + vistas/tiempo, con el padding un poco más grande).
        const alturaInfo = 136.0;

        final anchoColumna =
            (constraints.maxWidth - espaciado * (columnas - 1)) / columnas;
        final altoMiniatura = anchoColumna * 9 / 16;
        // La proporción de la tarjeta se calcula a partir del video (16:9)
        // + el bloque de información real que tiene debajo, en vez de un
        // childAspectRatio fijo que dejaba espacio de más o de menos.
        final proporcionTarjeta = anchoColumna / (altoMiniatura + alturaInfo);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            crossAxisSpacing: espaciado,
            mainAxisSpacing: espaciado,
            childAspectRatio: proporcionTarjeta,
          ),
          itemCount: tutoriales.length,
          itemBuilder: (_, i) => TarjetaTutorial(
            tutorial: tutoriales[i],
            alPresionar: () => alPresionarVideo(tutoriales[i]),
          ),
        );
      },
    );
  }
}

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
            Text(tr(context, 'comprador_social.tutoriales_vacio_categoria'),
                style: TextStyle(color: colorSec, fontSize: 14, fontFamily: 'Poppins')),
            const SizedBox(height: 6),
            Text(tr(context, 'comprador_social.tutoriales_vacio_se_primero'),
                style: TextStyle(color: colorSec, fontSize: 12, fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}

class _EstadoError extends StatelessWidget {
  final Color colorSec;
  final String mensaje;
  const _EstadoError({required this.colorSec, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: CraftHubColors.error),
            const SizedBox(height: 16),
            Text(tr(context, 'comprador_social.tutoriales_error_cargar_titulo'),
                style: TextStyle(color: colorSec, fontSize: 14, fontFamily: 'Poppins')),
            const SizedBox(height: 6),
            Text(mensaje,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorSec, fontSize: 11, fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}