// lib/widgets/chip_categoria.dart
// Widget reutilizable para chips de categorías de productos artesanales
// Muestra imagen representativa, nombre y estado de selección animado

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChipCategoria extends StatefulWidget {
  final String nombre;
  final String rutaImagen; // Image.asset path
  final bool seleccionado;
  final VoidCallback alSeleccionar;

  const ChipCategoria({
    super.key,
    required this.nombre,
    required this.rutaImagen,
    required this.seleccionado,
    required this.alSeleccionar,
  });

  @override
  State<ChipCategoria> createState() => _ChipCategoriaState();
}

class _ChipCategoriaState extends State<ChipCategoria> {
  bool _enHover = false;

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorPrimario = const Color(0xFF821515);
    final colorFondo = esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white;
    final colorBorde = widget.seleccionado
        ? colorPrimario
        : (esModoOscuro ? const Color(0xFF3A3A3A) : const Color(0xFFE0D8D0));

    return MouseRegion(
      onEnter: (_) => setState(() => _enHover = true),
      onExit: (_) => setState(() => _enHover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alSeleccionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 110,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: widget.seleccionado
                ? colorPrimario.withValues(alpha: 0.08)
                : (_enHover ? colorPrimario.withValues(alpha: 0.04) : colorFondo),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorBorde,
              width: widget.seleccionado ? 2.0 : 1.5,
            ),
            boxShadow: _enHover || widget.seleccionado
                ? [
                    BoxShadow(
                      color: colorPrimario.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Imagen de la categoría
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      widget.rutaImagen,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      // 🔌 API: Si las imágenes vienen del backend, usar Image.network(urlImagen)
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorPrimario.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.category_outlined,
                          color: colorPrimario,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Nombre de categoría
                  Text(
                    widget.nombre,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: widget.seleccionado
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: widget.seleccionado
                          ? colorPrimario
                          : (esModoOscuro
                                ? Colors.white70
                                : const Color(0xFF2C2C2C)),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              // Badge de check en esquina superior derecha
              if (widget.seleccionado)
                Positioned(
                  top: 0,
                  right: 0,
                  child:
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colorPrimario,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ).animate().scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 200.ms,
                        curve: Curves.elasticOut,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
