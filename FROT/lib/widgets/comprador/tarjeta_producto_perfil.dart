import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TarjetaProductoPerfil extends StatefulWidget {
  final String imagenUrl;
  final String nombre;
  final String precio;
  final bool esFavorito;
  final VoidCallback alToggleFavorito;
  final VoidCallback alPresionar;

  const TarjetaProductoPerfil({
    super.key,
    required this.imagenUrl,
    required this.nombre,
    required this.precio,
    required this.esFavorito,
    required this.alToggleFavorito,
    required this.alPresionar,
  });

  @override
  State<TarjetaProductoPerfil> createState() => _TarjetaProductoPerfilState();
}

class _TarjetaProductoPerfilState extends State<TarjetaProductoPerfil> {
  bool _sobreEl = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobreEl = true),
      onExit:  (_) => setState(() => _sobreEl = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen
              Image.network(
                widget.imagenUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: CraftHubColors.bordeClaro,
                  child: const Icon(Icons.image_outlined,
                      color: CraftHubColors.textoSecClaro, size: 36),
                ),
              ),

              // Overlay con nombre y precio al hacer hover
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                bottom: _sobreEl ? 0 : -60,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.precio,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botón favorito flotante arriba a la derecha
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: widget.alToggleFavorito,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.90),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.esFavorito
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 16,
                      color: widget.esFavorito
                          ? CraftHubColors.vinoTinto
                          : CraftHubColors.textoSecClaro,
                    ),
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