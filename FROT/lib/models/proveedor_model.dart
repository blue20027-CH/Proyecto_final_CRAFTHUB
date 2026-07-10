// lib/models/proveedor_model.dart
// Modelo para la Red de Proveedores (pantalla del vendedor).

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
