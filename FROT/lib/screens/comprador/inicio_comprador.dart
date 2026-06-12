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
import '../../widgets/comprador/sidebar_comprador.dart';
import '../../widgets/comprador/tarjeta_producto.dart';
import '../../widgets/comprador/carrusel_hero.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// ðŸ”Œ DATOS MOCK â€” reemplazar con llamadas a FastAPI
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final List<BannerModelo> mockBanners = [
  BannerModelo(titulo: 'Bolso tejido\ntratdicional',
    descripcion: 'Tejido a mano por artesanas de ColÃ³n, PanamÃ¡.',
    imagenUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=900',
    productoId: '001'),
  BannerModelo(titulo: 'CerÃ¡mica\nNgÃ¤be-BuglÃ©',
    descripcion: 'Piezas Ãºnicas de la comarca NgÃ¤be-BuglÃ©.',
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
  {'nombre': 'Rosa MartÃ­nez', 'foto': 'https://i.pravatar.cc/150?img=5'},
  {'nombre': 'Juan PÃ©rez',    'foto': 'https://i.pravatar.cc/150?img=8'},
  {'nombre': 'Elena GarcÃ­a',  'foto': 'https://i.pravatar.cc/150?img=9'},
  {'nombre': 'Miguel Torres', 'foto': 'https://i.pravatar.cc/150?img=12'},
  {'nombre': 'Pedro DÃ­az',    'foto': 'https://i.pravatar.cc/150?img=15'},
];

final List<ProductoModelo> mockProductos = [
  ProductoModelo(id:'p1', nombre:'Pollera panameÃ±a', precio:45.00,
    imagenUrl:'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
    artesano:'Ana Santos', provincia:'Herrera', categoria:'Textiles'),
  ProductoModelo(id:'p2', nombre:'Cesta tejida', precio:28.00,
    imagenUrl:'https://images.unsplash.com/photo-1606760227091-3dd870d97f1d?w=400',
    artesano:'Rosa MartÃ­nez', provincia:'CoclÃ©', categoria:'Textiles'),
  ProductoModelo(id:'p3', nombre:'Vasija cerÃ¡mica', precio:62.00,
    imagenUrl:'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=400',
    artesano:'Carlos Ruiz', provincia:'Los Santos', categoria:'CerÃ¡mica'),
  ProductoModelo(id:'p4', nombre:'Tapete artesanal', precio:38.00,
    imagenUrl:'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
    artesano:'Elena GarcÃ­a', provincia:'Guna Yala', categoria:'Textiles'),
  ProductoModelo(id:'p5', nombre:'Bolso cuero', precio:95.00,
    imagenUrl:'https://images.unsplash.com/photo-1603912699214-92627f304eb6?w=400',
    artesano:'Juan PÃ©rez', provincia:'PanamÃ¡', categoria:'Accesorios'),
  ProductoModelo(id:'p6', nombre:'Set de tazas', precio:22.00,
    imagenUrl:'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=400',
    artesano:'Miguel Torres', provincia:'ChiriquÃ­', categoria:'CerÃ¡mica'),
];

// Provincias y comarcas de PanamÃ¡
const List<String> provincias = [
  'Bocas del Toro','ChiriquÃ­','CoclÃ©','ColÃ³n','DariÃ©n',
  'Herrera','Los Santos','PanamÃ¡','PanamÃ¡ Oeste','Veraguas',
];
const List<String> comarcas = [
  'Guna Yala','EmberÃ¡-Wounaan','NgÃ¤be-BuglÃ©',
  'Guna de MadugandÃ­','Guna de WargandÃ­',
];
const List<String> categorias = [
  'Textiles','CerÃ¡mica','Madera','JoyerÃ­a','DecoraciÃ³n','Accesorios',
];
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class HomeComprador extends StatefulWidget {
  const HomeComprador({super.key});

  @override
  State<HomeComprador> createState() => _HomeCompradorState();
}

class _HomeCompradorState extends State<HomeComprador> {
  int _navIndice       = 0;
  String _categoriaActiva = 'Textiles';
  String? _provinciaActiva;
  // ignore: unused_field
  bool _mostrarProvincias = false;

  // ðŸ”Œ controlador de bÃºsqueda â†’ GET /api/productos?q=
  final _busquedaCtrl = TextEditingController();

  // ðŸ”Œ Lista de productos: se llena desde la API
  List<ProductoModelo> _productos = List.from(mockProductos);

  // ðŸ”Œ AquÃ­ irÃ¡ la llamada real:
  // Future<void> _cargarProductos() async {
  //   final resp = await http.get(Uri.parse(
  //     '$baseUrl/api/productos?categoria=$_categoriaActiva&provincia=$_provinciaActiva'));
  //   final data = jsonDecode(resp.body) as List;
  //   setState(() => _productos = data.map(ProductoModelo.fromJson).toList());
  // }

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
          // 1. El sidebar se expande/colapsa solo â€” el Row se adapta automÃ¡ticamente
          SidebarComprador(
            indiceActivo: _navIndice,
            alSeleccionar: (i) => setState(() => _navIndice = i),
            alCerrarSesion: () {
              // ðŸ”Œ POST /api/auth/logout
            },
          ),

          // 2. El Expanded ocupa todo el espacio restante automÃ¡ticamente
          Expanded(
            child: Column(
              children: [
                // Barra superior (Buscador, usuario, etc.)
                _buildTopBar(esModoOscuro),
                
                // Contenido dinÃ¡mico principal que cambia segÃºn el Sidebar
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

  // â”€â”€ ðŸ› ï¸ MÃ‰TODO DE NAVEGACIÃ“N AGREGADO AQUÃ CORRECIENDO EL ERROR ROJO â”€â”€
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
        // Barra de bÃºsqueda â€” larga estilo Apple
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            child: TextField(
              controller: _busquedaCtrl,
              // onChanged: (q) => _cargarProductos(busqueda: q),
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar productos, artesanos, provinciasâ€¦',
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

        // Ãconos superiores derechos
        _IconTopBar(icono: Icons.chat_bubble_outline_rounded,
            tooltip: 'Mensajes', onTap: () {}), // ðŸ”Œ navegar a /mensajes
        _IconTopBar(icono: Icons.calendar_month_outlined,
            tooltip: 'Eventos', onTap: () {}),   // ðŸ”Œ navegar a /calendario
        _IconTopBar(icono: Icons.notifications_none_rounded,
            tooltip: 'Notificaciones', tieneNotif: true,
            onTap: () {}),                        // ðŸ”Œ GET /api/notificaciones
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
), // ðŸ”Œ navegar a /mapa

        // BotÃ³n toggle tema
        _IconTopBar(
          icono: Theme.of(context).brightness == Brightness.dark
              ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          tooltip: 'Cambiar tema',
          onTap: () => context.read<GestorTema>().alternarTema(),
        ),
      ]),
    );
  }

  // ignore: unused_element
  Widget _buildContenido(bool oscuro) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // â”€â”€ CARRUSEL HERO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        // ðŸ”Œ banners viene de: GET /api/productos/destacados
        CarruselHero(
          banners: mockBanners,
          alVerMas: (id) {
            // ðŸ”Œ navegar a PantallaDetalleProducto(productoId: id)
          },
        ),
        const SizedBox(height: 24),

        // â”€â”€ ARTESANOS DESTACADOS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        // ðŸ”Œ GET /api/artesanos/destacados
        Text('Artesanos destacados',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600,
            color: oscuro ? CraftHubColors.textoOscuro : CraftHubColors.textoClaro)),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: mockArtesanos.length, // ðŸ”Œ reemplazar con lista del backend
            itemBuilder: (_, i) => _TarjetaArtesano(
              nombre: mockArtesanos[i]['nombre']!,
              fotoUrl: mockArtesanos[i]['foto']!,
              onTap: () {
                // ðŸ”Œ navegar a PerfilArtesano(artesanoId: id)
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        // â”€â”€ FILTROS DE CATEGORÃAS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        // ðŸ”Œ GET /api/categorias
        Text('Explorar por categorÃ­as',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600,
            color: oscuro ? CraftHubColors.textoOscuro : CraftHubColors.textoClaro)),
        const SizedBox(height: 12),
        _buildFiltros(oscuro),
        const SizedBox(height: 24),

        // â”€â”€ GRID MASONRY DE PRODUCTOS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Text('Productos artesanales',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600,
            color: oscuro ? CraftHubColors.textoOscuro : CraftHubColors.textoClaro)),
        const SizedBox(height: 12),
        // ðŸ”Œ GET /api/productos?categoria=X&provincia=Y&pagina=1
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
                // ðŸ”Œ navegar a PantallaDetalleProducto(productoId: _productos[i].id)
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
            // ðŸ”Œ _cargarProductos()
          },
        )),
        // Dropdown Provincias y Comarcas
        _ChipProvincias(
          provinciaSeleccionada: _provinciaActiva,
          onSeleccionar: (prov) {
            setState(() { _provinciaActiva = prov; _mostrarProvincias = false; });
            // ðŸ”Œ _cargarProductos()
          },
        ),
      ],
    );
  }
}

// â”€â”€ Widgets auxiliares â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                  ? (oscuro ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05))
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
        onTap: widget.onTap, // ðŸ”Œ navegar al perfil del artesano
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(right: 16),
          transform: _hover ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
          child: Column(children: [
            Stack(children: [
              CircleAvatar(radius: 28,
                backgroundImage: NetworkImage(widget.fotoUrl), // ðŸ”Œ URL del backend
                backgroundColor: CraftHubColors.fondoClaro),
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
    // ðŸ”Œ las listas de provincias/comarcas vienen de GET /api/provincias
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


