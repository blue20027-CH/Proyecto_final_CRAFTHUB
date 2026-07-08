// lib/widgets/eventos/modal_detalle_evento.dart
//
// Modal de detalle de un evento. Comportamiento según el rol:
//  - Comprador: puede marcar favorito y reservar su espacio/entrada.
//  - Vendedor: ve el contacto directo del organizador y puede enviar una
//    solicitud para participar como vendedor en el evento.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/favoritos_provider.dart';
import '../../models/evento_modelo.dart';
import '../../services/eventos_api_service.dart';
import 'tarjeta_contacto_organizador.dart';

Future<void> mostrarDetalleEvento(
  BuildContext context, {
  required EventoArtesanal evento,
  required bool esVendedor,
  required String usuarioId,
  VoidCallback? alCambiarFavorito,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => ModalDetalleEvento(
      evento: evento,
      esVendedor: esVendedor,
      usuarioId: usuarioId,
      alCambiarFavorito: alCambiarFavorito,
    ),
  );
}

class ModalDetalleEvento extends StatefulWidget {
  final EventoArtesanal evento;
  final bool esVendedor;
  final String usuarioId;
  final VoidCallback? alCambiarFavorito;

  const ModalDetalleEvento({
    super.key,
    required this.evento,
    required this.esVendedor,
    required this.usuarioId,
    this.alCambiarFavorito,
  });

  @override
  State<ModalDetalleEvento> createState() => _ModalDetalleEventoState();
}

class _ModalDetalleEventoState extends State<ModalDetalleEvento> {
  bool _reservado = false;
  bool _mostrarFormularioSolicitud = false;
  bool _enviandoSolicitud = false;
  final _mensajeCtrl = TextEditingController(
    text: 'Hola, me gustaría participar como vendedor en este evento. '
        'Cuento con productos artesanales listos para exhibir.',
  );

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirGoogleMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.evento.latitud},${widget.evento.longitud}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _enviarSolicitud() async {
    setState(() => _enviandoSolicitud = true);
    final respuesta = await EventosApiService.solicitarEspacioVendedor(
      eventoId: widget.evento.id,
      vendedorId: widget.usuarioId,
      mensaje: _mensajeCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _enviandoSolicitud = false;
      widget.evento.solicitudEnviada = true;
      _mostrarFormularioSolicitud = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(respuesta['mensaje']?.toString() ?? 'Solicitud enviada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final evento = widget.evento;

    return Dialog(
      backgroundColor: CraftHubColors.panel(oscuro),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Imagen + cerrar + favorito ─────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: AspectRatio(
                      aspectRatio: 16 / 8,
                      child: Image.network(
                        evento.imagenUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: CraftHubColors.vinoTintoSuave,
                          child: const Icon(Icons.event_outlined,
                              size: 44, color: CraftHubColors.vinoTinto),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _BotonCircular(
                      icono: Icons.close_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  if (!widget.esVendedor)
                    Positioned(
                      top: 12,
                      right: 58,
                      child: Builder(builder: (context) {
                        final favorito =
                            context.watch<FavoritosProvider>().esEventoFavorito(evento.id);
                        return _BotonCircular(
                          icono: favorito ? Icons.favorite : Icons.favorite_border,
                          colorIcono: favorito ? CraftHubColors.vinoTinto : Colors.white,
                          onTap: () {
                            context.read<FavoritosProvider>().alternarEvento(evento);
                            widget.alCambiarFavorito?.call();
                          },
                        );
                      }),
                    ),
                  Positioned(
                    left: 16,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: CraftHubColors.vinoTinto,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(iconoCategoriaEvento(evento.categoria), size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(evento.categoria,
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ]),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.titulo,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CraftHubColors.textoPrincipal(oscuro),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FilaDato(
                      icono: Icons.calendar_today_outlined,
                      texto: evento.rangoFechasTexto,
                      oscuro: oscuro,
                    ),
                    const SizedBox(height: 8),
                    _FilaDato(
                      icono: Icons.schedule_rounded,
                      texto: evento.rangoHorarioTexto,
                      oscuro: oscuro,
                    ),
                    const SizedBox(height: 8),
                    _FilaDato(
                      icono: Icons.location_on_outlined,
                      texto: '${evento.ubicacion}, ${evento.provincia}',
                      oscuro: oscuro,
                      accion: TextButton(
                        onPressed: _abrirGoogleMaps,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          foregroundColor: CraftHubColors.vinoTinto,
                        ),
                        child: const Text('Cómo llegar',
                            style: TextStyle(
                                fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!evento.esGratuito && evento.tieneDescuento)
                      _FilaPrecioDescuento(evento: evento, oscuro: oscuro)
                    else
                      _FilaDato(
                        icono: evento.esGratuito
                            ? Icons.confirmation_number_outlined
                            : Icons.sell_outlined,
                        texto: evento.esGratuito
                            ? 'Entrada libre'
                            : 'Entrada: \$${evento.precioEntrada.toStringAsFixed(2)}',
                        oscuro: oscuro,
                      ),
                    if (widget.esVendedor) ...[
                      const SizedBox(height: 8),
                      _FilaDato(
                        icono: Icons.storefront_outlined,
                        texto: evento.cuposVendedorDisponibles > 0
                            ? '${evento.cuposVendedorDisponibles} de ${evento.cuposVendedorTotal} cupos de vendedor disponibles'
                            : 'Sin cupos de vendedor disponibles por ahora',
                        oscuro: oscuro,
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      evento.descripcion,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        height: 1.5,
                        color: CraftHubColors.textoSecundario(oscuro),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Organiza',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CraftHubColors.textoSecundario(oscuro),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TarjetaContactoOrganizador(organizador: evento.organizador),
                    const SizedBox(height: 22),

                    if (!widget.esVendedor) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _reservado
                              ? null
                              : () {
                                  setState(() => _reservado = true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('¡Reserva confirmada! Te esperamos.')),
                                  );
                                },
                          icon: Icon(_reservado ? Icons.check_circle_rounded : Icons.event_available_outlined),
                          label: Text(_reservado ? 'Espacio reservado' : 'Reservar mi espacio'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _reservado ? CraftHubColors.exito : CraftHubColors.vinoTinto,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          ),
                        ),
                      ),
                    ] else ...[
                      if (evento.solicitudEnviada)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: CraftHubColors.exito.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: CraftHubColors.exito),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, color: CraftHubColors.exito, size: 18),
                              SizedBox(width: 8),
                              Text('Solicitud enviada al organizador',
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      color: CraftHubColors.exito)),
                            ],
                          ),
                        )
                      else if (!_mostrarFormularioSolicitud)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _mostrarFormularioSolicitud = true),
                            icon: const Icon(Icons.storefront_outlined),
                            label: const Text('Solicitar espacio de venta'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CraftHubColors.vinoTinto,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mensaje para el organizador',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: CraftHubColors.textoPrincipal(oscuro),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _mensajeCtrl,
                              maxLines: 3,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: CraftHubColors.textoPrincipal(oscuro)),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: CraftHubColors.fondo(oscuro),
                                contentPadding: const EdgeInsets.all(12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: CraftHubColors.borde(oscuro)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _enviandoSolicitud ? null : _enviarSolicitud,
                                icon: _enviandoSolicitud
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.send_rounded, size: 16),
                                label: Text(_enviandoSolicitud ? 'Enviando…' : 'Enviar solicitud'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CraftHubColors.vinoTinto,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaPrecioDescuento extends StatelessWidget {
  final EventoArtesanal evento;
  final bool oscuro;

  const _FilaPrecioDescuento({required this.evento, required this.oscuro});

  @override
  Widget build(BuildContext context) {
    final precioFinal = evento.precioPromocional;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.sell_outlined, size: 17, color: CraftHubColors.vinoTinto),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '\$${evento.precioEntrada.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  decoration: TextDecoration.lineThrough,
                  color: CraftHubColors.textoSecundario(oscuro),
                ),
              ),
              Text(
                '\$${precioFinal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CraftHubColors.vinoTinto,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A843),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  evento.etiquetaDescuento,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'válido ${evento.rangoDescuentoTexto}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  color: CraftHubColors.textoSecundario(oscuro),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilaDato extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool oscuro;
  final Widget? accion;

  const _FilaDato({required this.icono, required this.texto, required this.oscuro, this.accion});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 17, color: CraftHubColors.vinoTinto),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CraftHubColors.textoPrincipal(oscuro),
            ),
          ),
        ),
        if (accion != null) accion!,
      ],
    );
  }
}

class _BotonCircular extends StatefulWidget {
  final IconData icono;
  final Color colorIcono;
  final VoidCallback onTap;

  const _BotonCircular({required this.icono, required this.onTap, this.colorIcono = Colors.white});

  @override
  State<_BotonCircular> createState() => _BotonCircularState();
}

class _BotonCircularState extends State<_BotonCircular> {
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: _hover ? 0.6 : 0.4),
          ),
          child: Icon(widget.icono, size: 17, color: widget.colorIcono),
        ),
      ),
    );
  }
}
