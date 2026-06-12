import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

/// Modelo de datos de un tutorial.
/// 🔌 GET /api/tutoriales → List<ModeloTutorial>
class ModeloTutorial {
  final String id;
  final String titulo;
  final String nombreArtesano;
  final String avatarArtesano;
  final String miniatura; // ruta Image.asset o URL futura
  final String duracion; // ej. "24:15"
  final int vistas;
  final String publicadoHace;
  final String categoria;

  const ModeloTutorial({
    required this.id,
    required this.titulo,
    required this.nombreArtesano,
    required this.avatarArtesano,
    required this.miniatura,
    required this.duracion,
    required this.vistas,
    required this.publicadoHace,
    required this.categoria,
  });

  /// 🔌 factory para mapear respuesta JSON de FastAPI
  factory ModeloTutorial.fromJson(Map<String, dynamic> json) {
    return ModeloTutorial(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      nombreArtesano: json['nombre_artesano'] as String,
      avatarArtesano: json['avatar_artesano'] as String,
      miniatura: json['miniatura'] as String,
      duracion: json['duracion'] as String,
      vistas: json['vistas'] as int,
      publicadoHace: json['publicado_hace'] as String,
      categoria: json['categoria'] as String,
    );
  }
}

/// Tarjeta de tutorial con hover: resalta borde vino tinto al pasar el mouse.
class TarjetaTutorial extends StatefulWidget {
  final ModeloTutorial tutorial;
  final VoidCallback? alPresionar;

  const TarjetaTutorial({
    super.key,
    required this.tutorial,
    this.alPresionar,
  });

  @override
  State<TarjetaTutorial> createState() => _TarjetaTutorialState();
}

class _TarjetaTutorialState extends State<TarjetaTutorial> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = CraftHubColors.panel(esOscuro);
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: colorFondo,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovering
                  ? CraftHubColors.vinoTinto
                  : CraftHubColors.borde(esOscuro),
              width: _hovering ? 1.5 : 1.0,
            ),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: CraftHubColors.vinoTinto.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Miniatura + duración ──────────────────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.asset(
                        widget.tutorial.miniatura,
                        fit: BoxFit.cover,
                        // 🔌 Reemplazar con Image.network(widget.tutorial.miniatura)
                        // cuando el backend devuelva URLs de miniaturas
                        errorBuilder: (_, __, ___) => Container(
                          color: CraftHubColors.vinoTintoOscuro,
                          child: const Center(
                            child: Icon(Icons.video_library,
                                color: Colors.white54, size: 40),
                          ),
                        ),
                      ),
                    ),
                    // Overlay oscuro suave al hacer hover
                    if (_hovering)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.25),
                        ),
                      ),
                    // Icono de reproducción centrado
                    Positioned.fill(
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: _hovering ? 1.0 : 0.75,
                          duration: const Duration(milliseconds: 180),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ),
                    // Chip de duración
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.tutorial.duracion,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Información ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tutorial.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorTexto,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage:
                              AssetImage(widget.tutorial.avatarArtesano),
                          // 🔌 Reemplazar con NetworkImage cuando exista endpoint de avatares
                          onBackgroundImageError: (_, __) {},
                          backgroundColor: CraftHubColors.vinoTintoSuave,
                          child: Text(
                            widget.tutorial.nombreArtesano.isNotEmpty
                                ? widget.tutorial.nombreArtesano[0]
                                : '?',
                            style: const TextStyle(
                              fontSize: 10,
                              color: CraftHubColors.vinoTinto,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.tutorial.nombreArtesano,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorSec,
                              fontSize: 11,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.visibility_outlined,
                            size: 13, color: colorSec),
                        const SizedBox(width: 3),
                        Text(
                          _formatearVistas(widget.tutorial.vistas),
                          style: TextStyle(
                              color: colorSec,
                              fontSize: 11,
                              fontFamily: 'Poppins'),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.schedule_outlined,
                            size: 13, color: colorSec),
                        const SizedBox(width: 3),
                        Text(
                          widget.tutorial.publicadoHace,
                          style: TextStyle(
                              color: colorSec,
                              fontSize: 11,
                              fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0);
  }

  String _formatearVistas(int vistas) {
    if (vistas >= 1000) {
      return '${(vistas / 1000).toStringAsFixed(1)}K vistas';
    }
    return '$vistas vistas';
  }
}