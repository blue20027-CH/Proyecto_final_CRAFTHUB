// 🔌 Modelos para la pantalla de detalle de producto.
// Mapeados para consumir GET /productos/{id} y GET /productos/{id}/similares
// (pendientes en el backend) y GET /productos/{id}/comentarios (ya expuesto
// en productos_router.py, con columnas nombre/comentario/created_at).
import '../widgets/comprador/tarjeta_producto.dart';

class ComentarioModelo {
  final String id;
  final String autor;
  final String avatarUrl;
  final String fecha;
  final double calificacion;
  final String texto;
  final String fotoUrl;

  const ComentarioModelo({
    required this.id,
    required this.autor,
    required this.avatarUrl,
    required this.fecha,
    required this.calificacion,
    required this.texto,
    this.fotoUrl = '',
  });

  factory ComentarioModelo.fromJson(Map<String, dynamic> json) {
    final creadoEn = (json['created_at'] ?? json['fecha'] ?? '').toString();
    return ComentarioModelo(
      id:           (json['id'] ?? '').toString(),
      autor:        (json['nombre'] ?? json['autor'] ?? json['usuario'] ?? 'Usuario CraftHub').toString(),
      avatarUrl:    (json['avatar_url'] ?? json['foto'] ?? '').toString(),
      fecha:        creadoEn.length >= 10 ? creadoEn.substring(0, 10) : creadoEn,
      calificacion: double.tryParse((json['calificacion'] ?? 5).toString()) ?? 5,
      texto:        (json['texto'] ?? json['comentario'] ?? '').toString(),
      // 🔌 el backend aún no persiste foto por comentario; se mapea por si se
      // agrega la columna `foto_url` en la tabla `comentarios` más adelante.
      fotoUrl:      (json['foto_url'] ?? '').toString(),
    );
  }
}

class ProductoSimilarModelo {
  final String id;
  final String nombre;
  final String autor;
  final bool verificado;
  final double calificacion;
  final int totalResenas;
  final double precio;
  final String imagenUrl;

  const ProductoSimilarModelo({
    required this.id,
    required this.nombre,
    required this.autor,
    required this.verificado,
    required this.calificacion,
    required this.totalResenas,
    required this.precio,
    required this.imagenUrl,
  });

  factory ProductoSimilarModelo.fromJson(Map<String, dynamic> json) {
    return ProductoSimilarModelo(
      id:            json['id'].toString(),
      nombre:        (json['nombre'] ?? '').toString(),
      autor:         (json['artesano'] ?? json['creador'] ?? 'Artesano local').toString(),
      verificado:    json['verificado'] ?? true,
      calificacion:  double.tryParse((json['calificacion'] ?? 0).toString()) ?? 0,
      totalResenas:  int.tryParse((json['total_resenas'] ?? 0).toString()) ?? 0,
      precio:        double.tryParse((json['precio'] ?? 0).toString()) ?? 0,
      imagenUrl:     (json['imagen_url'] ?? json['imagen'] ?? json['img'] ?? '').toString(),
    );
  }

  // Conversión de respaldo: se usa cuando el backend aún no expone
  // /productos/{id}/similares y se recurre al listado general de productos.
  factory ProductoSimilarModelo.desdeProducto(ProductoModelo p) {
    return ProductoSimilarModelo(
      id: p.id,
      nombre: p.nombre,
      autor: p.artesano,
      verificado: true,
      calificacion: 4.7,
      totalResenas: 12,
      precio: p.precio,
      imagenUrl: p.imagenUrl,
    );
  }
}

class ProductoDetalleModelo {
  final String id;
  final String nombre;
  final String etiquetaCategoria;
  final double precio;
  final String imagenUrl;
  final String creador;
  final bool creadorVerificado;
  final String ubicacion;
  final double calificacion;
  final int totalValoraciones;
  final String descripcion;
  final String categoria;
  final String materiales;
  final String tecnica;
  final String dimensiones;
  bool esFavorito;

  ProductoDetalleModelo({
    required this.id,
    required this.nombre,
    required this.etiquetaCategoria,
    required this.precio,
    required this.imagenUrl,
    required this.creador,
    required this.creadorVerificado,
    required this.ubicacion,
    required this.calificacion,
    required this.totalValoraciones,
    required this.descripcion,
    required this.categoria,
    required this.materiales,
    required this.tecnica,
    required this.dimensiones,
    this.esFavorito = false,
  });

  factory ProductoDetalleModelo.fromJson(Map<String, dynamic> json) {
    return ProductoDetalleModelo(
      id:                 json['id'].toString(),
      nombre:             (json['nombre'] ?? '').toString(),
      etiquetaCategoria:  (json['etiqueta_categoria'] ?? json['categoria'] ?? 'Artesanía').toString(),
      precio:             double.tryParse((json['precio'] ?? 0).toString()) ?? 0,
      imagenUrl:          (json['imagen_url'] ?? json['imagen'] ?? json['img'] ?? '').toString(),
      creador:            (json['artesano'] ?? json['creador'] ?? 'Artesano local').toString(),
      creadorVerificado:  json['creador_verificado'] ?? true,
      ubicacion:          (json['ubicacion'] ?? json['provincia'] ?? json['origen'] ?? 'Panamá').toString(),
      calificacion:       double.tryParse((json['calificacion'] ?? 0).toString()) ?? 0,
      totalValoraciones:  int.tryParse((json['total_valoraciones'] ?? 0).toString()) ?? 0,
      descripcion:        (json['descripcion'] ?? '').toString(),
      categoria:          (json['categoria'] ?? 'General').toString(),
      materiales:         (json['materiales'] ?? 'No especificado').toString(),
      tecnica:            (json['tecnica'] ?? 'Hecho a mano').toString(),
      dimensiones:        (json['dimensiones'] ?? 'No especificado').toString(),
      esFavorito:         json['es_favorito'] ?? false,
    );
  }

  // Construye un detalle provisional a partir de la tarjeta ya cargada en
  // pantalla (home / grid), para pintar la pantalla al instante mientras
  // se completa la petición GET /productos/{id} en segundo plano.
  factory ProductoDetalleModelo.previsualizacion(ProductoModelo p) {
    return ProductoDetalleModelo(
      id: p.id,
      nombre: p.nombre,
      etiquetaCategoria: p.categoria,
      precio: p.precio,
      imagenUrl: p.imagenUrl,
      creador: p.artesano,
      creadorVerificado: true,
      ubicacion: p.provincia,
      calificacion: 0,
      totalValoraciones: 0,
      descripcion: '',
      categoria: p.categoria,
      materiales: 'No especificado',
      tecnica: 'Hecho a mano',
      dimensiones: 'No especificado',
      esFavorito: p.esFavorito,
    );
  }
}
