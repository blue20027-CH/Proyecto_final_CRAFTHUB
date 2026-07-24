import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'pantalla_carrito.dart';
import 'artesanos_screen.dart';
import 'pantalla_favoritos.dart';
import 'pantalla_mapa.dart';
import 'pantalla_eventos_comprador.dart';
import 'pantalla_tutoriales_comprador.dart';
import 'pantalla_mensajes_comprador.dart';
import 'pantalla_detalle_producto.dart';
import '../auth/inicio_screen.dart';
import '../pantalla_editar_perfil.dart';
import '../navegacion_artesano.dart';
import 'pantalla_mi_perfil.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';
import '../../core/carrito_provider.dart';
import '../../core/favoritos_provider.dart';
import '../../widgets/comprador/sidebar_comprador.dart';
import '../../widgets/comprador/tarjeta_producto.dart';
import '../../widgets/comprador/carrusel_hero.dart';
import '../../widgets/topbar_flotante.dart';
import '../../widgets/chat/boton_flotante_ia.dart';
import '../../widgets/tutorial/overlay_tutorial_crafty.dart';
import '../../services/api_service.dart';
import '../../services/servicio_tutorial.dart';
import '../../models/artesano_modelo.dart';
import '../../core/i18n/i18n.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 🔌 DATOS MOCK – reemplazar con llamadas a FastAPI
// ──────────────────────────────────────────────────────────────────────────────
final List<BannerModelo> mockBanners = [
  BannerModelo(
    titulo: 'Bolso tejido\ntradicional',
    descripcion: 'Tejido a mano por artesanas de Colón, Panamá.',
    tituloEn: 'Traditional\nwoven bag',
    descripcionEn: 'Handwoven by artisans from Colón, Panama.',
    imagenUrl: 'https://i.imgur.com/ZWRiMCb.jpeg',
    productoId: '001',
  ),
  BannerModelo(
    titulo: 'Cerámica\nNgäbe-Buglé',
    descripcion: 'Piezas únicas de la comarca Ngäbe-Buglé.',
    tituloEn: 'Ngäbe-Buglé\npottery',
    descripcionEn: 'One-of-a-kind pieces from the Ngäbe-Buglé comarca.',
    imagenUrl:
        'https://tcezyirkglpihohuzrqo.supabase.co/storage/v1/object/public/perfiles/ChatGPT%20Image%20Jun%2030,%202026,%2004_01_52%20PM.png',
    productoId: '002',
  ),
  BannerModelo(
    titulo: 'Molas\noriginales',
    descripcion: 'Arte textil de la comarca Guna Yala.',
    tituloEn: 'Original\nmolas',
    descripcionEn: 'Textile art from the Guna Yala comarca.',
    imagenUrl:
        'https://tcezyirkglpihohuzrqo.supabase.co/storage/v1/object/public/perfiles/Jun%2030,%202026,%2004_02_06%20PM.png',
    productoId: '003',
  ),
  BannerModelo(
    titulo: 'Fibras\nNaturales',
    descripcion: 'Belleza artesanal en cada tejido.',
    tituloEn: 'Natural\nFibers',
    descripcionEn: 'Artisanal beauty in every weave.',
    imagenUrl:
        'https://tcezyirkglpihohuzrqo.supabase.co/storage/v1/object/public/perfiles/ChatGPT%20Image%20Jun%2030,%202026,%2004_07_25%20PM.png',
    productoId: '003',
  ),
  BannerModelo(
    titulo: 'Hecho en\nPanamá,',
    descripcion: 'Inspirado por nuentra cultura.',
    tituloEn: 'Made in\nPanama,',
    descripcionEn: 'Inspired by our culture.',
    imagenUrl:
        'https://tcezyirkglpihohuzrqo.supabase.co/storage/v1/object/public/perfiles/ChatGPT%20Image%20Jul%202,%202026,%2001_12_57%20PM.png',
    productoId: '003',
  ),
];

final List<ProductoModelo> mockProductos = [
  ProductoModelo(
    id: 'p1',
    nombre: 'Pollera panameña',
    precio: 45.00,
    imagenUrl:
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
    artesano: 'Ana Santos',
    provincia: 'Herrera',
    categoria: 'Textiles',
  ),
];

// Provincias y comarcas de Panamá
const List<String> provincias = [
  'Bocas del Toro',
  'Chiriquí',
  'Coclé',
  'Colón',
  'Darién',
  'Herrera',
  'Los Santos',
  'Panamá',
  'Panamá Oeste',
  'Veraguas',
];
const List<String> comarcas = [
  'Guna Yala',
  'Emberá-Wounaan',
  'Ngäbe-Buglé',
  'Guna de Madugandí',
  'Guna de Wargandí',
];
const List<String> categorias = [
  'Todos',
  'Vestir',
  'Artesanía',
  'Muebles',
  'Joyería',
  'Alimentos',
  'Accesorios',
  'Calzado',
];
// ──────────────────────────────────────────────────────────────────────────────

class HomeComprador extends StatefulWidget {
  final String userId;

  const HomeComprador({super.key, required this.userId});

  @override
  State<HomeComprador> createState() => _HomeCompradorState();
}

class _HomeCompradorState extends State<HomeComprador> {
  int _navIndice = 0;
  // Muestra el overlay del tour de bienvenida con Crafty la primera vez
  // que el usuario entra (o cuando lo relanza desde configuración).
  bool _mostrarTutorial = false;
  String _categoriaActiva = 'Todos';
  String? _provinciaActiva;
  bool _mostrarProvincias = false;

  final _busquedaCtrl = TextEditingController();

  List<ProductoModelo> _productos = [];
  bool _cargando = true;
  String? _error;
  List<ArtesanoModelo> _artesanos = [];

  // Preferencias guardadas por el usuario (pantalla de intereses): se usan
  // para que el catálogo muestre primero lo que coincide con lo que le gusta.
  Set<String> _categoriasPreferidas = {};
  Set<String> _regionesPreferidas = {};

  // ✅ NUEVO: datos del usuario logueado
  String _nombreUsuario = 'Usuario CraftHub';
  String _fotoUsuario = '';

  bool _tieneAnuncioSinLeer = false;

  @override
  void initState() {
    super.initState();
    _inicializarCarrito();
    _inicializarFavoritos();
    _cargarPreferenciasUsuario().then((_) => _cargarProductos());
    _cargarArtesanos();
    _cargarPerfilUsuario(); // ✅ NUEVO
    _revisarAnuncios();
    _revisarTutorialBienvenida();
  }

  Future<void> _revisarTutorialBienvenida() async {
    final yaVio = await ServicioTutorial.yaVioTutorial('comprador');
    if (!mounted || yaVio) return;
    setState(() => _mostrarTutorial = true);
  }

  Future<void> _cerrarTutorial() async {
    await ServicioTutorial.marcarComoVisto('comprador');
    if (!mounted) return;
    setState(() => _mostrarTutorial = false);
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

  // Contacto pendiente por abrir en la pestaña de Mensajes (llegó desde
  // "Enviar mensaje" en la lista o el perfil completo de un artesano). Se
  // consume una sola vez al construir esa pestaña, ver _obtenerPantallaActual.
  String? _chatContactoIdPendiente;
  String? _chatContactoNombrePendiente;

  void _abrirChatConArtesano(String? contactoId, String contactoNombre) {
    setState(() {
      _navIndice = 5;
      _tieneAnuncioSinLeer = false;
      _chatContactoIdPendiente = contactoId;
      _chatContactoNombrePendiente = contactoNombre;
    });
    if (widget.userId.isNotEmpty) {
      ApiService.marcarAnunciosLeidos(widget.userId);
    }
  }

  void _abrirMensajes() {
    setState(() {
      _navIndice = 5;
      _tieneAnuncioSinLeer = false;
    });
    if (widget.userId.isNotEmpty) {
      ApiService.marcarAnunciosLeidos(widget.userId);
    }
  }

  Future<void> _cargarPreferenciasUsuario() async {
    if (widget.userId.isEmpty) return;
    try {
      final data = await ApiService.getPreferencias(widget.userId);
      _categoriasPreferidas =
          (data['categorias'] as List<dynamic>? ?? []).map((e) => e.toString()).toSet();
      _regionesPreferidas = {
        ...(data['provincias'] as List<dynamic>? ?? []).map((e) => e.toString()),
        ...(data['comarcas'] as List<dynamic>? ?? []).map((e) => e.toString()),
      };
    } catch (e) {
      debugPrint('Error cargando preferencias: $e');
    }
  }

  // "Comarca Guna-Yala" (como se guarda desde la pantalla de intereses) debe
  // considerarse igual a "Guna Yala" (como aparece en productos/artesanos):
  // se quita el prefijo "comarca" y se normalizan guiones/mayúsculas.
  String _normalizarRegion(String s) {
    var t = s.trim().toLowerCase().replaceAll('-', ' ');
    if (t.startsWith('comarca ')) t = t.substring('comarca '.length);
    return t.trim();
  }

  bool _coincideCategoria(String preferida, String delProducto) {
    final a = preferida.trim().toLowerCase();
    final b = delProducto.trim().toLowerCase();
    if (a.isEmpty || b.isEmpty) return false;
    return a.contains(b) || b.contains(a);
  }

  // Pone primero (preservando el orden entre sí) los productos cuya
  // categoría o provincia coincide con las preferencias guardadas.
  List<ProductoModelo> _ordenarPorPreferencias(List<ProductoModelo> productos) {
    if (_categoriasPreferidas.isEmpty && _regionesPreferidas.isEmpty) {
      return productos;
    }
    final regionesNormalizadas = _regionesPreferidas.map(_normalizarRegion).toSet();
    final coinciden = <ProductoModelo>[];
    final resto = <ProductoModelo>[];
    for (final p in productos) {
      final coincideRegion = regionesNormalizadas.contains(_normalizarRegion(p.provincia));
      final coincideCategoria =
          _categoriasPreferidas.any((c) => _coincideCategoria(c, p.categoria));
      (coincideRegion || coincideCategoria ? coinciden : resto).add(p);
    }
    return [...coinciden, ...resto];
  }

  Future<void> _inicializarCarrito() async {
    try {
      await context.read<CarritoProvider>().inicializar(widget.userId);
      debugPrint('✅ Carrito inicializado para usuario: ${widget.userId}');
    } catch (e) {
      debugPrint('❌ Error inicializando carrito: $e');
    }
  }

  Future<void> _inicializarFavoritos() async {
    try {
      await context.read<FavoritosProvider>().inicializar(widget.userId);
    } catch (e) {
      debugPrint('❌ Error inicializando favoritos: $e');
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

  // ✅ NUEVO: carga nombre y foto reales del perfil. Si no hay userId
  // o falla la llamada, se queda con "Usuario CraftHub" / sin foto (UC).
  Future<void> _cargarPerfilUsuario() async {
    if (widget.userId.isEmpty) return;
    try {
      final perfil = await ApiService.getPerfil(widget.userId);
      if (!mounted) return;
      setState(() {
        final nombre = (perfil['nombre'] ?? '').toString().trim();
        _nombreUsuario = nombre.isEmpty ? 'Usuario CraftHub' : nombre;
        _fotoUsuario = (perfil['foto'] ?? '').toString();
      });
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
    }
  }

  Future<void> _verMiPerfil() async {
    if (widget.userId.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PantallaMiPerfilComprador(userId: widget.userId)),
    );
    _cargarPerfilUsuario();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final productos = await ApiService.getProductos(
        categoria: _categoriaActiva,
        busqueda: _busquedaCtrl.text,
      );
      setState(() => _productos = _ordenarPorPreferencias(productos));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cargarArtesanos() async {
    try {
      final artesanos = await ApiService.getArtesanos(limite: 30);
      setState(() => _artesanos = artesanos);
    } catch (e) {
      debugPrint('Error cargando artesanos: $e');
    }
  }

  // Conecta la tarjeta de "Artesanos destacados" con su perfil completo,
  // cargando sus productos reales desde GET /artesanos/{nombre}.
  Future<void> _abrirPerfilArtesano(ArtesanoModelo a) => abrirPerfilArtesano(context, a);

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
      body: Stack(
        children: [
          BotonFlotanteIA(
        userId: widget.userId,
        nombreUsuario: _nombreUsuario,
        child: Row(
          children: [
            // ✅ ACTUALIZADO: ahora pasa nombre y fotoUrl reales
            SidebarComprador(
              nombre: _nombreUsuario,
              fotoUrl: _fotoUsuario,
              indiceActivo: _navIndice,
              alSeleccionar: (i) => i == 5 ? _abrirMensajes() : setState(() => _navIndice = i),
              alCerrarSesion: () => _cerrarSesion(context),
              tieneNotificacionMensajes: _tieneAnuncioSinLeer,
              alTocarAvatar: _verMiPerfil,
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
      ),
          if (_mostrarTutorial)
            OverlayTutorialCrafty(
              rol: 'comprador',
              onCerrar: _cerrarTutorial,
              onIrASeccion: (i) => setState(() => _navIndice = i),
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
        return PantallaCarrito(alExplorarCatalogo: () => setState(() => _navIndice = 0));
      case 2:
        return ArtesanosScreen(onEnviarMensaje: _abrirChatConArtesano, userId: widget.userId);
      case 3:
        return PantallaFavoritos(userId: widget.userId);
      case 4:
        return PantallaTutorialesComprador(userId: widget.userId);
      case 5:
        // Se consume una sola vez: si el usuario vuelve a esta pestaña por
        // otro camino (sidebar), no debe reabrir el mismo contacto de nuevo.
        final contactoId = _chatContactoIdPendiente;
        final contactoNombre = _chatContactoNombrePendiente;
        _chatContactoIdPendiente = null;
        _chatContactoNombrePendiente = null;
        return PantallaMensajesComprador(
          userId: widget.userId,
          nombreComprador: _nombreUsuario,
          contactoIdInicial: contactoId,
          contactoNombreInicial: contactoNombre,
        );
      default:
        return _buildContenido(oscuro);
    }
  }

  Widget _buildTopBar(bool oscuro) {
    void abrirMapa() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => PantallaMapa(
            esOscuro: Theme.of(ctx).brightness == Brightness.dark,
          ),
        ),
      );
    }

    return TopbarFlotante(
      controladorBusqueda: _busquedaCtrl,
      alBuscar: (q) => _cargarProductos(),
      userId: widget.userId,
      mostrarExplorar: false,
      tieneNotificaciones: true,
      alPresionarUbicacion: abrirMapa,
      alPresionarLogo: () => setState(() => _navIndice = 0),
      alPresionarEventos: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaEventosComprador(userId: widget.userId),
        ),
      ),
    );
  }

  Widget _buildContenido(bool oscuro) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CarruselHero(
            banners: mockBanners,
            alVerMas: (id) {
              PantallaDetalleProducto.mostrar(
                context,
                productoId: id,
                userId: widget.userId,
              );
            },
          ),
          const SizedBox(height: 24),

          Text(
            tr(context, 'comprador_home.seccion_artesanos_destacados'),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: oscuro
                  ? CraftHubColors.textoOscuro
                  : CraftHubColors.textoClaro,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 104,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _artesanos.length,
              itemBuilder: (_, i) => _TarjetaArtesano(
                nombre: _artesanos[i].nombre,
                fotoUrl: _artesanos[i].fotoUrl,
                onTap: () => _abrirPerfilArtesano(_artesanos[i]),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            tr(context, 'comprador_home.seccion_explorar_categorias'),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: oscuro
                  ? CraftHubColors.textoOscuro
                  : CraftHubColors.textoClaro,
            ),
          ),
          const SizedBox(height: 12),
          _buildFiltros(oscuro),
          const SizedBox(height: 24),

          Text(
            tr(context, 'comprador_home.seccion_productos_artesanales'),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: oscuro
                  ? CraftHubColors.textoOscuro
                  : CraftHubColors.textoClaro,
            ),
          ),
          const SizedBox(height: 12),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  '${tr(context, 'comprador_home.error_cargando_productos')}: ${_error!}',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            )
          else if (_productos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text(tr(context, 'comprador_home.sin_productos'))),
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
                    PantallaDetalleProducto.mostrar(
                      context,
                      productoId: _productos[i].id,
                      productoPrevisualizado: _productos[i],
                      userId: widget.userId,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFiltros(bool oscuro) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...categorias.map(
          (cat) => _ChipCategoria(
            label: cat,
            activo: _categoriaActiva == cat,
            onTap: () {
              setState(() => _categoriaActiva = cat);
              _cargarProductos();
            },
          ),
        ),
        _ChipProvincias(
          provinciaSeleccionada: _provinciaActiva,
          onSeleccionar: (prov) {
            setState(() {
              _provinciaActiva = prov;
              _mostrarProvincias = false;
            });
            // 🔌 _cargarProductos()
          },
        ),
      ],
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────────────────────────

class _TarjetaArtesano extends StatefulWidget {
  final String nombre, fotoUrl;
  final VoidCallback onTap;
  const _TarjetaArtesano({
    required this.nombre,
    required this.fotoUrl,
    required this.onTap,
  });

  @override
  State<_TarjetaArtesano> createState() => _TarjetaArtesanoState();
}

class _TarjetaArtesanoState extends State<_TarjetaArtesano> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(right: 16),
          transform: _hover
              ? (Matrix4.identity()..scale(1.05))
              : Matrix4.identity(),
          child: Column(
            children: [
              Stack(
                children: [
                  // Anillo vino tinto alrededor de la foto (más grande que antes)
                  CircleAvatar(
                    radius: 33,
                    backgroundColor: CraftHubColors.vinoTinto,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color.fromARGB(255, 147, 10, 10),
                      backgroundImage: widget.fotoUrl.isNotEmpty
                          ? NetworkImage(widget.fotoUrl)
                          : null,
                      child: widget.fotoUrl.isEmpty
                          ? Text(
                              widget.nombre
                                  .trim()
                                  .split(' ')
                                  .take(2)
                                  .map((p) => p[0].toUpperCase())
                                  .join(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: CraftHubColors.vinoTinto,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                widget.nombre,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: CraftHubColors.textoPrincipal(
                    Theme.of(context).brightness == Brightness.dark,
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

class _ChipCategoria extends StatefulWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  const _ChipCategoria({
    required this.label,
    required this.activo,
    required this.onTap,
  });

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
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: activo
                ? CraftHubColors.vinoTinto
                : (_hover ? Colors.white : Colors.white),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: activo
                  ? CraftHubColors.vinoTinto
                  : (_hover
                        ? CraftHubColors.vinoTinto
                        : CraftHubColors.bordeClaro),
              width: 0.8,
            ),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: activo
                  ? Colors.white
                  : (_hover
                        ? CraftHubColors.vinoTinto
                        : const Color(0xFF5A4A42)),
              fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipProvincias extends StatefulWidget {
  final String? provinciaSeleccionada;
  final Function(String?) onSeleccionar;
  const _ChipProvincias({
    this.provinciaSeleccionada,
    required this.onSeleccionar,
  });

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
        PopupMenuItem(
          value: '__todos',
          child: Text(
            tr(context, 'comprador_home.filtro_todas'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          enabled: false,
          child: Text(
            tr(context, 'comprador_home.encabezado_provincias'),
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
        ),
        ...provincias.map(
          (p) => PopupMenuItem(
            value: p,
            child: Text(p, style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          enabled: false,
          child: Text(
            tr(context, 'comprador_home.encabezado_comarcas'),
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
        ),
        ...comarcas.map(
          (c) => PopupMenuItem(
            value: c,
            child: Text(c, style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F0),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: const Color(0xFFC9A84C), width: 0.9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 15,
              color: Color(0xFF7A5800),
            ),
            const SizedBox(width: 5),
            Text(
              widget.provinciaSeleccionada ?? tr(context, 'comprador_home.placeholder_provincias_comarcas'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF7A5800),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Color(0xFF7A5800),
            ),
          ],
        ),
      ),
    );
  }
}
