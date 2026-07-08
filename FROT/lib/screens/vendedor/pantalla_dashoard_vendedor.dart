// lib/screens/vendedor/home_vendedor.dart

import 'package:abi_frotend_nd/screens/vendedor/pantalla_inventario.dart';
import 'package:abi_frotend_nd/screens/vendedor/pantalla_tutoriales.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/carrito_provider.dart';
import '../../core/favoritos_provider.dart';
import '../../widgets/vendedor/sidebar_vendedor.dart';
import '../../widgets/vendedor/tarjeta_producto_ranking.dart';
import '../../widgets/vendedor/grafico_ingresos.dart';
import '../../widgets/vendedor/grafico_evaluaciones.dart';
import '../../services/vendedor_api_service.dart';
import '../../services/api_service.dart';
import '../../widgets/topbar_flotante.dart';
import '../auth/inicio_screen.dart';
import '../pantalla_editar_perfil.dart';
import '../comprador/pantalla_perfil_artesano.dart';
import '../../models/artesano_modelo.dart' show bannerPorCategoria;
import 'pantalla_eventos_vendedor.dart';
import 'pantalla_mensajes_vendedor.dart';
import 'pantalla_ordenes_vendedor.dart';
import 'pantalla_mapa_vendedor.dart';

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
  String? _pedidoResaltadoMapa;
  final TextEditingController _busquedaCtrl = TextEditingController();
  bool _tieneAnuncioSinLeer = false;
  bool _tieneNotificacionSinLeer = false;
  late String _fotoPerfilActual;
  String _genero = '';

  @override
  void initState() {
    super.initState();
    _fotoPerfilActual = widget.fotoPerfil;
    _revisarAnuncios();
    _revisarNotificaciones();
    _cargarGenero();
  }

  Future<void> _cargarGenero() async {
    if (widget.userId.isEmpty) return;
    try {
      final perfil = await ApiService.getPerfil(widget.userId);
      if (mounted) setState(() => _genero = (perfil['genero'] ?? '').toString());
    } catch (e) {
      debugPrint('Error cargando género del perfil: $e');
    }
  }

  // Editar perfil directo (llamado desde el botón "Editar perfil" al ver tu
  // propio perfil). Al volver, refresca la foto que se ve en el sidebar.
  Future<void> _editarPerfil() async {
    if (widget.userId.isEmpty) return;
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PantallaEditarPerfil(userId: widget.userId)),
    );
    if (actualizado != true) return;
    try {
      final perfil = await ApiService.getPerfil(widget.userId);
      if (mounted) setState(() => _fotoPerfilActual = (perfil['foto'] ?? '').toString());
    } catch (e) {
      debugPrint('Error refrescando foto de perfil: $e');
    }
  }

  // Tocar tu avatar en el sidebar te lleva a VER tu perfil, exactamente
  // igual a como lo ve cualquier comprador, con un botón de "Editar perfil".
  Future<void> _verMiPerfil() async {
    if (widget.userId.isEmpty || widget.nombreVendedor.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto)),
    );

    Map<String, dynamic> detalle = {};
    try {
      detalle = await ApiService.getDetalleArtesano(widget.nombreVendedor);
    } catch (e) {
      debugPrint('Error cargando mi perfil: $e');
    }

    if (!mounted) return;
    Navigator.pop(context);

    final productos = ((detalle['productos'] as List<dynamic>?) ?? [])
        .map((p) => ModeloProductoResumen.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
    final rating = double.tryParse((detalle['rating'] ?? 0).toString()) ?? 0;
    final totalResenas = int.tryParse((detalle['total_resenas'] ?? 0).toString()) ?? 0;
    final categoriaArtesano = (detalle['categoria'] ?? '').toString();
    final fotoPortada = (detalle['foto_portada'] ?? '').toString();

    final artesano = ModeloArtesano(
      nombre: widget.nombreVendedor,
      specialty: (detalle['especialidad'] ?? '').toString(),
      especialidad: (detalle['especialidad'] ?? '').toString(),
      ubicacion: (detalle['ubicacion'] ?? '').toString(),
      fotoUrl: (detalle['foto_url'] ?? _fotoPerfilActual).toString(),
      bannerUrl: fotoPortada.isNotEmpty ? fotoPortada : bannerPorCategoria(categoriaArtesano),
      calificacion: rating,
      totalResenas: totalResenas,
      verificado: true,
      totalProductos: productos.length,
      anosEnCraftHub: 1,
      valoracionesPositivas: (rating / 5 * 100).round(),
      ventasRealizadas: productos.length,
      descripcion: (detalle['descripcion'] ?? '').toString(),
      etiquetas: ((detalle['categorias'] as List<dynamic>?) ?? []).map((e) => e.toString()).toList(),
      colecciones: productos.map((p) => p.coleccion).toSet().toList(),
      productos: productos,
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaPerfilArtesano(
          artesano: artesano,
          esPropio: true,
          onEditar: _editarPerfil,
        ),
      ),
    );
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
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);
    final colorBorde = CraftHubColors.borde(esOscuro);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: CraftHubColors.panel(esOscuro),
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
                    Text('Notificaciones',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                            fontWeight: FontWeight.w700, color: colorTexto)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: colorTexto),
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text('No tienes notificaciones todavía.',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: colorSec)),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: notifs.length,
                        separatorBuilder: (_, _) => Divider(color: colorBorde, height: 16),
                        itemBuilder: (_, i) {
                          final n = notifs[i] as Map<String, dynamic>;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text((n['titulo'] ?? 'CraftHub').toString(),
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: colorTexto)),
                              const SizedBox(height: 3),
                              Text((n['mensaje'] ?? '').toString(),
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: colorSec)),
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
            fotoUrl: _fotoPerfilActual,
            indiceActivo: _navIndice,
            alSeleccionar: (i) => i == 3 ? _abrirMensajes() : setState(() => _navIndice = i),
            alCerrarSesion: () => _cerrarSesion(context),
            alTocarAvatar: _verMiPerfil,
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

  // Índices: 0=Dashboard, 1=Productos, 2=Tutoriales, 3=Mensajes,
  // 4=Pedidos, 5=Mapa (mismo orden que SidebarVendedor._items).
  Widget _obtenerPantallaActual(int indice, bool oscuro) {
    switch (indice) {
      case 0:
        return _ContenidoDashboard(
          esOscuro: oscuro,
          nombreVendedor: widget.nombreVendedor,
          genero: _genero,
          alVerProductos: () => setState(() => _navIndice = 1),
          alVerPedidos: () => setState(() => _navIndice = 4),
        );
      case 1:
        return PantallaInventario(nombreVendedor: widget.nombreVendedor);
      case 2:
        return PantallaTutoriales(userId: widget.userId);
      case 3:
        return PantallaMensajesVendedor(userId: widget.userId);
      case 4:
        return PantallaOrdenesVendedor(
          esOscuro: oscuro,
          nombreVendedor: widget.nombreVendedor,
          alVerEnMapa: (idPedido) => setState(() {
            _pedidoResaltadoMapa = idPedido;
            _navIndice = 5;
          }),
        );
      case 5:
        return PantallaMapaVendedor(
          esOscuro: oscuro,
          nombreVendedor: widget.nombreVendedor,
          pedidoResaltado: _pedidoResaltadoMapa,
        );
      default:
        return _ContenidoDashboard(
          esOscuro: oscuro,
          nombreVendedor: widget.nombreVendedor,
          genero: _genero,
          alVerProductos: () => setState(() => _navIndice = 1),
          alVerPedidos: () => setState(() => _navIndice = 4),
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
        ItemExplorar(icono: Icons.receipt_long_outlined, etiqueta: 'Pedidos',
            onTap: () => setState(() => _navIndice = 4)),
        ItemExplorar(icono: Icons.map_outlined, etiqueta: 'Mapa de pedidos',
            onTap: () => setState(() => _navIndice = 5)),
      ],
    );
  }
}

// ── CONTENIDO DASHBOARD ──────────────────────────────────────────────────────

class _ContenidoDashboard extends StatefulWidget {
  final bool esOscuro;
  final String nombreVendedor;
  final String genero;
  final VoidCallback alVerProductos;
  final VoidCallback? alVerPedidos;

  const _ContenidoDashboard({
    required this.esOscuro,
    required this.nombreVendedor,
    required this.genero,
    required this.alVerProductos,
    this.alVerPedidos,
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

    final esOscuro = widget.esOscuro;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroDashboard(
            datos: datos,
            genero: widget.genero,
            periodoSeleccionado: _periodoSeleccionado,
            periodos: _periodos,
            alCambiarPeriodo: (p) => setState(() => _periodoSeleccionado = p!),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.06, end: 0, duration: 350.ms),

          const SizedBox(height: 20),

          _FilaKpis(esOscuro: esOscuro, datos: datos, alVerPedidos: widget.alVerPedidos, alVerProductos: widget.alVerProductos),

          const SizedBox(height: 20),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: _PanelIngresos(datos: datos, esOscuro: esOscuro)),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: _PanelEvaluaciones(datos: datos, esOscuro: esOscuro)),
              ],
            ),
          ).animate().fadeIn(delay: 120.ms, duration: 350.ms).slideY(begin: 0.04, end: 0, duration: 350.ms),

          const SizedBox(height: 16),

          _PanelTopProductos(
            datos: datos,
            esOscuro: esOscuro,
            alVerTodos: widget.alVerProductos,
          ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.04, end: 0, duration: 350.ms),
        ],
      ),
    );
  }
}

// ── HÉROE DEL DASHBOARD ───────────────────────────────────────────────────────

// Saludo neutral por defecto: solo usa la forma con género cuando el
// vendedor lo indicó explícitamente en su perfil.
String _saludoPorGenero(String genero) {
  switch (genero.toLowerCase()) {
    case 'masculino':
      return 'Bienvenido';
    case 'femenino':
      return 'Bienvenida';
    default:
      return 'Bienvenido/a';
  }
}

class _HeroDashboard extends StatelessWidget {
  final DatosDashboardVendedor datos;
  final String genero;
  final String periodoSeleccionado;
  final List<String> periodos;
  final ValueChanged<String?> alCambiarPeriodo;

  const _HeroDashboard({
    required this.datos,
    required this.genero,
    required this.periodoSeleccionado,
    required this.periodos,
    required this.alCambiarPeriodo,
  });

  @override
  Widget build(BuildContext context) {
    final positivo = datos.variacionIngresos >= 0;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CraftHubColors.vinoTintoOscuro, CraftHubColors.vinoTinto, CraftHubColors.vinoTintoClaro],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: CraftHubColors.vinoTinto.withValues(alpha: 0.30), blurRadius: 28, offset: const Offset(0, 14)),
        ],
      ),
      child: Stack(
        children: [
          // Círculos decorativos difuminados — le dan el toque "futurista".
          Positioned(top: -46, right: -30, child: _BlurDecorativo(tamano: 170, opacidad: 0.10)),
          Positioned(bottom: -60, left: 90, child: _BlurDecorativo(tamano: 150, opacidad: 0.08)),
          Positioned(top: 30, right: 160, child: _BlurDecorativo(tamano: 60, opacidad: 0.07)),

          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_saludoPorGenero(genero)}, ${datos.nombreVendedor}',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 24,
                                  fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Aquí tienes el pulso de tu tienda en tiempo real.',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5,
                                  color: Colors.white.withValues(alpha: 0.75))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _SelectorPeriodo(
                      periodoSeleccionado: periodoSeleccionado,
                      periodos: periodos,
                      alCambiar: alCambiarPeriodo,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                LayoutBuilder(builder: (context, constraints) {
                  final compacto = constraints.maxWidth < 520;
                  final ingresos = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('INGRESOS TOTALES',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                              fontWeight: FontWeight.w700, letterSpacing: 0.8,
                              color: Colors.white.withValues(alpha: 0.65))),
                      const SizedBox(height: 4),
                      Text('\$${datos.ingresosTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 38,
                              fontWeight: FontWeight.w800, color: Colors.white, height: 1.0)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(positivo ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('${datos.variacionIngresos}% vs. período anterior',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11,
                                  fontWeight: FontWeight.w600, color: Colors.white)),
                        ]),
                      ),
                    ],
                  );

                  final miniStats = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MiniStatHero(icono: Icons.receipt_long_rounded, valor: '${datos.pedidosTotales}', etiqueta: 'Pedidos'),
                      Container(width: 1, height: 46, margin: const EdgeInsets.symmetric(horizontal: 22),
                          color: Colors.white.withValues(alpha: 0.18)),
                      _MiniStatHero(icono: Icons.star_rounded, valor: datos.promedioEvaluacion.toStringAsFixed(1), etiqueta: 'Calificación'),
                    ],
                  );

                  if (compacto) {
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ingresos,
                      const SizedBox(height: 24),
                      miniStats,
                    ]);
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ingresos,
                      const Spacer(),
                      miniStats,
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurDecorativo extends StatelessWidget {
  final double tamano;
  final double opacidad;
  const _BlurDecorativo({required this.tamano, required this.opacidad});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacidad)),
      ),
    );
  }
}

class _MiniStatHero extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  const _MiniStatHero({required this.icono, required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, color: Colors.white.withValues(alpha: 0.85), size: 17),
        const SizedBox(height: 6),
        Text(valor, style: const TextStyle(fontFamily: 'Poppins', fontSize: 21, fontWeight: FontWeight.w700, color: Colors.white)),
        Text(etiqueta, style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: Colors.white.withValues(alpha: 0.7))),
      ],
    );
  }
}

class _SelectorPeriodo extends StatelessWidget {
  final String periodoSeleccionado;
  final List<String> periodos;
  final ValueChanged<String?> alCambiar;

  const _SelectorPeriodo({required this.periodoSeleccionado, required this.periodos, required this.alCambiar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.white),
        const SizedBox(width: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: periodoSeleccionado,
            isDense: true,
            dropdownColor: CraftHubColors.vinoTintoOscuro,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
            items: periodos.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: alCambiar,
          ),
        ),
      ]),
    );
  }
}

// ── TARJETAS KPI ───────────────────────────────────────────────────────────────

class _FilaKpis extends StatelessWidget {
  final bool esOscuro;
  final DatosDashboardVendedor datos;
  final VoidCallback? alVerPedidos;
  final VoidCallback alVerProductos;

  const _FilaKpis({
    required this.esOscuro,
    required this.datos,
    required this.alVerPedidos,
    required this.alVerProductos,
  });

  static String _formatoMiles(int valor) =>
      valor.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final tarjetas = [
      _TarjetaKpi(
        esOscuro: esOscuro,
        icono: Icons.local_shipping_outlined,
        color: CraftHubColors.info,
        titulo: 'Pendientes por enviar',
        valor: '${datos.pendientesEnviar}',
        enlaceTexto: alVerPedidos != null ? 'Ver pedidos' : null,
        alPresionarEnlace: alVerPedidos,
      ),
      _TarjetaKpi(
        esOscuro: esOscuro,
        icono: Icons.inventory_2_outlined,
        color: CraftHubColors.exito,
        titulo: 'Productos activos',
        valor: '${datos.productosActivos}',
        enlaceTexto: 'Ver productos',
        alPresionarEnlace: alVerProductos,
      ),
      _TarjetaKpi(
        esOscuro: esOscuro,
        icono: Icons.sentiment_satisfied_alt_outlined,
        color: const Color(0xFFB8860B),
        titulo: 'Clientes felices',
        valor: '${datos.clientesFelices}',
      ),
      _TarjetaKpi(
        esOscuro: esOscuro,
        icono: Icons.storefront_outlined,
        color: CraftHubColors.vinoTintoClaro,
        titulo: 'Visitas a tu perfil',
        valor: _formatoMiles(datos.visitasTienda),
      ),
      _TarjetaKpi(
        esOscuro: esOscuro,
        icono: Icons.chat_bubble_outline_rounded,
        color: const Color(0xFF00897B),
        titulo: 'Nuevas opiniones',
        valor: '${datos.nuevasOpiniones}',
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final columnas = constraints.maxWidth >= 1180
          ? 5
          : constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 560
                  ? 2
                  : 1;
      const espacio = 14.0;
      final ancho = (constraints.maxWidth - espacio * (columnas - 1)) / columnas;

      return Wrap(
        spacing: espacio,
        runSpacing: espacio,
        children: [
          for (var i = 0; i < tarjetas.length; i++)
            SizedBox(width: ancho, child: tarjetas[i])
                .animate()
                .fadeIn(delay: Duration(milliseconds: 60 * i), duration: 300.ms)
                .slideY(begin: 0.12, end: 0, duration: 300.ms),
        ],
      );
    });
  }
}

class _TarjetaKpi extends StatefulWidget {
  final bool esOscuro;
  final IconData icono;
  final Color color;
  final String titulo;
  final String valor;
  final String? enlaceTexto;
  final VoidCallback? alPresionarEnlace;

  const _TarjetaKpi({
    required this.esOscuro,
    required this.icono,
    required this.color,
    required this.titulo,
    required this.valor,
    this.enlaceTexto,
    this.alPresionarEnlace,
  });

  @override
  State<_TarjetaKpi> createState() => _TarjetaKpiState();
}

class _TarjetaKpiState extends State<_TarjetaKpi> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 152,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: CraftHubColors.panel(widget.esOscuro),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _sobre ? widget.color.withValues(alpha: 0.5) : CraftHubColors.borde(widget.esOscuro)),
          boxShadow: [
            BoxShadow(
              color: (_sobre ? widget.color : Colors.black).withValues(alpha: _sobre ? 0.18 : 0.04),
              blurRadius: _sobre ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // spaceBetween mantiene el ícono arriba, el texto en el centro y el
        // enlace (si existe) siempre en la misma línea de base — así todas
        // las tarjetas quedan alineadas aunque unas tengan enlace y otras no.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [widget.color.withValues(alpha: 0.22), widget.color.withValues(alpha: 0.08)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icono, size: 19, color: widget.color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.valor,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700,
                        color: CraftHubColors.textoPrincipal(widget.esOscuro))),
                const SizedBox(height: 2),
                Text(widget.titulo,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: CraftHubColors.textoSecundario(widget.esOscuro))),
              ],
            ),
            SizedBox(
              height: 14,
              child: widget.enlaceTexto == null
                  ? null
                  : GestureDetector(
                      onTap: widget.alPresionarEnlace,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(widget.enlaceTexto!,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: widget.color)),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_forward_rounded, size: 12, color: widget.color),
                      ]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PANEL INGRESOS ────────────────────────────────────────────────────────────

class _PanelIngresos extends StatelessWidget {
  final DatosDashboardVendedor datos;
  final bool esOscuro;
  const _PanelIngresos({required this.datos, required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    final positivo = datos.variacionIngresos >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _decorPanel(esOscuro),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _IconoPanel(icono: Icons.show_chart_rounded, color: CraftHubColors.vinoTinto),
            const SizedBox(width: 10),
            Text('Ingresos totales',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                  fontWeight: FontWeight.w700, color: CraftHubColors.textoPrincipal(esOscuro))),
            const SizedBox(width: 6),
            Tooltip(
              message: 'Suma de todos tus ingresos en el período seleccionado',
              child: Icon(Icons.info_outline_rounded, size: 14, color: CraftHubColors.textoSecundario(esOscuro)),
            ),
          ]),
          const SizedBox(height: 12),
          Text('\$${datos.ingresosTotal.toStringAsFixed(2)}',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 30,
                fontWeight: FontWeight.w700, color: CraftHubColors.textoPrincipal(esOscuro))),
          Row(children: [
            Icon(positivo ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 13, color: positivo ? CraftHubColors.exito : CraftHubColors.error),
            const SizedBox(width: 3),
            Text('${datos.variacionIngresos}% vs. periodo anterior',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                  fontWeight: FontWeight.w600, color: positivo ? CraftHubColors.exito : CraftHubColors.error)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: GraficoIngresos(valores: datos.ingresoesMensuales, etiquetas: datos.etiquetasMeses, esOscuro: esOscuro),
          ),
        ],
      ),
    );
  }
}

class _IconoPanel extends StatelessWidget {
  final IconData icono;
  final Color color;
  const _IconoPanel({required this.icono, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30, height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.08)]),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icono, size: 15, color: color),
    );
  }
}

void _mostrarOpiniones(BuildContext context, String nombreVendedor, bool esOscuro) {
  final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
  final colorSec = CraftHubColors.textoSecundario(esOscuro);
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: CraftHubColors.panel(esOscuro),
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
                  Text('Opiniones de tus clientes',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                          fontWeight: FontWeight.w700, color: colorTexto)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: colorTexto),
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text('Aún no tienes opiniones de clientes.',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: colorSec)),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: opiniones.length,
                      separatorBuilder: (_, _) => Divider(color: CraftHubColors.borde(esOscuro), height: 20),
                      itemBuilder: (_, i) => _FilaOpinion(opinion: opiniones[i], esOscuro: esOscuro),
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
  final bool esOscuro;
  const _FilaOpinion({required this.opinion, required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);
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
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: colorTexto)),
            ),
            if (opinion.calificacion != null) ...[
              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD4A843)),
              const SizedBox(width: 2),
              Text(opinion.calificacion!.toStringAsFixed(1),
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: colorTexto)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text('Sobre "${opinion.producto}"',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: colorSec)),
        const SizedBox(height: 4),
        Text(opinion.comentario,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: colorTexto, height: 1.4)),
      ],
    );
  }
}

// ── PANEL EVALUACIONES ────────────────────────────────────────────────────────

class _PanelEvaluaciones extends StatelessWidget {
  final DatosDashboardVendedor datos;
  final bool esOscuro;
  const _PanelEvaluaciones({required this.datos, required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _decorPanel(esOscuro),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const _IconoPanel(icono: Icons.star_rounded, color: Color(0xFFD4A843)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Evaluaciones',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                    fontWeight: FontWeight.w700, color: CraftHubColors.textoPrincipal(esOscuro))),
            ),
            _BotonTexto(
              esOscuro: esOscuro,
              texto: 'Ver opiniones',
              alPresionar: () => _mostrarOpiniones(context, datos.nombreVendedor, esOscuro),
            ),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: GraficoEvaluaciones(
              distribucion: datos.distribucionEvaluaciones,
              promedio: datos.promedioEvaluacion,
              total: datos.totalEvaluaciones,
              esOscuro: esOscuro,
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
  final bool esOscuro;
  final VoidCallback alVerTodos;

  const _PanelTopProductos({
    required this.datos,
    required this.esOscuro,
    required this.alVerTodos,
  });

  @override
  Widget build(BuildContext context) {
    final colorSec = CraftHubColors.textoSecundario(esOscuro);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _decorPanel(esOscuro),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const _IconoPanel(icono: Icons.emoji_events_rounded, color: Color(0xFFD4A843)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Top 5 productos más vendidos',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                    fontWeight: FontWeight.w700, color: CraftHubColors.textoPrincipal(esOscuro))),
            ),
            _BotonTexto(esOscuro: esOscuro, texto: 'Ver todos', alPresionar: alVerTodos),
          ]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: [
              const SizedBox(width: 34),
              Expanded(child: Text('Producto',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                    fontWeight: FontWeight.w600, color: colorSec))),
              SizedBox(width: 50, child: Text('Ventas', textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                    fontWeight: FontWeight.w600, color: colorSec))),
              SizedBox(width: 80, child: Text('Ingresos', textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                    fontWeight: FontWeight.w600, color: colorSec))),
            ]),
          ),
          Divider(color: CraftHubColors.borde(esOscuro), height: 1),
          ...datos.topProductos.map((p) => TarjetaProductoRanking(
                producto: p,
                esOscuro: esOscuro,
                onTap: () => _mostrarDetalleProducto(context, p, esOscuro, alVerTodos),
              )),
        ],
      ),
    );
  }
}

// ── VISTA RÁPIDA DE PRODUCTO ─────────────────────────────────────────────────

void _mostrarDetalleProducto(
  BuildContext context,
  ModeloProductoRanking p,
  bool esOscuro,
  VoidCallback alVerEnInventario,
) {
  final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
  final colorSec = CraftHubColors.textoSecundario(esOscuro);

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: CraftHubColors.panel(esOscuro),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Icon(Icons.close_rounded, size: 20, color: colorSec),
                ),
              ),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    p.imagenUrl,
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 160,
                      height: 160,
                      color: CraftHubColors.borde(esOscuro),
                      child: Icon(Icons.image_outlined, size: 40, color: colorSec),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(p.nombre,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: colorTexto)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CraftHubColors.vinoTintoSuave,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(p.categoria,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: CraftHubColors.vinoTinto)),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ventas', style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: colorSec)),
                      Text('${p.ventas}',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: colorTexto)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ingresos', style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: colorSec)),
                      Text('\$${p.ingresos.toStringAsFixed(2)}',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: CraftHubColors.vinoTinto)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    alVerEnInventario();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: CraftHubColors.vinoTinto, padding: const EdgeInsets.symmetric(vertical: 13)),
                  icon: const Icon(Icons.inventory_2_outlined, size: 17, color: Colors.white),
                  label: const Text('Ver en mis productos',
                      style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ── BOTÓN TEXTO ───────────────────────────────────────────────────────────────

class _BotonTexto extends StatefulWidget {
  final String texto;
  final bool esOscuro;
  final VoidCallback alPresionar;
  const _BotonTexto({required this.texto, required this.esOscuro, required this.alPresionar});

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
            color: _sobre ? CraftHubColors.vinoTintoSuave : CraftHubColors.fondo(widget.esOscuro),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CraftHubColors.borde(widget.esOscuro), width: 1),
          ),
          child: Text(widget.texto,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _sobre ? CraftHubColors.vinoTinto : CraftHubColors.textoPrincipal(widget.esOscuro))),
        ),
      ),
    );
  }
}

// ── DECORACIÓN PANEL ──────────────────────────────────────────────────────────

BoxDecoration _decorPanel(bool esOscuro) => BoxDecoration(
  color: CraftHubColors.panel(esOscuro),
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: CraftHubColors.borde(esOscuro)),
  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: esOscuro ? 0.22 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
);

