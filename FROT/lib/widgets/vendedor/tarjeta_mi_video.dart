import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'tarjeta_tutorial.dart';

/// Tarjeta compacta para la columna lateral "Mis videos".
/// 🔌 GET /api/tutoriales/mis-videos → List<ModeloTutorial>
class TarjetaMiVideo extends StatefulWidget {
  final ModeloTutorial tutorial;
  final VoidCallback? alPresionar;
  final VoidCallback? alPresionarOpciones;

  const TarjetaMiVideo({
    super.key,
    required this.tutorial,
    this.alPresionar,
    this.alPresionarOpciones,
  });

  @override
  State<TarjetaMiVideo> createState() => _TarjetaMiVideoState();
}

class _TarjetaMiVideoState extends State<TarjetaMiVideo> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: _hovering
                ? CraftHubColors.vinoTintoSuave.withValues(
                    alpha: esOscuro ? 0.1 : 0.6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Miniatura
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    SizedBox(
                      width: 88,
                      height: 56,
                      child: widget.tutorial.miniatura.isEmpty
                          ? Container(
                              color: CraftHubColors.vinoTintoOscuro,
                              child: const Center(
                                child: Icon(Icons.video_library,
                                    color: Colors.white54, size: 20),
                              ),
                            )
                          : Image.network(
                              widget.tutorial.miniatura,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: CraftHubColors.vinoTintoOscuro,
                                child: const Center(
                                  child: Icon(Icons.video_library,
                                      color: Colors.white54, size: 20),
                                ),
                              ),
                            ),
                    ),
                    if (widget.tutorial.duracion.isNotEmpty)
                      Positioned(
                        bottom: 3,
                        right: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            widget.tutorial.duracion,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tutorial.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorTexto,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.tutorial.publicadoHace,
                      style: TextStyle(
                        color: colorSec,
                        fontSize: 10,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.visibility_outlined,
                            size: 11, color: colorSec),
                        const SizedBox(width: 3),
                        Text(
                          _formatearVistas(widget.tutorial.vistas),
                          style: TextStyle(
                              color: colorSec,
                              fontSize: 10,
                              fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Botón opciones
              IconButton(
                icon: Icon(Icons.more_vert_rounded, size: 16, color: colorSec),
                onPressed: widget.alPresionarOpciones,
                tooltip: 'Opciones',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 24, minHeight: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatearVistas(int vistas) {
    if (vistas >= 1000) {
      return '${(vistas / 1000).toStringAsFixed(1)}K';
    }
    return '$vistas';
  }
}