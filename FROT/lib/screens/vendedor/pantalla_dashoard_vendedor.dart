// lib/screens/vendedor/home_vendedor.dart

import 'package:abi_frotend_nd/screens/vendedor/pantalla_tutoriales.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/vendedor/sidebar_vendedor.dart';
import '../../widgets/vendedor/topbar_vendedor.dart';
import '../../widgets/vendedor/tarjeta_producto_ranking.dart';
import '../../widgets/vendedor/grafico_ingresos.dart';
import '../../widgets/vendedor/grafico_evaluaciones.dart';
import '../../widgets/vendedor/resumen_rapido.dart';

// ─────────────────────────────────────────────────────────────
// MODELOS MOCK
// 🔗 API: GET /vendedor/dashboard?periodo=
// ─────────────────────────────────────────────────────────────
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
  nombreVendedor: 'María',
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
      categoria: 'Decoración',
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
      categoria: 'Joyería',
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

// ─────────────────────────────────────────────────────────────
// HOME VENDEDOR — Scaffold principal único
// ─────────────────────────────────────────────────────────────
class HomeVendedor extends StatefulWidget {
  final bool esOscuro;
  const HomeVendedor({super.key, required this.esOscuro});

  @override
  State<HomeVendedor> createState() => _HomeVendedorState();
}

class _HomeVendedorState extends State<HomeVendedor> {
  int _indiceActual = 0;

  // Devuelve SOLO el contenido inner — sin Scaffold, sin sidebar, sin topbar
  Widget _obtenerPantallaActual() {
    switch (_indiceActual) {
      case 0:
        return _ContenidoDashboard(esOscuro: widget.esOscuro);
      case 1:
        return const Center(child: Text('Productos')); // TODO
      case 2:
        return const Center(child: Text('Pedidos')); // TODO
      case 3:
        return const Center(child: Text('Clientes')); // TODO
      case 4:
        return const PantallaTutoriales(); // TODO
      case 5:
        return const Center(child: Text('Reportes')); // TODO
      case 6:
        return const Center(child: Text('Configuración')); // TODO
      default:
        return _ContenidoDashboard(esOscuro: widget.esOscuro);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CraftHubColors.fondoClaro,
      body: Row(
        children: [
          // ── Sidebar ────────────────────────────────────────────────
          SidebarVendedor(
            indiceActivo: _indiceActual,
            alSeleccionar: (i) => setState(() => _indiceActual = i),
            alCerrarSesion: () {
              // 🔌 POST /api/auth/logout → limpiar token y navegar a inicio
              Navigator.pushReplacementNamed(context, '/');
            },
          ),

          // ── Contenido principal ────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Topbar
                VendedorTopbar(
                  cantidadNotif: 3, // 🔌 GET /api/vendedor/notificaciones/count
                  cantidadMensajes: 2, // 🔌 GET /api/vendedor/mensajes/count
                  onVerNotificaciones: () {},
                  onVerMensajes: () => setState(() => _indiceActual = 4),
                  onVerPerfil: () {},
                ),

                // Panel de contenido activo
                Expanded(child: _obtenerPantallaActual()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONTENIDO DASHBOARD — solo el inner, sin Scaffold
// ─────────────────────────────────────────────────────────────
class _ContenidoDashboard extends StatefulWidget {
  final bool esOscuro;
  const _ContenidoDashboard({required this.esOscuro});

  @override
  State<_ContenidoDashboard> createState() => _ContenidoDashboardState();
}

class _ContenidoDashboardState extends State<_ContenidoDashboard> {
  // 🔗 API: GET /vendedor/dashboard?periodo=
  String _periodoSeleccionado = 'Últimos 6 meses';
  final List<String> _periodos = [
    'Últimos 30 días',
    'Últimos 3 meses',
    'Últimos 6 meses',
    'Este año',
  ];

  @override
  Widget build(BuildContext context) {
    final datos = _datosMock; // 🔌 reemplazar con llamada real a FastAPI

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ────────────────────────────────────────────────
          _HeaderDashboard(
            nombreVendedor: datos.nombreVendedor,
            periodoSeleccionado: _periodoSeleccionado,
            periodos: _periodos,
            alCambiarPeriodo: (p) => setState(() => _periodoSeleccionado = p!),
          ),

          const SizedBox(height: 20),

          // ── FILA 1: Ingresos + Evaluaciones ───────────────────────
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

          // ── FILA 2: Top productos + Stats clientes ────────────────
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

          // ── RESUMEN RÁPIDO ────────────────────────────────────────
          ResumenRapido(
            pedidosTotales: datos.pedidosTotales,
            variacionPedidos: '↑ 16%',
            pendientesEnviar: datos.pendientesEnviar,
            productosActivos: datos.productosActivos,
            visitasTienda: datos.visitasTienda,
            variacionVisitas: '↑ 23%',
            alVerPedidos: () {
              // TODO: cambiar índice a pedidos
              // setState(() => _indiceActual = 2) — lo maneja HomeVendedor
            },
            alVerProductos: () {
              // TODO: cambiar índice a productos
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────
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
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: CraftHubColors.textoClaro,
                ),
              ),
              const Text(
                'Aquí tienes un resumen de tu actividad y rendimiento.',
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
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
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

// ─────────────────────────────────────────────────────────────
// PANEL INGRESOS
// ─────────────────────────────────────────────────────────────
class _PanelIngresos extends StatelessWidget {
  final _DatosDashboard datos;
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
                    'Suma de todos tus ingresos en el período seleccionado',
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
              fontFamily: 'PlayfairDisplay',
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

// ─────────────────────────────────────────────────────────────
// PANEL EVALUACIONES
// ─────────────────────────────────────────────────────────────
class _PanelEvaluaciones extends StatelessWidget {
  final _DatosDashboard datos;
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
                  // TODO: navegar a reseñas
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

// ─────────────────────────────────────────────────────────────
// PANEL TOP PRODUCTOS
// ─────────────────────────────────────────────────────────────
class _PanelTopProductos extends StatelessWidget {
  final _DatosDashboard datos;
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
                'Top 5 productos más vendidos',
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

// ─────────────────────────────────────────────────────────────
// PANEL STATS CLIENTES
// ─────────────────────────────────────────────────────────────
class _PanelStatsClientes extends StatelessWidget {
  final _DatosDashboard datos;
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
            variacion: '↑ 20%',
            positivo: true,
          ),
          const Divider(color: CraftHubColors.bordeClaro, height: 1),
          _StatCliente(
            icono: Icons.chat_bubble_outline_rounded,
            titulo: 'Nuevas opiniones',
            valor: '${datos.nuevasOpiniones}',
            variacion: '↑ 12%',
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

// ─────────────────────────────────────────────────────────────
// BOTÓN TEXTO
// ─────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────
// DECORACIÓN PANEL REUTILIZABLE
// ─────────────────────────────────────────────────────────────
BoxDecoration _decorPanel() => BoxDecoration(
  color: CraftHubColors.panelClaro,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: CraftHubColors.bordeClaro),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
);