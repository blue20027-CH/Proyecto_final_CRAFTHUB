import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';

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
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final etiqueta = widget.coleccionSeleccionada ?? tr(context, 'compartido.todas_colecciones');

    return MouseRegion(
      onEnter: (_) => setState(() => _sobreEl = true),
      onExit:  (_) => setState(() => _sobreEl = false),
      child: PopupMenuButton<String?>(
        onSelected: widget.alSeleccionar,
        color: CraftHubColors.panel(esOscuro),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        offset: const Offset(0, 42),
        itemBuilder: (_) => [
          // Opción "Todas"
          PopupMenuItem<String?>(
            value: null,
            child: Text(
              tr(context, 'compartido.todas_colecciones'),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.coleccionSeleccionada == null
                    ? CraftHubColors.vinoTinto
                    : CraftHubColors.textoPrincipal(esOscuro),
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
                    : CraftHubColors.textoPrincipal(esOscuro),
              ),
            ),
          )),
        ],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _sobreEl
                ? CraftHubColors.vinoTintoSuave.withValues(alpha: esOscuro ? 0.15 : 1)
                : CraftHubColors.panel(esOscuro),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _sobreEl
                  ? CraftHubColors.vinoTinto.withValues(alpha: 0.4)
                  : CraftHubColors.borde(esOscuro),
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
                      : CraftHubColors.textoPrincipal(esOscuro),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: CraftHubColors.textoSecundario(esOscuro)),
            ],
          ),
        ),
      ),
    );
  }
}