import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'pantalla_carrito.dart';
import 'artesanos_screen.dart';
import 'pantalla_favoritos.dart';
import 'pantalla_mapa.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';
import '../../core/carrito_provider.dart';
import '../../widgets/comprador/sidebar_comprador.dart';
import '../../widgets/comprador/tarjeta_producto.dart';
import '../../widgets/comprador/carrusel_hero.dart';
import '../../services/api_service.dart';
import '../../models/artesano_modelo.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 🔌 DATOS MOCK – reemplazar con llamadas a FastAPI
// ──────────────────────────────────────────────────────────────────────────────
final List<BannerModelo> mockBanners = [
  BannerModelo(titulo: 'Bolso tejido\ntradicional',
    descripcion: 'Tejido a mano por artesanas de Colón, Panamá.',
    imagenUrl: 'https://i.imgur.com/ZWRiMCb.jpeg',
    productoId: '001'),
  BannerModelo(titulo: 'Cerámica\nNgäbe-Buglé',
    descripcion: 'Piezas únicas de la comarca Ngäbe-Buglé.',
    imagenUrl: 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=900',
    productoId: '002'),
  BannerModelo(titulo: 'Molas\noriginales',
    descripcion: 'Arte textil de la comarca Guna Yala.',
    imagenUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=900',
    productoId: '003'),
];

final List<Map<String,String>> mockArtesanos = [
  {'nombre': 'Ana Santos',    'foto': 'https://i.pravatar.cc/150?img=1'},
  {'nombre': 'Carlos Ruiz',   'foto': 'https://i.pravatar.cc/150?img=3'},
  {'nombre': 'Rosa Martínez', 'foto': 'https://i.pravatar.cc/150?img=5'},
  {'nombre': 'Juan Pérez',    'foto': 'https://i.pravatar.cc/150?img=8'},
  {'nombre': 'Elena García',  'foto': 'https://i.pravatar.cc/150?img=9'},
  {'nombre': 'Miguel Torres', 'foto': 'https://i.pravatar.cc/150?img=12'},
  {'nombre': 'Pedro Díaz',    'foto': 'https://i.pravatar.cc/150?img=15'},
];

final List<ProductoModelo> mockProductos = [
  ProductoModelo(id:'p1', nombre:'Pollera panameña', precio:45.00,
    imagenUrl:'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
    artesano:'Ana Santos', provincia:'Herrera', categoria:'Textiles'),
  ProductoModelo(id:'p2', nombre:'Cesta tejida', precio:28.00,
    imagenUrl:'https://images.unsplash.com/photo-1606760227091-3dd870d97f1d?w=400',
    artesano:'Rosa Martínez', provincia:'Coclé', categoria:'Textiles'),
  ProductoModelo(id:'p3', nombre:'Vasija cerámica', precio:62.00,
    imagenUrl:'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=400',
    artesano:'Carlos Ruiz', provincia:'Los Santos', categoria:'Cerámica'),
  ProductoModelo(id:'p4', nombre:'Tapete artesanal', precio:38.00,
    imagenUrl:'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
    artesano:'Elena García', provincia:'Guna Yala', categoria:'Textiles'),
  ProductoModelo(id:'p5', nombre:'Bolso cuero', precio:95.00,
    imagenUrl:'https://images.unsplash.com/photo-1603912699214-92627f304eb6?w=400',
    artesano:'Juan Pérez', provincia:'Panamá', categoria:'Accesorios'),
  ProductoModelo(id:'p6', nombre:'Set de tazas', precio:22.00,
    imagenUrl:'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=400',
    artesano:'Miguel Torres', provincia:'Chiriquí', categoria:'Cerámica'),
];

// Provincias y comarcas de Panamá
const List<String> provincias = [
  'Bocas del Toro','Chiriquí','Coclé','Colón','Darién',
  'Herrera','Los Santos','Panamá','Panamá Oeste','Veraguas',
];
const List<String> comarcas = [
  'Guna Yala','Emberá-Wounaan','Ngäbe-Buglé',
  'Guna de Madugandí','Guna de Wargandí',
];
const List<String> categorias = [
  'Todos','Vestir','Artesanía','Muebles','Joyería','Alimentos','Accesorios','Calzado'
];
// ──────────────────────────────────────────────────────────────────────────────

class HomeComprador extends StatefulWidget {
  final String userId;  // ✅ CAMBIO #1: AGREGADO

  const HomeComprador({
    super.key,
    required this.userId,  // ✅ CAMBIO #1: AGREGADO
  });

  @override
  State<HomeComprador> createState() => _HomeCompradorState();
}

class _HomeCompradorState extends State<HomeComprador> {
  int _navIndice       = 0;
  String _categoriaActiva = 'Todos';
  String? _provinciaActiva;
  bool _mostrarProvincias = false;

  final _busquedaCtrl = TextEditingController();

  List<ProductoModelo> _productos = [];
  bool _cargando = true;
  String? _error;
  List<ArtesanoModelo> _artesanos = [];

  @override
  void initState() {
    super.initState();
    _inicializarCarrito();  // ✅ CAMBIO #2: AGREGADO
    _cargarProductos();
    _cargarArtesanos();
  }

  // ✅ CAMBIO #3: NUEVO MÉTODO - Inicializar Carrito con userId
  Future<void> _inicializarCarrito() async {
    try {
      await context.read<CarritoProvider>().inicializar(widget.userId);
      debugPrint('✅ Carrito inicializado para usuario: ${widget.userId}');
    } catch (e) {
      debugPrint('❌ Error inicializando carrito: $e');
    }
  }

  Future<void> _cargarProductos() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final productos = await ApiService.getProductos(
        categoria: _categoriaActiva,
        busqueda: _busquedaCtrl.text,
      );
      setState(() => _productos = productos);
    } catch (e) {
      setState(() => _error = 'No se pudieron cargar los productos: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cargarArtesanos() async {
    try {
      final artesanos = await ApiService.getArtesanos();
      setState(() => _artesanos = artesanos);
    } catch (e) {
      print('Error cargando artesanos: $e');
    }
  }

  @override
  void dispose() { _busquedaCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = esModoOscuro ? CraftHubColors.fondoOscuro : CraftHubColors.fondoClaro;

    return Scaffold(
      backgroundColor: colorFondo,
      body: Row(
        children: [
          SidebarComprador(
            indiceActivo: _navIndice,
            alSeleccionar: (i) => setState(() => _navIndice = i),
            alCerrarSesion: () {
              // 🔌 POST /api/auth/logout
            },
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
        return _buildContenido(oscuro);
      case 1:
        return const PantallaCarrito();
      case 2:
        return const ArtesanosScreen();
      case 3:
        return const PantallaFavoritos();
      default:
        return _buildContenido(oscuro);
    }
  }
  
  Widget _buildTopBar(bool oscuro) {
    final border = oscuro ? CraftHubColors.bordeOscuro : CraftHubColors.bordeClaro;
    final fondo  = oscuro ? CraftHubColors.fondoOscuro : CraftHubColors.fondoClaro;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: fondo,
      ),
      child: Row(
        children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            child: TextField(
              controller: _busquedaCtrl,
              onChanged: (q) => _cargarProductos(),
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar productos, artesanos, provincias...',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
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
                  borderSide: const BorderSide(color: CraftHubColors.vinoTinto, width: 1.2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        _IconTopBar(icono: Icons.chat_bubble_outline_rounded,
            tooltip: 'Mensajes', onTap: () {}),
        _IconTopBar(icono: Icons.calendar_month_outlined,
            tooltip: 'Eventos', onTap: () {}),
        _IconTopBar(icono: Icons.notifications_none_rounded,
            tooltip: 'Notificaciones', tieneNotif: true,
            onTap: () {}),
        _IconTopBar(
            icono: Icons.location_on_outlined,
           tooltip: 'Mapa artesanos',
           onTap: () {
             Navigator.push(
             context,
              MaterialPageRoute(
              builder: (ctx) => PantallaMapa(
              esOscuro: Theme.of(ctx).brightness == Brightness.dark,
        ),
      ),
    );
  },
),

        _IconTopBar(
          icono: Theme.of(context).brightness == Brightness.dark
              ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          tooltip: 'Cambiar tema',
          onTap: () => context.read<GestorTema>().alternarTema(),
        ),
      ]),
    );
  }

  Widget _buildContenido(bool oscuro) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        CarruselHero(
          banners: mockBanners,
          alVerMas: (id) {
            // 🔌 navegar a PantallaDetalleProducto(productoId: id)
          },
        ),
        const SizedBox(height: 24),

        Text('Artesanos destacados',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600,
            color: oscuro ? CraftHubColors.textoOscuro : CraftHubColors.textoClaro)),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _artesanos.length,
            itemBuilder: (_, i) => _TarjetaArtesano(
           nombre: _artesanos[i].nombre,
           fotoUrl: _artesanos[i].fotoUrl,
              onTap: () {
                // 🔌 navegar a PerfilArtesano(artesanoId: id)
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text('Explorar por categorías',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600,
            color: oscuro ? CraftHubColors.textoOscuro : CraftHubColors.textoClaro)),
        const SizedBox(height: 12),
        _buildFiltros(oscuro),
        const SizedBox(height: 24),

        Text('Productos artesanales',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600,
            color: oscuro ? CraftHubColors.textoOscuro : CraftHubColors.textoClaro)),
        const SizedBox(height: 12),
        if (_cargando)
  const Padding(
    padding: EdgeInsets.symmetric(vertical: 40),
    child: Center(child: CircularProgressIndicator()),
  )
else if (_error != null)
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(child: Text(_error!, style: GoogleFonts.poppins(color: Colors.red))),
  )
else if (_productos.isEmpty)
  const Padding(
    padding: EdgeInsets.symmetric(vertical: 40),
    child: Center(child: Text('No hay productos disponibles.')),
  )
else
  MasonryGridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 4,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    itemCount: _productos.length,
    itemBuilder: (_, i) {
      final alturas = [280.0, 220.0, 310.0, 250.0, 290.0, 240.0];
      return TarjetaProducto(
        producto: _productos[i],
        altura: alturas[i % alturas.length],
        alPresionar: () {
          // 🔌 navegar a PantallaDetalleProducto(productoId: _productos[i].id)
        },
      );
    },
  ),
      ]),
    );
  }

  Widget _buildFiltros(bool oscuro) {
    return Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...categorias.map((cat) => _ChipCategoria(
          label: cat,
          activo: _categoriaActiva == cat,
       onTap: () {
         setState(() => _categoriaActiva = cat);
              _cargarProductos();
            },
        )),
        _ChipProvincias(
          provinciaSeleccionada: _provinciaActiva,
          onSeleccionar: (prov) {
            setState(() { _provinciaActiva = prov; _mostrarProvincias = false; });
            // 🔌 _cargarProductos()
          },
        ),
      ],
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────────────────────────

class _IconTopBar extends StatefulWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;
  final bool tieneNotif;

  const _IconTopBar({required this.icono, required this.tooltip,
      required this.onTap, this.tieneNotif = false});

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
      onExit:  (_) => setState(() => _hover = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hover
                  ? (oscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05))
                  : (oscuro ? CraftHubColors.panelOscuro : Colors.white),
              border: Border.all(
                color: oscuro ? CraftHubColors.bordeOscuro : CraftHubColors.bordeClaro, width: 0.8),
            ),
            child: Stack(alignment: Alignment.center, children: [
              Icon(widget.icono, size: 19,
                color: oscuro ? CraftHubColors.textoOscuro : const Color(0xFF5A4A42)),
              if (widget.tieneNotif)
                Positioned(top: 6, right: 6,
                  child: Container(width: 7, height: 7,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: CraftHubColors.vinoTinto,
                      border: Border.all(
                        color: oscuro ? CraftHubColors.fondoOscuro : CraftHubColors.fondoClaro,
                        width: 1.5)))),
            ]),
          ),
        ),
      ),
    );
  }
}

class _TarjetaArtesano extends StatefulWidget {
  final String nombre, fotoUrl;
  final VoidCallback onTap;
  const _TarjetaArtesano({required this.nombre, required this.fotoUrl, required this.onTap});

  @override
  State<_TarjetaArtesano> createState() => _TarjetaArtesanoState();
}
class _TarjetaArtesanoState extends State<_TarjetaArtesano> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(right: 16),
          transform: _hover ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
          child: Column(children: [
            Stack(children: [
        CircleAvatar(
          radius: 28,
         backgroundColor: const Color.fromARGB(255, 251, 175, 175),
         backgroundImage: widget.fotoUrl.isNotEmpty 
        ? NetworkImage(widget.fotoUrl) 
        : null,
            child: widget.fotoUrl.isEmpty
        ? Text(
            widget.nombre.trim().split(' ').take(2)
                .map((p) => p[0].toUpperCase()).join(),
            style: const TextStyle(
              color:CraftHubColors.vinoTinto,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          )
        : null,
  ),
  Positioned(bottom: 0, right: 0,
    child: Container(
      width: 17, height: 17,
      decoration: BoxDecoration(
        color: CraftHubColors.vinoTinto, shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5)),
      child: const Icon(Icons.check, size: 10, color: Colors.white),
    )),
]),
const SizedBox(height: 5),
  Text(widget.nombre,
    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500,
      color: const Color(0xFF5A4A42))),
]),
        ),
      ),
    );
  }
}
class _ChipCategoria extends StatefulWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  const _ChipCategoria({required this.label, required this.activo, required this.onTap});

  @override
  State<_ChipCategoria> createState() => _ChipCategoriaState();
}
class _ChipCategoriaState extends State<_ChipCategoria> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final activo = widget.activo;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: activo ? CraftHubColors.vinoTinto
                : (_hover ? Colors.white : Colors.white),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: activo ? CraftHubColors.vinoTinto
                  : (_hover ? CraftHubColors.vinoTinto : CraftHubColors.bordeClaro), width: 0.8),
          ),
          child: Text(widget.label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: activo ? Colors.white
                  : (_hover ? CraftHubColors.vinoTinto : const Color(0xFF5A4A42)),
              fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
            )),
        ),
      ),
    );
  }
}

class _ChipProvincias extends StatefulWidget {
  final String? provinciaSeleccionada;
  final Function(String?) onSeleccionar;
  const _ChipProvincias({this.provinciaSeleccionada, required this.onSeleccionar});

  @override
  State<_ChipProvincias> createState() => _ChipProvinciasState();
}
class _ChipProvinciasState extends State<_ChipProvincias> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (val) => widget.onSeleccionar(val == '__todos' ? null : val),
      itemBuilder: (_) => [
        PopupMenuItem(value: '__todos', child: Text('Todas',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500))),
        const PopupMenuDivider(),
        PopupMenuItem(enabled: false, child: Text('PROVINCIAS',
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey, letterSpacing: 1))),
        ...provincias.map((p) => PopupMenuItem(value: p,
          child: Text(p, style: GoogleFonts.poppins(fontSize: 13)))),
        const PopupMenuDivider(),
        PopupMenuItem(enabled: false, child: Text('COMARCAS',
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey, letterSpacing: 1))),
        ...comarcas.map((c) => PopupMenuItem(value: c,
          child: Text(c, style: GoogleFonts.poppins(fontSize: 13)))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F0),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: const Color(0xFFC9A84C), width: 0.9),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF7A5800)),
          const SizedBox(width: 5),
          Text(widget.provinciaSeleccionada ?? 'Provincias y comarcas',
            style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF7A5800),
              fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF7A5800)),
        ]),
      ),
    );
  }
}