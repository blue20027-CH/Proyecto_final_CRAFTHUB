import 'dart:typed_data';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/carrito_provider.dart';
import '../../core/favoritos_provider.dart';
import '../../models/detalle_producto_model.dart';
import '../../services/api_service.dart';
import '../../widgets/comprador/tarjeta_producto.dart';
import 'pantalla_pago.dart';
import '../../core/i18n/i18n.dart';

// ──────────────────────────────────────────────────────────────────────────
// PANTALLA DETALLE DE PRODUCTO
// Se muestra como panel modal flotante sobre la pantalla de origen
// (inicio_comprador, favoritos, perfil de artesano, etc.)
// 🔌 Backend: GET /productos/{id}, GET /productos/{id}/similares,
//    GET /productos/{id}/comentarios, POST/DELETE /productos/favoritos,
//    POST /api/carrito/agregar (ya integrado vía CarritoProvider).
// ──────────────────────────────────────────────────────────────────────────
class PantallaDetalleProducto extends StatefulWidget {
  final String productoId;
  final ProductoModelo? productoPrevisualizado;
  final String userId;

  const PantallaDetalleProducto({
    super.key,
    required this.productoId,
    this.productoPrevisualizado,
    this.userId = '',
  });

  /// Abre el detalle como panel modal flotante centrado, con fondo
  /// difuminado, sobre la pantalla actual. [productoPrevisualizado] permite
  /// pintar datos ya conocidos (nombre, imagen, precio) al instante mientras
  /// se completa la carga del detalle completo desde el backend.
  static Future<void> mostrar(
    BuildContext context, {
    required String productoId,
    ProductoModelo? productoPrevisualizado,
    String userId = '',
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: tr(context, 'comprador_secundario.cerrar_detalle_producto'),
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) => PantallaDetalleProducto(
        productoId: productoId,
        productoPrevisualizado: productoPrevisualizado,
        userId: userId,
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 6 * animation.value,
            sigmaY: 6 * animation.value,
          ),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.96, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<PantallaDetalleProducto> createState() => _PantallaDetalleProductoState();
}

class _PantallaDetalleProductoState extends State<PantallaDetalleProducto> {
  ProductoDetalleModelo? _detalle;
  List<ProductoSimilarModelo> _similares = [];
  List<ComentarioModelo> _comentarios = [];

  bool _cargando = true;
  String? _error;
  bool _agregandoAlCarrito = false;
  bool _comprandoAhora = false;
  String _ordenComentarios = 'Más recientes';
  String? _mensajeToast;

  // null = aún no se conoce; true = imagen horizontal; false = vertical.
  bool? _imagenEsAncha;
  String _ultimaUrlImagenResuelta = '';

  @override
  void initState() {
    super.initState();
    final previa = widget.productoPrevisualizado;
    if (previa != null) {
      _detalle = ProductoDetalleModelo.previsualizacion(previa);
      _cargando = false;
      _resolverProporcionImagen(previa.imagenUrl);
    }
    _cargarDetalle();
    _cargarSimilares();
    _cargarComentarios();
  }

  // Detecta si la imagen principal es horizontal o vertical para adaptar su
  // tamaño en el layout (la imagen es el elemento protagonista de la pantalla).
  void _resolverProporcionImagen(String url) {
    if (url.isEmpty || url == _ultimaUrlImagenResuelta) return;
    _ultimaUrlImagenResuelta = url;
    final stream = NetworkImage(url).resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      final ancha = info.image.width >= info.image.height;
      if (mounted) setState(() => _imagenEsAncha = ancha);
      stream.removeListener(listener);
    }, onError: (error, stackTrace) {
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }

  Future<void> _cargarDetalle() async {
    if (_detalle == null) setState(() { _cargando = true; _error = null; });
    try {
      final data = await ApiService.getDetalleProducto(widget.productoId);
      final detalle = ProductoDetalleModelo.fromJson(data);
      if (!mounted) return;
      setState(() {
        _detalle = detalle;
        _cargando = false;
        _error = null;
      });
      _resolverProporcionImagen(detalle.imagenUrl);
    } catch (e) {
      debugPrint('Endpoint GET /productos/{id} no disponible aún: $e');
      // 🔌 Respaldo temporal mientras el backend expone /productos/{id}:
      // se busca el producto dentro del listado general ya existente
      // (GET /productos/) para no dejar la pantalla sin datos.
      if (_detalle == null) {
        try {
          final productos = await ApiService.getProductos();
          ProductoModelo? coincidencia;
          for (final p in productos) {
            if (p.id == widget.productoId) { coincidencia = p; break; }
          }
          final encontrado = coincidencia;
          if (encontrado != null) {
            if (!mounted) return;
            setState(() {
              _detalle = ProductoDetalleModelo.previsualizacion(encontrado);
              _cargando = false;
            });
            _resolverProporcionImagen(encontrado.imagenUrl);
            return;
          }
        } catch (e2) {
          debugPrint('Respaldo por listado general también falló: $e2');
        }
        if (!mounted) return;
        setState(() {
          _error = tr(context, 'comprador_secundario.error_cargar_producto');
          _cargando = false;
        });
      } else {
        if (mounted) setState(() => _cargando = false);
      }
    }
  }

  Future<void> _cargarSimilares() async {
    try {
      final data = await ApiService.getProductosSimilares(widget.productoId);
      final lista = data.map((e) => ProductoSimilarModelo.fromJson(e)).toList();
      if (mounted) setState(() => _similares = lista);
    } catch (e) {
      debugPrint('Endpoint de similares no disponible, usando respaldo: $e');
      // 🔌 Respaldo temporal mientras el backend expone /productos/{id}/similares
      try {
        final productos = await ApiService.getProductos(categoria: _detalle?.categoria);
        final lista = productos
            .where((p) => p.id != widget.productoId)
            .take(8)
            .map((p) => ProductoSimilarModelo.desdeProducto(p))
            .toList();
        if (mounted) setState(() => _similares = lista);
      } catch (e2) {
        debugPrint('Respaldo de similares falló: $e2');
      }
    }
  }

  Future<void> _cargarComentarios() async {
    try {
      final data = await ApiService.getComentariosProducto(widget.productoId);
      final lista = data.map((e) => ComentarioModelo.fromJson(e)).toList();
      if (mounted) setState(() => _comentarios = lista);
    } catch (e) {
      debugPrint('Comentarios no disponibles aún: $e');
    }
  }

  // Publica un nuevo comentario del comprador: sube la foto adjunta (si hay),
  // inserta el comentario de forma optimista para feedback inmediato y luego
  // lo envía al backend. Si falla, retira el comentario optimista.
  Future<bool> _publicarComentario(
    String texto,
    double calificacion,
    Uint8List? fotoBytes,
    String? fotoNombre,
  ) async {
    String? fotoUrl;
    if (fotoBytes != null && fotoNombre != null) {
      try {
        fotoUrl = await ApiService.subirFotoComentario(fotoBytes, fotoNombre);
      } catch (e) {
        debugPrint('Foto de comentario no disponible aún (endpoint pendiente): $e');
      }
    }

    final optimista = ComentarioModelo(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      autor: tr(context, 'comprador_secundario.autor_tu'),
      avatarUrl: '',
      fecha: tr(context, 'comprador_secundario.fecha_ahora'),
      calificacion: calificacion,
      texto: texto,
      fotoUrl: fotoUrl ?? '',
    );
    if (mounted) setState(() => _comentarios = [optimista, ..._comentarios]);

    try {
      await ApiService.publicarComentario(
        productoId: widget.productoId,
        texto: texto,
        calificacion: calificacion,
        userId: widget.userId,
        fotoUrl: fotoUrl,
      );
      _mostrarToast(tr(context, 'comprador_secundario.comentario_publicado'));
      return true;
    } catch (e) {
      debugPrint('Error publicando comentario: $e');
      if (mounted) {
        setState(() => _comentarios = _comentarios.where((c) => c.id != optimista.id).toList());
      }
      _mostrarToast(tr(context, 'comprador_secundario.error_publicar_comentario'));
      return false;
    }
  }

  void _alternarFavorito() {
    final detalle = _detalle;
    if (detalle == null) return;
    context.read<FavoritosProvider>().alternarProducto(
          ProductoModelo(
            id: detalle.id,
            nombre: detalle.nombre,
            precio: detalle.precio,
            imagenUrl: detalle.imagenUrl,
            artesano: detalle.creador,
            provincia: detalle.ubicacion,
            categoria: detalle.categoria,
          ),
        );
  }

  Future<void> _agregarAlCarrito() async {
    if (_detalle == null || _agregandoAlCarrito) return;
    if (widget.userId.isEmpty) {
      _mostrarToast(tr(context, 'comprador_secundario.inicia_sesion_agregar_carrito'));
      return;
    }
    setState(() => _agregandoAlCarrito = true);
    try {
      await context.read<CarritoProvider>().agregarItem(
            productoId: int.tryParse(_detalle!.id) ?? 0,
            nombreProducto: _detalle!.nombre,
            precio: _detalle!.precio,
            imagenUrl: _detalle!.imagenUrl,
            artesano: _detalle!.creador,
          );
      _mostrarToast(tr(context, 'comprador_secundario.anadido_al_carrito'));
    } catch (e) {
      debugPrint('Error agregando al carrito: $e');
      _mostrarToast(tr(context, 'comprador_secundario.error_anadir_carrito'));
    } finally {
      if (mounted) setState(() => _agregandoAlCarrito = false);
    }
  }

  // Añade el producto al carrito y lleva directo a la pasarela de pago,
  // sin pasar por la pantalla de carrito. No se puede comprar sin sesión.
  Future<void> _comprarAhora() async {
    if (_detalle == null || _comprandoAhora) return;
    if (widget.userId.isEmpty) {
      _mostrarToast(tr(context, 'comprador_secundario.inicia_sesion_comprar_producto'));
      return;
    }
    setState(() => _comprandoAhora = true);
    try {
      await context.read<CarritoProvider>().agregarItem(
            productoId: int.tryParse(_detalle!.id) ?? 0,
            nombreProducto: _detalle!.nombre,
            precio: _detalle!.precio,
            imagenUrl: _detalle!.imagenUrl,
            artesano: _detalle!.creador,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PantallaPago(userId: widget.userId)),
      );
    } catch (e) {
      debugPrint('Error en compra directa: $e');
      _mostrarToast(tr(context, 'comprador_secundario.error_procesar_compra'));
    } finally {
      if (mounted) setState(() => _comprandoAhora = false);
    }
  }

  void _mostrarToast(String mensaje) {
    setState(() => _mensajeToast = mensaje);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _mensajeToast == mensaje) setState(() => _mensajeToast = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final tamano = MediaQuery.of(context).size;
    final anchoCard = tamano.width > 1280 ? 1180.0 : tamano.width * 0.94;
    final altoCard = (tamano.height * 0.92).clamp(420.0, 880.0);

    return Center(
      child: SizedBox(
        width: anchoCard,
        height: altoCard,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: CraftHubColors.fondo(oscuro),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(child: _buildCuerpo(oscuro)),
                Positioned(top: 16, left: 16, child: _BotonCerrar(oscuro: oscuro)),
                if (_mensajeToast != null)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(child: _Toast(texto: _mensajeToast!)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCuerpo(bool oscuro) {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: CraftHubColors.vinoTinto),
      );
    }
    if (_error != null && _detalle == null) {
      return _EstadoError(oscuro: oscuro, mensaje: _error!, onReintentar: _cargarDetalle);
    }

    final detalle = _detalle!;
    final favorito = context.watch<FavoritosProvider>().esProductoFavorito(detalle.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 880;
          return compacto
              ? _layoutCompacto(oscuro, detalle, favorito)
              : _layoutAmplio(oscuro, detalle, favorito);
        },
      ),
    );
  }

  // ── LAYOUT ESCRITORIO / TABLET GRANDE (imagen + info | panel similares) ──
  Widget _layoutAmplio(bool oscuro, ProductoDetalleModelo detalle, bool favorito) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // La imagen es el elemento protagonista: se ensancha si es
                    // horizontal y crece en altura si es vertical.
                    Expanded(
                      flex: _imagenEsAncha == true ? 7 : 6,
                      child: _SeccionImagen(
                        imagenUrl: detalle.imagenUrl,
                        favorito: favorito,
                        onToggleFavorito: _alternarFavorito,
                        altura: _imagenEsAncha == false ? 620 : 560,
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: _imagenEsAncha == true ? 4 : 5,
                      child: _PanelInformacion(
                        detalle: detalle,
                        oscuro: oscuro,
                        agregandoAlCarrito: _agregandoAlCarrito,
                        comprandoAhora: _comprandoAhora,
                        favorito: favorito,
                        estaLogueado: widget.userId.isNotEmpty,
                        onAgregarAlCarrito: _agregarAlCarrito,
                        onComprarAhora: _comprarAhora,
                        onToggleFavorito: _alternarFavorito,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SeccionComentarios(
                  oscuro: oscuro,
                  comentarios: _comentarios,
                  orden: _ordenComentarios,
                  estaLogueado: widget.userId.isNotEmpty,
                  onCambiarOrden: (v) => setState(() => _ordenComentarios = v),
                  onPublicar: _publicarComentario,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 300,
          child: _PanelSimilares(oscuro: oscuro, similares: _similares, userId: widget.userId),
        ),
      ],
    );
  }

  // ── LAYOUT MÓVIL / TABLET ANGOSTO (todo apilado, similares en fila) ──
  Widget _layoutCompacto(bool oscuro, ProductoDetalleModelo detalle, bool favorito) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SeccionImagen(
            imagenUrl: detalle.imagenUrl,
            favorito: favorito,
            onToggleFavorito: _alternarFavorito,
            altura: _imagenEsAncha == false ? 340 : 260,
          ),
          const SizedBox(height: 20),
          _PanelInformacion(
            detalle: detalle,
            oscuro: oscuro,
            agregandoAlCarrito: _agregandoAlCarrito,
            comprandoAhora: _comprandoAhora,
            favorito: favorito,
            estaLogueado: widget.userId.isNotEmpty,
            onAgregarAlCarrito: _agregarAlCarrito,
            onComprarAhora: _comprarAhora,
            onToggleFavorito: _alternarFavorito,
          ),
          const SizedBox(height: 28),
          Text(tr(context, 'comprador_secundario.productos_similares'),
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CraftHubColors.textoPrincipal(oscuro))),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: _similares.isEmpty
                ? Center(
                    child: Text(tr(context, 'comprador_secundario.sin_recomendaciones_por_ahora'),
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: CraftHubColors.textoSecundario(oscuro))))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _similares.length,
                    itemBuilder: (_, i) => SizedBox(
                      width: 170,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _TarjetaSimilar(
                          oscuro: oscuro,
                          producto: _similares[i],
                          userId: widget.userId,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 28),
          _SeccionComentarios(
            oscuro: oscuro,
            comentarios: _comentarios,
            orden: _ordenComentarios,
            estaLogueado: widget.userId.isNotEmpty,
            onCambiarOrden: (v) => setState(() => _ordenComentarios = v),
            onPublicar: _publicarComentario,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// BOTÓN CERRAR
// ──────────────────────────────────────────────────────────────────────────
class _BotonCerrar extends StatefulWidget {
  final bool oscuro;
  const _BotonCerrar({required this.oscuro});

  @override
  State<_BotonCerrar> createState() => _BotonCerrarState();
}

class _BotonCerrarState extends State<_BotonCerrar> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _hover
                ? CraftHubColors.panel(widget.oscuro)
                : CraftHubColors.fondo(widget.oscuro),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: CraftHubColors.borde(widget.oscuro)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.close_rounded, size: 16, color: CraftHubColors.vinoTinto),
              const SizedBox(width: 6),
              Text(tr(context, 'comprador_secundario.cerrar'),
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CraftHubColors.textoPrincipal(widget.oscuro))),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// TOAST DE CONFIRMACIÓN (dentro del propio panel, sin depender de Scaffold)
// ──────────────────────────────────────────────────────────────────────────
class _Toast extends StatelessWidget {
  final String texto;
  const _Toast({required this.texto});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: CraftHubColors.textoClaro.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
        ),
        child: Text(texto,
            style: GoogleFonts.poppins(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// ESTADO DE ERROR
// ──────────────────────────────────────────────────────────────────────────
class _EstadoError extends StatelessWidget {
  final bool oscuro;
  final String mensaje;
  final VoidCallback onReintentar;
  const _EstadoError({required this.oscuro, required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 46, color: CraftHubColors.vinoTinto),
            const SizedBox(height: 14),
            Text(mensaje,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13.5, color: CraftHubColors.textoSecundario(oscuro))),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onReintentar,
              style: ElevatedButton.styleFrom(
                backgroundColor: CraftHubColors.vinoTinto,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(tr(context, 'comprador_secundario.reintentar'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// SECCIÓN IMAGEN PRINCIPAL
// ──────────────────────────────────────────────────────────────────────────
class _SeccionImagen extends StatelessWidget {
  final String imagenUrl;
  final bool favorito;
  final VoidCallback onToggleFavorito;
  final double altura;

  const _SeccionImagen({
    required this.imagenUrl,
    required this.favorito,
    required this.onToggleFavorito,
    required this.altura,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: altura,
        width: double.infinity,
        child: Stack(fit: StackFit.expand, children: [
          Image.network(
            imagenUrl, // 🔌 URL desde backend
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: CraftHubColors.vinoTintoSuave,
              child: const Icon(Icons.image_outlined, size: 48, color: CraftHubColors.vinoTinto),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _BotonCorazon(activo: favorito, onTap: onToggleFavorito),
          ),
        ]),
      ),
    );
  }
}

class _BotonCorazon extends StatefulWidget {
  final bool activo;
  final VoidCallback onTap;
  const _BotonCorazon({required this.activo, required this.onTap});

  @override
  State<_BotonCorazon> createState() => _BotonCorazonState();
}

class _BotonCorazonState extends State<_BotonCorazon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: widget.activo
                ? CraftHubColors.vinoTinto
                : Colors.white.withValues(alpha: _hover ? 1 : 0.92),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
          ),
          child: Icon(
            widget.activo ? Icons.favorite : Icons.favorite_border_rounded,
            size: 18,
            color: widget.activo ? Colors.white : CraftHubColors.vinoTinto,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// PANEL DE INFORMACIÓN (título, precio, descripción, specs, acciones)
// ──────────────────────────────────────────────────────────────────────────

// Una ficha de especificación solo se muestra si tiene un dato real: se
// oculta cuando está vacía o quedó como "No especificado" por defecto.
bool _specConDato(String valor) {
  final v = valor.trim().toLowerCase();
  return v.isNotEmpty && v != 'no especificado' && v != 'not specified';
}

class _PanelInformacion extends StatelessWidget {
  final ProductoDetalleModelo detalle;
  final bool oscuro;
  final bool agregandoAlCarrito;
  final bool comprandoAhora;
  final bool favorito;
  final bool estaLogueado;
  final VoidCallback onAgregarAlCarrito;
  final VoidCallback onComprarAhora;
  final VoidCallback onToggleFavorito;

  const _PanelInformacion({
    required this.detalle,
    required this.oscuro,
    required this.agregandoAlCarrito,
    required this.comprandoAhora,
    required this.favorito,
    required this.estaLogueado,
    required this.onAgregarAlCarrito,
    required this.onComprarAhora,
    required this.onToggleFavorito,
  });

  @override
  Widget build(BuildContext context) {
    final textoPrincipal = CraftHubColors.textoPrincipal(oscuro);
    final textoSecundario = CraftHubColors.textoSecundario(oscuro);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: CraftHubColors.panel(oscuro),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: CraftHubColors.borde(oscuro)),
          ),
          child: Text(detalle.etiquetaCategoria,
              style: GoogleFonts.poppins(fontSize: 11.5, color: textoSecundario)),
        ),
        const SizedBox(height: 14),
        Text(detalle.nombre,
            style: GoogleFonts.poppins(
                fontSize: 26, fontWeight: FontWeight.w700, height: 1.15, color: textoPrincipal)),
        const SizedBox(height: 10),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('${tr(context, 'comprador_secundario.creado_por')} ', style: GoogleFonts.poppins(fontSize: 13.5, color: textoSecundario)),
            Text(detalle.creador,
                style: GoogleFonts.poppins(
                    fontSize: 13.5, fontWeight: FontWeight.w700, color: CraftHubColors.vinoTinto)),
            if (detalle.creadorVerificado) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified_rounded, size: 15, color: CraftHubColors.vinoTinto),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: textoSecundario),
            const SizedBox(width: 5),
            Flexible(
              child: Text(detalle.ubicacion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12.5, height: 1.0, color: textoSecundario)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (detalle.totalValoraciones > 0)
          Row(children: [
            _Estrellas(calificacion: detalle.calificacion),
            const SizedBox(width: 6),
            Text('${detalle.calificacion.toStringAsFixed(1)} (${detalle.totalValoraciones} ${tr(context, 'comprador_secundario.valoraciones_palabra')})',
                style: GoogleFonts.poppins(fontSize: 12.5, color: textoSecundario)),
          ]),
        const SizedBox(height: 16),
        Text('\$${detalle.precio.toStringAsFixed(2)} USD',
            style: GoogleFonts.poppins(
                fontSize: 26, fontWeight: FontWeight.w800, color: CraftHubColors.vinoTinto)),
        const SizedBox(height: 14),
        if (detalle.descripcion.isNotEmpty)
          Text(detalle.descripcion,
              style: GoogleFonts.poppins(fontSize: 13, height: 1.55, color: textoSecundario)),
        const SizedBox(height: 18),
        Divider(color: CraftHubColors.borde(oscuro)),
        const SizedBox(height: 14),
        // Solo se muestran las fichas con dato real: Materiales y Dimensiones
        // se ocultan cuando el vendedor no las especificó (evita el eterno
        // "No especificado"). Categoría y Técnica siempre tienen valor.
        _FilaSpec(icono: Icons.category_outlined, etiqueta: tr(context, 'comprador_secundario.categoria'), valor: detalle.categoria, oscuro: oscuro),
        if (_specConDato(detalle.materiales)) ...[
          const SizedBox(height: 10),
          _FilaSpec(icono: Icons.texture_rounded, etiqueta: tr(context, 'comprador_secundario.materiales'), valor: detalle.materiales, oscuro: oscuro),
        ],
        const SizedBox(height: 10),
        _FilaSpec(icono: Icons.brush_outlined, etiqueta: tr(context, 'comprador_secundario.tecnica'), valor: detalle.tecnica, oscuro: oscuro),
        if (_specConDato(detalle.dimensiones)) ...[
          const SizedBox(height: 10),
          _FilaSpec(icono: Icons.straighten_rounded, etiqueta: tr(context, 'comprador_secundario.dimensiones'), valor: detalle.dimensiones, oscuro: oscuro),
        ],
        // ── Tallas disponibles (solo Vestir/Calzado) ────────────────────
        if (detalle.tallas.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(tr(context, 'comprador_secundario.tallas_disponibles'),
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: textoPrincipal)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: detalle.tallas.map((t) => Container(
              width: 52,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CraftHubColors.panel(oscuro),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CraftHubColors.vinoTinto.withValues(alpha: 0.55), width: 1.3),
              ),
              child: Text(t,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: CraftHubColors.vinoTinto)),
            )).toList(),
          ),
        ],
        const SizedBox(height: 22),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: estaLogueado
              ? [
                  _BotonComprarAhora(cargando: comprandoAhora, estaLogueado: true, onTap: onComprarAhora),
                  _BotonAgregarCarrito(cargando: agregandoAlCarrito, estaLogueado: true, onTap: onAgregarAlCarrito),
                  _BotonMeGusta(activo: favorito, onTap: onToggleFavorito),
                ]
              : [
                  // Sin sesión: un solo mensaje claro en vez de repetirlo en
                  // cada botón — "Me gusta" sigue disponible porque guardar
                  // favoritos no requiere haber iniciado sesión.
                  _BotonComprarAhora(cargando: false, estaLogueado: false, onTap: onComprarAhora),
                  _BotonMeGusta(activo: favorito, onTap: onToggleFavorito),
                ],
        ),
      ],
    );
  }
}

class _FilaSpec extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final bool oscuro;
  const _FilaSpec({required this.icono, required this.etiqueta, required this.valor, required this.oscuro});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 17, color: CraftHubColors.vinoTinto),
        const SizedBox(width: 10),
        SizedBox(
          width: 92,
          child: Text(etiqueta,
              style: GoogleFonts.poppins(fontSize: 12.5, color: CraftHubColors.textoSecundario(oscuro))),
        ),
        Expanded(
          child: Text(valor,
              style: GoogleFonts.poppins(
                  fontSize: 12.5, fontWeight: FontWeight.w500, color: CraftHubColors.textoPrincipal(oscuro))),
        ),
      ],
    );
  }
}

class _BotonComprarAhora extends StatefulWidget {
  final bool cargando;
  final bool estaLogueado;
  final VoidCallback onTap;
  const _BotonComprarAhora({
    required this.cargando,
    required this.estaLogueado,
    required this.onTap,
  });

  @override
  State<_BotonComprarAhora> createState() => _BotonComprarAhoraState();
}

class _BotonComprarAhoraState extends State<_BotonComprarAhora> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bloqueado = !widget.estaLogueado;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.cargando ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          decoration: BoxDecoration(
            color: bloqueado
                ? Colors.grey.withValues(alpha: _hover ? 0.55 : 0.45)
                : (_hover ? CraftHubColors.vinoTintoOscuro : CraftHubColors.vinoTinto),
            borderRadius: BorderRadius.circular(50),
            boxShadow: bloqueado
                ? null
                : [BoxShadow(color: CraftHubColors.vinoTinto.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.cargando)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else
                Icon(bloqueado ? Icons.lock_outline_rounded : Icons.bolt_rounded,
                    size: 17, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                  bloqueado
                      ? tr(context, 'comprador_secundario.inicia_sesion_para_comprar')
                      : tr(context, 'comprador_secundario.comprar_ahora'),
                  style: GoogleFonts.poppins(
                      fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonAgregarCarrito extends StatefulWidget {
  final bool cargando;
  final bool estaLogueado;
  final VoidCallback onTap;
  const _BotonAgregarCarrito({
    required this.cargando,
    required this.estaLogueado,
    required this.onTap,
  });

  @override
  State<_BotonAgregarCarrito> createState() => _BotonAgregarCarritoState();
}

class _BotonAgregarCarritoState extends State<_BotonAgregarCarrito> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bloqueado = !widget.estaLogueado;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.cargando ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          decoration: BoxDecoration(
            color: _hover ? CraftHubColors.vinoTintoSuave : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: bloqueado ? CraftHubColors.borde(oscuro) : CraftHubColors.vinoTinto),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.cargando)
                SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2, color: CraftHubColors.vinoTinto),
                )
              else
                Icon(bloqueado ? Icons.lock_outline_rounded : Icons.shopping_bag_outlined,
                    size: 17, color: bloqueado ? CraftHubColors.textoSecundario(oscuro) : CraftHubColors.vinoTinto),
              const SizedBox(width: 8),
              Text(
                  bloqueado
                      ? tr(context, 'comprador_secundario.inicia_sesion')
                      : tr(context, 'comprador_secundario.anadir_al_carrito'),
                  style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: bloqueado ? CraftHubColors.textoSecundario(oscuro) : CraftHubColors.vinoTinto)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonMeGusta extends StatefulWidget {
  final bool activo;
  final VoidCallback onTap;
  const _BotonMeGusta({required this.activo, required this.onTap});

  @override
  State<_BotonMeGusta> createState() => _BotonMeGustaState();
}

class _BotonMeGustaState extends State<_BotonMeGusta> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: widget.activo
                ? CraftHubColors.vinoTintoSuave
                : (_hover ? CraftHubColors.panel(oscuro) : Colors.transparent),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
                color: widget.activo ? CraftHubColors.vinoTinto : CraftHubColors.borde(oscuro)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.activo ? Icons.favorite : Icons.favorite_border_rounded,
                  size: 16, color: CraftHubColors.vinoTinto),
              const SizedBox(width: 8),
              Text(tr(context, 'comprador_secundario.me_gusta'),
                  style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      // El fondo "activo" (vinoTintoSuave) es un rosa claro fijo,
                      // sin importar el tema — el texto tiene que ser siempre
                      // oscuro ahí, o se vuelve ilegible en modo oscuro.
                      color: widget.activo
                          ? CraftHubColors.vinoTintoOscuro
                          : CraftHubColors.textoPrincipal(oscuro))),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// ESTRELLAS DE CALIFICACIÓN
// ──────────────────────────────────────────────────────────────────────────
class _Estrellas extends StatelessWidget {
  final double calificacion;
  final double tamano;
  const _Estrellas({required this.calificacion, this.tamano = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final valor = calificacion - i;
        IconData icono;
        if (valor >= 1) {
          icono = Icons.star_rounded;
        } else if (valor >= 0.5) {
          icono = Icons.star_half_rounded;
        } else {
          icono = Icons.star_border_rounded;
        }
        return Icon(icono, size: tamano, color: const Color(0xFFD4A843));
      }),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// SECCIÓN COMENTARIOS
// ──────────────────────────────────────────────────────────────────────────
class _SeccionComentarios extends StatelessWidget {
  final bool oscuro;
  final List<ComentarioModelo> comentarios;
  final String orden;
  final bool estaLogueado;
  final ValueChanged<String> onCambiarOrden;
  final Future<bool> Function(String texto, double calificacion, Uint8List? fotoBytes, String? fotoNombre)
      onPublicar;

  const _SeccionComentarios({
    required this.oscuro,
    required this.comentarios,
    required this.orden,
    required this.estaLogueado,
    required this.onCambiarOrden,
    required this.onPublicar,
  });

  List<ComentarioModelo> get _comentariosOrdenados {
    final lista = List<ComentarioModelo>.of(comentarios);
    if (orden == 'Mejor valorados') {
      lista.sort((a, b) => b.calificacion.compareTo(a.calificacion));
    }
    // 'Más recientes' respeta el orden ya entregado por el backend
    // (GET /productos/{id}/comentarios ordena por created_at desc).
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: CraftHubColors.borde(oscuro)),
        const SizedBox(height: 14),
        Row(
          children: [
            Text('${tr(context, 'comprador_secundario.comentarios')} (${comentarios.length})',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CraftHubColors.textoPrincipal(oscuro))),
            const Spacer(),
            _SelectorOrden(oscuro: oscuro, valor: orden, onCambiar: onCambiarOrden),
          ],
        ),
        const SizedBox(height: 16),
        estaLogueado
            ? _ComposerComentario(oscuro: oscuro, onPublicar: onPublicar)
            : _AvisoIniciarSesion(oscuro: oscuro),
        const SizedBox(height: 20),
        if (comentarios.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(tr(context, 'comprador_secundario.sin_comentarios_producto'),
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: CraftHubColors.textoSecundario(oscuro))),
          )
        else
          Column(
            children: _comentariosOrdenados
                .map((c) => _TarjetaComentario(oscuro: oscuro, comentario: c))
                .toList(),
          ),
      ],
    );
  }
}

class _SelectorOrden extends StatelessWidget {
  final bool oscuro;
  final String valor;
  final ValueChanged<String> onCambiar;
  const _SelectorOrden({required this.oscuro, required this.valor, required this.onCambiar});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: tr(context, 'comprador_secundario.ordenar_comentarios'),
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onCambiar,
      itemBuilder: (_) => ['Más recientes', 'Mejor valorados']
          .map((o) => PopupMenuItem(value: o, child: Text(o, style: GoogleFonts.poppins(fontSize: 13))))
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${tr(context, 'comprador_secundario.ordenar_por')}: ',
              style: GoogleFonts.poppins(fontSize: 12, color: CraftHubColors.textoSecundario(oscuro))),
          Text(valor,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600, color: CraftHubColors.textoPrincipal(oscuro))),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: CraftHubColors.textoSecundario(oscuro)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// COMPOSER: escribir comentario con calificación, emojis y foto adjunta
// ──────────────────────────────────────────────────────────────────────────
class _AvisoIniciarSesion extends StatelessWidget {
  final bool oscuro;
  const _AvisoIniciarSesion({required this.oscuro});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(oscuro),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CraftHubColors.borde(oscuro)),
      ),
      child: Row(children: [
        Icon(Icons.lock_outline_rounded, size: 18, color: CraftHubColors.textoSecundario(oscuro)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(tr(context, 'comprador_secundario.inicia_sesion_comentar'),
              style: GoogleFonts.poppins(fontSize: 12.5, color: CraftHubColors.textoSecundario(oscuro))),
        ),
      ]),
    );
  }
}

class _ComposerComentario extends StatefulWidget {
  final bool oscuro;
  final Future<bool> Function(String texto, double calificacion, Uint8List? fotoBytes, String? fotoNombre)
      onPublicar;

  const _ComposerComentario({required this.oscuro, required this.onPublicar});

  @override
  State<_ComposerComentario> createState() => _ComposerComentarioState();
}

class _ComposerComentarioState extends State<_ComposerComentario> {
  static const List<String> _emojis = [
    '😀', '😍', '🥰', '😊', '👏', '👍', '🔥', '🎉', '💯', '✨',
    '❤️', '👌', '😅', '🙌', '😮', '🥳', '😢', '😡', '🤔', '💪',
  ];

  final _controlador = TextEditingController();
  final _focoTexto = FocusNode();
  int _calificacion = 0;
  Uint8List? _fotoBytes;
  String? _fotoNombre;
  bool _mostrarEmojis = false;
  bool _enviando = false;

  @override
  void dispose() {
    _controlador.dispose();
    _focoTexto.dispose();
    super.dispose();
  }

  void _insertarEmoji(String emoji) {
    final texto = _controlador.text;
    final seleccion = _controlador.selection;
    final inicio = seleccion.start >= 0 ? seleccion.start : texto.length;
    final fin = seleccion.end >= 0 ? seleccion.end : texto.length;
    final nuevoTexto = texto.replaceRange(inicio, fin, emoji);
    _controlador.text = nuevoTexto;
    _controlador.selection = TextSelection.collapsed(offset: inicio + emoji.length);
    _focoTexto.requestFocus();
  }

  Future<void> _seleccionarFoto() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (resultado == null || resultado.files.isEmpty) return;
    final archivo = resultado.files.single;
    if (archivo.bytes == null) return;
    setState(() {
      _fotoBytes = archivo.bytes;
      _fotoNombre = archivo.name;
    });
  }

  bool get _puedeEnviar =>
      !_enviando && _calificacion > 0 && _controlador.text.trim().isNotEmpty;

  Future<void> _enviar() async {
    if (!_puedeEnviar) return;
    setState(() => _enviando = true);
    final exito = await widget.onPublicar(
      _controlador.text.trim(),
      _calificacion.toDouble(),
      _fotoBytes,
      _fotoNombre,
    );
    if (!mounted) return;
    setState(() {
      _enviando = false;
      if (exito) {
        _controlador.clear();
        _calificacion = 0;
        _fotoBytes = null;
        _fotoNombre = null;
        _mostrarEmojis = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = widget.oscuro;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(oscuro),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CraftHubColors.borde(oscuro)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(tr(context, 'comprador_secundario.tu_calificacion'),
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: CraftHubColors.textoPrincipal(oscuro))),
            const SizedBox(width: 10),
            _SelectorEstrellasInteractivo(
              valor: _calificacion,
              onCambiar: (v) => setState(() => _calificacion = v),
            ),
          ]),
          const SizedBox(height: 10),
          if (_fotoBytes != null) ...[
            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(_fotoBytes!, height: 90, width: 90, fit: BoxFit.cover),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() { _fotoBytes = null; _fotoNombre = null; }),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _controlador,
            focusNode: _focoTexto,
            minLines: 1,
            maxLines: 4,
            style: GoogleFonts.poppins(fontSize: 13, color: CraftHubColors.textoPrincipal(oscuro)),
            decoration: InputDecoration(
              hintText: tr(context, 'comprador_secundario.comparte_experiencia_hint'),
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: CraftHubColors.textoSecundario(oscuro)),
              filled: true,
              fillColor: CraftHubColors.fondo(oscuro),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: CraftHubColors.borde(oscuro)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: CraftHubColors.borde(oscuro)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: CraftHubColors.vinoTinto, width: 1.2),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_mostrarEmojis) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _emojis
                  .map((e) => GestureDetector(
                        onTap: () => _insertarEmoji(e),
                        child: Text(e, style: const TextStyle(fontSize: 20)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(children: [
            _BotonIconoComposer(
              icono: Icons.emoji_emotions_outlined,
              activo: _mostrarEmojis,
              onTap: () => setState(() => _mostrarEmojis = !_mostrarEmojis),
              oscuro: oscuro,
            ),
            const SizedBox(width: 8),
            _BotonIconoComposer(
              icono: Icons.image_outlined,
              activo: _fotoBytes != null,
              onTap: _seleccionarFoto,
              oscuro: oscuro,
            ),
            const Spacer(),
            GestureDetector(
              onTap: _puedeEnviar ? _enviar : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  color: _puedeEnviar
                      ? CraftHubColors.vinoTinto
                      : CraftHubColors.vinoTinto.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(tr(context, 'comprador_secundario.publicar'),
                        style: GoogleFonts.poppins(
                            fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _BotonIconoComposer extends StatelessWidget {
  final IconData icono;
  final bool activo;
  final VoidCallback onTap;
  final bool oscuro;
  const _BotonIconoComposer({
    required this.icono,
    required this.activo,
    required this.onTap,
    required this.oscuro,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: activo ? CraftHubColors.vinoTintoSuave : CraftHubColors.fondo(oscuro),
          shape: BoxShape.circle,
          border: Border.all(color: activo ? CraftHubColors.vinoTinto : CraftHubColors.borde(oscuro)),
        ),
        child: Icon(icono, size: 18, color: CraftHubColors.vinoTinto),
      ),
    );
  }
}

class _SelectorEstrellasInteractivo extends StatelessWidget {
  final int valor;
  final ValueChanged<int> onCambiar;
  const _SelectorEstrellasInteractivo({required this.valor, required this.onCambiar});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final activa = i < valor;
        return GestureDetector(
          onTap: () => onCambiar(i + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(
              activa ? Icons.star_rounded : Icons.star_border_rounded,
              size: 22,
              color: const Color(0xFFD4A843),
            ),
          ),
        );
      }),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// TARJETA DE UN COMENTARIO
// ──────────────────────────────────────────────────────────────────────────
class _TarjetaComentario extends StatelessWidget {
  final bool oscuro;
  final ComentarioModelo comentario;
  const _TarjetaComentario({required this.oscuro, required this.comentario});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: CraftHubColors.vinoTintoSuave,
            backgroundImage: comentario.avatarUrl.isNotEmpty
                ? NetworkImage(comentario.avatarUrl) // 🔌 URL desde backend
                : null,
            child: comentario.avatarUrl.isEmpty
                ? Text(
                    comentario.autor.trim().isNotEmpty ? comentario.autor.trim()[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: CraftHubColors.vinoTinto, fontWeight: FontWeight.bold, fontSize: 13),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(comentario.autor,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700, color: CraftHubColors.textoPrincipal(oscuro))),
                  const SizedBox(width: 8),
                  Text(comentario.fecha,
                      style: GoogleFonts.poppins(fontSize: 11.5, color: CraftHubColors.textoSecundario(oscuro))),
                ]),
                const SizedBox(height: 4),
                _Estrellas(calificacion: comentario.calificacion, tamano: 13),
                const SizedBox(height: 6),
                Text(comentario.texto,
                    style: GoogleFonts.poppins(
                        fontSize: 12.5, height: 1.5, color: CraftHubColors.textoSecundario(oscuro))),
                if (comentario.fotoUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      comentario.fotoUrl, // 🔌 URL desde backend
                      height: 90,
                      width: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// PANEL PRODUCTOS SIMILARES (columna derecha, con scroll propio)
// ──────────────────────────────────────────────────────────────────────────
class _PanelSimilares extends StatefulWidget {
  final bool oscuro;
  final List<ProductoSimilarModelo> similares;
  final String userId;
  const _PanelSimilares({required this.oscuro, required this.similares, required this.userId});

  @override
  State<_PanelSimilares> createState() => _PanelSimilaresState();
}

class _PanelSimilaresState extends State<_PanelSimilares> {
  final _controladorScroll = ScrollController();

  @override
  void dispose() {
    _controladorScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = widget.oscuro;
    final similares = widget.similares;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(context, 'comprador_secundario.productos_similares'),
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w700, color: CraftHubColors.textoPrincipal(oscuro))),
        const SizedBox(height: 14),
        Expanded(
          child: similares.isEmpty
              ? Center(
                  child: Text(tr(context, 'comprador_secundario.sin_recomendaciones_por_ahora'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 12.5, color: CraftHubColors.textoSecundario(oscuro))),
                )
              : Scrollbar(
                  controller: _controladorScroll,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _controladorScroll,
                    padding: const EdgeInsets.only(right: 8),
                    itemCount: similares.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TarjetaSimilar(
                        oscuro: oscuro,
                        producto: similares[i],
                        userId: widget.userId,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _TarjetaSimilar extends StatefulWidget {
  final bool oscuro;
  final ProductoSimilarModelo producto;
  final String userId;
  const _TarjetaSimilar({required this.oscuro, required this.producto, required this.userId});

  @override
  State<_TarjetaSimilar> createState() => _TarjetaSimilarState();
}

class _TarjetaSimilarState extends State<_TarjetaSimilar> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final favorito = context.watch<FavoritosProvider>().esProductoFavorito(p.id);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Abre el detalle del producto similar seleccionado, conservando
          // la sesión del usuario (antes se abría siempre como invitado).
          PantallaDetalleProducto.mostrar(context, productoId: p.id, userId: widget.userId);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hover ? CraftHubColors.panel(widget.oscuro) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Image.network(
                    p.imagenUrl, // 🔌 URL desde backend
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: CraftHubColors.vinoTintoSuave,
                      child: const Icon(Icons.image_outlined, size: 20, color: CraftHubColors.vinoTinto),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: CraftHubColors.textoPrincipal(widget.oscuro))),
                    const SizedBox(height: 2),
                    Row(children: [
                      Flexible(
                        child: Text(p.autor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 10.5, color: CraftHubColors.textoSecundario(widget.oscuro))),
                      ),
                      if (p.verificado) ...[
                        const SizedBox(width: 3),
                        const Icon(Icons.verified_rounded, size: 11, color: CraftHubColors.vinoTinto),
                      ],
                    ]),
                    const SizedBox(height: 3),
                    Row(children: [
                      _Estrellas(calificacion: p.calificacion, tamano: 11),
                      const SizedBox(width: 4),
                      Text('(${p.totalResenas})',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: CraftHubColors.textoSecundario(widget.oscuro))),
                    ]),
                    const SizedBox(height: 3),
                    Text('\$${p.precio.toStringAsFixed(2)} USD',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w700, color: CraftHubColors.vinoTinto)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.read<FavoritosProvider>().alternarProducto(
                      ProductoModelo(
                        id: p.id,
                        nombre: p.nombre,
                        precio: p.precio,
                        imagenUrl: p.imagenUrl,
                        artesano: p.autor,
                        provincia: '',
                        categoria: '',
                      ),
                    ),
                child: Icon(
                  favorito ? Icons.favorite : Icons.favorite_border_rounded,
                  size: 16,
                  color: CraftHubColors.vinoTinto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
