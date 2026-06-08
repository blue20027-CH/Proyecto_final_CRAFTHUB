// 🔌 Mapea la respuesta de GET /api/artesanos
class ArtesanoModelo {
  final String id;
  final String nombre;
  final String especialidad;
  final String categoria;
  final String provincia;
  final String fotoUrl;
  final String fotoPortadaUrl;
  final double rating;
  final int totalResenas;
  final int totalVentas;
  final int anosExperiencia;
  final bool estaVerificado;
  final List<String> especialidades;
  final String descripcion;
  bool esFavorito;

  ArtesanoModelo({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.categoria,
    required this.provincia,
    required this.fotoUrl,
    required this.fotoPortadaUrl,
    required this.rating,
    required this.totalResenas,
    required this.totalVentas,
    required this.anosExperiencia,
    required this.estaVerificado,
    required this.especialidades,
    required this.descripcion,
    this.esFavorito = false,
  });

  // 🔌 Convierte JSON del backend en modelo
  factory ArtesanoModelo.fromJson(Map<String, dynamic> json) {
    return ArtesanoModelo(
      id:               json['id'],
      nombre:           json['nombre'],
      especialidad:     json['especialidad'],
      categoria:        json['categoria'],
      provincia:        json['provincia'],
      fotoUrl:          json['foto_url'],
      fotoPortadaUrl:   json['foto_portada_url'],
      rating:           (json['rating'] as num).toDouble(),
      totalResenas:     json['total_resenas'],
      totalVentas:      json['total_ventas'],
      anosExperiencia:  json['anos_experiencia'],
      estaVerificado:   json['esta_verificado'] ?? false,
      especialidades:   List<String>.from(json['especialidades'] ?? []),
      descripcion:      json['descripcion'] ?? '',
      esFavorito:       json['es_favorito'] ?? false,
    );
  }
}