// lib/screens/vendedor/home_vendedor.dart

import 'package:abi_frotend_nd/screens/vendedor/pantalla_inventario.dart';
import 'package:abi_frotend_nd/screens/vendedor/pantalla_tutoriales.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:abi_frotend_nd/main.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/vendedor/sidebar_vendedor.dart';
import '../../widgets/vendedor/tarjeta_producto_ranking.dart';
import '../../widgets/vendedor/grafico_ingresos.dart';
import '../../widgets/vendedor/grafico_evaluaciones.dart';
import '../../widgets/vendedor/resumen_rapido.dart';
import '../../services/vendedor_api_service.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// MODELOS MOCK
// ðŸ”— API: GET /vendedor/dashboard?periodo=
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DatosDashboard {
  final String nombreVendedor;
  final double ingresosTotal;
  final double variacionIngresos;
  final List<double> ingresoesMensuales;
  final List<String> etiquetasMeses;
  final List<ModeloProductoRanking> topProductos;
  final double promedioEvaluacion;
  final int totalEvaluaciones;
  final Map<int, int> distribucionEvaluaciones;
  final int clientesFelices;
  final int nuevasOpiniones;
  final int pedidosTotales;
  final int pendientesEnviar;
  final int productosActivos;
  final int visitasTienda;

  const _DatosDashboard({
    required this.nombreVendedor,
    required this.ingresosTotal,
    required this.variacionIngresos,
    required this.ingresoesMensuales,
    required this.etiquetasMeses,
    required this.topProductos,
    required this.promedioEvaluacion,
    required this.totalEvaluaciones,
    required this.distribucionEvaluaciones,
    required this.clientesFelices,
    required this.nuevasOpiniones,
    required this.pedidosTotales,
    required this.pendientesEnviar,
    required this.productosActivos,
    required this.visitasTienda,
  });
}

final _datosMock = _DatosDashboard(
  nombreVendedor: 'MarÃ­a',
  ingresosTotal: 8545.00,
  variacionIngresos: 18.6,
  ingresoesMensuales: [900, 1400, 1200, 1800, 2200, 1800, 2400],
  etiquetasMeses: ['Oct', 'Nov', 'Dic', 'Ene', 'Feb', 'Mar'],
  topProductos: [
    ModeloProductoRanking(
      posicion: 1,
      nombre: 'Bolso tejido tradicional',
      categoria: 'Bolsos',
      imagenUrl:
          'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=80',
      ventas: 128,
      ingresos: 2560,
    ),
    ModeloProductoRanking(
      posicion: 2,
      nombre: 'Vasija decorativa',
      categoria: 'DecoraciÃ³n',
      imagenUrl:
          'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=80',
      ventas: 97,
      ingresos: 1940,
    ),
    ModeloProductoRanking(
      posicion: 3,
      nombre: 'Tabla de madera decorativa',
      categoria: 'Hogar',
      imagenUrl:
          'https://images.unsplash.com/photo-1611486212557-88be5ff6f941?w=80',
      ventas: 76,
      ingresos: 1520,
    ),
    ModeloProductoRanking(
      posicion: 4,
      nombre: 'Aretes de filigrana',
      categoria: 'JoyerÃ­a',
      imagenUrl:
          'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=80',
      ventas: 65,
      ingresos: 975,
    ),
    ModeloProductoRanking(
      posicion: 5,
      nombre: 'Taza artesanal',
      categoria: 'Hogar',
      imagenUrl:
          'https://images.unsplash.com/photo-1514228742587-6b1558fcca3d?w=80',
      ventas: 58,
      ingresos: 812,
    ),
  ],
  promedioEvaluacion: 4.7,
  totalEvaluaciones: 128,
  distribucionEvaluaciones: {5: 100, 4: 19, 3: 6, 2: 1, 1: 2},
  clientesFelices: 120,
  nuevasOpiniones: 18,
  pedidosTotales: 156,
  pendientesEnviar: 12,
  productosActivos: 28,
  visitasTienda: 2345,
);

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// HOME VENDEDOR â€” Scaffold principal Ãºnico
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = esModoOscuro
        ? CraftHubColors.fondoOscuro
        : CraftHubColors.fondoClaro;

    return Scaffold(
      backgroundColor: colorFondo,
      body: Row(
        children: [
          // 1. El sidebar se expande/colapsa solo â€” el Row se adapta automÃ¡ticamente
          SidebarVendedor(
            nombre: widget.nombreVendedor,
            fotoUrl: widget.fotoPerfil,
            indiceActivo: _navIndice,
            alSeleccionar: (i) => setState(() => _navIndice = i),
            alCerrarSesion: () {
              // ðŸ“Œ POST /api/auth/logout
            },
          ),

          // 2. El Expanded ocupa todo el espacio restante automÃ¡ticamente
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
        );
      case 1:
        return PantallaInventario(nombreVendedor: widget.nombreVendedor);
      case 2:
      //return const ArtesanosScreen();
      case 3:
      // return const PantallaFavoritos();
     case 4:
     return PantallaTutoriales(userId: widget.userId);
      default:
        return _ContenidoDashboard(
          esOscuro: oscuro,
          nombreVendedor: widget.nombreVendedor,
        );
    }
  }

  Widget _buildTopBar(bool oscuro) {
    final border = oscuro
        ? CraftHubColors.bordeOscuro
        : CraftHubColors.bordeClaro;
    final fondo = oscuro
        ? CraftHubColors.fondoOscuro
        : CraftHubColors.fondoClaro;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(color: fondo),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              child: TextField(
                controller: _busquedaCtrl,
                // ðŸ“Œ onChanged: (q) => _cargarProductos(busqueda: q)  â†’ GET /api/productos?q=
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar productos, artesanos, provinciasâ€¦',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: oscuro ? CraftHubColors.panelOscuro : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(color: border, width: 0.8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: const BorderSide(
                      color: CraftHubColors.vinoTinto,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          _IconTopBar(
            icono: Icons.chat_bubble_outline_rounded,
            tooltip: 'Mensajes',
            onTap: () {}, // ðŸ“Œ navegar a /mensajes
          ),
          _IconTopBar(
            icono: Icons.calendar_month_outlined,
            tooltip: 'Eventos',
            onTap: () {}, // ðŸ“Œ navegar a /calendario
          ),
          _IconTopBar(
            icono: Icons.notifications_none_rounded,
            tooltip: 'Notificaciones',
            tieneNotif: true,
            onTap: () {}, // ðŸ“Œ GET /api/notificaciones
          ),
          _IconTopBar(
            icono: Icons.location_on_outlined,
            tooltip: 'Mapa artesanos',
            onTap: () {
              //Navigator.push(
              // context,
              // MaterialPageRoute(
              //  builder: (ctx) => PantallaMapa(
              //   esOscuro: Theme.of(ctx).brightness == Brightness.dark,
              // ),
              //  ),
              //  );
            },
          ),
          _IconTopBar(
            icono: Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            tooltip: 'Cambiar tema',
            onTap: () => context.read<GestorTema>().alternarTema(),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// CONTENIDO DASHBOARD â€” solo el inner, sin Scaffold
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ContenidoDashboard extends StatefulWidget {
  final bool esOscuro;
  final String nombreVendedor;

  const _ContenidoDashboard({
    required this.esOscuro,
    required this.nombreVendedor,
  });

  @override
  State<_ContenidoDashboard> createState() => _ContenidoDashboardState();
}

class _ContenidoDashboardState extends State<_ContenidoDashboard> {
  // ðŸ”— API: GET /vendedor/dashboard?periodo=
  String _periodoSeleccionado = 'Ãšltimos 6 meses';
  DatosDashboardVendedor? _datos;
  bool _cargando = true;
  String? _error;
  final List<String> _periodos = [
    'Ãšltimos 30 dÃ­as',
    'Ãšltimos 3 meses',
    'Ãšltimos 6 meses',
    'Este aÃ±o',
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
    setState(() {
      _cargando = true;
      _error = null;
    });

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
      return const Center(
        child: CircularProgressIndicator(color: CraftHubColors.vinoTinto),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'No se pudo cargar el dashboard: $_error',
          style: const TextStyle(color: CraftHubColors.error),
        ),
      );
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
          // â”€â”€ HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _HeaderDashboard(
            nombreVendedor: datos.nombreVendedor,
            periodoSeleccionado: _periodoSeleccionado,
            periodos: _periodos,
            alCambiarPeriodo: (p) => setState(() => _periodoSeleccionado = p!),
          ),

          const SizedBox(height: 20),

          // â”€â”€ FILA 1: Ingresos + Evaluaciones â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

          // â”€â”€ FILA 2: Top productos + Stats clientes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: _PanelTopProductos(datos: datos)),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: _PanelStatsClientes(datos: datos)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // â”€â”€ RESUMEN RÃPIDO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          ResumenRapido(
            pedidosTotales: datos.pedidosTotales,
            variacionPedidos: 'â†‘ 16%',
            pendientesEnviar: datos.pendientesEnviar,
            productosActivos: datos.productosActivos,
            visitasTienda: datos.visitasTienda,
            variacionVisitas: 'â†‘ 23%',
            alVerPedidos: () {
              // TODO: cambiar Ã­ndice a pedidos
              // setState(() => _indiceActual = 2) â€” lo maneja HomeVendedor
            },
            alVerProductos: () {
              // TODO: cambiar Ã­ndice a productos
            },
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// HEADER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
              Text(
                'Bienvenida, $nombreVendedor',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: CraftHubColors.textoClaro,
                ),
              ),
              const Text(
                'AquÃ­ tienes un resumen de tu actividad y rendimiento.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: CraftHubColors.textoSecClaro,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: CraftHubColors.panelClaro,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CraftHubColors.bordeClaro, width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: CraftHubColors.vinoTinto,
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: periodoSeleccionado,
                  isDense: true,
                  dropdownColor: CraftHubColors.panelClaro,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CraftHubColors.textoClaro,
                  ),
                  items: periodos
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PANEL INGRESOS
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
          Row(
            children: [
              const Text(
                'Ingresos totales',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CraftHubColors.textoSecClaro,
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message:
                    'Suma de todos tus ingresos en el perÃ­odo seleccionado',
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: CraftHubColors.textoSecClaro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\$${datos.ingresosTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: CraftHubColors.textoClaro,
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                size: 13,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(width: 3),
              Text(
                '${datos.variacionIngresos}% vs. periodo anterior',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: GraficoIngresos(
              valores: datos.ingresoesMensuales,
              etiquetas: datos.etiquetasMeses,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PANEL EVALUACIONES
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
          Row(
            children: [
              const Icon(
                Icons.star_outline_rounded,
                size: 18,
                color: Color(0xFFD4A843),
              ),
              const SizedBox(width: 8),
              const Text(
                'Evaluaciones de clientes',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CraftHubColors.textoClaro,
                ),
              ),
              const Spacer(),
              _BotonTexto(
                texto: 'Ver opiniones',
                alPresionar: () {
                  // TODO: navegar a reseÃ±as
                },
              ),
            ],
          ),
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PANEL TOP PRODUCTOS
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PanelTopProductos extends StatelessWidget {
  final DatosDashboardVendedor datos;
  const _PanelTopProductos({required this.datos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _decorPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: CraftHubColors.vinoTintoSuave,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  size: 16,
                  color: CraftHubColors.vinoTinto,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Top 5 productos mÃ¡s vendidos',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CraftHubColors.textoClaro,
                ),
              ),
              const Spacer(),
              _BotonTexto(
                texto: 'Ver todos',
                alPresionar: () {
                  // TODO: navegar a productos
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Encabezado tabla
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: const [
                SizedBox(width: 34),
                Expanded(
                  child: Text(
                    'Producto',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CraftHubColors.textoSecClaro,
                    ),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    'Ventas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CraftHubColors.textoSecClaro,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Ingresos',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CraftHubColors.textoSecClaro,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: CraftHubColors.bordeClaro, height: 1),
          ...datos.topProductos.map((p) => TarjetaProductoRanking(producto: p)),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PANEL STATS CLIENTES
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
          _StatCliente(
            icono: Icons.sentiment_satisfied_alt_outlined,
            titulo: 'Clientes felices',
            valor: '${datos.clientesFelices}',
            variacion: 'â†‘ 20%',
            positivo: true,
          ),
          const Divider(color: CraftHubColors.bordeClaro, height: 1),
          _StatCliente(
            icono: Icons.chat_bubble_outline_rounded,
            titulo: 'Nuevas opiniones',
            valor: '${datos.nuevasOpiniones}',
            variacion: 'â†‘ 12%',
            positivo: true,
          ),
          const Divider(color: CraftHubColors.bordeClaro, height: 1),
          _StatCliente(
            icono: Icons.check_circle_outline_rounded,
            titulo: 'Respuestas',
            valor: '100%',
            subtitulo: 'Tiempo de respuesta < 24h',
            positivo: true,
          ),
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
    required this.icono,
    required this.titulo,
    required this.valor,
    this.variacion,
    this.subtitulo,
    required this.positivo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CraftHubColors.vinoTintoSuave,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, size: 18, color: CraftHubColors.vinoTinto),
          ),
          const SizedBox(width: 12),
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
                Row(
                  children: [
                    Text(
                      valor,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CraftHubColors.textoClaro,
                      ),
                    ),
                    if (variacion != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        variacion!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: positivo
                              ? const Color(0xFF2E7D32)
                              : CraftHubColors.error,
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitulo != null)
                  Text(
                    subtitulo!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: CraftHubColors.textoSecClaro,
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// BOTÃ“N TEXTO
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
            color: _sobre
                ? CraftHubColors.vinoTintoSuave
                : CraftHubColors.fondoClaro,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CraftHubColors.bordeClaro, width: 1),
          ),
          child: Text(
            widget.texto,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CraftHubColors.textoClaro,
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// DECORACIÃ“N PANEL REUTILIZABLE
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
BoxDecoration _decorPanel() => BoxDecoration(
  color: CraftHubColors.panelClaro,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: CraftHubColors.bordeClaro),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
);

class _IconTopBar extends StatefulWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;
  final bool tieneNotif;

  const _IconTopBar({
    required this.icono,
    required this.tooltip,
    required this.onTap,
    this.tieneNotif = false,
  });

  @override
  State<_IconTopBar> createState() => _IconTopBarState();
}

class _IconTopBarState extends State<_IconTopBar> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hover
                  ? (oscuro
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05))
                  : (oscuro ? CraftHubColors.panelOscuro : Colors.white),
              border: Border.all(
                color: oscuro
                    ? CraftHubColors.bordeOscuro
                    : CraftHubColors.bordeClaro,
                width: 0.8,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  widget.icono,
                  size: 19,
                  color: oscuro
                      ? CraftHubColors.textoOscuro
                      : const Color(0xFF5A4A42),
                ),
                if (widget.tieneNotif)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CraftHubColors.vinoTinto,
                        border: Border.all(
                          color: oscuro
                              ? CraftHubColors.fondoOscuro
                              : CraftHubColors.fondoClaro,
                          width: 1.5,
                        ),
                      ),
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

