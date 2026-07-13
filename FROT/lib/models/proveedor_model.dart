// lib/models/proveedor_model.dart
// Modelo para la Red de Proveedores (pantalla del vendedor).

// Foto por defecto según categoría, para cuando el proveedor no subió su
// propia imagen (mismo patrón que bannerPorCategoria en artesano_modelo.dart).
const Map<String, String> _imagenesPorCategoriaProveedor = {
  'Cuero':                 'https://images.unsplash.com/photo-1531310197839-ccf54634509e?w=600',
  'Textiles':              'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=600',
  'Cerámica':              'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=600',
  'Cuentas y abalorios':   'https://images.unsplash.com/photo-1611955167811-4711904bb9f8?w=600',
  'Metales':               'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=600',
  'Madera':                'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600',
  'Ceras y velas':         'https://images.unsplash.com/photo-1602523961358-f9f03dd557db?w=600',
  'Pinturas y tintes':     'https://images.unsplash.com/photo-1580136579312-94651dfd596d?w=600',
  'Herramientas':          'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?w=600',
};
const String _imagenProveedorRespaldo =
    'https://images.unsplash.com/photo-1523419409543-8c1a1b1b6a15?w=600';

String imagenPorCategoriaProveedor(String categoria) {
  final clave = _imagenesPorCategoriaProveedor.keys.firstWhere(
    (k) => categoria.toLowerCase().contains(k.toLowerCase()),
    orElse: () => '',
  );
  return _imagenesPorCategoriaProveedor[clave] ?? _imagenProveedorRespaldo;
}

class ProveedorModelo {
  final String id;
  final String nombre;
  final String propietario;
  final String categoria;
  final String ubicacion;
  final String descripcion;
  final List<String> materiales;
  final double calificacion;
  final int totalResenas;
  final bool verificado;
  final String imagenUrl;
  final String telefono;
  final String email;

  const ProveedorModelo({
    required this.id,
    required this.nombre,
    required this.propietario,
    required this.categoria,
    required this.ubicacion,
    required this.descripcion,
    required this.materiales,
    required this.calificacion,
    required this.totalResenas,
    required this.verificado,
    required this.imagenUrl,
    required this.telefono,
    required this.email,
  });

  String get imagenEfectiva =>
      imagenUrl.isNotEmpty ? imagenUrl : imagenPorCategoriaProveedor(categoria);

  factory ProveedorModelo.fromJson(Map<String, dynamic> json) {
    return ProveedorModelo(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? 'Proveedor').toString(),
      propietario: (json['propietario'] ?? '').toString(),
      categoria: (json['categoria'] ?? 'General').toString(),
      ubicacion: (json['ubicacion'] ?? 'Panamá').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      materiales: ((json['materiales'] as List?) ?? []).map((e) => e.toString()).toList(),
      calificacion: double.tryParse((json['calificacion'] ?? 0).toString()) ?? 0,
      totalResenas: int.tryParse((json['total_resenas'] ?? 0).toString()) ?? 0,
      verificado: json['verificado'] == true,
      imagenUrl: (json['imagen_url'] ?? '').toString(),
      telefono: (json['telefono'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }
}

class RespuestaProveedores {
  final List<ProveedorModelo> proveedores;
  final int total;
  final List<String> categorias;

  const RespuestaProveedores({
    required this.proveedores,
    required this.total,
    required this.categorias,
  });
}
