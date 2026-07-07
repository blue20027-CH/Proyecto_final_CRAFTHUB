import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/comprador/tarjeta_producto_perfil.dart';
import '../../widgets/comprador/selector_coleccion.dart';
import '../../services/api_service.dart';

// Modelo de datos del artesano
// TODO: reemplazar con tu modelo real desde FastAPI
class ModeloArtesano {
  final String nombre;
  final String specialty; // Cambiado internamente si es necesario o manteniendo la interfaz
  final String especialidad;
  final String ubicacion;
  final String fotoUrl;
  final String bannerUrl;
  final double calificacion;
  final int totalResenas;
  final bool verificado;
  final int totalProductos;
  final int anosEnCraftHub;
  final int valoracionesPositivas;
  final int ventasRealizadas;
  final String descripcion;
  final List<String> etiquetas;
  final List<String> colecciones;
  final List<ModeloProductoResumen> productos;

  const ModeloArtesano({
    required this.nombre,
    required this.specialty,
    required this.especialidad,
    required this.ubicacion,
    required this.fotoUrl,
    required this.bannerUrl,
    required this.calificacion,
    required this.totalResenas,
    required this.verificado,
    required this.totalProductos,
    required this.anosEnCraftHub,
    required this.valoracionesPositivas,
    required this.ventasRealizadas,
    required this.descripcion,
    required this.etiquetas,
    required this.colecciones,
    required this.productos,
  });
}

class ModeloProductoResumen {
  final String id;
  final String nombre;
  final String precio;
  final String imagenUrl;
  final String coleccion;

  const ModeloProductoResumen({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.imagenUrl,
    required this.coleccion,
  });

  // Mapea el producto crudo que devuelve GET /artesanos/{nombre} (campo "productos").
  factory ModeloProductoResumen.fromJson(Map<String, dynamic> json) {
    final precio = double.tryParse((json['precio'] ?? 0).toString()) ?? 0;
    return ModeloProductoResumen(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      precio: '\$${precio.toStringAsFixed(2)}',
      imagenUrl: (json['imagen_url'] ?? json['imagen'] ?? json['img'] ?? '').toString(),
      coleccion: (json['categoria'] ?? 'General').toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────────────────────
class PantallaPerfilArtesano extends StatefulWidget {
  final ModeloArtesano artesano;
  // Cuando es tu propio perfil (te lo abrió el sidebar del vendedor), se ve
  // exactamente igual a como lo ve un comprador, pero con un botón de
  // "Editar perfil" en vez de "Enviar mensaje"/"Seguir".
  final bool esPropio;
  final VoidCallback? onEditar;

  const PantallaPerfilArtesano({
    super.key,
    required this.artesano,
    this.esPropio = false,
    this.onEditar,
  });

  @override
  State<PantallaPerfilArtesano> createState() => _PantallaPerfilArtesanoState();
}

class _PantallaPerfilArtesanoState extends State<PantallaPerfilArtesano> {
  String? _coleccionSeleccionada;
  final Set<String> _favoritos = {};

  @override
  void initState() {
    super.initState();
    // Cuenta como una visita real al perfil (dashboard del vendedor).
    ApiService.registrarVisitaPerfil(widget.artesano.nombre);
  }

  List<ModeloProductoResumen> get _productosFiltrados {
    if (_coleccionSeleccionada == null) return widget.artesano.productos;
    return widget.artesano.productos
        .where((p) => p.coleccion == _coleccionSeleccionada)
        .toList();
  }

  String get _tituloProductos {
    final nombre = widget.artesano.nombre.split(' ').first;
    if (_coleccionSeleccionada == null) return 'Productos de $nombre';
    return _coleccionSeleccionada!;
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.artesano;

    return Scaffold(
      backgroundColor: CraftHubColors.fondoClaro,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── BANNER + INFO SUPERIOR ──────────────────────────────────
            _SeccionBanner(
              artesano: a,
              onVolver: () => Navigator.maybePop(context),
              esPropio: widget.esPropio,
              onEditar: widget.onEditar,
            ),

            // ── CUERPO: stats + contenido ───────────────────────────────
            _SeccionEstadisticas(artesano: a),

            // ── CONTENIDO PRINCIPAL ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel izquierdo: descripción + delivery
                  SizedBox(
                    width: 260,
                    child: _PanelIzquierdo(artesano: a),
                  ),
                  const SizedBox(width: 32), 
                  // Panel derecho: grid de productos
                  Expanded(
                    child: _PanelProductos(
                      tituloProductos: _tituloProductos,
                      totalProductos: _productosFiltrados.length,
                      colecciones: a.colecciones,
                      coleccionSeleccionada: _coleccionSeleccionada,
                      productos: _productosFiltrados,
                      favoritos: _favoritos,
                      alSeleccionarColeccion: (c) =>
                          setState(() => _coleccionSeleccionada = c),
                      alToggleFavorito: (id) => setState(() {
                        _favoritos.contains(id)
                            ? _favoritos.remove(id)
                            : _favoritos.add(id);
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECCIÓN BANNER
// ─────────────────────────────────────────────────────────────
class _SeccionBanner extends StatelessWidget {
  final ModeloArtesano artesano;
  final VoidCallback onVolver;
  final bool esPropio;
  final VoidCallback? onEditar;

  const _SeccionBanner({
    required this.artesano,
    required this.onVolver,
    this.esPropio = false,
    this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner de fondo
          Positioned.fill(
            child: Image.network(
              artesano.bannerUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: CraftHubColors.vinoTinto.withValues(alpha: 0.15),
              ),
            ),
          ),

          // Velo oscuro sutil
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Botón volver arriba izquierda
          Positioned(
            top: 20,
            left: 24,
            child: _BotonVolver(onVolver: onVolver),
          ),

          // Contenedor blanco flotante informativo
          Positioned(
            bottom: -40,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Avatar circular con borde de verificación integrado corregido
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                artesano.fotoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: CraftHubColors.bordeClaro,
                                  child: const Icon(
                                    Icons.person, 
                                    size: 40,
                                    color: CraftHubColors.textoSecClaro,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (artesano.verificado)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD4A843), // Dorado
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 12, 
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Nombre + Especialidad + Ubicación + Reseñas
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            artesano.nombre,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: CraftHubColors.textoClaro,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            artesano.especialidad,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: CraftHubColors.textoSecClaro,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(artesano.ubicacion, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                              const SizedBox(width: 16),
                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD4A843)),
                              const SizedBox(width: 4),
                              Text(
                                '${artesano.calificacion} (${artesano.totalResenas} reseñas)',
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Botones de acción alineados a la derecha
                  Row(
                    children: esPropio
                        ? [
                            _BotonAccion(
                              texto: 'Editar perfil',
                              icono: Icons.edit_outlined,
                              esPrimario: true,
                              alPresionar: onEditar ?? () {},
                            ),
                          ]
                        : [
                            _BotonAccion(
                              texto: 'Enviar mensaje',
                              icono: Icons.chat_bubble_outline_rounded,
                              esPrimario: true,
                              alPresionar: () {},
                            ),
                            const SizedBox(width: 12),
                            _BotonAccion(
                              texto: 'Seguir artesana',
                              icono: Icons.favorite_border_rounded,
                              esPrimario: false,
                              alPresionar: () {},
                            ),
                          ],
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

// ─────────────────────────────────────────────────────────────
// BOTÓN VOLVER
// ─────────────────────────────────────────────────────────────
class _BotonVolver extends StatefulWidget {
  final VoidCallback onVolver;
  const _BotonVolver({required this.onVolver});

  @override
  State<_BotonVolver> createState() => _BotonVolverState();
}

class _BotonVolverState extends State<_BotonVolver> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit:  (_) => setState(() => _sobre = false), // Corregido typo (_false = false)
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onVolver,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _sobre
                ? Colors.white.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded, size: 16, color: CraftHubColors.textoClaro),
              SizedBox(width: 6),
              Text(
                'Volver',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CraftHubColors.textoClaro,
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
// BOTÓN ACCIÓN (Enviar mensaje / Seguir)
// ─────────────────────────────────────────────────────────────
class _BotonAccion extends StatefulWidget {
  final String texto;
  final IconData icono;
  final bool esPrimario;
  final VoidCallback alPresionar;

  const _BotonAccion({
    required this.texto,
    required this.icono,
    required this.esPrimario,
    required this.alPresionar,
  });

  @override
  State<_BotonAccion> createState() => _BotonAccionState();
}

class _BotonAccionState extends State<_BotonAccion> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    final colorFondo = widget.esPrimario
        ? (_sobre ? CraftHubColors.vinoTintoOscuro : CraftHubColors.vinoTinto)
        : (_sobre ? Colors.grey[50] : Colors.white);
    final colorTexto = widget.esPrimario ? Colors.white : CraftHubColors.textoClaro;
    final colorBorde = widget.esPrimario ? Colors.transparent : CraftHubColors.bordeClaro;

    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit:  (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 160, 
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: colorFondo,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorBorde, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icono, size: 15, color: colorTexto),
              const SizedBox(width: 6),
              Text(
                widget.texto,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorTexto,
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
// SECCIÓN ESTADÍSTICAS
// ─────────────────────────────────────────────────────────────
class _SeccionEstadisticas extends StatelessWidget {
  final ModeloArtesano artesano;
  const _SeccionEstadisticas({required this.artesano});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(44, 60, 44, 20), 
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        // Corregido: border debe estar contenido obligatoriamente dentro de un BoxDecoration
        border: Border(
          bottom: BorderSide(color: CraftHubColors.bordeClaro, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, 
        children: [
          _StatNumerico(
              icono: Icons.inventory_2_outlined,
              valor: '${artesano.totalProductos}',
              etiqueta: 'Productos'),
          const SizedBox(width: 48),
          _StatNumerico(
              icono: Icons.calendar_today_outlined,
              valor: '${artesano.anosEnCraftHub} años',
              etiqueta: 'En CraftHub'),
          const SizedBox(width: 48),
          _StatNumerico(
              icono: Icons.thumb_up_alt_outlined,
              valor: '${artesano.valoracionesPositivas}%',
              etiqueta: 'Valoraciones positivas'),
          const SizedBox(width: 48),
          _StatNumerico(
              icono: Icons.shopping_bag_outlined,
              valor: '${artesano.ventasRealizadas}',
              etiqueta: 'Ventas realizadas'),
        ],
      ),
    );
  }
}

class _StatNumerico extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;

  const _StatNumerico({
    required this.icono,
    required this.valor,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icono, size: 20, color: CraftHubColors.textoSecClaro.withValues(alpha: 0.7)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              valor,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: CraftHubColors.textoClaro,
              ),
            ),
            Text(
              etiqueta,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: CraftHubColors.textoSecClaro,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PANEL IZQUIERDO
// ─────────────────────────────────────────────────────────────
class _PanelIzquierdo extends StatelessWidget {
  final ModeloArtesano artesano;
  const _PanelIzquierdo({required this.artesano});

  @override
  Widget build(BuildContext context) {
    final primerNombre = artesano.nombre.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sobre $primerNombre',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CraftHubColors.textoClaro,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          artesano.descripcion,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            height: 1.6,
            color: CraftHubColors.textoSecClaro,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: artesano.etiquetas
              .map((e) => _EtiquetaChip(texto: e))
              .toList(),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF6F0), 
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.local_shipping_outlined, size: 18, color: CraftHubColors.vinoTinto),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Envíos a todo Panamá',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CraftHubColors.textoClaro,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Entregas rápidas y seguras a cualquier provincia.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: CraftHubColors.textoSecClaro,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EtiquetaChip extends StatelessWidget {
  final String texto;
  const _EtiquetaChip({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFEA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: CraftHubColors.textoClaro,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PANEL PRODUCTOS
// ─────────────────────────────────────────────────────────────
class _PanelProductos extends StatelessWidget {
  final String tituloProductos;
  final int totalProductos;
  final List<String> colecciones;
  final String? coleccionSeleccionada;
  final List<ModeloProductoResumen> productos;
  final Set<String> favoritos;
  final ValueChanged<String?> alSeleccionarColeccion;
  final ValueChanged<String> alToggleFavorito;

  const _PanelProductos({
    required this.tituloProductos,
    required this.totalProductos,
    required this.colecciones,
    required this.coleccionSeleccionada,
    required this.productos,
    required this.favoritos,
    required this.alSeleccionarColeccion,
    required this.alToggleFavorito,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              tituloProductos,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: CraftHubColors.textoClaro,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EFEA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalProductos productos',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: CraftHubColors.textoSecClaro,
                ),
              ),
            ),
            const Spacer(),
            SelectorColeccion(
              colecciones: colecciones,
              coleccionSeleccionada: coleccionSeleccionada,
              alSeleccionar: alSeleccionarColeccion,
            ),
          ],
        ),
        const SizedBox(height: 20),

        productos.isEmpty
            ? const SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'No hay productos en esta colección.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: CraftHubColors.textoSecClaro,
                    ),
                  ),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.82, 
                ),
                itemCount: productos.length,
                itemBuilder: (_, i) {
                  final p = productos[i];
                  return TarjetaProductoPerfil(
                    imagenUrl: p.imagenUrl,
                    nombre: p.nombre,
                    precio: p.precio,
                    esFavorito: favoritos.contains(p.id),
                    alToggleFavorito: () => alToggleFavorito(p.id),
                    alPresionar: () {},
                  );
                },
              ),
      ],
    );
  }
}