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
  
 String get bannerEfectivo {
  if (fotoPortadaUrl.isNotEmpty && fotoPortadaUrl != fotoUrl) {
    return fotoPortadaUrl;
  }
  const banners = {
    'Vestir':      'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=900',
    'Artesanía':   'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=900',
    'Muebles':     'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=900',
    'Joyería':     'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=900',
    'Alimentos':   'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900',
    'Accesorios':  'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=900',
    'Calzado':     'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=900',
  };
  final key = banners.keys.firstWhere(
    (k) => categoria.toLowerCase().contains(k.toLowerCase()),
    orElse: () => '',
  );
  return banners[key] ?? 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=900';
}
  factory ArtesanoModelo.fromJson(Map<String, dynamic> json) {
    final categorias = (json['categorias'] as List?)
            ?.map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList() ??
        <String>[];
    final especialidades = (json['especialidades'] as List?)
            ?.map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList() ??
        categorias;
    final categoriaPrincipal =
        categorias.isNotEmpty ? categorias.first : 'Artesanias';
    final foto = (json['foto_url'] ?? json['foto'] ?? '').toString();

    return ArtesanoModelo(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? 'Artesano local').toString(),
      especialidad: (json['especialidad'] ?? categoriaPrincipal).toString(),
      categoria: (json['categoria'] ?? categoriaPrincipal).toString(),
      provincia: (json['provincia'] ?? json['ubicacion'] ?? '').toString(),
      fotoUrl: foto,
     fotoPortadaUrl:
    (json['foto_portada'] ?? json['foto_portada_url'] ?? json['banner_url'] ?? foto).toString(),
      rating: double.tryParse((json['rating'] ?? '4.8').toString()) ?? 4.8,
      totalResenas:
          int.tryParse((json['total_resenas'] ?? '0').toString()) ?? 0,
      totalVentas: int.tryParse(
            (json['total_ventas'] ?? json['total_productos'] ?? '0')
                .toString(),
          ) ??
          0,
      anosExperiencia:
          int.tryParse((json['anos_experiencia'] ?? '1').toString()) ?? 1,
      estaVerificado: json['esta_verificado'] ?? false,
      especialidades: especialidades,
      descripcion: (json['descripcion'] ?? '').toString(),
      esFavorito: json['es_favorito'] ?? false,
    );
  }
}
