// lib/widgets/chip_region.dart
// Widget reutilizable para chips de provincias y comarcas de Panamá
// Muestra bandera (emoji o imagen), nombre y estado de selección animado

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChipRegion extends StatefulWidget {
  final String nombre;
  final String bandera; // Emoji de bandera o ruta de imagen
  final bool seleccionado;
  final VoidCallback alSeleccionar;
  final bool usarImagenAsset; // true si la bandera es una imagen local

  const ChipRegion({
    super.key,
    required this.nombre,
    required this.bandera,
    required this.seleccionado,
    required this.alSeleccionar,
    this.usarImagenAsset = false,
  });

  @override
  State<ChipRegion> createState() => _ChipRegionState();
}

class _ChipRegionState extends State<ChipRegion> {
  bool _enHover = false;

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorPrimario = const Color(0xFF821515);
    final colorFondo = esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white;
    final colorBorde = widget.seleccionado
        ? colorPrimario
        : (esModoOscuro ? const Color(0xFF3A3A3A) : const Color(0xFFE0D8D0));
    final colorTexto = widget.seleccionado
        ? colorPrimario
        : (esModoOscuro ? Colors.white : const Color(0xFF2C2C2C));

    return MouseRegion(
      onEnter: (_) => setState(() => _enHover = true),
      onExit: (_) => setState(() => _enHover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alSeleccionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bandera
              _construirBandera(),
              const SizedBox(width: 8),
              // Nombre
              Flexible(
                child: Text(
                  widget.nombre,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: widget.seleccionado
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: colorTexto,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Ícono de check animado
              if (widget.seleccionado) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: colorPrimario,
                ).animate().scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 200.ms,
                  curve: Curves.elasticOut,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirBandera() {
    if (widget.usarImagenAsset) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(
          widget.bandera,
          width: 28,
          height: 20,
          fit: BoxFit.cover,
          // 🔌 Si las banderas vienen de la API, reemplaza Image.asset por Image.network(widget.bandera)
        ),
      );
    }
    // Emoji de bandera o texto
    return Container(
      width: 32,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.transparent,
      ),
      child: Center(
        child: Text(widget.bandera, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
