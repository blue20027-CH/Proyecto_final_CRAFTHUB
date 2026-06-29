import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Botón principal reutilizable con estilo vino tinto y flecha opcional
class BotonPrimario extends StatefulWidget {
  final String texto;
  final VoidCallback alPresionar;
  final double? ancho;

  const BotonPrimario({
    super.key,
    required this.texto,
    required this.alPresionar,
    this.ancho,
  });

  @override
  State<BotonPrimario> createState() => _BotonPrimarioState();
}

class _BotonPrimarioState extends State<BotonPrimario> {
  bool _sobreEl = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobreEl = true),
      onExit: (_) => setState(() => _sobreEl = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.ancho ?? 340,
        height: 54,
        decoration: BoxDecoration(
          color: _sobreEl
              ? CraftHubColors.vinoTintoOscuro
              : CraftHubColors.vinoTinto,
          borderRadius: BorderRadius.circular(50),
          boxShadow: _sobreEl
              ? [
                  BoxShadow(
                    color: CraftHubColors.vinoTinto.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.alPresionar,
            borderRadius: BorderRadius.circular(50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.texto,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
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