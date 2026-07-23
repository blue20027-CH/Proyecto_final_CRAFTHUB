import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../core/theme/app_theme.dart';

// ──────────────────────────────────────────────────────────────────────────
// REPRODUCTOR DE VIDEO DIRECTO (archivo subido, no YouTube)
// Reproduce una URL de video (.mp4, .webm, etc.) dentro de la app usando un
// <video> HTML5 embebido en el mismo WebView nativo que ya usa el reproductor
// de YouTube — así no hace falta agregar el paquete video_player (que en
// Windows tiene soporte limitado).
// ──────────────────────────────────────────────────────────────────────────
class ReproductorVideoNativo extends StatefulWidget {
  final String url;
  const ReproductorVideoNativo({super.key, required this.url});

  @override
  State<ReproductorVideoNativo> createState() => _ReproductorVideoNativoState();
}

class _ReproductorVideoNativoState extends State<ReproductorVideoNativo> {
  double _progreso = 0;

  String get _html => '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  html, body { margin: 0; padding: 0; background: #000; height: 100%; overflow: hidden; }
  video { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: #000; }
</style>
</head>
<body>
<video src="${widget.url}" controls autoplay playsinline></video>
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
              initialData: InAppWebViewInitialData(data: _html),
              initialSettings: InAppWebViewSettings(
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
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
