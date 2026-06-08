import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/carrito_provider.dart';
import '../../models/carrito_model.dart';
import '../../widgets/comprador/selector_carrito.dart';
import '../../widgets/comprador/tarjeta_item_carrito.dart';
import '../../widgets/comprador/panel_resumen_pedido.dart';
import '../../widgets/comprador/seccion_sugerencias.dart';
import '../../core/theme/app_theme.dart';

// ============================================================
// PANTALLA: MI CARRITO
// Usa el Sidebar y TopBar ya existentes en tu proyecto.
//
// INTEGRACIÓN EN TU SCAFFOLD PRINCIPAL:
//   Cuando el índice de navegación del sidebar sea "Mi carrito"
//   (índice 1), muestra este widget como body del contenido.
//
// Ejemplo de uso dentro de tu pantalla principal:
//
//   body: Row(
//     children: [
//       SidebarComprador(...),   // tu widget existente
//       Expanded(
//         child: Column(
//           children: [
//             TopBarComprador(...),  // tu widget existente
//             Expanded(child: PantallaCarrito()),
//           ],
//         ),
//       ),
//     ],
//   ),
// ============================================================

class PantallaCarrito extends StatelessWidget {
  const PantallaCarrito({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CarritoProvider(),
      child: const _ContenidoCarrito(),
    );
  }
}

class _ContenidoCarrito extends StatelessWidget {
  const _ContenidoCarrito();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CarritoProvider>();
    final carrito = provider.carritoActivo;
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: esModoOscuro ? AppColors.fondoOscuro : AppColors.fondoClaro,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ──────────────────────────────────────────
                  // COLUMNA IZQUIERDA — Lista de items
                  // ──────────────────────────────────────────
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado con selector de carrito y botón vaciar
                        Row(
                          children: [
                            const SelectorCarrito(),
                            const Spacer(),
                            if (carrito.items.isNotEmpty)
                              _BotonVaciarCarrito(
                                alPresionar: () => _confirmarVaciar(context, provider),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Estado vacío o lista de items
                        if (carrito.items.isEmpty)
                          _EstadoCarritoVacio(esModoOscuro: esModoOscuro)
                        else
                          ...carrito.items.map(
                            (item) => TarjetaItemCarrito(key: ValueKey(item.id), item: item),
                          ),

                        const SizedBox(height: 32),

                        // Sección de sugerencias
                        SeccionSugerencias(sugerencias: sugerenciasMock),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // ──────────────────────────────────────────
                  // COLUMNA DERECHA — Resumen del pedido
                  // ──────────────────────────────────────────
                  if (carrito.items.isNotEmpty)
                    const PanelResumenPedido(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Diálogo de confirmación para vaciar el carrito
  void _confirmarVaciar(BuildContext context, CarritoProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
            SizedBox(width: 10),
            Text(
              'Vaciar carrito',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro que deseas eliminar todos los productos de este carrito?',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.grey[500],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              provider.vaciarCarrito();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Vaciar',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ESTADO VACÍO DEL CARRITO
// ============================================================
class _EstadoCarritoVacio extends StatelessWidget {
  final bool esModoOscuro;
  const _EstadoCarritoVacio({required this.esModoOscuro});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: esModoOscuro ? AppColors.panelOscuro : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: esModoOscuro
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: esModoOscuro
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.12),
          ),
          const SizedBox(height: 16),
          Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: esModoOscuro
                  ? AppColors.textoOscuro
                  : AppColors.textoClaro,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explora el catálogo y agrega productos\nde artesanos panameños.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: esModoOscuro
                  ? AppColors.textoSecOscuro
                  : AppColors.textoSecClaro,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navegar al catálogo (índice 0 del sidebar)
            },
            icon: const Icon(Icons.explore_outlined, size: 18),
            label: const Text(
              'Explorar catálogo',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vinoTinto,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BOTÓN "VACIAR CARRITO"
// ============================================================
class _BotonVaciarCarrito extends StatefulWidget {
  final VoidCallback alPresionar;
  const _BotonVaciarCarrito({required this.alPresionar});

  @override
  State<_BotonVaciarCarrito> createState() => _BotonVaciarCarritoState();
}

class _BotonVaciarCarritoState extends State<_BotonVaciarCarrito> {
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _hover ? Colors.red.withOpacity(0.08) : Colors.transparent,
            border: Border.all(
              color: _hover
                  ? Colors.red.withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 15,
                color: _hover ? Colors.red[400] : Colors.grey[400],
              ),
              const SizedBox(width: 6),
              Text(
                'Vaciar carrito',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: _hover ? Colors.red[400] : Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}