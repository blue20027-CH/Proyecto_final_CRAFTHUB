import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';
import '../../services/api_service.dart';
import '../../widgets/vendedor/tarjeta_tutorial.dart';
import '../../widgets/comprador/reproductor_youtube/reproductor_youtube.dart';

// ──────────────────────────────────────────────────────────────────────────
// PANTALLA DETALLE DE VIDEO
// El video ocupa la mayor parte de la pantalla (arriba); la información
// (título, vistas, artesano, descripción) va debajo y scrollea.
// 🔌 Backend: GET /api/tutoriales/{id}, POST /api/tutoriales/{id}/vista.
// En Flutter Web se embebe el reproductor real de YouTube. En el resto de
// plataformas (Android/iOS/Windows) se usa un reproductor de respaldo con
// miniatura + controles, que abre el video en YouTube al presionarlo.
// ──────────────────────────────────────────────────────────────────────────
class PantallaDetalleVideo extends StatefulWidget {
  final ModeloTutorial tutorial;
  const PantallaDetalleVideo({super.key, required this.tutorial});

  @override
  State<PantallaDetalleVideo> createState() => _PantallaDetalleVideoState();
}

class _PantallaDetalleVideoState extends State<PantallaDetalleVideo> {
  late ModeloTutorial _tutorial;

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
    if (vistas >= 1000000) return '${(vistas / 1000000).toStringAsFixed(1)}M ${tr(context, 'comprador_social.video_vistas_label')}';
    if (vistas >= 1000) return '${(vistas / 1000).toStringAsFixed(1)}K ${tr(context, 'comprador_social.video_vistas_label')}';
    return '$vistas ${vistas == 1 ? tr(context, 'comprador_social.video_vista_singular') : tr(context, 'comprador_social.video_vistas_label')}';
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final tamano = MediaQuery.of(context).size;
    // El video ocupa la mayor parte de la pantalla (~62% del alto visible).
    final alturaVideo = (tamano.height * 0.62).clamp(240.0, 720.0);
    final videoId = _extraerIdYoutube(_tutorial.youtubeUrl);

    return Scaffold(
      backgroundColor: CraftHubColors.fondo(oscuro),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: alturaVideo,
              width: double.infinity,
              child: ColoredBox(
                color: Colors.black,
                child: Stack(children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: (kIsWeb && videoId.isNotEmpty)
                          ? ReproductorYoutubeEmbed(videoId: videoId)
                          : _ReproductorRespaldo(tutorial: _tutorial, videoId: videoId),
                    ),
                  ),
                  Positioned(top: 12, left: 12, child: _BotonVolverVideo()),
                ]),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: _PanelInfoVideo(
                      tutorial: _tutorial,
                      oscuro: oscuro,
                      textoVistas: _formatearVistas(_tutorial.vistas),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonVolverVideo extends StatelessWidget {
  const _BotonVolverVideo();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// REPRODUCTOR DE RESPALDO (Android/iOS/Windows/desktop)
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
        SnackBar(content: Text(tr(context, 'comprador_social.video_no_se_pudo_abrir'))),
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
            child: Text(tr(context, 'comprador_social.video_toca_reproducir_youtube'),
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 10.5)),
          ),
        ),
        // Barra de controles (estética de reproductor; abre YouTube al tocar)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: const LinearProgressIndicator(
                    value: 0,
                    minHeight: 3,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(CraftHubColors.vinoTintoClaro),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '0:00 / ${tutorial.duracion.isNotEmpty ? tutorial.duracion : '--:--'}',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 11),
                  ),
                  const Spacer(),
                  const Icon(Icons.volume_up_rounded, color: Colors.white, size: 19),
                  const SizedBox(width: 12),
                  const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// PANEL DE INFORMACIÓN (debajo del video)
// ──────────────────────────────────────────────────────────────────────────
class _PanelInfoVideo extends StatelessWidget {
  final ModeloTutorial tutorial;
  final bool oscuro;
  final String textoVistas;

  const _PanelInfoVideo({
    required this.tutorial,
    required this.oscuro,
    required this.textoVistas,
  });

  @override
  Widget build(BuildContext context) {
    final textoPrincipal = CraftHubColors.textoPrincipal(oscuro);
    final textoSecundario = CraftHubColors.textoSecundario(oscuro);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    Text(tr(context, 'comprador_social.video_artesano_en_crafthub'),
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
            Text(tr(context, 'comprador_social.video_descripcion_titulo'),
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
