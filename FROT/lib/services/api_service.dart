// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/comprador/tarjeta_producto.dart';

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
}
