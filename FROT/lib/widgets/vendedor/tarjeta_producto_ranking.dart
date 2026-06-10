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

  const TarjetaProductoRanking({super.key, required this.producto});

  @override
  State<TarjetaProductoRanking> createState() =>
      _TarjetaProductoRankingState();
}

class _TarjetaProductoRankingState extends State<TarjetaProductoRanking> {
  bool _sobreEl = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;

    return MouseRegion(
      onEnter: (_) => setState(() => _sobreEl = true),
      onExit: (_) => setState(() => _sobreEl = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _sobreEl
              ? CraftHubColors.vinoTintoSuave
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Número
            SizedBox(
              width: 24,
              child: Text(
                '${p.posicion}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CraftHubColors.textoSecClaro,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                p.imagenUrl,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 42,
                  height: 42,
                  color: CraftHubColors.bordeClaro,
                  child: const Icon(Icons.image_outlined,
                      color: CraftHubColors.textoSecClaro, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Nombre + categoría
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CraftHubColors.textoClaro,
                    ),
                  ),
                  Text(
                    p.categoria,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: CraftHubColors.textoSecClaro,
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
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CraftHubColors.textoClaro,
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
    );
  }
}