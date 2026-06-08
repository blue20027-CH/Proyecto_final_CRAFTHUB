// ============================================================
// MODELOS DEL CARRITO DE COMPRAS
// TODO [API]: Endpoints esperados en FastAPI:
//   GET    /api/carritos                    → lista de carritos del usuario
//   GET    /api/carritos/{carritoId}/items  → items de un carrito
//   POST   /api/carritos                    → crear nuevo carrito
//   PUT    /api/carritos/{carritoId}/items/{itemId} → actualizar cantidad
//   DELETE /api/carritos/{carritoId}/items/{itemId} → eliminar item
//   DELETE /api/carritos/{carritoId}        → vaciar carrito
//   POST   /api/carritos/{carritoId}/cupon → aplicar cupón
//   GET    /api/carritos/{carritoId}/factura → descargar PDF de factura
// ============================================================

class ItemCarritoModel {
  final int id;
  final int productoId;
  final String nombreProducto;
  final String descripcion;
  final String artesanoNombre;
  final String provincia;
  final String imagenUrl;
  int cantidad;
  final double precioUnitario;

  ItemCarritoModel({
    required this.id,
    required this.productoId,
    required this.nombreProducto,
    required this.descripcion,
    required this.artesanoNombre,
    required this.provincia,
    required this.imagenUrl,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotalItem => precioUnitario * cantidad;

  // TODO [API]: factory ItemCarritoModel.fromJson(Map<String, dynamic> json) { ... }
}

class CarritoModel {
  final int id;
  final String nombre; // Ej: "Compras Navidad", "Lista Mamá"
  final List<ItemCarritoModel> items;
  final DateTime fechaCreacion;

  CarritoModel({
    required this.id,
    required this.nombre,
    required this.items,
    required this.fechaCreacion,
  });

  double get subtotal => items.fold(0, (s, i) => s + i.subtotalItem);
  double get envio => subtotal > 150 ? 0.0 : 7.50;
  double get impuestos => subtotal * 0.07;
  double get total => subtotal + envio + impuestos;
  int get totalItems => items.fold(0, (s, i) => s + i.cantidad);

  // TODO [API]: factory CarritoModel.fromJson(Map<String, dynamic> json) { ... }
}

// ============================================================
// DATOS MOCK — Reemplazar con llamadas a ApiService
// ============================================================

final List<CarritoModel> carritosMock = [
  CarritoModel(
    id: 1,
    nombre: 'Mi carrito principal',
    fechaCreacion: DateTime(2025, 6, 1),
    items: [
      ItemCarritoModel(
        id: 101,
        productoId: 1,
        nombreProducto: 'Bolso tejido tradicional',
        descripcion: 'Tejido a mano con fibra natural',
        artesanoNombre: 'Rosa Martínez',
        provincia: 'Chiriquí',
        imagenUrl: 'https://images.unsplash.com/photo-1584917865442-de89be371e81?w=400',
        cantidad: 1,
        precioUnitario: 45.00,
      ),
      ItemCarritoModel(
        id: 102,
        productoId: 2,
        nombreProducto: 'Sombrero Pintao',
        descripcion: 'Pintado a mano con tintes naturales',
        artesanoNombre: 'Carlos Ruiz',
        provincia: 'Los Santos',
        imagenUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400',
        cantidad: 2,
        precioUnitario: 50.00,
      ),
      ItemCarritoModel(
        id: 103,
        productoId: 3,
        nombreProducto: 'Set de cerámica artesanal',
        descripcion: 'Hecho a mano en barro natural',
        artesanoNombre: 'Ana Santos',
        provincia: 'Herrera',
        imagenUrl: 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=400',
        cantidad: 1,
        precioUnitario: 32.00,
      ),
    ],
  ),
  CarritoModel(
    id: 2,
    nombre: 'Regalos Navidad 🎄',
    fechaCreacion: DateTime(2025, 5, 20),
    items: [
      ItemCarritoModel(
        id: 201,
        productoId: 4,
        nombreProducto: 'Mola Guna Yala',
        descripcion: 'Arte textil ancestral de la comarca',
        artesanoNombre: 'Delia Morales',
        provincia: 'Guna Yala',
        imagenUrl: 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=400',
        cantidad: 3,
        precioUnitario: 85.00,
      ),
    ],
  ),
  CarritoModel(
    id: 3,
    nombre: 'Lista para mamá 💛',
    fechaCreacion: DateTime(2025, 5, 28),
    items: [
      ItemCarritoModel(
        id: 301,
        productoId: 5,
        nombreProducto: 'Collar Emberá',
        descripcion: 'Elaborado con semillas naturales',
        artesanoNombre: 'Yira Cabrera',
        provincia: 'Emberá-Wounaan',
        imagenUrl: 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=400',
        cantidad: 1,
        precioUnitario: 28.00,
      ),
      ItemCarritoModel(
        id: 302,
        productoId: 6,
        nombreProducto: 'Vasija decorativa Coclé',
        descripcion: 'Inspirada en diseños precolombinos',
        artesanoNombre: 'Pedro Quintero',
        provincia: 'Coclé',
        imagenUrl: 'https://images.unsplash.com/photo-1607344645866-009c320b63e0?w=400',
        cantidad: 2,
        precioUnitario: 55.00,
      ),
    ],
  ),
];

// Productos sugeridos para la sección "También podría gustarte"
final List<Map<String, dynamic>> sugerenciasMock = [
  {'nombre': 'Mola Guna Yala',       'precio': 85.00, 'imagen': 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=300'},
  {'nombre': 'Collar Emberá',        'precio': 28.00, 'imagen': 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=300'},
  {'nombre': 'Camino de mesa tejido','precio': 42.00, 'imagen': 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=300'},
  {'nombre': 'Máscara tradicional',  'precio': 75.00, 'imagen': 'https://images.unsplash.com/photo-1566734904496-9309bb1798ae?w=300'},
  {'nombre': 'Canasta artesanal',    'precio': 36.00, 'imagen': 'https://images.unsplash.com/photo-1607344645866-009c320b63e0?w=300'},
  {'nombre': 'Jarrón decorativo',    'precio': 48.00, 'imagen': 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=300'},
];