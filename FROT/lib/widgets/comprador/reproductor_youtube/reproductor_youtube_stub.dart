import 'package:flutter/material.dart';

// Implementación por defecto (Android/iOS/Windows/desktop): este proyecto
// aún no integra un SDK nativo de YouTube en esas plataformas, así que la
// pantalla de detalle usa la miniatura + botón "Abrir en YouTube" en su
// lugar. En Flutter Web se usa el embed real (ver reproductor_youtube_web.dart).
class ReproductorYoutubeEmbed extends StatelessWidget {
  final String videoId;
  const ReproductorYoutubeEmbed({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
