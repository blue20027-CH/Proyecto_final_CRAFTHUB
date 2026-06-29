import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TarjetaStat extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final String? variacion;
  final bool variacionPositiva;
  final String? linkTexto;
  final VoidCallback? alPresionarLink;

  const TarjetaStat({
    super.key,
    required this.icono,
    required this.titulo,
    required this.valor,
    this.variacion,
    this.variacionPositiva = true,
    this.linkTexto,
    this.alPresionarLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: CraftHubColors.panelClaro,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CraftHubColors.bordeClaro, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícono
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CraftHubColors.vinoTintoSuave,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, size: 22, color: CraftHubColors.vinoTinto),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: CraftHubColors.textoSecClaro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: CraftHubColors.textoClaro,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (variacion != null) ...[
                      Icon(
                        variacionPositiva
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 11,
                        color: variacionPositiva
                            ? const Color(0xFF2E7D32)
                            : CraftHubColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        variacion!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: variacionPositiva
                              ? const Color(0xFF2E7D32)
                              : CraftHubColors.error,
                        ),
                      ),
                    ],
                    if (linkTexto != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: alPresionarLink,
                        child: Text(
                          linkTexto!,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CraftHubColors.vinoTinto,
                            decoration: TextDecoration.underline,
                            decorationColor: CraftHubColors.vinoTinto,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}