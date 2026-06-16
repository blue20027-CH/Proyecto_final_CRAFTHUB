import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/producto_model.dart';
import '../models/artesano_model.dart';

class CompradorApiService {
  static const String baseUrl = 'http://127.0.0.1:8080';

  // AQUI CONECTARAS TU API DE PYTHON
  // Ejemplo esperado en FastAPI:
  // GET http://localhost:8000/api/productos
  static Future<List<ProductoModel>> obtenerProductos() async {
    final response = await http.get(Uri.parse('$baseUrl/productos')).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => ProductoModel.fromJson(item)).toList();
    }

    throw Exception('Error al obtener productos');
  }

  // AQUI CONECTARAS TU API DE PYTHON
  // Ejemplo esperado en FastAPI:
  // GET http://localhost:8000/api/artesanos
  static Future<List<ArtesanoModel>> obtenerArtesanos() async {
    final response = await http.get(Uri.parse('$baseUrl/api/artesanos'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => ArtesanoModel.fromJson(item)).toList();
    }

    throw Exception('Error al obtener artesanos');
  }
}
