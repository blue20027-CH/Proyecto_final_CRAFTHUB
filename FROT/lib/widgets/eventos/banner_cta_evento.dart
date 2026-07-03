// lib/widgets/eventos/banner_cta_evento.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class BannerCtaEvento extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final String textoBoton;
  final VoidCallback onPressed;

  const BannerCtaEvento({
    super.key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.textoBoton,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(oscuro),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CraftHubColors.borde(oscuro)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final apilado = constraints.maxWidth < 480;
          final iconoWidget = Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: CraftHubColors.vinoTinto,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: Colors.white, size: 22),
          );
          final texto = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CraftHubColors.textoPrincipal(oscuro),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitulo,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: CraftHubColors.textoSecundario(oscuro),
                ),
              ),
            ],
          );
          final boton = ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: CraftHubColors.vinoTinto,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              elevation: 0,
            ),
            child: Text(
              textoBoton,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          );

          if (apilado) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [iconoWidget, const SizedBox(width: 14), Expanded(child: texto)]),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: boton),
              ],
            );
          }
          return Row(
            children: [
              iconoWidget,
              const SizedBox(width: 14),
              Expanded(child: texto),
              const SizedBox(width: 14),
              boton,
            ],
          );
        },
      ),
    );
  }
}
