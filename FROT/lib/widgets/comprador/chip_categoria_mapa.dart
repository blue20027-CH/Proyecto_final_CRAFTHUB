import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ChipCategoriaMapa extends StatefulWidget {
  final String nombre;
  final String imagenUrl;
  final int totalArtesanos;
  final bool seleccionado;
  final VoidCallback alPresionar;

  const ChipCategoriaMapa({
    super.key,
    required this.nombre,
    required this.imagenUrl,
    required this.totalArtesanos,
    required this.seleccionado,
    required this.alPresionar,
  });

  @override
  State<ChipCategoriaMapa> createState() => _ChipCategoriaMapaState();
}

class _ChipCategoriaMapaState extends State<ChipCategoriaMapa> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.seleccionado
                  ? CraftHubColors.vinoTinto
                  : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: _sobre || widget.seleccionado
                ? [
                    BoxShadow(
                      color: CraftHubColors.vinoTinto.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Imagen
                SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: Image.network(
                    widget.imagenUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: CraftHubColors.bordeClaro,
                      child: const Icon(Icons.category_outlined,
                          color: CraftHubColors.textoSecClaro),
                    ),
                  ),
                ),
                // Velo
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(
                              alpha: widget.seleccionado ? 0.65 : 0.50),
                        ],
                      ),
                    ),
                  ),
                ),
                // Texto
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nombre,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${widget.totalArtesanos} artesanos',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.80),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}