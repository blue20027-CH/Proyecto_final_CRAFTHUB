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
