// lib/widgets/eventos/encabezado_eventos.dart
//
// Encabezado de la pantalla de eventos: botón "Volver" (cierra la pantalla
// empujada desde el ícono de calendario del topbar), título y acción extra
// opcional (p. ej. "Nuevo evento" para el vendedor).

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class EncabezadoEventos extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget? accionExtra;

  const EncabezadoEventos({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.accionExtra,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, constraints) {
      final compacto = constraints.maxWidth < 640;
      final volver = _BotonVolver(oscuro: oscuro);
      final encabezadoTexto = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: compacto ? 22 : 26,
              fontWeight: FontWeight.w700,
              color: CraftHubColors.textoPrincipal(oscuro),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: CraftHubColors.textoSecundario(oscuro),
            ),
          ),
        ],
      );

      if (compacto) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              volver,
              if (accionExtra != null) ...[const Spacer(), accionExtra!],
            ]),
            const SizedBox(height: 14),
            encabezadoTexto,
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          volver,
          const SizedBox(width: 18),
          Expanded(child: encabezadoTexto),
          if (accionExtra != null) accionExtra!,
        ],
      );
    });
  }
}

class _BotonVolver extends StatefulWidget {
  final bool oscuro;
  const _BotonVolver({required this.oscuro});

  @override
  State<_BotonVolver> createState() => _BotonVolverState();
}

class _BotonVolverState extends State<_BotonVolver> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _hover
                ? CraftHubColors.panel(widget.oscuro)
                : CraftHubColors.fondo(widget.oscuro),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: CraftHubColors.borde(widget.oscuro)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_rounded, size: 16, color: CraftHubColors.vinoTinto),
              const SizedBox(width: 6),
              Text(
                'Volver',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CraftHubColors.textoPrincipal(widget.oscuro),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
