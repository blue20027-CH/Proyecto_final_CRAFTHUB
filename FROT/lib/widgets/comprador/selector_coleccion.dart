import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SelectorColeccion extends StatefulWidget {
  final List<String> colecciones;
  final String? coleccionSeleccionada;
  final ValueChanged<String?> alSeleccionar;

  const SelectorColeccion({
    super.key,
    required this.colecciones,
    required this.coleccionSeleccionada,
    required this.alSeleccionar,
  });

  @override
  State<SelectorColeccion> createState() => _SelectorColeccionState();
}

class _SelectorColeccionState extends State<SelectorColeccion> {
  bool _sobreEl = false;

  @override
  Widget build(BuildContext context) {
    final etiqueta = widget.coleccionSeleccionada ?? 'Todas las colecciones';

    return MouseRegion(
      onEnter: (_) => setState(() => _sobreEl = true),
      onExit:  (_) => setState(() => _sobreEl = false),
      child: PopupMenuButton<String?>(
        onSelected: widget.alSeleccionar,
        color: CraftHubColors.panelClaro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        offset: const Offset(0, 42),
        itemBuilder: (_) => [
          // Opción "Todas"
          PopupMenuItem<String?>(
            value: null,
            child: Text(
              'Todas las colecciones',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.coleccionSeleccionada == null
                    ? CraftHubColors.vinoTinto
                    : CraftHubColors.textoClaro,
              ),
            ),
          ),
          const PopupMenuDivider(),
          // Colecciones del vendedor
          ...widget.colecciones.map((c) => PopupMenuItem<String?>(
            value: c,
            child: Text(
              c,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: widget.coleccionSeleccionada == c
                    ? CraftHubColors.vinoTinto
                    : CraftHubColors.textoClaro,
              ),
            ),
          )),
        ],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _sobreEl
                ? CraftHubColors.vinoTintoSuave
                : CraftHubColors.panelClaro,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _sobreEl
                  ? CraftHubColors.vinoTinto.withValues(alpha: 0.4)
                  : CraftHubColors.bordeClaro,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                etiqueta,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.coleccionSeleccionada != null
                      ? CraftHubColors.vinoTinto
                      : CraftHubColors.textoClaro,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: CraftHubColors.textoSecClaro),
            ],
          ),
        ),
      ),
    );
  }
}