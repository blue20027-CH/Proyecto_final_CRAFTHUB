import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/carrito_provider.dart';
import '../../models/carrito_model.dart';
import '../../core/theme/app_theme.dart';

// ============================================================
// SELECTOR DE CARRITO (DROPDOWN MULTI-CARRITO)
// Permite al comprador cambiar entre carritos guardados
// o crear uno nuevo. Se muestra como título de la pantalla.
// ============================================================

class SelectorCarrito extends StatefulWidget {
  const SelectorCarrito({super.key});

  @override
  State<SelectorCarrito> createState() => _SelectorCarritoState();
}

class _SelectorCarritoState extends State<SelectorCarrito> {
  OverlayEntry? _overlay;
  final GlobalKey _key = GlobalKey();
  bool _abierto = false;

  void _toggleDropdown(CarritoProvider provider) {
    if (_abierto) {
      _cerrar();
    } else {
      _abrir(provider);
    }
  }

  void _abrir(CarritoProvider provider) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;

    _overlay = OverlayEntry(
      builder: (_) => GestureDetector(
        onTap: _cerrar,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              top: pos.dy + size.height + 8,
              left: pos.dx,
              child: Material(
                color: Colors.transparent,
                child: _MenuCarritos(
                  provider: provider,
                  alSeleccionar: (i) {
                    provider.cambiarCarrito(i);
                    _cerrar();
                  },
                  alCrearNuevo: () {
                    _cerrar();
                    _mostrarDialogoNuevoCarrito(context, provider);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlay!);
    if (mounted) {
      setState(() => _abierto = true);
    }
  }

  void _cerrar() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) {
      setState(() => _abierto = false);
    }
  }

  void _mostrarDialogoNuevoCarrito(BuildContext ctx, CarritoProvider provider) {
    final controlador = TextEditingController();
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.shopping_bag_outlined, color: AppColors.vinoTinto, size: 22),
            const SizedBox(width: 10),
            Text('Nuevo carrito',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.vinoTinto,
                )),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: controlador,
            autofocus: true,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ej: Regalos de cumpleaños 🎂',
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: const Color(0xFFF9F6F0),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.vinoTinto, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancelar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey[500],
                  fontSize: 13,
                )),
          ),
          ElevatedButton(
            onPressed: () {
              final nombre = controlador.text.trim();
              if (nombre.isNotEmpty) {
                provider.crearNuevoCarrito(nombre);
                Navigator.pop(dialogCtx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vinoTinto,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Crear', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   final provider = context.watch<CarritoProvider>();
   final carrito = provider.carritoActivo;
   if (carrito == null) return const SizedBox();
   final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      key: _key,
      onTap: () => _toggleDropdown(provider),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ícono del carrito
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.vinoTinto.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: AppColors.vinoTinto, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre del carrito con flecha de dropdown
                Row(
                  children: [
                    Text(
                      carrito.nombre,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: esModoOscuro ? AppColors.textoOscuro : AppColors.textoClaro,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _abierto ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.vinoTinto,
                      ),
                    ),
                  ],
                ),
                // Subtítulo con cantidad de productos
                Text(
                  '${carrito.totalItems} ${carrito.totalItems == 1 ? 'producto' : 'productos'} en tu carrito',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: esModoOscuro ? AppColors.textoSecOscuro : AppColors.textoSecClaro,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MENÚ DESPLEGABLE CON LISTA DE CARRITOS
// ============================================================
class _MenuCarritos extends StatelessWidget {
  final CarritoProvider provider;
  final ValueChanged<int> alSeleccionar;
  final VoidCallback alCrearNuevo;

  const _MenuCarritos({
    required this.provider,
    required this.alSeleccionar,
    required this.alCrearNuevo,
  });

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 300,
      constraints: const BoxConstraints(maxHeight: 360),
      decoration: BoxDecoration(
        color: esModoOscuro ? AppColors.panelOscuro : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esModoOscuro
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Mis carritos',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: esModoOscuro ? AppColors.textoSecOscuro : AppColors.textoSecClaro,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.vinoTinto.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${provider.carritos.length}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.vinoTinto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Lista de carritos
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: provider.carritos.length,
                itemBuilder: (context, index) {
                  final carrito = provider.carritos[index];
                  final esActivo = provider.indiceCarritoActivo == index;
                  return _ItemCarritoMenu(
                    carrito: carrito,
                    esActivo: esActivo,
                    alPresionar: () => alSeleccionar(index),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // Botón crear nuevo carrito
            _BotonCrearCarrito(alPresionar: alCrearNuevo),
          ],
        ),
      ),
    );
  }
}

class _ItemCarritoMenu extends StatefulWidget {
  final CarritoModel carrito;
  final bool esActivo;
  final VoidCallback alPresionar;

  const _ItemCarritoMenu({
    required this.carrito,
    required this.esActivo,
    required this.alPresionar,
  });

  @override
  State<_ItemCarritoMenu> createState() => _ItemCarritoMenuState();
}

class _ItemCarritoMenuState extends State<_ItemCarritoMenu> {
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
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: widget.esActivo
                ? AppColors.vinoTinto.withValues(alpha: 0.1)
                : _hover
                    ? (esModoOscuro
                        ? Colors.white.withValues(alpha: 0.04)
                        : const Color(0xFFF9F6F0))
                    : Colors.transparent,
          ),
          child: Row(
            children: [
              // Ícono
              Icon(
                Icons.shopping_bag_outlined,
                size: 18,
                color: widget.esActivo
                    ? AppColors.vinoTinto
                    : esModoOscuro
                        ? AppColors.textoSecOscuro
                        : AppColors.textoSecClaro,
              ),
              const SizedBox(width: 10),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.carrito.nombre,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: widget.esActivo ? FontWeight.w600 : FontWeight.w500,
                        color: widget.esActivo
                            ? AppColors.vinoTinto
                            : esModoOscuro
                                ? AppColors.textoOscuro
                                : AppColors.textoClaro,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.carrito.totalItems} items · \$${widget.carrito.total.toStringAsFixed(2)}',
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
              ),
              if (widget.esActivo)
                const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.vinoTinto),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonCrearCarrito extends StatefulWidget {
  final VoidCallback alPresionar;
  const _BotonCrearCarrito({required this.alPresionar});

  @override
  State<_BotonCrearCarrito> createState() => _BotonCrearCarritoState();
}

class _BotonCrearCarritoState extends State<_BotonCrearCarrito> {
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
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: _hover
              ? AppColors.vinoTinto.withValues(alpha: 0.06)
              : Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline, size: 16, color: AppColors.vinoTinto),
              const SizedBox(width: 8),
              const Text(
                'Crear nuevo carrito',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.vinoTinto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}