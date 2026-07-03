// lib/widgets/eventos/chip_categoria_evento.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/evento_modelo.dart';

class ChipCategoriaEvento extends StatefulWidget {
  final String categoria;
  final bool activo;
  final VoidCallback onTap;

  const ChipCategoriaEvento({
    super.key,
    required this.categoria,
    required this.activo,
    required this.onTap,
  });

  @override
  State<ChipCategoriaEvento> createState() => _ChipCategoriaEventoState();
}

class _ChipCategoriaEventoState extends State<ChipCategoriaEvento> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final activo = widget.activo;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: activo
                ? CraftHubColors.vinoTinto
                : (_hover
                    ? CraftHubColors.vinoTinto.withValues(alpha: 0.06)
                    : CraftHubColors.panel(oscuro)),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: activo ? CraftHubColors.vinoTinto : CraftHubColors.borde(oscuro),
              width: 0.9,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.categoria == 'Todos'
                    ? Icons.apps_rounded
                    : iconoCategoriaEvento(widget.categoria),
                size: 15,
                color: activo ? Colors.white : CraftHubColors.vinoTinto,
              ),
              const SizedBox(width: 6),
              Text(
                widget.categoria,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                  color: activo ? Colors.white : CraftHubColors.textoPrincipal(oscuro),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
