import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/vendedor/tarjeta_tutorial.dart';
import '../../widgets/comprador/reproductor_youtube/reproductor_youtube.dart';
import '../../widgets/comprador/reproductor_youtube/reproductor_youtube_nativo.dart';

// ──────────────────────────────────────────────────────────────────────────
// PANTALLA DETALLE DE VIDEO
// El video ocupa toda la pantalla disponible; debajo va una pequeña barra
// con los datos esenciales (título, vistas, categoría, artesano), que se
// puede ocultar/mostrar con un botón para que el video use el 100% de la
// pantalla.
// 🔌 Backend: GET /api/tutoriales/{id}, POST /api/tutoriales/{id}/vista.
// El video se reproduce SIEMPRE dentro de la propia app (nunca redirige a
// YouTube): en Flutter Web vía iframe embebido y en Android/iOS/macOS/
// Windows vía un WebView nativo (flutter_inappwebview) apuntando al
// reproductor embed de YouTube.
// ──────────────────────────────────────────────────────────────────────────
class PantallaDetalleVideo extends StatefulWidget {
  final ModeloTutorial tutorial;
  const PantallaDetalleVideo({super.key, required this.tutorial});

  @override
  State<PantallaDetalleVideo> createState() => _PantallaDetalleVideoState();
}

class _PantallaDetalleVideoState extends State<PantallaDetalleVideo> {
  late ModeloTutorial _tutorial;
  bool _mostrarBarraInfo = true;

  @override
  void initState() {
    super.initState();
    _tutorial = widget.tutorial;
    _inicializar();
  }

  Future<void> _inicializar() async {
    if (widget.tutorial.id.isEmpty) return;
    // Trae datos frescos (descripción completa, vistas actuales).
    try {
      final actualizado = await ApiService.getTutorial(widget.tutorial.id);
      if (mounted) setState(() => _tutorial = actualizado);
    } catch (e) {
      debugPrint('No se pudo refrescar el detalle del video: $e');
    }
    // Registra la vista en el backend y refleja el conteo real devuelto.
    try {
      final vistas = await ApiService.registrarVistaTutorial(widget.tutorial.id);
      if (mounted) setState(() => _tutorial = _tutorial.copiarCon(vistas: vistas));
    } catch (e) {
      debugPrint('No se pudo registrar la vista: $e');
    }
  }

  String _extraerIdYoutube(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    }
    return uri.queryParameters['v'] ?? '';
  }

  String _formatearVistas(int vistas) {
    if (vistas >= 1000000) return '${(vistas / 1000000).toStringAsFixed(1)}M vistas';
    if (vistas >= 1000) return '${(vistas / 1000).toStringAsFixed(1)}K vistas';
    return '$vistas vista${vistas == 1 ? '' : 's'}';
  }

  // El video se reproduce siempre dentro de la app: iframe embebido en Web,
  // WebView nativo en Android/iOS/macOS/Windows, y solo como último recurso
  // (plataformas sin soporte de WebView, o sin id de YouTube) la miniatura.
  Widget _construirReproductor(String videoId) {
    if (videoId.isEmpty) {
      return _ReproductorRespaldo(tutorial: _tutorial, videoId: videoId);
    }
    if (kIsWeb) {
      return ReproductorYoutubeEmbed(videoId: videoId);
    }
    const plataformasConWebViewNativo = [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    ];
    if (plataformasConWebViewNativo.contains(defaultTargetPlatform)) {
      return ReproductorYoutubeNativo(videoId: videoId);
    }
    return _ReproductorRespaldo(tutorial: _tutorial, videoId: videoId);
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final videoId = _extraerIdYoutube(_tutorial.youtubeUrl);
    final textoVistas = _formatearVistas(_tutorial.vistas);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Barra de controles fina, FUERA del área del video: el
            // reproductor embebido (iframe en Web / WebView nativo) siempre
            // se compone por encima de los widgets de Flutter, así que un
            // botón superpuesto sobre el video quedaría invisible e
            // inalcanzable al toque. Por eso viven en su propia franja.
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  _BotonCircular(
                    icono: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  _BotonCircular(
                    icono: _mostrarBarraInfo
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    onTap: () => setState(() => _mostrarBarraInfo = !_mostrarBarraInfo),
                  ),
                ],
              ),
            ),
            // El video ocupa todo el espacio disponible de la pantalla.
            Expanded(
              child: ColoredBox(
                color: Colors.black,
                child: _construirReproductor(videoId),
              ),
            ),
            // Barra pequeña con los datos; se puede ocultar para que el
            // video use el 100% de la pantalla.
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _mostrarBarraInfo
                  ? _BarraInfoVideo(
                      tutorial: _tutorial,
                      oscuro: oscuro,
                      textoVistas: textoVistas,
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonCircular extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;
  const _BotonCircular({required this.icono, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(icono, color: Colors.white, size: 20),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// REPRODUCTOR DE RESPALDO
// Último recurso: solo se usa si no hay id de YouTube válido o si la
// plataforma no tiene soporte de WebView nativo (p. ej. Linux).
// ──────────────────────────────────────────────────────────────────────────
class _ReproductorRespaldo extends StatelessWidget {
  final ModeloTutorial tutorial;
  final String videoId;
  const _ReproductorRespaldo({required this.tutorial, required this.videoId});

  Future<void> _abrirEnYoutube(BuildContext context) async {
    final url = tutorial.youtubeUrl.isNotEmpty
        ? tutorial.youtubeUrl
        : (videoId.isNotEmpty ? 'https://www.youtube.com/watch?v=$videoId' : '');
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    final abierto = await canLaunchUrl(uri) && await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el video')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _abrirEnYoutube(context),
      child: Stack(fit: StackFit.expand, children: [
        tutorial.miniatura.isNotEmpty
            ? Image.network(
                tutorial.miniatura,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: CraftHubColors.vinoTintoOscuro),
              )
            : Container(color: CraftHubColors.vinoTintoOscuro),
        Container(color: Colors.black.withValues(alpha: 0.25)),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Este dispositivo abrirá el video en YouTube',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 10.5)),
          ),
        ),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// BARRA PEQUEÑA DE INFORMACIÓN (debajo del video, ocultable)
// Muestra lo esencial en una sola franja compacta; al tocarla se abre una
// hoja con el detalle completo (descripción, artesano, categoría).
// ──────────────────────────────────────────────────────────────────────────
class _BarraInfoVideo extends StatelessWidget {
  final ModeloTutorial tutorial;
  final bool oscuro;
  final String textoVistas;

  const _BarraInfoVideo({
    required this.tutorial,
    required this.oscuro,
    required this.textoVistas,
  });

  void _abrirDetalleCompleto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CraftHubColors.fondo(oscuro),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, controlador) => SingleChildScrollView(
          controller: controlador,
          child: _PanelDetalleCompleto(
            tutorial: tutorial,
            oscuro: oscuro,
            textoVistas: textoVistas,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textoPrincipal = CraftHubColors.textoPrincipal(oscuro);
    final textoSecundario = CraftHubColors.textoSecundario(oscuro);

    return Material(
      color: CraftHubColors.fondo(oscuro),
      child: InkWell(
        onTap: () => _abrirDetalleCompleto(context),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: CraftHubColors.vinoTintoSuave,
                  backgroundImage: tutorial.avatarArtesano.isNotEmpty
                      ? NetworkImage(tutorial.avatarArtesano)
                      : null,
                  child: tutorial.avatarArtesano.isEmpty
                      ? Text(
                          tutorial.nombreArtesano.isNotEmpty
                              ? tutorial.nombreArtesano[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: CraftHubColors.vinoTinto, fontWeight: FontWeight.bold, fontSize: 13),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tutorial.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 13.5, fontWeight: FontWeight.w700, color: textoPrincipal),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 13, color: textoSecundario),
                          const SizedBox(width: 3),
                          Text(textoVistas,
                              style: GoogleFonts.poppins(fontSize: 11, color: textoSecundario)),
                          if (tutorial.publicadoHace.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text('•', style: TextStyle(color: textoSecundario, fontSize: 11)),
                            const SizedBox(width: 8),
                            Text(tutorial.publicadoHace,
                                style: GoogleFonts.poppins(fontSize: 11, color: textoSecundario)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_up_rounded, color: textoSecundario, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// PANEL DE DETALLE COMPLETO (hoja modal con toda la información)
// ──────────────────────────────────────────────────────────────────────────
class _PanelDetalleCompleto extends StatelessWidget {
  final ModeloTutorial tutorial;
  final bool oscuro;
  final String textoVistas;

  const _PanelDetalleCompleto({
    required this.tutorial,
    required this.oscuro,
    required this.textoVistas,
  });

  @override
  Widget build(BuildContext context) {
    final textoPrincipal = CraftHubColors.textoPrincipal(oscuro);
    final textoSecundario = CraftHubColors.textoSecundario(oscuro);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: CraftHubColors.borde(oscuro),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text(
            tutorial.titulo,
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w700, height: 1.25, color: textoPrincipal),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 6,
            children: [
              _MetaDato(icono: Icons.visibility_outlined, texto: textoVistas, color: textoSecundario),
              if (tutorial.publicadoHace.isNotEmpty)
                _MetaDato(icono: Icons.schedule_outlined, texto: tutorial.publicadoHace, color: textoSecundario),
              if (tutorial.duracion.isNotEmpty)
                _MetaDato(icono: Icons.timer_outlined, texto: tutorial.duracion, color: textoSecundario),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CraftHubColors.panel(oscuro),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: CraftHubColors.borde(oscuro)),
            ),
            child: Text(tutorial.categoria,
                style: GoogleFonts.poppins(fontSize: 11.5, color: textoSecundario)),
          ),
          const SizedBox(height: 20),
          Divider(color: CraftHubColors.borde(oscuro)),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: CraftHubColors.vinoTintoSuave,
                backgroundImage:
                    tutorial.avatarArtesano.isNotEmpty ? NetworkImage(tutorial.avatarArtesano) : null,
                child: tutorial.avatarArtesano.isEmpty
                    ? Text(
                        tutorial.nombreArtesano.isNotEmpty ? tutorial.nombreArtesano[0].toUpperCase() : '?',
                        style: const TextStyle(color: CraftHubColors.vinoTinto, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tutorial.nombreArtesano,
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700, color: textoPrincipal)),
                    Text('Artesano en CraftHub',
                        style: GoogleFonts.poppins(fontSize: 11.5, color: textoSecundario)),
                  ],
                ),
              ),
            ],
          ),
          if (tutorial.descripcion.isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(color: CraftHubColors.borde(oscuro)),
            const SizedBox(height: 18),
            Text('Descripción',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: textoPrincipal)),
            const SizedBox(height: 8),
            Text(tutorial.descripcion,
                style: GoogleFonts.poppins(fontSize: 13, height: 1.6, color: textoSecundario)),
          ],
        ],
      ),
    );
  }
}

class _MetaDato extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  const _MetaDato({required this.icono, required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icono, size: 15, color: color),
      const SizedBox(width: 4),
      Text(texto, style: GoogleFonts.poppins(fontSize: 12.5, color: color)),
    ]);
  }
}
