import 'package:flutter/material.dart';
import 'tarjeta_favorito.dart';

/// Grid tipo Masonry para el catálogo de favoritos.
/// Implementado con un CustomScrollView de dos columnas con alturas variables.
/// Solo esta sección hace scroll, no la pantalla completa.
class GridMasonryFavoritos extends StatelessWidget {
  final List<ModeloFavorito> productos;
  final VoidCallback? alQuitarFavorito;

  const GridMasonryFavoritos({
    super.key,
    required this.productos,
    this.alQuitarFavorito,
  });

  // Alturas variables para efecto Masonry real
  static const List<double> _alturasMasonry = [
    220, 280, 240, 200, 260, 300, 210, 250, 230, 270,
    195, 285, 245, 215, 265, 290, 205, 255, 235, 275,
  ];

  double _obtenerAltura(int indice) {
    return _alturasMasonry[indice % _alturasMasonry.length];
  }

  @override
  Widget build(BuildContext context) {
    // Dividir productos en dos columnas para simular Masonry
    final columnaIzquierda = <ModeloFavorito>[];
    final columnaDerecha = <ModeloFavorito>[];

    for (int i = 0; i < productos.length; i++) {
      if (i % 2 == 0) {
        columnaIzquierda.add(productos[i]);
      } else {
        columnaDerecha.add(productos[i]);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final anchoPorColumna = (constraints.maxWidth - 12) / 2;

        return SingleChildScrollView(
          // 🎯 Solo este widget tiene scroll — no la pantalla completa
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna izquierda
              SizedBox(
                width: anchoPorColumna,
                child: Column(
                  children: List.generate(columnaIzquierda.length, (i) {
                    final indiceReal = i * 2;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TarjetaFavorito(
                        producto: columnaIzquierda[i],
                        altura: _obtenerAltura(indiceReal),
                        alQuitarFavorito: alQuitarFavorito,
                        alAgregarAlCarrito: () {
                          // 🔗 API: POST /api/v1/carrito/agregar
                          // Body: { productoId: producto.id, cantidad: 1 }
                        },
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(width: 12),

              // Columna derecha
              SizedBox(
                width: anchoPorColumna,
                child: Column(
                  children: List.generate(columnaDerecha.length, (i) {
                    final indiceReal = i * 2 + 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TarjetaFavorito(
                        producto: columnaDerecha[i],
                        altura: _obtenerAltura(indiceReal),
                        alQuitarFavorito: alQuitarFavorito,
                        alAgregarAlCarrito: () {
                          // 🔗 API: POST /api/v1/carrito/agregar
                        },
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}