import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _vistasYaRegistradas = {};

// Embebe el reproductor oficial de YouTube (iframe) dentro de Flutter Web
// usando un HtmlElementView. No requiere paquetes adicionales: usa las
// interoperabilidades DOM de `package:web`, que reemplazan a `dart:html`.
class ReproductorYoutubeEmbed extends StatelessWidget {
  final String videoId;
  const ReproductorYoutubeEmbed({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    final viewId = 'youtube-player-$videoId';

    if (!_vistasYaRegistradas.contains(viewId)) {
      _vistasYaRegistradas.add(viewId);
      ui_web.platformViewRegistry.registerViewFactory(viewId, (int _) {
        final iframe = web.HTMLIFrameElement()
          ..src = 'https://www.youtube.com/embed/$videoId?rel=0&modestbranding=1'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true
          ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; '
              'gyroscope; picture-in-picture';
        return iframe;
      });
    }

    return HtmlElementView(viewType: viewId);
  }
}
