import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Chip de filtro de categoría para la pantalla de tutoriales.
class ChipCategoriaTutorial extends StatelessWidget {
  final String etiqueta;
  final IconData icono;
  final bool seleccionado;
  final VoidCallback alPresionar;

  const ChipCategoriaTutorial({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.seleccionado,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: alPresionar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado
              ? CraftHubColors.vinoTinto
              : CraftHubColors.panel(esOscuro),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: seleccionado
                ? CraftHubColors.vinoTinto
                : CraftHubColors.borde(esOscuro),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              size: 15,
              color: seleccionado
                  ? Colors.white
                  : CraftHubColors.textoSecundario(esOscuro),
            ),
            const SizedBox(width: 6),
            Text(
              etiqueta,
              style: TextStyle(
                color: seleccionado
                    ? Colors.white
                    : CraftHubColors.textoPrincipal(esOscuro),
                fontSize: 12,
                fontWeight:
                    seleccionado ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}