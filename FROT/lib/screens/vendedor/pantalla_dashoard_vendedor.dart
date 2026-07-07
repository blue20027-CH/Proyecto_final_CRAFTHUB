// lib/screens/vendedor/home_vendedor.dart

import 'package:abi_frotend_nd/screens/vendedor/pantalla_inventario.dart';
import 'package:abi_frotend_nd/screens/vendedor/pantalla_tutoriales.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/carrito_provider.dart';
import '../../core/favoritos_provider.dart';
import '../../widgets/vendedor/sidebar_vendedor.dart';
import '../../widgets/vendedor/tarjeta_producto_ranking.dart';
import '../../widgets/vendedor/grafico_ingresos.dart';
import '../../widgets/vendedor/grafico_evaluaciones.dart';
import '../../widgets/vendedor/resumen_rapido.dart';
import '../../services/vendedor_api_service.dart';
import '../../services/api_service.dart';
import '../../widgets/topbar_flotante.dart';
import '../auth/inicio_screen.dart';
import 'pantalla_eventos_vendedor.dart';
import 'pantalla_mensajes_vendedor.dart';

class HomeVendedor extends StatefulWidget {
  final bool esOscuro;
  final String nombreVendedor;
  final String fotoPerfil;
  final String userId;

  const HomeVendedor({
    super.key,
    required this.esOscuro,
    this.nombreVendedor = 'Vendedor',
    this.fotoPerfil = '',
    this.userId = '',
  });

  @override
  State<HomeVendedor> createState() => _HomeVendedorState();
}

class _HomeVendedorState extends State<HomeVendedor> {
  int _navIndice = 0;
  final TextEditingController _busquedaCtrl = TextEditingController();
  bool _tieneAnuncioSinLeer = false;
  bool _tieneNotificacionSinLeer = false;

  @override
  void initState() {
    super.initState();
    _revisarAnuncios();
    _revisarNotificaciones();
  }

  Future<void> _revisarNotificaciones() async {
    if (widget.userId.isEmpty) return;
    try {
      final data = await ApiService.getNotificacionesUsuario(widget.userId);
      if (!mounted) return;
      setState(() => _tieneNotificacionSinLeer = (data['no_leidas'] ?? 0) > 0);
    } catch (e) {
      debugPrint('Error revisando notificaciones: $e');
    }
  }

  void _mostrarNotificaciones() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('Notificaciones',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                            fontWeight: FontWeight.w700, color: CraftHubColors.textoClaro)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Flexible(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: ApiService.getNotificacionesUsuario(widget.userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto)),
                        );
                      }
                      final notifs = (snapshot.data?['notificaciones'] as List<dynamic>? ?? []);
                      if (notifs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text('No tienes notificaciones todavía.',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: CraftHubColors.textoSecClaro)),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: notifs.length,
                        separatorBuilder: (_, _) => const Divider(color: CraftHubColors.bordeClaro, height: 16),
                        itemBuilder: (_, i) {
                          final n = notifs[i] as Map<String, dynamic>;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text((n['titulo'] ?? 'CraftHub').toString(),
                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: CraftHubColors.textoClaro)),
                              const SizedBox(height: 3),
                              Text((n['mensaje'] ?? '').toString(),
                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: CraftHubColors.textoSecClaro)),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    setState(() => _tieneNotificacionSinLeer = false);
    ApiService.marcarNotificacionesLeidas(widget.userId);
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _revisarAnuncios() async {
    if (widget.userId.isEmpty) return;
    try {
      final data = await ApiService.getAnuncios(widget.userId);
      if (!mounted) return;
      setState(() => _tieneAnuncioSinLeer = (data['no_leidos'] ?? 0) > 0);
    } catch (e) {
      debugPrint('Error revisando anuncios: $e');
    }
  }

  void _abrirMensajes() {
    setState(() {
      _navIndice = 3;
      _tieneAnuncioSinLeer = false;
    });
    if (widget.userId.isNotEmpty) {
      ApiService.marcarAnunciosLeidos(widget.userId);
    }
  }

  void _cerrarSesion(BuildContext context) {
    // 🔌 POST /api/auth/logout (invalidar token en el backend cuando exista)
    context.read<CarritoProvider>().cerrarSesion();
    context.read<FavoritosProvider>().cerrarSesion();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PantallaInicio()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = esModoOscuro ? CraftHubColors.fondoOscuro : CraftHubColors.fondoClaro;

    return Scaffold(
      backgroundColor: colorFondo,
      body: Row(
        children: [
          SidebarVendedor(
            nombre: widget.nombreVendedor,
            fotoUrl: widget.fotoPerfil,
            indiceActivo: _navIndice,
            alSeleccionar: (i) => i == 3 ? _abrirMensajes() : setState(() => _navIndice = i),
            alCerrarSesion: () => _cerrarSesion(context),
            tieneNotificacionMensajes: _tieneAnuncioSinLeer,
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(esModoOscuro),
                Expanded(
                  child: _obtenerPantallaActual(_navIndice, esModoOscuro),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _obtenerPantallaActual(int indice, bool oscuro) {
    switch (indice) {
      case 0:
        return _ContenidoDashboard(
          esOscuro: oscuro,
          nombreVendedor: widget.nombreVendedor,
          alVerProductos: () => setState(() => _navIndice = 1),
        );
      case 1:
        return PantallaInventario(nombreVendedor: widget.nombreVendedor);
      case 2:
        return PantallaTutoriales(userId: widget.userId);
      case 3:
        return PantallaMensajesVendedor(userId: widget.userId);
      default:
        return _ContenidoDashboard(
          esOscuro: oscuro,
          nombreVendedor: widget.nombreVendedor,
          alVerProductos: () => setState(() => _navIndice = 1),
        );
    }
  }

  Widget _buildTopBar(bool oscuro) {
    return TopbarFlotante(
      controladorBusqueda: _busquedaCtrl,
      tieneNotificaciones: _tieneNotificacionSinLeer,
      alPresionarNotificaciones: widget.userId.isEmpty ? null : _mostrarNotificaciones,
      alPresionarLogo: () => setState(() => _navIndice = 0),
      alPresionarEventos: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaEventosVendedor(
            userId: widget.userId,
            nombreVendedor: widget.nombreVendedor,
          ),
        ),
      ),
      itemsExplorar: [
        ItemExplorar(icono: Icons.dashboard_outlined, etiqueta: 'Dashboard',
            onTap: () => setState(() => _navIndice = 0)),
        ItemExplorar(icono: Icons.inventory_2_outlined, etiqueta: 'Productos',
            onTap: () => setState(() => _navIndice = 1)),
        ItemExplorar(icono: Icons.video_library_outlined, etiqueta: 'Tutoriales',
            onTap: () => setState(() => _navIndice = 2)),
        ItemExplorar(icono: Icons.forum_outlined, etiqueta: 'Mensajes',
            onTap: _abrirMensajes),
      ],
    );
  }
}

// ── CONTENIDO DASHBOARD ──────────────────────────────────────────────────────

class _ContenidoDashboard extends StatefulWidget {
  final bool esOscuro;
  final String nombreVendedor;
  final VoidCallback alVerProductos;

  const _ContenidoDashboard({
    required this.esOscuro,
    required this.nombreVendedor,
    required this.alVerProductos,
  });

  @override
  State<_ContenidoDashboard> createState() => _ContenidoDashboardState();
}

class _ContenidoDashboardState extends State<_ContenidoDashboard> {
  String _periodoSeleccionado = 'Últimos 6 meses';
  DatosDashboardVendedor? _datos;
  bool _cargando = true;
  String? _error;
  final List<String> _periodos = [
    'Últimos 30 días',
    'Últimos 3 meses',
    'Últimos 6 meses',
    'Este año',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDashboard();
  }

  @override
  void didUpdateWidget(covariant _ContenidoDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nombreVendedor != widget.nombreVendedor) {
      _cargarDashboard();
    }
  }

  Future<void> _cargarDashboard() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final datos = await VendedorApiService.cargarDashboard(widget.nombreVendedor);
      if (mounted) setState(() => _datos = datos);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto));
    }
    if (_error != null) {
      return Center(child: Text('No se pudo cargar el dashboard: $_error',
          style: const TextStyle(color: CraftHubColors.error)));
    }
    final datos = _datos;
    if (datos == null) {
      return const Center(child: Text('No hay datos del vendedor.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderDashboard(
            nombreVendedor: datos.nombreVendedor,
            periodoSeleccionado: _periodoSeleccionado,
            periodos: _periodos,
            alCambiarPeriodo: (p) => setState(() => _periodoSeleccionado = p!),
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: _PanelIngresos(datos: datos)),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: _PanelEvaluaciones(datos: datos)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 6,
                  child: _PanelTopProductos(
                    datos: datos,
                    alVerTodos: widget.alVerProductos,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: _PanelStatsClientes(datos: datos)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ResumenRapido(
            pedidosTotales: datos.pedidosTotales,
            pendientesEnviar: datos.pendientesEnviar,
            productosActivos: datos.productosActivos,
            visitasTienda: datos.visitasTienda,
            alVerPedidos: () {},
            alVerProductos: widget.alVerProductos,
          ),
        ],
      ),
    );
  }
}

// ── HEADER ───────────────────────────────────────────────────────────────────

class _HeaderDashboard extends StatelessWidget {
  final String nombreVendedor;
  final String periodoSeleccionado;
  final List<String> periodos;
  final ValueChanged<String?> alCambiarPeriodo;

  const _HeaderDashboard({
    required this.nombreVendedor,
    required this.periodoSeleccionado,
    required this.periodos,
    required this.alCambiarPeriodo,
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
              Text('Bienvenida, $nombreVendedor',
                style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 28,
                  fontWeight: FontWeight.w700, color: CraftHubColors.textoClaro)),
              const Text('Aquí tienes un resumen de tu actividad y rendimiento.',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: CraftHubColors.textoSecClaro)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: CraftHubColors.panelClaro,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CraftHubColors.bordeClaro, width: 1.2),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 15, color: CraftHubColors.vinoTinto),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: periodoSeleccionado,
                  isDense: true,
                  dropdownColor: CraftHubColors.panelClaro,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
                      fontWeight: FontWeight.w500, color: CraftHubColors.textoClaro),
                  items: periodos.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: alCambiarPeriodo,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── PANEL INGRESOS ────────────────────────────────────────────────────────────

class _PanelIngresos extends StatelessWidget {
  final DatosDashboardVendedor datos;
  const _PanelIngresos({required this.datos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _decorPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Ingresos totales',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                  fontWeight: FontWeight.w600, color: CraftHubColors.textoSecClaro)),
            const SizedBox(width: 6),
            const Tooltip(
              message: 'Suma de todos tus ingresos en el período seleccionado',
              child: Icon(Icons.info_outline_rounded, size: 14, color: CraftHubColors.textoSecClaro),
            ),
          ]),
          const SizedBox(height: 4),
          Text('\$${datos.ingresosTotal.toStringAsFixed(2)}',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 32,
                fontWeight: FontWeight.w700, color: CraftHubColors.textoClaro)),
          Row(children: [
            const Icon(Icons.arrow_upward_rounded, size: 13, color: Color(0xFF2E7D32)),
            const SizedBox(width: 3),
            Text('${datos.variacionIngresos}% vs. periodo anterior',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                  fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: GraficoIngresos(valores: datos.ingresoesMensuales, etiquetas: datos.etiquetasMeses),
          ),
        ],
      ),
    );
  }
}

void _mostrarOpiniones(BuildContext context, String nombreVendedor) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Opiniones de tus clientes',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                          fontWeight: FontWeight.w700, color: CraftHubColors.textoClaro)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: FutureBuilder<List<OpinionVendedor>>(
                  future: VendedorApiService.cargarOpiniones(nombreVendedor),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto)),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text('No se pudieron cargar las opiniones: ${snapshot.error}',
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: CraftHubColors.error)),
                      );
                    }
                    final opiniones = snapshot.data ?? [];
                    if (opiniones.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text('Aún no tienes opiniones de clientes.',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: CraftHubColors.textoSecClaro)),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: opiniones.length,
                      separatorBuilder: (_, _) => const Divider(color: CraftHubColors.bordeClaro, height: 20),
                      itemBuilder: (_, i) => _FilaOpinion(opinion: opiniones[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FilaOpinion extends StatelessWidget {
  final OpinionVendedor opinion;
  const _FilaOpinion({required this.opinion});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: CraftHubColors.vinoTintoSuave,
              backgroundImage: opinion.avatarUrl.isNotEmpty ? NetworkImage(opinion.avatarUrl) : null,
              child: opinion.avatarUrl.isEmpty
                  ? Text(opinion.nombre.isNotEmpty ? opinion.nombre[0].toUpperCase() : '?',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: CraftHubColors.vinoTinto))
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(opinion.nombre,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: CraftHubColors.textoClaro)),
            ),
            if (opinion.calificacion != null) ...[
              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD4A843)),
              const SizedBox(width: 2),
              Text(opinion.calificacion!.toStringAsFixed(1),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: CraftHubColors.textoClaro)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text('Sobre "${opinion.producto}"',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: CraftHubColors.textoSecClaro)),
        const SizedBox(height: 4),
        Text(opinion.comentario,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: CraftHubColors.textoClaro, height: 1.4)),
      ],
    );
  }
}

// ── PANEL EVALUACIONES ────────────────────────────────────────────────────────

class _PanelEvaluaciones extends StatelessWidget {
  final DatosDashboardVendedor datos;
  const _PanelEvaluaciones({required this.datos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _decorPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.star_outline_rounded, size: 18, color: Color(0xFFD4A843)),
            const SizedBox(width: 8),
            const Text('Evaluaciones de clientes',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                  fontWeight: FontWeight.w600, color: CraftHubColors.textoClaro)),
            const Spacer(),
            _BotonTexto(
              texto: 'Ver opiniones',
              alPresionar: () => _mostrarOpiniones(context, datos.nombreVendedor),
            ),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: GraficoEvaluaciones(
              distribucion: datos.distribucionEvaluaciones,
              promedio: datos.promedioEvaluacion,
              total: datos.totalEvaluaciones,
            ),
          ),
        ],
      ),
    );
  }
}

// ── PANEL TOP PRODUCTOS ───────────────────────────────────────────────────────

class _PanelTopProductos extends StatelessWidget {
  final DatosDashboardVendedor datos;
  final VoidCallback alVerTodos;

  const _PanelTopProductos({
    required this.datos,
    required this.alVerTodos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _decorPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: CraftHubColors.vinoTintoSuave,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.emoji_events_outlined, size: 16, color: CraftHubColors.vinoTinto),
            ),
            const SizedBox(width: 10),
            const Text('Top 5 productos más vendidos',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                  fontWeight: FontWeight.w700, color: CraftHubColors.textoClaro)),
            const Spacer(),
            _BotonTexto(texto: 'Ver todos', alPresionar: alVerTodos),
          ]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: const [
              SizedBox(width: 34),
              Expanded(child: Text('Producto',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                    fontWeight: FontWeight.w600, color: CraftHubColors.textoSecClaro))),
              SizedBox(width: 50, child: Text('Ventas', textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                    fontWeight: FontWeight.w600, color: CraftHubColors.textoSecClaro))),
              SizedBox(width: 80, child: Text('Ingresos', textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                    fontWeight: FontWeight.w600, color: CraftHubColors.textoSecClaro))),
            ]),
          ),
          const Divider(color: CraftHubColors.bordeClaro, height: 1),
          ...datos.topProductos.map((p) => TarjetaProductoRanking(producto: p)),
        ],
      ),
    );
  }
}

// ── PANEL STATS CLIENTES ──────────────────────────────────────────────────────

class _PanelStatsClientes extends StatelessWidget {
  final DatosDashboardVendedor datos;
  const _PanelStatsClientes({required this.datos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _decorPanel(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatCliente(icono: Icons.sentiment_satisfied_alt_outlined,
            titulo: 'Clientes felices', valor: '${datos.clientesFelices}',
            positivo: true),
          const Divider(color: CraftHubColors.bordeClaro, height: 1),
          _StatCliente(icono: Icons.chat_bubble_outline_rounded,
            titulo: 'Nuevas opiniones', valor: '${datos.nuevasOpiniones}',
            subtitulo: 'Últimos 30 días', positivo: true),
          const Divider(color: CraftHubColors.bordeClaro, height: 1),
          _StatCliente(icono: Icons.check_circle_outline_rounded,
            titulo: 'Pedidos completados',
            valor: '${datos.pedidosTotales - datos.pendientesEnviar}',
            subtitulo: '${datos.pendientesEnviar} pendientes por enviar',
            positivo: true),
        ],
      ),
    );
  }
}

class _StatCliente extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final String? variacion;
  final String? subtitulo;
  final bool positivo;

  const _StatCliente({
    required this.icono, required this.titulo, required this.valor,
    this.variacion, this.subtitulo, required this.positivo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: CraftHubColors.vinoTintoSuave,
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icono, size: 18, color: CraftHubColors.vinoTinto),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11,
              color: CraftHubColors.textoSecClaro)),
          Row(children: [
            Text(valor, style: const TextStyle(fontFamily: 'Poppins', fontSize: 20,
                fontWeight: FontWeight.w700, color: CraftHubColors.textoClaro)),
            if (variacion != null) ...[
              const SizedBox(width: 6),
              Text(variacion!, style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: positivo ? const Color(0xFF2E7D32) : CraftHubColors.error)),
            ],
          ]),
          if (subtitulo != null)
            Text(subtitulo!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
                color: CraftHubColors.textoSecClaro)),
        ])),
      ]),
    );
  }
}

// ── BOTÓN TEXTO ───────────────────────────────────────────────────────────────

class _BotonTexto extends StatefulWidget {
  final String texto;
  final VoidCallback alPresionar;
  const _BotonTexto({required this.texto, required this.alPresionar});

  @override
  State<_BotonTexto> createState() => _BotonTextoState();
}

class _BotonTextoState extends State<_BotonTexto> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _sobre ? CraftHubColors.vinoTintoSuave : CraftHubColors.fondoClaro,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CraftHubColors.bordeClaro, width: 1),
          ),
          child: Text(widget.texto,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                fontWeight: FontWeight.w600, color: CraftHubColors.textoClaro)),
        ),
      ),
    );
  }
}

// ── DECORACIÓN PANEL ──────────────────────────────────────────────────────────

BoxDecoration _decorPanel() => BoxDecoration(
  color: CraftHubColors.panelClaro,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: CraftHubColors.bordeClaro),
  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
);

