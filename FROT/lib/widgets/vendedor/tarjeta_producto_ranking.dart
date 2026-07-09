import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ModeloProductoRanking {
  final int posicion;
  final String nombre;
  final String categoria;
  final String imagenUrl;
  final int ventas;
  final double ingresos;

  const ModeloProductoRanking({
    required this.posicion,
    required this.nombre,
    required this.categoria,
    required this.imagenUrl,
    required this.ventas,
    required this.ingresos,
  });
}

class TarjetaProductoRanking extends StatefulWidget {
  final ModeloProductoRanking producto;
  final bool esOscuro;
  final VoidCallback? onTap;

  const TarjetaProductoRanking({
    super.key,
    required this.producto,
    this.esOscuro = false,
    this.onTap,
  });

  @override
  State<TarjetaProductoRanking> createState() => _TarjetaProductoRankingState();
}

class _TarjetaProductoRankingState extends State<TarjetaProductoRanking> {
  bool _sobreEl = false;

  static const _coloresPodio = [
    Color(0xFFD4A843), // oro
    Color(0xFFB8C0CC), // plata
    Color(0xFFC98A4B), // bronce
  ];

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final colorTexto = CraftHubColors.textoPrincipal(widget.esOscuro);
    final colorSec = CraftHubColors.textoSecundario(widget.esOscuro);
    final esPodio = p.posicion <= 3;
    final colorBadge = esPodio
        ? _coloresPodio[p.posicion - 1]
        : CraftHubColors.borde(widget.esOscuro);

    return MouseRegion(
      onEnter: (_) => setState(() => _sobreEl = true),
      onExit: (_) => setState(() => _sobreEl = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _sobreEl
                ? (widget.esOscuro
                    ? CraftHubColors.vinoTinto.withValues(alpha: 0.16)
                    : CraftHubColors.vinoTintoSuave)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Insignia de posición
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: esPodio
                      ? LinearGradient(
                          colors: [
                            colorBadge,
                            colorBadge.withValues(alpha: 0.6),
                          ],
                        )
                      : null,
                  color: esPodio ? null : colorBadge.withValues(alpha: 0.25),
                ),
                child: Text(
                  '${p.posicion}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: esPodio ? Colors.white : colorSec,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Imagen
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  p.imagenUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 60,
                    height: 60,
                    color: CraftHubColors.borde(widget.esOscuro),
                    child: Icon(
                      Icons.image_outlined,
                      color: colorSec,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Nombre + categoría
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nombre,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorTexto,
                      ),
                    ),
                    Text(
                      p.categoria,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: colorSec,
                      ),
                    ),
                  ],
                ),
              ),

              // Ventas
              SizedBox(
                width: 50,
                child: Text(
                  '${p.ventas}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorTexto,
                  ),
                ),
              ),

              // Ingresos
              SizedBox(
                width: 80,
                child: Text(
                  '\$${p.ingresos.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CraftHubColors.vinoTinto,
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
