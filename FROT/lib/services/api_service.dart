// lib/services/api_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/artesano_modelo.dart';
import '../widgets/comprador/tarjeta_producto.dart';
import '../widgets/vendedor/tarjeta_tutorial.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8080';

  static Future<List<ProductoModelo>> getProductos({
    String? categoria,
    String? busqueda,
  }) async {
    final params = <String, String>{};
    if (categoria != null && categoria != 'Todos') params['categoria'] = categoria;
    if (busqueda != null && busqueda.isNotEmpty) params['busqueda'] = busqueda;

    final uri = Uri.parse('$baseUrl/productos').replace(queryParameters: params);
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Error al cargar productos: ${response.statusCode} ${response.body}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ProductoModelo.fromJson(json)).toList();
  }

  // Registra una visita al perfil público de un artesano (para el dashboard
  // del vendedor). No bloquea la UI si falla: es una métrica, no algo crítico.
  static Future<void> registrarVisitaPerfil(String nombreArtesano) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/vendedor/visita-perfil'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': nombreArtesano}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Silencioso: no afecta la experiencia del comprador viendo el perfil.
    }
  }

  static Future<List<ArtesanoModelo>> getArtesanos({
    String? categoria,
    String? provincia,
    int limite = 8,
  }) async {
    final params = <String, String>{};
    if (categoria != null && !categoria.startsWith('Todas')) {
      params['categoria'] = categoria;
    }
    if (provincia != null && !provincia.startsWith('Todas')) {
      params['provincia'] = provincia;
    }

    final uri = Uri.parse('$baseUrl/artesanos/').replace(
      queryParameters: params.isEmpty ? null : params,
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Error al cargar artesanos: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> data = decoded is Map<String, dynamic>
        ? (decoded['artesanos'] as List<dynamic>? ?? [])
        : (decoded as List<dynamic>);

    return data
        .take(limite)
        .map((json) => ArtesanoModelo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> login(
      String email, String password, String modo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'modo': modo}),
    );
    return jsonDecode(response.body);
  }

  // Notificaciones reales (no derivadas de pedidos), p. ej. "te marcaron favorito".
  static Future<Map<String, dynamic>> getNotificacionesUsuario(String userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/notificaciones/usuario/$userId'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Error al cargar notificaciones: ${response.statusCode} ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> marcarNotificacionesLeidas(String userId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/notificaciones/usuario/$userId/marcar-leidas'),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Silencioso: en el peor caso el puntito rojo tarda un poco en apagarse.
    }
  }

  static Future<void> marcarNotificacionLeida(String notificacionId) async {
    try {
      await http.patch(
        Uri.parse('$baseUrl/api/notificaciones/$notificacionId/leida'),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Silencioso: no bloquea la interacción del usuario.
    }
  }

  static Future<Map<String, dynamic>> getNotificacionesComprador(String compradorId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/pagos/notificaciones/comprador/$compradorId'),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> crearPedido(Map<String, dynamic> pedido) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/pagos/crear'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(pedido),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['detail'] ?? 'No se pudo completar el pago.');
    }
    return data;
  }

  /// 🔗 GET /api/pagos/metodos — métodos de pago disponibles (Tarjeta,
  /// Transferencia, Yappy, PayPal, Banistmo).
  static Future<List<Map<String, dynamic>>> getMetodosPago() async {
    final response = await http.get(Uri.parse('$baseUrl/api/pagos/metodos'));
    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los métodos de pago.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ((data['metodos'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  /// 🔗 POST /api/pagos/resumen — subtotal, envío y total antes de pagar.
  static Future<Map<String, dynamic>> resumenPedido({
    required List<Map<String, dynamic>> carrito,
    required String ubicacionComprador,
  }) async {
    final uri = Uri.parse('$baseUrl/api/pagos/resumen').replace(
      queryParameters: {'ubicacion_comprador': ubicacionComprador},
    );
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(carrito),
    );
    if (response.statusCode != 200) {
      throw Exception('No se pudo calcular el resumen del pedido.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getPerfil(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/perfil/$userId'));
    return jsonDecode(response.body);
  }

  // ── CARRITO ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> getCarritos(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/carrito/$userId'));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> crearCarrito(String userId, String nombre) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/carrito/crear'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'nombre': nombre}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> agregarItem({
    required String carritoId,
    required int productoId,
    required String nombreProducto,
    required double precio,
    String imagenUrl = '',
    String artesano = '',
    int cantidad = 1,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/carrito/agregar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'carrito_id': carritoId,
        'producto_id': productoId,
        'nombre_producto': nombreProducto,
        'imagen_url': imagenUrl,
        'artesano': artesano,
        'precio': precio,
        'cantidad': cantidad,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<void> actualizarCantidad(String itemId, int cantidad) async {
    await http.patch(
      Uri.parse('$baseUrl/api/carrito/item/$itemId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cantidad': cantidad}),
    );
  }

  static Future<void> eliminarItem(String itemId) async {
    await http.delete(Uri.parse('$baseUrl/api/carrito/item/$itemId'));
  }

  static Future<void> vaciarCarrito(String carritoId) async {
    await http.delete(Uri.parse('$baseUrl/api/carrito/vaciar/$carritoId'));
  }

  // ── TUTORIALES ──────────────────────────────────────────────

  static Future<List<ModeloTutorial>> getTutoriales({String? categoria}) async {
    final params = <String, String>{};
    if (categoria != null && categoria != 'Todas') {
      params['categoria'] = categoria;
    }

    final uri = Uri.parse('$baseUrl/api/tutoriales').replace(
      queryParameters: params.isEmpty ? null : params,
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Error al cargar tutoriales: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> data = decoded['tutoriales'] as List<dynamic>? ?? [];
    return data.map((json) => ModeloTutorial.fromJson(json)).toList();
  }

  static Future<List<ModeloTutorial>> getMisVideos(String creadorId) async {
    final uri = Uri.parse('$baseUrl/api/tutoriales/mis-videos')
        .replace(queryParameters: {'creador_id': creadorId});
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Error al cargar mis videos: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> data = decoded['tutoriales'] as List<dynamic>? ?? [];
    return data.map((json) => ModeloTutorial.fromJson(json)).toList();
  }

  // 🔌 GET /api/tutoriales/{id} → detalle actualizado del video (incluye
  // descripción completa y el conteo de vistas más reciente).
  static Future<ModeloTutorial> getTutorial(String id) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/tutoriales/$id'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Error al cargar el video: ${response.statusCode}');
    }
    return ModeloTutorial.fromJson(jsonDecode(response.body));
  }

  // 🔌 POST /api/tutoriales/{id}/vista → registra una vista real en el
  // backend y devuelve el nuevo total (fuente de verdad, evita duplicar
  // el conteo si el usuario reabre la pantalla varias veces en el cliente).
  static Future<int> registrarVistaTutorial(String id) async {
    final response = await http
        .post(Uri.parse('$baseUrl/api/tutoriales/$id/vista'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Error al registrar la vista: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['vistas'] as num?)?.toInt() ?? 0;
  }

  static Future<Map<String, dynamic>> getDetalleArtesano(String nombre) async {
    final response = await http.get(
      Uri.parse('$baseUrl/artesanos/${Uri.encodeComponent(nombre)}'),
    );
    return jsonDecode(response.body);
  }

  static Future<void> actualizarPerfil(String userId, Map<String, dynamic> datos) async {
    await http.patch(
      Uri.parse('$baseUrl/api/perfil/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );
  }

  static Future<String> subirFotoPerfil(String userId, List<int> bytes, String nombreArchivo, {String tipo = 'foto'}) async {
    final uri = Uri.parse('$baseUrl/api/perfil/$userId/subir-foto?tipo=$tipo');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: nombreArchivo,
    ));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw Exception('Error al subir la imagen: ${response.statusCode} $body');
    }
    final data = jsonDecode(body);
    return (data['url'] ?? '').toString();
  }

  static Future<Map<String, dynamic>> subirTutorial({
    required String titulo,
    required String youtubeUrl,
    required String creadorId,
    String? descripcion,
    String categoria = 'General',
    String? duracion,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tutoriales'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'titulo': titulo,
        'youtube_url': youtubeUrl,
        'creador_id': creadorId,
        'descripcion': descripcion,
        'categoria': categoria,
        'duracion': duracion,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al subir el tutorial: ${response.statusCode} ${response.body}');
    }
    return jsonDecode(response.body);
  }

  // ── FAVORITOS ──────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getFavoritos(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/productos/favoritos/$userId'));
    debugPrint('FAVORITOS STATUS: ${response.statusCode}');
    debugPrint('FAVORITOS BODY: ${response.body}');
    if (response.statusCode != 200) throw Exception('Error al cargar favoritos: ${response.body}');
    final decoded = jsonDecode(response.body);
    final lista = decoded['favoritos'];
    debugPrint('FAVORITOS TIPO: ${lista.runtimeType}');
    if (lista == null) return [];
    return (lista as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<void> agregarFavorito(String userId, int productoId) async {
    await http.post(
      Uri.parse('$baseUrl/productos/favoritos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'producto_id': productoId}),
    );
  }

  static Future<void> quitarFavorito(String userId, int productoId) async {
    await http.delete(Uri.parse('$baseUrl/productos/favoritos/$userId/$productoId'));
  }

  static Future<void> eliminarTutorial(String tutorialId) async {
    await http.delete(Uri.parse('$baseUrl/api/tutoriales/$tutorialId'));
  }

  // ── DETALLE DE PRODUCTO ──────────────────────────────────────
  // 🔌 GET /productos/{id} → ficha completa (descripción, materiales,
  // técnica, dimensiones, calificación, etc.)
  static Future<Map<String, dynamic>> getDetalleProducto(String productoId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/productos/$productoId'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Error al cargar el producto: ${response.statusCode} ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Crea un producto nuevo (vendedor).
  static Future<Map<String, dynamic>> crearProducto({
    required String nombre,
    required double precio,
    required int stock,
    required String categoria,
    required String creador,
    String? imagenUrl,
    String? descripcion,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/productos/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'precio': precio,
        'stock': stock,
        'categoria': categoria,
        'creador': creador,
        if (imagenUrl != null && imagenUrl.isNotEmpty) 'img': imagenUrl,
        if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
      }),
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al crear el producto: ${response.statusCode} ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Sube una foto de producto y devuelve su URL pública en Supabase Storage.
  static Future<String> subirFotoProducto(List<int> bytes, String nombreArchivo) async {
    final uri = Uri.parse('$baseUrl/productos/subir-foto');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: nombreArchivo));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('No se pudo subir la imagen: ${response.statusCode}');
    }
    final data = jsonDecode(body);
    return (data['url'] ?? '').toString();
  }

  static Future<void> eliminarProducto(String productoId) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/productos/$productoId'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar el producto: ${response.statusCode} ${response.body}');
    }
  }

  // Edita nombre/precio/stock/categoría/imagen de un producto (vendedor).
  static Future<Map<String, dynamic>> actualizarProducto({
    required String productoId,
    required String nombre,
    required double precio,
    required int stock,
    required String categoria,
    String? imagenUrl,
    String? descripcion,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/productos/$productoId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'precio': precio,
        'stock': stock,
        'categoria': categoria,
        if (imagenUrl != null && imagenUrl.isNotEmpty) 'img': imagenUrl,
        if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
      }),
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar el producto: ${response.statusCode} ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // 🔌 GET /productos/{id}/similares?limite=N → recomendaciones relacionadas
  static Future<List<Map<String, dynamic>>> getProductosSimilares(
    String productoId, {
    int limite = 8,
  }) async {
    final uri = Uri.parse('$baseUrl/productos/$productoId/similares')
        .replace(queryParameters: {'limite': '$limite'});
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Error al cargar productos similares: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    final List<dynamic> data = decoded is Map<String, dynamic>
        ? (decoded['productos'] as List<dynamic>? ?? [])
        : (decoded as List<dynamic>);
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // 🔌 GET /productos/{id}/comentarios → reseñas de compradores
  static Future<List<Map<String, dynamic>>> getComentariosProducto(String productoId) async {
    final uri = Uri.parse('$baseUrl/productos/$productoId/comentarios');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Error al cargar comentarios: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    final List<dynamic> data = decoded is Map<String, dynamic>
        ? (decoded['comentarios'] as List<dynamic>? ?? [])
        : (decoded as List<dynamic>);
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // POST /productos/comentarios (ya expuesto en productos_router.py).
  // 🔌 'calificacion' y 'foto_url' viajan como campos extra: el backend los
  // ignora hasta que se agreguen esas columnas a la tabla `comentarios`.
  static Future<Map<String, dynamic>> publicarComentario({
    required String productoId,
    required String texto,
    required double calificacion,
    String? nombreUsuario,
    String? userId,
    String? fotoUrl,
  }) async {
    final uri = Uri.parse('$baseUrl/productos/comentarios').replace(
      queryParameters: (userId != null && userId.isNotEmpty) ? {'user_id': userId} : null,
    );
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'producto_id': int.tryParse(productoId) ?? 0,
        'nombre': (nombreUsuario == null || nombreUsuario.isEmpty) ? 'Comprador CraftHub' : nombreUsuario,
        'comentario': texto,
        'calificacion': calificacion,
        if (fotoUrl != null && fotoUrl.isNotEmpty) 'foto_url': fotoUrl,
      }),
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al publicar comentario: ${response.statusCode} ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // 🔌 POST /productos/comentarios/subir-foto (pendiente en el backend).
  // Sigue el mismo patrón multipart que subirFotoPerfil para devolver la URL
  // pública de la imagen adjunta a un comentario.
  static Future<String> subirFotoComentario(List<int> bytes, String nombreArchivo) async {
    final uri = Uri.parse('$baseUrl/productos/comentarios/subir-foto');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: nombreArchivo));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('No se pudo subir la foto del comentario: ${response.statusCode}');
    }
    final data = jsonDecode(body);
    return (data['url'] ?? '').toString();
  }

  // ── ANUNCIOS (mensajes de CraftHub para todos los usuarios) ────────────

  static Future<Map<String, dynamic>> getAnuncios(String userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/anuncios/$userId'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Error al cargar anuncios: ${response.statusCode} ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> marcarAnunciosLeidos(String userId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/anuncios/marcar-leido'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Silencioso: en el peor caso el puntito rojo tarda un poco en apagarse.
    }
  }

  // ── PREFERENCIAS (provincias/comarcas/categorías de interés) ──────────

  static Future<Map<String, dynamic>> getPreferencias(String userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/preferencias/$userId'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Error al cargar preferencias: ${response.statusCode} ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> guardarPreferencias({
    required String userId,
    required List<String> provincias,
    required List<String> comarcas,
    required List<String> categorias,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/preferencias/guardar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'provincias': provincias,
        'comarcas': comarcas,
        'categorias': categorias,
      }),
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Error al guardar preferencias: ${response.statusCode} ${response.body}');
    }
  }
}