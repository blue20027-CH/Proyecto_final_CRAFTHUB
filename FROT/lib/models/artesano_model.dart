
class ArtesanoModel {
  final String nombre;
  final String imagen;

  ArtesanoModel({
    required this.nombre,
    required this.imagen,
  });

  factory ArtesanoModel.fromJson(Map<String, dynamic> json) {
    return ArtesanoModel(
      nombre: json['nombre'] ?? '',
      imagen: json['imagen'] ?? '',
    );
  }
}