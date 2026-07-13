// lib/screens/vendedor/pantalla_ordenes_vendedor.dart
// Pantalla "Mis Órdenes" del vendedor — se inserta en _obtenerPantallaActual()
// NO contiene Scaffold, Sidebar ni TopBar propios (sigue el patrón de
// PantallaInventario). Totalmente responsive, con soporte claro/oscuro y
// conectada al backend FastAPI (VendedorApiService).

import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pedido_vendedor_model.dart';
import '../../services/vendedor_api_service.dart';

// ─────────────────────────────────────────────────────────────
// HELPERS DE ESTADO
// ─────────────────────────────────────────────────────────────
Color colorEstadoPedido(String estado) {
  switch (estado) {
    case EstadoPedido.aceptada:
      return CraftHubColors.info;
    case EstadoPedido.enviado:
      return const Color(0xFF00897B);
    case EstadoPedido.completada:
      return CraftHubColors.exito;
    case EstadoPedido.cancelada:
      return CraftHubColors.error;
    case EstadoPedido.pendiente:
    default:
      return CraftHubColors.advertencia;
  }
}

IconData iconoEstadoPedido(String estado) {
  switch (estado) {
    case EstadoPedido.aceptada:
      return Icons.thumb_up_alt_outlined;
    case EstadoPedido.enviado:
      return Icons.local_shipping_outlined;
    case EstadoPedido.completada:
      return Icons.check_circle_outline_rounded;
    case EstadoPedido.cancelada:
      return Icons.cancel_outlined;
    case EstadoPedido.pendiente:
    default:
      return Icons.hourglass_empty_rounded;
  }
}

String _formatoFecha(DateTime? fecha) {
  if (fecha == null) return '—';
  const meses = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  final hora = fecha.hour % 12 == 0 ? 12 : fecha.hour % 12;
  final ampm = fecha.hour >= 12 ? 'PM' : 'AM';
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '${fecha.day} ${meses[fecha.month - 1]}, ${fecha.year} · $hora:$minuto $ampm';
}

String _formatoFechaCorta(DateTime? fecha) {
  if (fecha == null) return '—';
  const meses = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  return '${fecha.day} ${meses[fecha.month - 1]}, ${fecha.year}';
}

String _formatoHora(DateTime? fecha) {
  if (fecha == null) return '';
  final hora = fecha.hour % 12 == 0 ? 12 : fecha.hour % 12;
  final ampm = fecha.hour >= 12 ? 'PM' : 'AM';
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '$hora:$minuto $ampm';
}

// ─────────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────────────────────
class PantallaOrdenesVendedor extends StatefulWidget {
  final bool esOscuro;
  final String nombreVendedor;

  /// Se invoca cuando el vendedor toca la ubicación de un pedido; recibe el
  /// id del pedido para que la pantalla del mapa lo resalte.
  final ValueChanged<String>? alVerEnMapa;

  /// Se invoca cuando el vendedor quiere chatear con el cliente de un pedido;
  /// recibe el nombre (y el id, si se conoce) del cliente para abrir/crear
  /// esa conversación.
  final void Function(String nombreCliente, String? idCliente)? alAbrirChat;

  const PantallaOrdenesVendedor({
    super.key,
    required this.esOscuro,
    required this.nombreVendedor,
    this.alVerEnMapa,
    this.alAbrirChat,
  });

  @override
  State<PantallaOrdenesVendedor> createState() =>
      _PantallaOrdenesVendedorState();
}

class _PantallaOrdenesVendedorState extends State<PantallaOrdenesVendedor> {
  List<PedidoVendedor> _pedidos = [];
  EstadisticasPedidosVendedor _stats = EstadisticasPedidosVendedor.vacio;
  bool _cargando = true;
  String? _error;

  final TextEditingController _busquedaCtrl = TextEditingController();
  String _busqueda = '';
  String _clienteFiltro = 'Todos los clientes';
  String _estadoFiltro = 'Todos los estados';
  String _orden = 'recientes';
  Timer? _debounce;
  final Set<String> _actualizando = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant PantallaOrdenesVendedor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nombreVendedor != widget.nombreVendedor) _cargar();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resp = await VendedorApiService.cargarPedidos(
        widget.nombreVendedor,
      );
      if (!mounted) return;
      setState(() {
        _pedidos = resp.pedidos;
        _stats = resp.estadisticas;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _onBuscar(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _busqueda = v);
    });
  }

  List<String> get _clientesDisponibles {
    final nombres = _pedidos.map((p) => p.clienteNombre).toSet().toList()
      ..sort();
    return ['Todos los clientes', ...nombres];
  }

  List<PedidoVendedor> get _pedidosFiltrados {
    final texto = _busqueda.trim().toLowerCase();
    var lista = _pedidos.where((p) {
      final coincideCliente =
          _clienteFiltro == 'Todos los clientes' ||
          p.clienteNombre == _clienteFiltro;
      final coincideEstado =
          _estadoFiltro == 'Todos los estados' ||
          p.estadoLabel == _estadoFiltro;
      final coincideBusqueda =
          texto.isEmpty ||
          p.orden.toLowerCase().contains(texto) ||
          p.clienteNombre.toLowerCase().contains(texto) ||
          p.productos.any((it) => it.nombre.toLowerCase().contains(texto));
      return coincideCliente && coincideEstado && coincideBusqueda;
    }).toList();

    lista.sort((a, b) {
      // Las canceladas siempre quedan al final, sin importar el orden
      // elegido — ya no son relevantes para el día a día del vendedor.
      final aCancelada = a.estado == EstadoPedido.cancelada;
      final bCancelada = b.estado == EstadoPedido.cancelada;
      if (aCancelada != bCancelada) return aCancelada ? 1 : -1;

      switch (_orden) {
        case 'antiguos':
          return (a.fecha ?? DateTime(2000)).compareTo(
            b.fecha ?? DateTime(2000),
          );
        case 'mayor_total':
          return b.total.compareTo(a.total);
        case 'menor_total':
          return a.total.compareTo(b.total);
        case 'recientes':
        default:
          return (b.fecha ?? DateTime(2000)).compareTo(
            a.fecha ?? DateTime(2000),
          );
      }
    });
    return lista;
  }

  Future<void> _cambiarEstado(PedidoVendedor pedido, String nuevoEstado) async {
    if (nuevoEstado == pedido.estado) return;
    setState(() => _actualizando.add(pedido.id));
    try {
      final label = await VendedorApiService.actualizarEstadoPedido(
        pedidoId: pedido.id,
        nombreVendedor: widget.nombreVendedor,
        nuevoEstado: nuevoEstado,
      );
      if (!mounted) return;
      setState(() {
        final i = _pedidos.indexWhere((p) => p.id == pedido.id);
        if (i != -1) {
          _pedidos[i] = _pedidos[i].copyWith(
            estado: nuevoEstado,
            estadoLabel: label.isNotEmpty
                ? label
                : EstadoPedido.etiqueta(nuevoEstado),
          );
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${pedido.orden} → ${EstadoPedido.etiqueta(nuevoEstado)}',
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
      if (mounted) setState(() => _actualizando.remove(pedido.id));
    }
  }

  void _verEnMapa(PedidoVendedor pedido) => widget.alVerEnMapa?.call(pedido.id);

  void _abrirChat(PedidoVendedor pedido) => widget.alAbrirChat?.call(pedido.clienteNombre, pedido.clienteId);

  void _verDetalle(PedidoVendedor pedido) {
    showDialog(
      context: context,
      builder: (_) => _DialogoDetallePedido(
        pedido: pedido,
        esOscuro: widget.esOscuro,
        alCambiarEstado: (e) => _cambiarEstado(pedido, e),
        alVerEnMapa: () {
          Navigator.of(context).pop();
          _verEnMapa(pedido);
        },
        alChatear: () {
          Navigator.of(context).pop();
          _abrirChat(pedido);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = widget.esOscuro;

    return Container(
      color: CraftHubColors.fondo(esOscuro),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 920;
          final padHorizontal = constraints.maxWidth < 600 ? 14.0 : 24.0;

          return RefreshIndicator(
            color: CraftHubColors.vinoTinto,
            onRefresh: _cargar,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                padHorizontal,
                20,
                padHorizontal,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Encabezado(
                    esOscuro: esOscuro,
                    alActualizar: _cargar,
                    cargando: _cargando,
                  ),
                  const SizedBox(height: 20),
                  _FilaEstadisticas(stats: _stats, esOscuro: esOscuro),
                  const SizedBox(height: 20),
                  _BarraFiltros(
                    esOscuro: esOscuro,
                    controladorBusqueda: _busquedaCtrl,
                    alBuscar: _onBuscar,
                    clientes: _clientesDisponibles,
                    clienteSeleccionado: _clienteFiltro,
                    alCambiarCliente: (v) => setState(
                      () => _clienteFiltro = v ?? 'Todos los clientes',
                    ),
                    estadoSeleccionado: _estadoFiltro,
                    alCambiarEstado: (v) => setState(
                      () => _estadoFiltro = v ?? 'Todos los estados',
                    ),
                    ordenSeleccionado: _orden,
                    alCambiarOrden: (v) =>
                        setState(() => _orden = v ?? 'recientes'),
                    compacto: compacto,
                  ),
                  const SizedBox(height: 18),
                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: CraftHubColors.vinoTinto,
                        ),
                      ),
                    )
                  else if (_error != null)
                    _EstadoError(
                      mensaje: _error!,
                      esOscuro: esOscuro,
                      alReintentar: _cargar,
                    )
                  else if (_pedidosFiltrados.isEmpty)
                    _EstadoVacio(esOscuro: esOscuro)
                  else if (compacto)
                    Column(
                      children: _pedidosFiltrados
                          .map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TarjetaOrdenCompacta(
                                pedido: p,
                                esOscuro: esOscuro,
                                actualizando: _actualizando.contains(p.id),
                                alCambiarEstado: (e) => _cambiarEstado(p, e),
                                alVerEnMapa: () => _verEnMapa(p),
                                alVerDetalle: () => _verDetalle(p),
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    _TablaOrdenes(
                      pedidos: _pedidosFiltrados,
                      esOscuro: esOscuro,
                      actualizando: _actualizando,
                      alCambiarEstado: _cambiarEstado,
                      alVerEnMapa: _verEnMapa,
                      alVerDetalle: _verDetalle,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ENCABEZADO
// ─────────────────────────────────────────────────────────────
class _Encabezado extends StatelessWidget {
  final bool esOscuro;
  final VoidCallback alActualizar;
  final bool cargando;

  const _Encabezado({
    required this.esOscuro,
    required this.alActualizar,
    required this.cargando,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    tr(context, 'vendedor_operaciones.titulo_mis_ordenes'),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: CraftHubColors.textoPrincipal(esOscuro),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: CraftHubColors.vinoTinto,
                  ),
                ],
              ),
              Text(
                tr(context, 'vendedor_operaciones.subtitulo_mis_ordenes'),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: CraftHubColors.textoSecundario(esOscuro),
                ),
              ),
            ],
          ),
        ),
        _BotonActualizar(
          esOscuro: esOscuro,
          alTap: alActualizar,
          cargando: cargando,
        ),
      ],
    );
  }
}

class _BotonActualizar extends StatefulWidget {
  final bool esOscuro;
  final VoidCallback alTap;
  final bool cargando;
  const _BotonActualizar({
    required this.esOscuro,
    required this.alTap,
    required this.cargando,
  });

  @override
  State<_BotonActualizar> createState() => _BotonActualizarState();
}

class _BotonActualizarState extends State<_BotonActualizar> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: tr(context, 'vendedor_operaciones.tooltip_actualizar_ordenes'),
        child: GestureDetector(
          onTap: widget.cargando ? null : widget.alTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        size: 16,
                        color: Colors.white,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FILA DE ESTADÍSTICAS
// ─────────────────────────────────────────────────────────────
class _FilaEstadisticas extends StatelessWidget {
  final EstadisticasPedidosVendedor stats;
  final bool esOscuro;
  const _FilaEstadisticas({required this.stats, required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    final tarjetas = [
      _DatoTarjeta(
        icono: Icons.receipt_long_outlined,
        color: CraftHubColors.vinoTinto,
        titulo: tr(context, 'vendedor_operaciones.stat_total_ordenes'),
        valor: '${stats.totalOrdenes}',
        subtitulo: tr(context, 'vendedor_operaciones.stat_todas_las_ordenes'),
      ),
      _DatoTarjeta(
        icono: Icons.fiber_new_rounded,
        color: CraftHubColors.info,
        titulo: tr(context, 'vendedor_operaciones.stat_nuevas_ordenes'),
        valor: '${stats.nuevasOrdenes}',
        subtitulo: tr(context, 'vendedor_operaciones.stat_ultimos_30_dias'),
      ),
      _DatoTarjeta(
        icono: Icons.check_circle_outline_rounded,
        color: CraftHubColors.exito,
        titulo: tr(context, 'vendedor_operaciones.stat_ordenes_completadas'),
        valor: '${stats.completadas}',
        subtitulo: tr(context, 'vendedor_operaciones.stat_ultimos_30_dias'),
      ),
      _DatoTarjeta(
        icono: Icons.cancel_outlined,
        color: CraftHubColors.error,
        titulo: tr(context, 'vendedor_operaciones.stat_ordenes_canceladas'),
        valor: '${stats.canceladas}',
        subtitulo: tr(context, 'vendedor_operaciones.stat_ultimos_30_dias'),
      ),
      _DatoTarjeta(
        icono: Icons.attach_money_rounded,
        color: const Color(0xFFB8860B),
        titulo: tr(context, 'vendedor_operaciones.stat_ingresos_totales'),
        valor: '\$${stats.ingresosTotales.toStringAsFixed(2)}',
        subtitulo: tr(context, 'vendedor_operaciones.stat_ultimos_30_dias'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth >= 1200
            ? 5
            : constraints.maxWidth >= 860
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final espacio = 14.0;
        final ancho =
            (constraints.maxWidth - espacio * (columnas - 1)) / columnas;

        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: tarjetas
              .map(
                (t) => SizedBox(
                  width: ancho,
                  child: _TarjetaEstadistica(dato: t, esOscuro: esOscuro),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DatoTarjeta {
  final IconData icono;
  final Color color;
  final String titulo;
  final String valor;
  final String subtitulo;
  const _DatoTarjeta({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.valor,
    required this.subtitulo,
  });
}

class _TarjetaEstadistica extends StatelessWidget {
  final _DatoTarjeta dato;
  final bool esOscuro;
  const _TarjetaEstadistica({required this.dato, required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(esOscuro),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CraftHubColors.borde(esOscuro)),
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: dato.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(dato.icono, color: dato.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dato.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    color: CraftHubColors.textoSecundario(esOscuro),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dato.valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: CraftHubColors.textoPrincipal(esOscuro),
                  ),
                ),
                Text(
                  dato.subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    color: CraftHubColors.textoSecundario(esOscuro),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BARRA DE FILTROS
// ─────────────────────────────────────────────────────────────
class _BarraFiltros extends StatelessWidget {
  final bool esOscuro;
  final TextEditingController controladorBusqueda;
  final ValueChanged<String> alBuscar;
  final List<String> clientes;
  final String clienteSeleccionado;
  final ValueChanged<String?> alCambiarCliente;
  final String estadoSeleccionado;
  final ValueChanged<String?> alCambiarEstado;
  final String ordenSeleccionado;
  final ValueChanged<String?> alCambiarOrden;
  final bool compacto;

  const _BarraFiltros({
    required this.esOscuro,
    required this.controladorBusqueda,
    required this.alBuscar,
    required this.clientes,
    required this.clienteSeleccionado,
    required this.alCambiarCliente,
    required this.estadoSeleccionado,
    required this.alCambiarEstado,
    required this.ordenSeleccionado,
    required this.alCambiarOrden,
    required this.compacto,
  });

  static const _estados = [
    'Todos los estados',
    'Pendiente',
    'Aceptada',
    'Enviado',
    'Completada',
    'Cancelada',
  ];

  static const _ordenesKeys = {
    'recientes': 'vendedor_operaciones.orden_mas_recientes',
    'antiguos': 'vendedor_operaciones.orden_mas_antiguos',
    'mayor_total': 'vendedor_operaciones.orden_mayor_total',
    'menor_total': 'vendedor_operaciones.orden_menor_total',
  };

  Widget _decorador(Widget child) => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: CraftHubColors.panel(esOscuro),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: CraftHubColors.borde(esOscuro)),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final campoBusqueda = _decorador(
      Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 18,
            color: CraftHubColors.textoSecundario(esOscuro),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controladorBusqueda,
              onChanged: alBuscar,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: CraftHubColors.textoPrincipal(esOscuro),
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: tr(context, 'vendedor_operaciones.buscar_ordenes_hint'),
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: CraftHubColors.textoSecundario(esOscuro),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final dropdownCliente = _decorador(
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: clienteSeleccionado,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          dropdownColor: CraftHubColors.panel(esOscuro),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: CraftHubColors.textoPrincipal(esOscuro),
          ),
          items: clientes
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: alCambiarCliente,
        ),
      ),
    );

    final dropdownEstado = _decorador(
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: estadoSeleccionado,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          dropdownColor: CraftHubColors.panel(esOscuro),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: CraftHubColors.textoPrincipal(esOscuro),
          ),
          items: _estados
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: alCambiarEstado,
        ),
      ),
    );

    final dropdownOrden = _decorador(
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ordenSeleccionado,
          isDense: true,
          icon: const Icon(Icons.sort_rounded, size: 16),
          dropdownColor: CraftHubColors.panel(esOscuro),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: CraftHubColors.textoPrincipal(esOscuro),
          ),
          items: _ordenesKeys.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(tr(context, e.value))))
              .toList(),
          onChanged: alCambiarOrden,
        ),
      ),
    );

    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dropdownCliente,
          const SizedBox(height: 10),
          campoBusqueda,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: dropdownEstado),
              const SizedBox(width: 10),
              Expanded(child: dropdownOrden),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(width: 190, child: dropdownCliente),
        const SizedBox(width: 12),
        Expanded(child: campoBusqueda),
        const SizedBox(width: 12),
        SizedBox(width: 170, child: dropdownEstado),
        const SizedBox(width: 12),
        SizedBox(width: 170, child: dropdownOrden),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ESTADOS VACÍO / ERROR
// ─────────────────────────────────────────────────────────────
class _EstadoVacio extends StatelessWidget {
  final bool esOscuro;
  const _EstadoVacio({required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(esOscuro),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CraftHubColors.borde(esOscuro)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 42,
            color: CraftHubColors.textoSecundario(esOscuro),
          ),
          const SizedBox(height: 10),
          Text(
            tr(context, 'vendedor_operaciones.vacio_sin_resultados'),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: CraftHubColors.textoSecundario(esOscuro),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoError extends StatelessWidget {
  final String mensaje;
  final bool esOscuro;
  final VoidCallback alReintentar;
  const _EstadoError({
    required this.mensaje,
    required this.esOscuro,
    required this.alReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(esOscuro),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CraftHubColors.borde(esOscuro)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 36,
            color: CraftHubColors.error,
          ),
          const SizedBox(height: 10),
          Text(
            tr(context, 'vendedor_operaciones.error_no_se_pudieron_cargar'),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CraftHubColors.textoPrincipal(esOscuro),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: CraftHubColors.textoSecundario(esOscuro),
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: alReintentar,
            icon: const Icon(
              Icons.refresh_rounded,
              color: CraftHubColors.vinoTinto,
            ),
            label: Text(
              tr(context, 'vendedor_operaciones.reintentar'),
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: CraftHubColors.vinoTinto,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHIP DE ESTADO EDITABLE
// ─────────────────────────────────────────────────────────────
class _ChipEstado extends StatelessWidget {
  final PedidoVendedor pedido;
  final bool actualizando;
  final ValueChanged<String> alCambiarEstado;

  const _ChipEstado({
    required this.pedido,
    required this.actualizando,
    required this.alCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorEstadoPedido(pedido.estado);

    if (actualizando) {
      return SizedBox(
        width: 110,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              tr(context, 'vendedor_operaciones.guardando'),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<String>(
        tooltip: tr(context, 'vendedor_operaciones.tooltip_cambiar_estado'),
        offset: const Offset(0, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: alCambiarEstado,
        itemBuilder: (_) => EstadoPedido.todos.map((e) {
          final c = colorEstadoPedido(e);
          return PopupMenuItem<String>(
            value: e,
            child: Row(
              children: [
                Icon(iconoEstadoPedido(e), size: 16, color: c),
                const SizedBox(width: 10),
                Text(
                  EstadoPedido.etiqueta(e),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: e == pedido.estado ? c : null,
                    fontWeight: e == pedido.estado
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                pedido.estadoLabel,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MINIATURAS DE PRODUCTOS (apiladas)
// ─────────────────────────────────────────────────────────────
class _MiniaturasProductos extends StatelessWidget {
  final List<ItemPedidoVendedor> productos;
  final bool esOscuro;
  final double tamano;
  const _MiniaturasProductos({
    required this.productos,
    required this.esOscuro,
    this.tamano = 40,
  });

  @override
  Widget build(BuildContext context) {
    const maxVisibles = 3;
    final visibles = productos.take(maxVisibles).toList();
    final restantes = productos.length - visibles.length;

    return SizedBox(
      height: tamano,
      width:
          tamano +
          (visibles.length - 1) * (tamano * 0.62) +
          (restantes > 0 ? tamano * 0.62 : 0),
      child: Stack(
        children: [
          for (var i = 0; i < visibles.length; i++)
            Positioned(
              left: i * (tamano * 0.62),
              child: Container(
                width: tamano,
                height: tamano,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CraftHubColors.panel(esOscuro),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: visibles[i].imagenUrl.isNotEmpty
                      ? Image.network(
                          visibles[i].imagenUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholderImg(),
                        )
                      : _placeholderImg(),
                ),
              ),
            ),
          if (restantes > 0)
            Positioned(
              left: visibles.length * (tamano * 0.62),
              child: Container(
                width: tamano,
                height: tamano,
                decoration: BoxDecoration(
                  color: CraftHubColors.vinoTintoSuave,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CraftHubColors.panel(esOscuro),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$restantes',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CraftHubColors.vinoTinto,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholderImg() => Container(
    color: CraftHubColors.borde(esOscuro),
    child: Icon(
      Icons.image_outlined,
      size: 16,
      color: CraftHubColors.textoSecundario(esOscuro),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// UBICACIÓN CLICKEABLE (lleva al mapa del vendedor)
// ─────────────────────────────────────────────────────────────
class _UbicacionTappable extends StatefulWidget {
  final String texto;
  final bool esOscuro;
  final VoidCallback onTap;
  const _UbicacionTappable({
    required this.texto,
    required this.esOscuro,
    required this.onTap,
  });

  @override
  State<_UbicacionTappable> createState() => _UbicacionTappableState();
}

class _UbicacionTappableState extends State<_UbicacionTappable> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: tr(context, 'vendedor_operaciones.ver_en_el_mapa'),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 15,
                color: CraftHubColors.vinoTinto,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.texto,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: _sobre
                        ? CraftHubColors.vinoTinto
                        : CraftHubColors.textoPrincipal(widget.esOscuro),
                    decoration: _sobre
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    fontWeight: FontWeight.w500,
                  ),
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
// TABLA DE ÓRDENES (escritorio / pantallas anchas)
// ─────────────────────────────────────────────────────────────
class _TablaOrdenes extends StatelessWidget {
  final List<PedidoVendedor> pedidos;
  final bool esOscuro;
  final Set<String> actualizando;
  final void Function(PedidoVendedor, String) alCambiarEstado;
  final ValueChanged<PedidoVendedor> alVerEnMapa;
  final ValueChanged<PedidoVendedor> alVerDetalle;

  const _TablaOrdenes({
    required this.pedidos,
    required this.esOscuro,
    required this.actualizando,
    required this.alCambiarEstado,
    required this.alVerEnMapa,
    required this.alVerDetalle,
  });

  static const _flexOrden = 2;
  static const _flexCliente = 3;
  static const _flexUbicacion = 3;
  static const _flexProductos = 2;
  static const _flexTotal = 1;
  static const _flexEstado = 2;
  static const _flexFecha = 2;
  static const _anchoAcciones = 92.0;

  // Ancho mínimo bajo el cual las columnas (sobre todo el chip de Estado y
  // la fecha) ya no caben cómodamente. Por debajo de esto, en vez de
  // comprimirse y recortarse, la tabla se vuelve deslizable horizontalmente.
  static const _anchoMinimoTabla = 980.0;

  @override
  Widget build(BuildContext context) {
    final tabla = Container(
      decoration: BoxDecoration(
        color: CraftHubColors.panel(esOscuro),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CraftHubColors.borde(esOscuro)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _encabezado(context),
          for (var i = 0; i < pedidos.length; i++)
            _fila(context, pedidos[i], destacada: i.isEven),
        ],
      ),
    );

    return LayoutBuilder(builder: (context, constraints) {
      final ancho = constraints.maxWidth < _anchoMinimoTabla ? _anchoMinimoTabla : constraints.maxWidth;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: constraints.maxWidth < _anchoMinimoTabla
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        child: SizedBox(width: ancho, child: tabla),
      );
    });
  }

  Widget _celdaTexto(
    String texto,
    int flex, {
    TextAlign align = TextAlign.left,
  }) => Expanded(
    flex: flex,
    child: Text(
      texto,
      textAlign: align,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
    ),
  );

  Widget _encabezado(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [CraftHubColors.vinoTinto, CraftHubColors.vinoTintoOscuro],
        ),
      ),
      child: Row(
        children: [
          _celdaTexto(tr(context, 'vendedor_operaciones.col_orden'), _flexOrden),
          _celdaTexto(tr(context, 'vendedor_operaciones.col_cliente'), _flexCliente),
          _celdaTexto(tr(context, 'vendedor_operaciones.col_ubicacion'), _flexUbicacion),
          _celdaTexto(tr(context, 'vendedor_operaciones.productos'), _flexProductos),
          _celdaTexto(tr(context, 'vendedor_operaciones.total'), _flexTotal),
          _celdaTexto(tr(context, 'vendedor_operaciones.col_estado'), _flexEstado),
          _celdaTexto(tr(context, 'vendedor_operaciones.col_fecha'), _flexFecha),
          SizedBox(
            width: _anchoAcciones,
            child: Text(
              tr(context, 'vendedor_operaciones.col_acciones'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(
    BuildContext context,
    PedidoVendedor pedido, {
    required bool destacada,
  }) {
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: destacada
            ? (esOscuro ? CraftHubColors.panelOscuro2 : const Color(0xFFFBF8F4))
            : CraftHubColors.panel(esOscuro),
        border: Border(
          bottom: BorderSide(color: CraftHubColors.borde(esOscuro), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Orden
          Expanded(
            flex: _flexOrden,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pedido.orden,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colorTexto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pedido.cantidadProductos} ${pedido.cantidadProductos == 1 ? tr(context, 'vendedor_operaciones.producto_singular') : tr(context, 'vendedor_operaciones.producto_plural')}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    color: colorSec,
                  ),
                ),
              ],
            ),
          ),
          // Cliente
          Expanded(
            flex: _flexCliente,
            child: Row(
              children: [
                _AvatarIniciales(nombre: pedido.clienteNombre),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pedido.clienteNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorTexto,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Ubicación
          Expanded(
            flex: _flexUbicacion,
            child: _UbicacionTappable(
              texto: pedido.ubicacion,
              esOscuro: esOscuro,
              onTap: () => alVerEnMapa(pedido),
            ),
          ),
          // Productos
          Expanded(
            flex: _flexProductos,
            child: _MiniaturasProductos(
              productos: pedido.productos,
              esOscuro: esOscuro,
            ),
          ),
          // Total
          Expanded(
            flex: _flexTotal,
            child: Text(
              '\$${pedido.total.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: colorTexto,
              ),
            ),
          ),
          // Estado
          Expanded(
            flex: _flexEstado,
            child: _ChipEstado(
              pedido: pedido,
              actualizando: actualizando.contains(pedido.id),
              alCambiarEstado: (e) => alCambiarEstado(pedido, e),
            ),
          ),
          // Fecha
          Expanded(
            flex: _flexFecha,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatoFechaCorta(pedido.fecha),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: colorTexto,
                  ),
                ),
                Text(
                  _formatoHora(pedido.fecha),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: colorSec,
                  ),
                ),
              ],
            ),
          ),
          // Acciones
          SizedBox(
            width: _anchoAcciones,
            child: _AccionesFila(
              pedido: pedido,
              esOscuro: esOscuro,
              alVerDetalle: () => alVerDetalle(pedido),
              alVerEnMapa: () => alVerEnMapa(pedido),
              alCambiarEstado: (e) => alCambiarEstado(pedido, e),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarIniciales extends StatelessWidget {
  final String nombre;
  const _AvatarIniciales({required this.nombre});

  String get _iniciales {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2);
    final texto = partes.map((p) => p[0].toUpperCase()).join();
    return texto.isEmpty ? 'C' : texto;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: CraftHubColors.vinoTintoSuave,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _iniciales,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: CraftHubColors.vinoTinto,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACCIONES (ver detalle + menú)
// ─────────────────────────────────────────────────────────────
class _AccionesFila extends StatelessWidget {
  final PedidoVendedor pedido;
  final bool esOscuro;
  final VoidCallback alVerDetalle;
  final VoidCallback alVerEnMapa;
  final ValueChanged<String> alCambiarEstado;

  const _AccionesFila({
    required this.pedido,
    required this.esOscuro,
    required this.alVerDetalle,
    required this.alVerEnMapa,
    required this.alCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BotonIcono(
          icono: Icons.visibility_outlined,
          tooltip: tr(context, 'vendedor_operaciones.ver_detalle'),
          onTap: alVerDetalle,
          esOscuro: esOscuro,
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          tooltip: tr(context, 'vendedor_operaciones.mas_acciones'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (v) {
            if (v == 'mapa') {
              alVerEnMapa();
            } else {
              alCambiarEstado(v);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'mapa',
              child: Row(
                children: [
                  const Icon(
                    Icons.map_outlined,
                    size: 16,
                    color: CraftHubColors.vinoTinto,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    tr(context, 'vendedor_operaciones.ver_en_el_mapa'),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            ...EstadoPedido.todos
                .where((e) => e != pedido.estado)
                .map(
                  (e) => PopupMenuItem(
                    value: e,
                    child: Row(
                      children: [
                        Icon(
                          iconoEstadoPedido(e),
                          size: 16,
                          color: colorEstadoPedido(e),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${tr(context, 'vendedor_operaciones.marcar_como')} ${EstadoPedido.etiqueta(e)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          child: _BotonIcono(
            icono: Icons.more_vert_rounded,
            tooltip: tr(context, 'vendedor_operaciones.mas_acciones'),
            onTap: null,
            esOscuro: esOscuro,
          ),
        ),
      ],
    );
  }
}

class _BotonIcono extends StatefulWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback? onTap;
  final bool esOscuro;
  const _BotonIcono({
    required this.icono,
    required this.tooltip,
    required this.onTap,
    required this.esOscuro,
  });

  @override
  State<_BotonIcono> createState() => _BotonIconoState();
}

class _BotonIconoState extends State<_BotonIcono> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _sobre
                  ? CraftHubColors.vinoTintoSuave
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icono,
              size: 17,
              color: _sobre
                  ? CraftHubColors.vinoTinto
                  : CraftHubColors.textoSecundario(widget.esOscuro),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TARJETA COMPACTA (móvil / pantallas angostas)
// ─────────────────────────────────────────────────────────────
class _TarjetaOrdenCompacta extends StatelessWidget {
  final PedidoVendedor pedido;
  final bool esOscuro;
  final bool actualizando;
  final ValueChanged<String> alCambiarEstado;
  final VoidCallback alVerEnMapa;
  final VoidCallback alVerDetalle;

  const _TarjetaOrdenCompacta({
    required this.pedido,
    required this.esOscuro,
    required this.actualizando,
    required this.alCambiarEstado,
    required this.alVerEnMapa,
    required this.alVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(esOscuro),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CraftHubColors.borde(esOscuro)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AvatarIniciales(nombre: pedido.clienteNombre),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pedido.clienteNombre,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: colorTexto,
                      ),
                    ),
                    Text(
                      pedido.orden,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        color: colorSec,
                      ),
                    ),
                  ],
                ),
              ),
              _ChipEstado(
                pedido: pedido,
                actualizando: actualizando,
                alCambiarEstado: alCambiarEstado,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _UbicacionTappable(
            texto: pedido.ubicacion,
            esOscuro: esOscuro,
            onTap: alVerEnMapa,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniaturasProductos(
                productos: pedido.productos,
                esOscuro: esOscuro,
                tamano: 36,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${pedido.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorTexto,
                    ),
                  ),
                  Text(
                    _formatoFechaCorta(pedido.fecha),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: colorSec,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: alVerDetalle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CraftHubColors.vinoTinto),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: CraftHubColors.vinoTinto,
                  ),
                  label: Text(
                    tr(context, 'vendedor_operaciones.ver_detalle'),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      color: CraftHubColors.vinoTinto,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: alVerEnMapa,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CraftHubColors.vinoTinto,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(
                    Icons.map_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    tr(context, 'vendedor_operaciones.mapa'),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DIÁLOGO DE DETALLE DE PEDIDO
// ─────────────────────────────────────────────────────────────
class _DialogoDetallePedido extends StatelessWidget {
  final PedidoVendedor pedido;
  final bool esOscuro;
  final ValueChanged<String> alCambiarEstado;
  final VoidCallback alVerEnMapa;
  final VoidCallback? alChatear;

  const _DialogoDetallePedido({
    required this.pedido,
    required this.esOscuro,
    required this.alCambiarEstado,
    required this.alVerEnMapa,
    this.alChatear,
  });

  @override
  Widget build(BuildContext context) {
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);

    return Dialog(
      backgroundColor: CraftHubColors.panel(esOscuro),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pedido.orden,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorTexto,
                      ),
                    ),
                  ),
                  _ChipEstado(
                    pedido: pedido,
                    actualizando: false,
                    alCambiarEstado: alCambiarEstado,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatoFecha(pedido.fecha),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: colorSec,
                ),
              ),
              const Divider(height: 24),

              Row(
                children: [
                  _AvatarIniciales(nombre: pedido.clienteNombre),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pedido.clienteNombre,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorTexto,
                          ),
                        ),
                        GestureDetector(
                          onTap: alVerEnMapa,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: CraftHubColors.vinoTinto,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                pedido.ubicacion,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: CraftHubColors.vinoTinto,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (alChatear != null)
                    _BotonIcono(
                      icono: Icons.forum_outlined,
                      tooltip: tr(context, 'vendedor_operaciones.chatear_con_cliente'),
                      onTap: alChatear,
                      esOscuro: esOscuro,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                tr(context, 'vendedor_operaciones.productos'),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colorSec,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pedido.productos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final item = pedido.productos[i];
                    return Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.imagenUrl.isNotEmpty
                              ? Image.network(
                                  item.imagenUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 40,
                                    height: 40,
                                    color: CraftHubColors.borde(esOscuro),
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  color: CraftHubColors.borde(esOscuro),
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 18,
                                    color: colorSec,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.nombre,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: colorTexto,
                            ),
                          ),
                        ),
                        Text(
                          'x${item.cantidad}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            color: colorSec,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr(context, 'vendedor_operaciones.total'),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorTexto,
                    ),
                  ),
                  Text(
                    '\$${pedido.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: CraftHubColors.vinoTinto,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CraftHubColors.vinoTinto,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    tr(context, 'vendedor_operaciones.cerrar'),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
