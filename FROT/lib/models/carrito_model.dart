class ItemCarritoModel {
  final String id;
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

  factory ItemCarritoModel.fromJson(Map<String, dynamic> json) {
    return ItemCarritoModel(
      id: json['id'].toString(),
      productoId: json['producto_id'] ?? 0,
      nombreProducto: json['nombre_producto'] ?? '',
      descripcion: '',
      artesanoNombre: json['artesano'] ?? '',
      provincia: '',
      imagenUrl: json['imagen_url'] ?? '',
      cantidad: json['cantidad'] ?? 1,
      precioUnitario: double.tryParse(json['precio'].toString()) ?? 0.0,
    );
  }
}

class CarritoModel {
  final String id;
  final String nombre;
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

  factory CarritoModel.fromJson(Map<String, dynamic> json) {
    return CarritoModel(
      id: json['id'].toString(),
      nombre: json['nombre'] ?? 'Mi carrito',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => ItemCarritoModel.fromJson(i))
          .toList(),
      fechaCreacion: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

final List<Map<String, dynamic>> sugerenciasMock = [
  {'nombre': 'Mola Guna Yala',        'precio': 85.00, 'imagen': 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=300'},
  {'nombre': 'Collar Emberá',         'precio': 28.00, 'imagen': 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=300'},
  {'nombre': 'Camino de mesa tejido', 'precio': 42.00, 'imagen': 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=300'},
  {'nombre': 'Máscara tradicional',   'precio': 75.00, 'imagen': 'https://images.unsplash.com/photo-1566734904496-9309bb1798ae?w=300'},
  {'nombre': 'Canasta artesanal',     'precio': 36.00, 'imagen': 'https://images.unsplash.com/photo-1607344645866-009c320b63e0?w=300'},
  {'nombre': 'Jarrón decorativo',     'precio': 48.00, 'imagen': 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=300'},
];