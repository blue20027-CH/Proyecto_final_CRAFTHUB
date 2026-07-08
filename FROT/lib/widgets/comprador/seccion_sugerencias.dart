import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/favoritos_provider.dart';
import '../../services/api_service.dart';
import '../../screens/comprador/pantalla_detalle_producto.dart';
import 'tarjeta_producto.dart';

// ============================================================
// SECCIÓN "TAMBIÉN PODRÍA GUSTARTE"
// Fila horizontal de productos reales de la app (no mocks) con efecto hover.
// 🔌 GET /productos (mismo endpoint que el catálogo); cuando el backend
// exponga /api/productos/sugerencias?carritoId={id} basta con cambiar la
// llamada de _cargarSugerencias por esa ruta.
// ============================================================

class SeccionSugerencias extends StatefulWidget {
  final String userId;

  const SeccionSugerencias({super.key, required this.userId});

  @override
  State<SeccionSugerencias> createState() => _SeccionSugerenciasState();
}

class _SeccionSugerenciasState extends State<SeccionSugerencias> {
  List<ProductoModelo> _productos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarSugerencias();
  }

  Future<void> _cargarSugerencias() async {
    try {
      final productos = await ApiService.getProductos();
      if (!mounted) return;
      setState(() {
        _productos = productos.take(10).toList();
        _cargando = false;
      });
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto)),
      );
    }
    if (_productos.isEmpty) return const SizedBox.shrink();

    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFFC9A84C), size: 18),
            const SizedBox(width: 8),
            Text(
              'También podría gustarte',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: CraftHubColors.textoPrincipal(oscuro),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _productos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return _TarjetaSugerencia(producto: _productos[index], userId: widget.userId);
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TARJETA DE PRODUCTO SUGERIDO
// ============================================================
class _TarjetaSugerencia extends StatefulWidget {
  final ProductoModelo producto;
  final String userId;
  const _TarjetaSugerencia({required this.producto, required this.userId});

  @override
  State<_TarjetaSugerencia> createState() => _TarjetaSugerenciaState();
}

class _TarjetaSugerenciaState extends State<_TarjetaSugerencia>
    with SingleTickerProviderStateMixin {
  bool _estaHover = false;
  late AnimationController _ctrl;
  late Animation<double> _zoom;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _zoom = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final favorito = context.watch<FavoritosProvider>().esProductoFavorito(producto.id);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _estaHover = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _estaHover = false);
        _ctrl.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          PantallaDetalleProducto.mostrar(
            context,
            productoId: producto.id,
            productoPrevisualizado: producto,
            userId: widget.userId,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 185,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _estaHover ? 0.15 : 0.07),
                blurRadius: _estaHover ? 18 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Imagen con zoom
                AnimatedBuilder(
                  animation: _zoom,
                  builder: (_, child) => Transform.scale(scale: _zoom.value, child: child),
                  child: Image.network(
                    producto.imagenUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: CraftHubColors.vinoTintoSuave,
                      child: const Icon(Icons.image_outlined, size: 32, color: CraftHubColors.vinoTinto),
                    ),
                  ),
                ),
                // Overlay inferior siempre visible en sugerencias
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xB8000000),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          producto.nombre,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '\$${producto.precio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Botón favorito
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => context.read<FavoritosProvider>().alternarProducto(producto),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.9),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6),
                        ],
                      ),
                      child: Icon(
                        favorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 14,
                        color: favorito ? CraftHubColors.vinoTinto : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
