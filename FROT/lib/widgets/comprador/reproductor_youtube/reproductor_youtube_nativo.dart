import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../core/theme/app_theme.dart';

// ──────────────────────────────────────────────────────────────────────────
// REPRODUCTOR NATIVO DE YOUTUBE (Android / iOS / macOS / Windows)
// Embebe el reproductor de YouTube dentro de un WebView nativo, igual que
// en Flutter Web: el video se reproduce dentro de la propia app y nunca
// redirige a la app/sitio de YouTube.
// ──────────────────────────────────────────────────────────────────────────
class ReproductorYoutubeNativo extends StatefulWidget {
  final String videoId;
  const ReproductorYoutubeNativo({super.key, required this.videoId});

  @override
  State<ReproductorYoutubeNativo> createState() => _ReproductorYoutubeNativoState();
}

class _ReproductorYoutubeNativoState extends State<ReproductorYoutubeNativo> {
  double _progreso = 0;

  // El iframe se envuelve en una página HTML propia con baseUrl de YouTube:
  // cargar la URL del embed directamente como initialUrlRequest hace que el
  // WebView nativo la abra sin un origen/referer válido, y YouTube la
  // rechaza con "Error 153 - Error de configuración del reproductor de
  // video". Al servir el iframe desde un documento con baseUrl
  // https://www.youtube.com, la petición sí lleva un origen que YouTube
  // reconoce como propio.
  String get _html => '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  html, body { margin: 0; padding: 0; background: #000; height: 100%; overflow: hidden; }
  iframe { position: fixed; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
</style>
</head>
<body>
<iframe
  src="https://www.youtube.com/embed/${widget.videoId}?rel=0&modestbranding=1&playsinline=1"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
  allowfullscreen>
</iframe>
</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InAppWebView(
              initialData: InAppWebViewInitialData(
                data: _html,
                baseUrl: WebUri('https://www.youtube.com'),
              ),
              initialSettings: InAppWebViewSettings(
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                iframeAllowFullscreen: true,
                transparentBackground: false,
                supportZoom: false,
              ),
              onProgressChanged: (controller, progreso) {
                if (mounted) setState(() => _progreso = progreso / 100);
              },
            ),
          ),
          if (_progreso < 1.0)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(
                value: _progreso,
                minHeight: 2,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(CraftHubColors.vinoTintoClaro),
              ),
            ),
        ],
      ),
    );
  }
}
