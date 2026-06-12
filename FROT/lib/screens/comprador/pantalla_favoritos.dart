import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/comprador/tarjeta_favorito.dart';
import '../../widgets/comprador/grid_masonry_favoritos.dart';
import '../../widgets/comprador/panel_lateral_favoritos.dart';
import '../../widgets/comprador/modal_artesanos_seguidos.dart';
import '../../widgets/comprador/barra_filtros_favoritos.dart';

/// ════════════════════════════════════════════════════════════
/// PantallaFavoritos — Pantalla "Mis Favoritos" del comprador
///
/// NOTAS DE INTEGRACIÓN CON API (FastAPI/Python):
/// ─────────────────────────────────────────────
/// • Cargar favoritos:    GET  /api/v1/favoritos/{usuarioId}
/// • Quitar favorito:     DELETE /api/v1/favoritos/{usuarioId}/{productoId}
/// • Carritos guardados:  GET  /api/v1/carritos/{usuarioId}
/// • Crear carrito:       POST /api/v1/carritos  → { nombre, usuarioId }
/// • Artesanos seguidos:  GET  /api/v1/artesanos/seguidos/{usuarioId}
///
/// Esta pantalla asume que el Sidebar y TopBar ya existen en el layout
/// padre (MainLayout). Solo renderiza el contenido interior del panel.
/// ════════════════════════════════════════════════════════════
class PantallaFavoritos extends StatefulWidget {
  const PantallaFavoritos({super.key});

  @override
  State<PantallaFavoritos> createState() => _PantallaFavoritosState();
}

class _PantallaFavoritosState extends State<PantallaFavoritos> {
  // ─── Datos de ejemplo (reemplazar con llamadas a la API) ───────────────────
  // 🔗 En initState, llamar al servicio: ServicioFavoritos.obtenerFavoritos(usuarioId)
  final List<ModeloFavorito> _favoritos = _generarFavoritosEjemplo();
  List<ModeloFavorito> _favoritosFiltrados = [];

  final List<ModeloCarritoGuardado> _carritos = _generarCarritosEjemplo();
  final List<ModeloArtesanoSeguido> _artesanosSeguidos =
      _generarArtesanosEjemplo();

  @override
  void initState() {
    super.initState();
    _favoritosFiltrados = _favoritos;
    // 🔗 API: Aquí cargar datos reales desde el servicio
    // _cargarFavoritos();
    // _cargarCarritos();
    // _cargarArtesanosSeguidos();
  }

  void _alCambiarFiltros(EstadoFiltrosFavoritos filtros) {
    // 🔗 API: GET /api/v1/favoritos/{usuarioId}?tipo={filtros.tipoSeleccionado}&...
    setState(() {
      // Lógica de filtrado local (reemplazar con respuesta del API)
      _favoritosFiltrados = _favoritos;
    });
  }

  void _abrirModalArtesanos() {
    mostrarModalArtesanosSeguidos(
      context: context,
      artesanos: _artesanosSeguidos,
    );
  }

  void _crearNuevoCarrito() {
    // 🔗 API: POST /api/v1/carritos → { nombre: "Mi carrito", usuarioId: X }
    _mostrarDialogoNombreCarrito();
  }

  void _mostrarDialogoNombreCarrito() {
    final controlador = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Nuevo carrito',
          style: TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controlador,
          autofocus: true,
          style: const TextStyle(fontFamily: 'Poppins'),
          decoration: InputDecoration(
            hintText: 'Nombre del carrito...',
            hintStyle: const TextStyle(fontFamily: 'Poppins'),
            filled: true,
            fillColor: const Color(0xFFF9F6F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controlador.text.trim().isNotEmpty) {
                Navigator.pop(context);
                // 🔗 API: POST /api/v1/carritos { nombre: controlador.text }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF821515),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Crear',
                style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esTemaOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondoPantalla =
        esTemaOscuro ? const Color(0xFF121212) : const Color(0xFFF9F6F0);

    return Container(
      color: colorFondoPantalla,
      // ── Layout principal: columna fija sin scroll externo ───────────────
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: _EncabezadoFavoritos(
              totalFavoritos: _favoritosFiltrados.length,
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.03),
          ),

          const SizedBox(height: 18),

          // ── Filtros ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: BarraFiltrosFavoritos(
              alCambiarFiltros: _alCambiarFiltros,
            ).animate().fadeIn(delay: 100.ms),
          ),

          const SizedBox(height: 18),

          // ── Cuerpo principal (Masonry + Panel lateral) ─────────────────
          // 🎯 Expanded para que ocupe el espacio restante sin scroll externo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Grid Masonry (con scroll interno propio) ────────────
                  Expanded(
                    flex: 3,
                    child: _favoritosFiltrados.isEmpty
                        ? _EstadoVacioFavoritos(esTemaOscuro: esTemaOscuro)
                        : GridMasonryFavoritos(
                            productos: _favoritosFiltrados,
                            alQuitarFavorito: () {},
                          ),
                  ),

                  const SizedBox(width: 20),

                  // ── Panel lateral con scroll interno propio ─────────────
                  SizedBox(
                    width: 280,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: PanelLateralFavoritos(
                        carritos: _carritos,
                        artesanosSeguidos: _artesanosSeguidos,
                        alCrearNuevoCarrito: _crearNuevoCarrito,
                        alVerTodosLosArtesanos: _abrirModalArtesanos,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Encabezado de la pantalla ──────────────────────────────────────────────
class _EncabezadoFavoritos extends StatelessWidget {
  final int totalFavoritos;

  const _EncabezadoFavoritos({required this.totalFavoritos});

  @override
  Widget build(BuildContext context) {
    final esTemaOscuro = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Mis favoritos',
              style: TextStyle(
                fontFamily: 'RocaTwo',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.favorite,
                color: Color(0xFF821515), size: 24),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Productos y artesanos que te han encantado.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: esTemaOscuro ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

/// ── Estado vacío cuando no hay favoritos ──────────────────────────────────
class _EstadoVacioFavoritos extends StatelessWidget {
  final bool esTemaOscuro;

  const _EstadoVacioFavoritos({required this.esTemaOscuro});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 64,
            color: esTemaOscuro ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes favoritos aún',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: esTemaOscuro ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explora el catálogo y guarda los productos\nque más te gusten.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: esTemaOscuro ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // 🔗 Navegar al catálogo → Navigator.pushNamed(context, '/catalogo')
            },
            icon: const Icon(Icons.store_rounded, size: 18),
            label: const Text(
              'Explorar catálogo',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF821515),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }
}

// ── Datos de ejemplo ─────────────────────────────────────────────────────────
// 🔗 Reemplazar con llamadas reales a la API

List<ModeloFavorito> _generarFavoritosEjemplo() => [
      const ModeloFavorito(
        id: '1',
        nombreProducto: 'Bolso tejido tradicional',
        nombreArtesano: 'Rosa Martínez',
        provincia: 'Chiriquí',
        precio: 45.00,
        rutaImagen: 'assets/images/productos/bolso_tejido.jpg',
      ),
      const ModeloFavorito(
        id: '2',
        nombreProducto: 'Sombrero Pintao',
        nombreArtesano: 'Carlos Ruiz',
        provincia: 'Los Santos',
        precio: 100.00,
        rutaImagen: 'assets/images/productos/sombrero_pintao.jpg',
      ),
      const ModeloFavorito(
        id: '3',
        nombreProducto: 'Mola Guna Yala',
        nombreArtesano: 'Ana Santos',
        provincia: 'Guna Yala',
        precio: 85.00,
        rutaImagen: 'assets/images/productos/mola_guna.jpg',
      ),
      const ModeloFavorito(
        id: '4',
        nombreProducto: 'Aretes de filigrana',
        nombreArtesano: 'Elena García',
        provincia: 'Herrera',
        precio: 28.00,
        rutaImagen: 'assets/images/productos/aretes_filigrana.jpg',
      ),
      const ModeloFavorito(
        id: '5',
        nombreProducto: 'Jarrón de cerámica',
        nombreArtesano: 'Miguel Torres',
        provincia: 'Coclé',
        precio: 32.00,
        rutaImagen: 'assets/images/productos/jarron_ceramica.jpg',
      ),
      const ModeloFavorito(
        id: '6',
        nombreProducto: 'Máscara tradicional',
        nombreArtesano: 'José Morales',
        provincia: 'Colón',
        precio: 75.00,
        rutaImagen: 'assets/images/productos/mascara_tradicional.jpg',
      ),
      const ModeloFavorito(
        id: '7',
        nombreProducto: 'Collar de semillas',
        nombreArtesano: 'Lucía Pérez',
        provincia: 'Darién',
        precio: 36.00,
        rutaImagen: 'assets/images/productos/collar_semillas.jpg',
      ),
      const ModeloFavorito(
        id: '8',
        nombreProducto: 'Canasta artesanal',
        nombreArtesano: 'Pedro Díaz',
        provincia: 'Veraguas',
        precio: 40.00,
        rutaImagen: 'assets/images/productos/canasta_artesanal.jpg',
      ),
      const ModeloFavorito(
        id: '9',
        nombreProducto: 'Camino de mesa tejido',
        nombreArtesano: 'Rosa Martínez',
        provincia: 'Panamá Oeste',
        precio: 26.00,
        rutaImagen: 'assets/images/productos/camino_mesa.jpg',
      ),
    ];

List<ModeloCarritoGuardado> _generarCarritosEjemplo() => [
      const ModeloCarritoGuardado(
        id: 'c1',
        nombre: 'Regalos de Navidad',
        cantidadProductos: 4,
        totalEstimado: 185.00,
        rutaImagenPortada: 'assets/images/productos/bolso_tejido.jpg',
      ),
      const ModeloCarritoGuardado(
        id: 'c2',
        nombre: 'Para la oficina',
        cantidadProductos: 2,
        totalEstimado: 68.00,
        rutaImagenPortada: 'assets/images/productos/jarron_ceramica.jpg',
      ),
      const ModeloCarritoGuardado(
        id: 'c3',
        nombre: 'Souvenirs',
        cantidadProductos: 6,
        totalEstimado: 246.00,
        rutaImagenPortada: 'assets/images/productos/mola_guna.jpg',
      ),
    ];

List<ModeloArtesanoSeguido> _generarArtesanosEjemplo() => [
      const ModeloArtesanoSeguido(
        id: 'a1',
        nombre: 'Rosa Martínez',
        rutaFoto: 'assets/images/artesanos/rosa.jpg',
        provincia: 'Chiriquí',
        categoria: 'Textiles',
        totalProductos: 24,
        calificacion: 4.9,
      ),
      const ModeloArtesanoSeguido(
        id: 'a2',
        nombre: 'Carlos Ruiz',
        rutaFoto: 'assets/images/artesanos/carlos.jpg',
        provincia: 'Los Santos',
        categoria: 'Sombreros',
        totalProductos: 12,
        calificacion: 4.8,
      ),
      const ModeloArtesanoSeguido(
        id: 'a3',
        nombre: 'Ana Santos',
        rutaFoto: 'assets/images/artesanos/ana.jpg',
        provincia: 'Guna Yala',
        categoria: 'Molas',
        totalProductos: 38,
        calificacion: 5.0,
      ),
      const ModeloArtesanoSeguido(
        id: 'a4',
        nombre: 'Miguel Torres',
        rutaFoto: 'assets/images/artesanos/miguel.jpg',
        provincia: 'Coclé',
        categoria: 'Cerámica',
        totalProductos: 19,
        calificacion: 4.7,
      ),
      const ModeloArtesanoSeguido(
        id: 'a5',
        nombre: 'Elena García',
        rutaFoto: 'assets/images/artesanos/elena.jpg',
        provincia: 'Herrera',
        categoria: 'Joyería',
        totalProductos: 31,
        calificacion: 4.9,
      ),
      const ModeloArtesanoSeguido(
        id: 'a6',
        nombre: 'José Morales',
        rutaFoto: 'assets/images/artesanos/jose.jpg',
        provincia: 'Colón',
        categoria: 'Máscaras',
        totalProductos: 8,
        calificacion: 4.6,
      ),
    ];