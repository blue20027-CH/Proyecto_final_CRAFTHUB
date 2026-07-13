// lib/screens/vendedor/pantalla_mapa_vendedor.dart
// Mapa de pedidos del vendedor: en vez de mostrar artesanos (como el mapa del
// comprador), muestra a SUS PROPIOS CLIENTES y el estado de cada pedido
// (pendiente, aceptada, enviado/en camino, completada, cancelada).
// Se inserta en _obtenerPantallaActual() — NO contiene Scaffold/Sidebar propios.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pedido_vendedor_model.dart';
import '../../services/vendedor_api_service.dart';
import 'pantalla_ordenes_vendedor.dart'
    show colorEstadoPedido, iconoEstadoPedido;

class PantallaMapaVendedor extends StatefulWidget {
  final bool esOscuro;
  final String nombreVendedor;

  /// Id de un pedido a resaltar/centrar al entrar (p.ej. viniendo de "Mis Órdenes").
  final String? pedidoResaltado;

  const PantallaMapaVendedor({
    super.key,
    required this.esOscuro,
    required this.nombreVendedor,
    this.pedidoResaltado,
  });

  @override
  State<PantallaMapaVendedor> createState() => _PantallaMapaVendedorState();
}

class _PantallaMapaVendedorState extends State<PantallaMapaVendedor> {
  final MapController _mapController = MapController();
  final TextEditingController _ctrlBusqueda = TextEditingController();

  List<PuntoMapaPedido> _puntos = [];
  bool _cargando = true;
  String? _error;
  String _textoBusqueda = '';
  String _estadoFiltro = 'Todos los estados';
  String? _idSeleccionado;
  PuntoMapaPedido? _puntoPopup;
  bool _actualizandoEstado = false;

  static const _centroDefault = LatLng(8.5940, -80.1099);

  static const _estados = [
    'Todos los estados',
    'Pendiente',
    'Aceptada',
    'Enviado',
    'Completada',
    'Cancelada',
  ];

  static const _estadoParam = {
    'Todos los estados': null,
    'Pendiente': EstadoPedido.pendiente,
    'Aceptada': EstadoPedido.aceptada,
    'Enviado': EstadoPedido.enviado,
    'Completada': EstadoPedido.completada,
    'Cancelada': EstadoPedido.cancelada,
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant PantallaMapaVendedor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nombreVendedor != widget.nombreVendedor) {
      _cargar();
    } else if (widget.pedidoResaltado != null &&
        widget.pedidoResaltado != oldWidget.pedidoResaltado) {
      _resaltarPedido(widget.pedidoResaltado!);
    }
  }

  @override
  void dispose() {
    _ctrlBusqueda.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final puntos = await VendedorApiService.cargarPedidosMapa(
        widget.nombreVendedor,
        estado: _estadoParam[_estadoFiltro],
      );
      if (!mounted) return;
      setState(() => _puntos = puntos);
      if (widget.pedidoResaltado != null) {
        _resaltarPedido(widget.pedidoResaltado!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _resaltarPedido(String id) {
    final punto = _puntos.where((p) => p.id == id).toList();
    if (punto.isEmpty) return;
    _seleccionarPunto(punto.first);
  }

  void _seleccionarPunto(PuntoMapaPedido p) {
    setState(() {
      _idSeleccionado = p.id;
      _puntoPopup = p;
    });
    _mapController.move(LatLng(p.lat, p.lng), 9.5);
  }

  void _cerrarPopup() => setState(() {
    _puntoPopup = null;
    _idSeleccionado = null;
  });

  List<PuntoMapaPedido> get _puntosFiltrados {
    final texto = _textoBusqueda.trim().toLowerCase();
    if (texto.isEmpty) return _puntos;
    return _puntos
        .where(
          (p) =>
              p.clienteNombre.toLowerCase().contains(texto) ||
              p.ubicacion.toLowerCase().contains(texto) ||
              p.orden.toLowerCase().contains(texto),
        )
        .toList();
  }

  Future<void> _cambiarEstado(PuntoMapaPedido punto, String nuevoEstado) async {
    setState(() => _actualizandoEstado = true);
    try {
      final label = await VendedorApiService.actualizarEstadoPedido(
        pedidoId: punto.id,
        nombreVendedor: widget.nombreVendedor,
        nuevoEstado: nuevoEstado,
      );
      if (!mounted) return;
      final actualizado = PuntoMapaPedido(
        id: punto.id,
        orden: punto.orden,
        clienteNombre: punto.clienteNombre,
        ubicacion: punto.ubicacion,
        lat: punto.lat,
        lng: punto.lng,
        estado: nuevoEstado,
        estadoLabel: label.isNotEmpty
            ? label
            : EstadoPedido.etiquetaMapa(nuevoEstado),
        total: punto.total,
        telefono: punto.telefono,
        fecha: punto.fecha,
      );
      setState(() {
        final i = _puntos.indexWhere((p) => p.id == punto.id);
        if (i != -1) _puntos[i] = actualizado;
        _puntoPopup = actualizado;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${punto.orden} → ${EstadoPedido.etiqueta(nuevoEstado)}',
          ),
          backgroundColor: CraftHubColors.vinoTinto,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: CraftHubColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _actualizandoEstado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = widget.esOscuro;
    final colorFondo = CraftHubColors.fondo(esOscuro);
    final colorPanel = CraftHubColors.panel(esOscuro);

    return Container(
      color: colorFondo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderMapaVendedor(
            esOscuro: esOscuro,
            estadoSeleccionado: _estadoFiltro,
            estados: _estados,
            alCambiarEstado: (v) {
              setState(() => _estadoFiltro = v ?? 'Todos los estados');
              _cargar();
            },
            alActualizar: _cargar,
            cargando: _cargando,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compacto = constraints.maxWidth < 780;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: compacto
                      ? _mapa(esOscuro)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 260,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: colorPanel,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.07),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _panelLista(esOscuro),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: _mapa(esOscuro)),
                          ],
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelLista(bool esOscuro) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: _CampoBusquedaMapa(
            controlador: _ctrlBusqueda,
            esOscuro: esOscuro,
            alCambiar: (v) => setState(() => _textoBusqueda = v),
          ),
        ),
        Expanded(
          child: _cargando
              ? const Center(
                  child: CircularProgressIndicator(
                    color: CraftHubColors.vinoTinto,
                  ),
                )
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: CraftHubColors.textoSecundario(esOscuro),
                      ),
                    ),
                  ),
                )
              : _puntosFiltrados.isEmpty
              ? Center(
                  child: Text(
                    tr(context, 'vendedor_operaciones.vacio_sin_pedidos'),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      color: CraftHubColors.textoSecundario(esOscuro),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  itemCount: _puntosFiltrados.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 2),
                  itemBuilder: (_, i) {
                    final p = _puntosFiltrados[i];
                    return _TarjetaPedidoMapa(
                      punto: p,
                      esOscuro: esOscuro,
                      seleccionado: _idSeleccionado == p.id,
                      alPresionar: () => _seleccionarPunto(p),
                    ).animate().fadeIn(
                      delay: Duration(milliseconds: i * 30),
                      duration: 250.ms,
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: _LeyendaEstados(esOscuro: esOscuro),
        ),
      ],
    );
  }

  Widget _mapa(bool esOscuro) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centroDefault,
              initialZoom: 7.0,
              onTap: (_, _) => _cerrarPopup(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.crafthub.app',
              ),
              MarkerLayer(
                markers: _puntosFiltrados.map((p) {
                  final seleccionado = _idSeleccionado == p.id;
                  return Marker(
                    point: LatLng(p.lat, p.lng),
                    width: seleccionado ? 74 : 62,
                    height: seleccionado ? 84 : 70,
                    child: GestureDetector(
                      onTap: () => _seleccionarPunto(p),
                      child: _PinPedido(punto: p, seleccionado: seleccionado),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          if (_cargando)
            const Positioned(
              top: 16,
              left: 16,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: CraftHubColors.vinoTinto,
                ),
              ),
            ),

          if (_puntoPopup != null)
            Positioned(
              top: 16,
              right: 16,
              child:
                  _PopupPedidoMapa(
                        punto: _puntoPopup!,
                        esOscuro: esOscuro,
                        actualizando: _actualizandoEstado,
                        alCerrar: _cerrarPopup,
                        alCambiarEstado: (e) => _cambiarEstado(_puntoPopup!, e),
                      )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .slideY(begin: -0.1, end: 0, duration: 200.ms),
            ),

          Positioned(
            bottom: 16,
            right: 16,
            child: _ControlesZoomVendedor(
              mapController: _mapController,
              centro: _centroDefault,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────
class _HeaderMapaVendedor extends StatelessWidget {
  final bool esOscuro;
  final String estadoSeleccionado;
  final List<String> estados;
  final ValueChanged<String?> alCambiarEstado;
  final VoidCallback alActualizar;
  final bool cargando;

  const _HeaderMapaVendedor({
    required this.esOscuro,
    required this.estadoSeleccionado,
    required this.estados,
    required this.alCambiarEstado,
    required this.alActualizar,
    required this.cargando,
  });

  @override
  Widget build(BuildContext context) {
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 26,
                color: CraftHubColors.vinoTinto,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'vendedor_operaciones.titulo_mapa_pedidos'),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colorTexto,
                    ),
                  ),
                  Text(
                    tr(context, 'vendedor_operaciones.subtitulo_mapa_pedidos'),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: CraftHubColors.textoSecundario(esOscuro),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SelectorEstadoMapa(
                esOscuro: esOscuro,
                valor: estadoSeleccionado,
                opciones: estados,
                alCambiar: alCambiarEstado,
              ),
              const SizedBox(width: 10),
              _BotonActualizarMapa(
                esOscuro: esOscuro,
                onTap: cargando ? null : alActualizar,
                cargando: cargando,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectorEstadoMapa extends StatelessWidget {
  final bool esOscuro;
  final String valor;
  final List<String> opciones;
  final ValueChanged<String?> alCambiar;

  const _SelectorEstadoMapa({
    required this.esOscuro,
    required this.valor,
    required this.opciones,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(esOscuro),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CraftHubColors.borde(esOscuro), width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valor,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          dropdownColor: CraftHubColors.panel(esOscuro),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CraftHubColors.textoPrincipal(esOscuro),
          ),
          items: opciones
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: alCambiar,
        ),
      ),
    );
  }
}

class _BotonActualizarMapa extends StatefulWidget {
  final bool esOscuro;
  final VoidCallback? onTap;
  final bool cargando;
  const _BotonActualizarMapa({
    required this.esOscuro,
    required this.onTap,
    required this.cargando,
  });

  @override
  State<_BotonActualizarMapa> createState() => _BotonActualizarMapaState();
}

class _BotonActualizarMapaState extends State<_BotonActualizarMapa> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _sobre
                ? CraftHubColors.vinoTintoOscuro
                : CraftHubColors.vinoTinto,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: CraftHubColors.vinoTinto.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.cargando
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
              const SizedBox(width: 8),
              Text(
                tr(context, 'vendedor_operaciones.actualizar'),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CAMPO DE BÚSQUEDA
// ─────────────────────────────────────────────────────────────
class _CampoBusquedaMapa extends StatelessWidget {
  final TextEditingController controlador;
  final bool esOscuro;
  final ValueChanged<String> alCambiar;

  const _CampoBusquedaMapa({
    required this.controlador,
    required this.esOscuro,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      onChanged: alCambiar,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        color: CraftHubColors.textoPrincipal(esOscuro),
      ),
      decoration: InputDecoration(
        hintText: tr(context, 'vendedor_operaciones.buscar_cliente_direccion_hint'),
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: CraftHubColors.textoSecundario(esOscuro),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: CraftHubColors.textoSecundario(esOscuro),
        ),
        filled: true,
        fillColor: esOscuro
            ? CraftHubColors.panelOscuro2
            : CraftHubColors.fondoClaro,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: CraftHubColors.borde(esOscuro),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: CraftHubColors.vinoTinto,
            width: 1.3,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TARJETA DE PEDIDO EN LA LISTA IZQUIERDA
// ─────────────────────────────────────────────────────────────
class _TarjetaPedidoMapa extends StatefulWidget {
  final PuntoMapaPedido punto;
  final bool esOscuro;
  final bool seleccionado;
  final VoidCallback alPresionar;

  const _TarjetaPedidoMapa({
    required this.punto,
    required this.esOscuro,
    required this.seleccionado,
    required this.alPresionar,
  });

  @override
  State<_TarjetaPedidoMapa> createState() => _TarjetaPedidoMapaState();
}

class _TarjetaPedidoMapaState extends State<_TarjetaPedidoMapa> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.punto;
    final color = colorEstadoPedido(p.estado);
    final resaltado = widget.seleccionado || _sobre;

    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: resaltado
                ? (widget.esOscuro
                    ? CraftHubColors.vinoTinto.withValues(alpha: 0.16)
                    : CraftHubColors.vinoTintoSuave)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: widget.seleccionado
                ? Border.all(color: CraftHubColors.vinoTinto, width: 1.2)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconoEstadoPedido(p.estado),
                  size: 17,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.clienteNombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: CraftHubColors.textoPrincipal(widget.esOscuro),
                      ),
                    ),
                    Text(
                      p.ubicacion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: CraftHubColors.textoSecundario(widget.esOscuro),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.estadoLabel,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${p.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CraftHubColors.textoPrincipal(widget.esOscuro),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LEYENDA DE ESTADOS (reemplaza la sección de categorías del mapa de comprador)
// ─────────────────────────────────────────────────────────────
class _LeyendaEstados extends StatelessWidget {
  final bool esOscuro;
  const _LeyendaEstados({required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: EstadoPedido.todos.map((e) {
        final color = colorEstadoPedido(e);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              EstadoPedido.etiquetaMapa(e),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                color: CraftHubColors.textoSecundario(esOscuro),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PIN EN EL MAPA
// ─────────────────────────────────────────────────────────────
class _PinPedido extends StatelessWidget {
  final PuntoMapaPedido punto;
  final bool seleccionado;

  const _PinPedido({required this.punto, required this.seleccionado});

  @override
  Widget build(BuildContext context) {
    final color = colorEstadoPedido(punto.estado);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: seleccionado ? color : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            punto.estadoLabel,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: seleccionado ? Colors.white : color,
            ),
          ),
        ),
        const SizedBox(height: 3),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: seleccionado ? 46 : 38,
          height: seleccionado ? 46 : 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: Colors.white,
              width: seleccionado ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            iconoEstadoPedido(punto.estado),
            color: Colors.white,
            size: seleccionado ? 20 : 16,
          ),
        ),
        CustomPaint(
          size: const Size(11, 6),
          painter: _PintaPuntaVendedor(color: color),
        ),
      ],
    );
  }
}

class _PintaPuntaVendedor extends CustomPainter {
  final Color color;
  const _PintaPuntaVendedor({required this.color});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = ui.Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// POPUP DE PEDIDO SELECCIONADO
// ─────────────────────────────────────────────────────────────
class _PopupPedidoMapa extends StatelessWidget {
  final PuntoMapaPedido punto;
  final bool esOscuro;
  final bool actualizando;
  final VoidCallback alCerrar;
  final ValueChanged<String> alCambiarEstado;

  const _PopupPedidoMapa({
    required this.punto,
    required this.esOscuro,
    required this.actualizando,
    required this.alCerrar,
    required this.alCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorEstadoPedido(punto.estado);
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);

    return Container(
      width: 268,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(esOscuro),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  punto.orden,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: colorTexto,
                  ),
                ),
              ),
              GestureDetector(
                onTap: alCerrar,
                child: Icon(Icons.close_rounded, size: 18, color: colorSec),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            punto.clienteNombre,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorTexto,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: CraftHubColors.vinoTinto,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  punto.ubicacion,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: colorSec,
                  ),
                ),
              ),
            ],
          ),
          if (punto.telefono != null && punto.telefono!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.call_outlined,
                  size: 14,
                  color: CraftHubColors.vinoTinto,
                ),
                const SizedBox(width: 4),
                Text(
                  punto.telefono!,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: colorSec,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(context, 'vendedor_operaciones.total'),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: colorSec,
                ),
              ),
              Text(
                '\$${punto.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CraftHubColors.vinoTinto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tr(context, 'vendedor_operaciones.estado_del_pedido'),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorSec,
            ),
          ),
          const SizedBox(height: 6),
          actualizando
              ? Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr(context, 'vendedor_operaciones.actualizando'),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                  ],
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: EstadoPedido.todos.map((e) {
                    final c = colorEstadoPedido(e);
                    final activo = e == punto.estado;
                    return GestureDetector(
                      onTap: () => alCambiarEstado(e),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: activo ? c : c.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: c.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          EstadoPedido.etiqueta(e),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: activo ? Colors.white : c,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONTROLES DE ZOOM
// ─────────────────────────────────────────────────────────────
class _ControlesZoomVendedor extends StatelessWidget {
  final MapController mapController;
  final LatLng centro;
  const _ControlesZoomVendedor({
    required this.mapController,
    required this.centro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          _BtnZoomVendedor(
            icono: Icons.add_rounded,
            onTap: () => mapController.move(
              mapController.camera.center,
              mapController.camera.zoom + 1,
            ),
          ),
          Container(height: 1, color: CraftHubColors.bordeClaro),
          _BtnZoomVendedor(
            icono: Icons.remove_rounded,
            onTap: () => mapController.move(
              mapController.camera.center,
              mapController.camera.zoom - 1,
            ),
          ),
          Container(height: 1, color: CraftHubColors.bordeClaro),
          _BtnZoomVendedor(
            icono: Icons.center_focus_strong_rounded,
            onTap: () => mapController.move(centro, 7.0),
          ),
        ],
      ),
    );
  }
}

class _BtnZoomVendedor extends StatefulWidget {
  final IconData icono;
  final VoidCallback onTap;
  const _BtnZoomVendedor({required this.icono, required this.onTap});

  @override
  State<_BtnZoomVendedor> createState() => _BtnZoomVendedorState();
}

class _BtnZoomVendedorState extends State<_BtnZoomVendedor> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 38,
          height: 38,
          color: _sobre ? CraftHubColors.vinoTintoSuave : Colors.transparent,
          child: Icon(widget.icono, size: 18, color: CraftHubColors.textoClaro),
        ),
      ),
    );
  }
}
