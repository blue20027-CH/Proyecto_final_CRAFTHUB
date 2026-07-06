import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/carrito_provider.dart';
import '../../core/favoritos_provider.dart';
import '../../models/carrito_model.dart';
import '../../core/theme/app_theme.dart';
import 'tarjeta_producto.dart';

// ============================================================
// TARJETA DE ÍTEM DEL CARRITO
// ============================================================

class TarjetaItemCarrito extends StatefulWidget {
  final ItemCarritoModel item;

  const TarjetaItemCarrito({super.key, required this.item});

  @override
  State<TarjetaItemCarrito> createState() => _TarjetaItemCarritoState();
}

class _TarjetaItemCarritoState extends State<TarjetaItemCarrito> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CarritoProvider>();
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    final favorito = context
        .watch<FavoritosProvider>()
        .esProductoFavorito(widget.item.productoId.toString());

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: esModoOscuro ? AppColors.panelOscuro : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hover
                ? AppColors.vinoTinto.withValues(alpha: 0.2)
                : (esModoOscuro
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hover ? 0.08 : 0.04),
              blurRadius: _hover ? 16 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Imagen del producto (con botón de favorito) ─
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 110,
                      height: 90,
                      child: Image.network(
                        widget.item.imagenUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFF0EBE3),
                          child: const Icon(Icons.image_outlined,
                              color: Colors.grey, size: 32),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => context.read<FavoritosProvider>().alternarProducto(
                            ProductoModelo(
                              id: widget.item.productoId.toString(),
                              nombre: widget.item.nombreProducto,
                              precio: widget.item.precioUnitario,
                              imagenUrl: widget.item.imagenUrl,
                              artesano: widget.item.artesanoNombre,
                              provincia: widget.item.provincia,
                              categoria: '',
                            ),
                          ),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: favorito
                              ? AppColors.vinoTinto
                              : Colors.white.withValues(alpha: 0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          favorito ? Icons.favorite : Icons.favorite_border_rounded,
                          size: 14,
                          color: favorito ? Colors.white : AppColors.vinoTinto,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // ── Info del producto ─────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(
                      widget.item.nombreProducto,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: esModoOscuro
                            ? AppColors.textoOscuro
                            : AppColors.textoClaro,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Descripción
                    Text(
                      widget.item.descripcion,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: esModoOscuro
                            ? AppColors.textoSecOscuro
                            : AppColors.textoSecClaro,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Artesano
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                        children: [
                          TextSpan(
                            text: 'por ',
                            style: TextStyle(
                              color: esModoOscuro
                                  ? AppColors.textoSecOscuro
                                  : AppColors.textoSecClaro,
                            ),
                          ),
                          TextSpan(
                            text: widget.item.artesanoNombre,
                            style: const TextStyle(
                              color: AppColors.vinoTinto,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Provincia
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.vinoTinto),
                        const SizedBox(width: 3),
                        Text(
                          widget.item.provincia,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: esModoOscuro
                                ? AppColors.textoSecOscuro
                                : AppColors.textoSecClaro,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // ── Controles de cantidad ─────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Botones - cantidad +
                  Row(
                    children: [
                      _BotonCantidad(
                        icono: Icons.remove_rounded,
                        alPresionar: () => provider.actualizarCantidad(
                            widget.item.id, widget.item.cantidad - 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          '${widget.item.cantidad}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: esModoOscuro
                                ? AppColors.textoOscuro
                                : AppColors.textoClaro,
                          ),
                        ),
                      ),
                      _BotonCantidad(
                        icono: Icons.add_rounded,
                        alPresionar: () => provider.actualizarCantidad(
                            widget.item.id, widget.item.cantidad + 1),
                      ),
                      const SizedBox(width: 12),
                      // Botón eliminar
                      _BotonEliminar(
                        alPresionar: () =>
                            provider.eliminarItem(widget.item.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Precio del ítem
                  Text(
                    '\$${widget.item.subtotalItem.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.vinoTinto,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BOTÓN DE CANTIDAD ( + / - )
// ============================================================
class _BotonCantidad extends StatefulWidget {
  final IconData icono;
  final VoidCallback alPresionar;

  const _BotonCantidad({required this.icono, required this.alPresionar});

  @override
  State<_BotonCantidad> createState() => _BotonCantidadState();
}

class _BotonCantidadState extends State<_BotonCantidad> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _hover
                ? AppColors.vinoTinto.withValues(alpha: 0.1)
                : (esModoOscuro
                    ? AppColors.panelOscuro2
                    : const Color(0xFFF5F0EB)),
            border: Border.all(
              color: _hover
                  ? AppColors.vinoTinto.withValues(alpha: 0.3)
                  : (esModoOscuro
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08)),
            ),
          ),
          child: Icon(
            widget.icono,
            size: 16,
            color: _hover
                ? AppColors.vinoTinto
                : (esModoOscuro ? AppColors.textoSecOscuro : AppColors.textoSecClaro),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BOTÓN ELIMINAR ÍTEM
// ============================================================
class _BotonEliminar extends StatefulWidget {
  final VoidCallback alPresionar;
  const _BotonEliminar({required this.alPresionar});

  @override
  State<_BotonEliminar> createState() => _BotonEliminarState();
}

class _BotonEliminarState extends State<_BotonEliminar> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _hover
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
              color: _hover
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            size: 17,
            color: _hover ? Colors.red[400] : Colors.grey[400],
          ),
        ),
      ),
    );
  }
}