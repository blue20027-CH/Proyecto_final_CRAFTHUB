import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CampoDropdown<T> extends StatelessWidget {
  final T? valorSeleccionado;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> alCambiar;
  final String hint;
  final IconData icono;

  const CampoDropdown({
    super.key,
    required this.valorSeleccionado,
    required this.items,
    required this.alCambiar,
    required this.hint,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: CraftHubColors.panelClaro,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CraftHubColors.bordeClaro, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icono, size: 18, color: CraftHubColors.textoSecClaro),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: valorSeleccionado,
                hint: Text(
                  hint,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    color: CraftHubColors.textoSecClaro,
                  ),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: CraftHubColors.textoSecClaro,
                  size: 20,
                ),
                isExpanded: true,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  color: CraftHubColors.textoClaro,
                ),
                dropdownColor: CraftHubColors.panelClaro,
                borderRadius: BorderRadius.circular(12),
                items: items,
                onChanged: alCambiar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}