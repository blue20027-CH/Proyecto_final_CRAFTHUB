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
    return jsonDecode(response.body);
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
    final data = jsonDecode(body);
    return data['url'] ?? '';
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
}