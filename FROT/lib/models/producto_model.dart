class ProductoModel {
  final String nombre;
  final String imagen;
  final double precio;

  ProductoModel({
    required this.nombre,
    required this.imagen,
    required this.precio,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    return ProductoModel(
      nombre: json['nombre'] ?? '',
      imagen: json['imagen'] ?? json['img'] ?? '',
      precio: double.tryParse(json['precio'].toString()) ?? 0,
    );
  }
}