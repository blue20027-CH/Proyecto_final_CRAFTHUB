import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

// 🔌 Modelo que mapea la respuesta de GET /api/productos
class ProductoModelo {
  final String id;
  final String nombre;
  final double precio;
  final String imagenUrl;
  final String artesano;
  final String provincia;
  final String categoria;
  bool esFavorito;

  ProductoModelo({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.imagenUrl,
    required this.artesano,
    required this.provincia,
    required this.categoria,
    this.esFavorito = false,
  });

  // 🔌 Convierte JSON del backend en modelo
  factory ProductoModelo.fromJson(Map<String, dynamic> json) {
    return ProductoModelo(
      id:          json['id'].toString(),
      nombre:      (json['nombre'] ?? '').toString(),
      precio:      double.tryParse((json['precio'] ?? 0).toString()) ?? 0,
      imagenUrl:   (json['imagen_url'] ?? json['imagen'] ?? json['img'] ?? '').toString(),
      artesano:    (json['artesano'] ?? json['creador'] ?? 'Artesano local').toString(),
      provincia:   (json['provincia'] ?? json['origen'] ?? json['region'] ?? 'Panama').toString(),
      categoria:   (json['categoria'] ?? 'General').toString(),
      esFavorito:  json['es_favorito'] ?? false,
    );
  }
}

class TarjetaProducto extends StatefulWidget {
  final ProductoModelo producto;
  final double altura;
  final VoidCallback? alPresionar;

  const TarjetaProducto({
    super.key,
    required this.producto,
    this.altura = 280,
    this.alPresionar,
  });

  @override
  State<TarjetaProducto> createState() => _TarjetaProductoState();
}

class _TarjetaProductoState extends State<TarjetaProducto>
    with SingleTickerProviderStateMixin {
  // ignore: unused_field
  bool _hover = false;
  bool _favorito = false;
  late AnimationController _ctrl;
  late Animation<double> _overlay, _zoom;

  @override
  void initState() {
    super.initState();
    _favorito = widget.producto.esFavorito;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _overlay = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _zoom = Tween(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) { setState(() => _hover = true);  _ctrl.forward(); },
      onExit:  (_) { setState(() => _hover = false); _ctrl.reverse(); },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: widget.altura,
            child: Stack(fit: StackFit.expand, children: [

              // ── Imagen con zoom ──
              AnimatedBuilder(
                animation: _zoom,
                builder: (_, child) => Transform.scale(scale: _zoom.value, child: child),
                child: Image.network(
                  widget.producto.imagenUrl, // 🔌 URL desde backend
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: CraftHubColors.fondoClaro,
                    child: const Icon(Icons.image_outlined, size: 40, color: CraftHubColors.vinoTinto),
                  ),
                ),
              ),

              // ── Overlay hover: precio y nombre ──
              AnimatedBuilder(
                animation: _overlay,
                builder: (_, child) => Positioned(
                  left: 0, right: 0,
                  bottom: (_overlay.value - 1) * 80,
                  child: Opacity(opacity: _overlay.value, child: child!),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: oscuro
                          ? [Colors.black.withOpacity(0.92), Colors.transparent]
                          : [const Color.fromARGB(255, 33, 33, 33).withOpacity(0.97), Colors.transparent],
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      '\$${widget.producto.precio.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: CraftHubColors.vinoTinto,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.producto.nombre,
                      style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: oscuro ? Colors.white.withOpacity(0.88) : Colors.white.withOpacity(0.88),
                      ),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.producto.artesano} · ${widget.producto.provincia}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: oscuro ? Colors.white54 : Colors.white54,
                      ),
                    ),
                  ]),
                ),
              ),

              // ── Corazón flotante ──
              Positioned(
                top: 10, right: 10,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _favorito = !_favorito);
                    // 🔌 POST /api/favoritos { producto_id: widget.producto.id }
                    // 🔌 DELETE /api/favoritos/${widget.producto.id}
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _favorito ? CraftHubColors.vinoTinto : Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12),
                          blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Icon(
                      _favorito ? Icons.favorite : Icons.favorite_border,
                      size: 15,
                      color: _favorito ? Colors.white : CraftHubColors.vinoTinto,
                    ),
                  ),
                ),
              ),

            ]),
          ),
        ),
      ),
    );
  }
}
