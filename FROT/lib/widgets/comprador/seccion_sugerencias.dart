import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ============================================================
// SECCIÓN "TAMBIÉN PODRÍA GUSTARTE"
// Fila horizontal de productos sugeridos con efecto hover.
// TODO [API]: GET /api/productos/sugerencias?carritoId={id}
// ============================================================

class SeccionSugerencias extends StatelessWidget {
  final List<Map<String, dynamic>> sugerencias;

  const SeccionSugerencias({super.key, required this.sugerencias});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: Color(0xFFC9A84C), size: 18),
            const SizedBox(width: 8),
            Text(
              'También podría gustarte',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textoOscuro
                    : AppColors.textoClaro,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Lista horizontal de sugerencias
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sugerencias.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return _TarjetaSugerencia(datos: sugerencias[index]);
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
  final Map<String, dynamic> datos;
  const _TarjetaSugerencia({required this.datos});

  @override
  State<_TarjetaSugerencia> createState() => _TarjetaSugerenciaState();
}

class _TarjetaSugerenciaState extends State<_TarjetaSugerencia>
    with SingleTickerProviderStateMixin {
  bool _estaHover = false;
  bool _esFavorito = false;
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 185,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_estaHover ? 0.15 : 0.07),
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
                builder: (_, child) =>
                    Transform.scale(scale: _zoom.value, child: child),
                child: Image.network(
                  widget.datos['imagen'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFFF0EBE3)),
                ),
              ),
              // Overlay inferior siempre visible en sugerencias
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.72),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.datos['nombre'] as String,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '\$${(widget.datos['precio'] as double).toStringAsFixed(2)}',
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
                  onTap: () => setState(() => _esFavorito = !_esFavorito),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      _esFavorito
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 14,
                      color: _esFavorito
                          ? AppColors.vinoTinto
                          : Colors.grey[400],
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