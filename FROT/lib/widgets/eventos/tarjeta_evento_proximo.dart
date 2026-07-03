// lib/widgets/eventos/tarjeta_evento_proximo.dart
//
// Tarjeta de evento para el panel lateral "Próximos eventos". El texto y la
// acción del botón principal cambian según el rol (comprador/vendedor).

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/evento_modelo.dart';

class TarjetaEventoProximo extends StatefulWidget {
  final EventoArtesanal evento;
  final String textoBotonPrimario;
  final IconData iconoBotonPrimario;
  final VoidCallback alPresionarPrimario;
  final VoidCallback alVerDetalles;

  const TarjetaEventoProximo({
    super.key,
    required this.evento,
    required this.textoBotonPrimario,
    required this.iconoBotonPrimario,
    required this.alPresionarPrimario,
    required this.alVerDetalles,
  });

  @override
  State<TarjetaEventoProximo> createState() => _TarjetaEventoProximoState();
}

class _TarjetaEventoProximoState extends State<TarjetaEventoProximo> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final evento = widget.evento;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: CraftHubColors.panel(oscuro),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CraftHubColors.borde(oscuro)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hover ? 0.10 : 0.04),
              blurRadius: _hover ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.alVerDetalles,
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      evento.imagenUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: CraftHubColors.vinoTintoSuave,
                        child: const Icon(Icons.event_outlined,
                            size: 34, color: CraftHubColors.vinoTinto),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _BadgeFecha(dia: evento.fechaInicio.day, mes: evento.mesAbreviado),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(iconoCategoriaEvento(evento.categoria),
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(evento.categoria,
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ]),
                    ),
                  ),
                  if (evento.tieneDescuento)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A843),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6),
                          ],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.local_offer_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${evento.etiquetaDescuento} · ${evento.rangoDescuentoTexto}',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: widget.alVerDetalles,
                    child: Text(
                      evento.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: CraftHubColors.textoPrincipal(oscuro),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _FilaIcono(
                    icono: Icons.location_on_outlined,
                    texto: '${evento.ubicacion}, ${evento.provincia}',
                    oscuro: oscuro,
                  ),
                  const SizedBox(height: 3),
                  _FilaIcono(
                    icono: Icons.schedule_rounded,
                    texto: '${evento.rangoFechasTexto} · ${evento.rangoHorarioTexto}',
                    oscuro: oscuro,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _BotonSecundario(
                          texto: 'Ver detalles',
                          onTap: widget.alVerDetalles,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BotonPrimario(
                          texto: widget.textoBotonPrimario,
                          icono: widget.iconoBotonPrimario,
                          onTap: widget.alPresionarPrimario,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeFecha extends StatelessWidget {
  final int dia;
  final String mes;
  const _BadgeFecha({required this.dia, required this.mes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: CraftHubColors.vinoTinto,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Text('$dia',
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1)),
          Text(mes.toUpperCase(),
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _FilaIcono extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool oscuro;
  const _FilaIcono({required this.icono, required this.texto, required this.oscuro});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 13, color: CraftHubColors.textoSecundario(oscuro)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              color: CraftHubColors.textoSecundario(oscuro),
            ),
          ),
        ),
      ],
    );
  }
}

class _BotonSecundario extends StatefulWidget {
  final String texto;
  final VoidCallback onTap;
  const _BotonSecundario({required this.texto, required this.onTap});

  @override
  State<_BotonSecundario> createState() => _BotonSecundarioState();
}

class _BotonSecundarioState extends State<_BotonSecundario> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hover ? CraftHubColors.vinoTintoSuave.withValues(alpha: oscuro ? 0.2 : 1) : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: CraftHubColors.borde(oscuro)),
          ),
          child: Text(
            widget.texto,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CraftHubColors.textoPrincipal(oscuro),
            ),
          ),
        ),
      ),
    );
  }
}

class _BotonPrimario extends StatefulWidget {
  final String texto;
  final IconData icono;
  final VoidCallback onTap;
  const _BotonPrimario({required this.texto, required this.icono, required this.onTap});

  @override
  State<_BotonPrimario> createState() => _BotonPrimarioState();
}

class _BotonPrimarioState extends State<_BotonPrimario> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hover ? CraftHubColors.vinoTintoOscuro : CraftHubColors.vinoTinto,
            borderRadius: BorderRadius.circular(50),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icono, size: 13, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  widget.texto,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
