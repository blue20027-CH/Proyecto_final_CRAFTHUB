import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8080';

  // LOGIN
  static Future<Map<String, dynamic>> login(
      String email, String password, String modo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'modo': modo}),
    );
    return jsonDecode(response.body);
  }

  // PRODUCTOS
  static Future<List<dynamic>> getProductos({String? categoria}) async {
    final uri = Uri.parse('$baseUrl/productos').replace(
        queryParameters: categoria != null ? {'categoria': categoria} : null);
    final response = await http.get(uri);
    return jsonDecode(response.body);
  }

  // NOTIFICACIONES
  static Future<Map<String, dynamic>> getNotificaciones(String compradorId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/pagos/notificaciones/comprador/$compradorId'),
    );
    return jsonDecode(response.body);
  }

  // CREAR PEDIDO
  static Future<Map<String, dynamic>> crearPedido(Map<String, dynamic> pedido) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/pagos/crear'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(pedido),
    );
    return jsonDecode(response.body);
  }
}