import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Modelo de datos de un producto favorito.
/// 🔗 API: GET /api/v1/favoritos/{usuarioId} → lista de [ModeloFavorito]
class ModeloFavorito {
  final String id;
  final String nombreProducto;
  final String nombreArtesano;
  final String provincia;
  final double precio;
  final String rutaImagen; // Image.asset path
  final bool esFavorito;

  const ModeloFavorito({
    required this.id,
    required this.nombreProducto,
    required this.nombreArtesano,
    required this.provincia,
    required this.precio,
    required this.rutaImagen,
    this.esFavorito = true,
  });
}

/// Tarjeta de favorito con efecto hover inmersivo (nombre/precio ocultos por defecto).
/// Se usa en el grid Masonry de PantallaFavoritos.
class TarjetaFavorito extends StatefulWidget {
  final ModeloFavorito producto;
  final double altura;
  final VoidCallback? alQuitarFavorito;
  final VoidCallback? alAgregarAlCarrito;

  const TarjetaFavorito({
    super.key,
    required this.producto,
    required this.altura,
    this.alQuitarFavorito,
    this.alAgregarAlCarrito,
  });

  @override
  State<TarjetaFavorito> createState() => _TarjetaFavoritoState();
}

class _TarjetaFavoritoState extends State<TarjetaFavorito>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final esTemaOscuro = Theme.of(context).brightness == Brightness.dark;
    const colorVino = Color(0xFF821515);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: widget.altura,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen protagonista
              Image.asset(
                widget.producto.rutaImagen,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: esTemaOscuro
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFEDE0D4),
                  child: const Icon(Icons.image_outlined,
                      size: 48, color: Colors.white38),
                ),
              ),

              // Gradiente base siempre visible (suave, abajo)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: widget.altura * 0.35,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.15),
                      ],
                    ),
                  ),
                ),
              ),

              // Panel hover animado desde abajo
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                bottom: _hovering ? 0 : -(widget.altura * 0.45),
                left: 0,
                right: 0,
                height: widget.altura * 0.45,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: esTemaOscuro
                        ? const Color(0xDD1E1E1E)
                        : const Color(0xEEFFFFFF),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.producto.nombreProducto,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12,
                              color: esTemaOscuro
                                  ? Colors.white54
                                  : Colors.black45),
                          const SizedBox(width: 3),
                          Text(
                            widget.producto.provincia,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: esTemaOscuro
                                  ? Colors.white54
                                  : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${widget.producto.precio.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colorVino,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.alAgregarAlCarrito,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: colorVino,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Añadir',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Botón favorito flotante (corazón) — siempre visible
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: widget.alQuitarFavorito,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: colorVino,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.97, 0.97)),
    );
  }
}