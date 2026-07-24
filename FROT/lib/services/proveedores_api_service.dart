import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/proveedor_model.dart';

class ProveedoresApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  /// 🔗 GET /api/proveedores?q=&categoria=&ubicacion=&calificacion_min=&orden=
  static Future<RespuestaProveedores> cargarProveedores({
    String? q,
    String? categoria,
    String? ubicacion,
    double? calificacionMin,
    String orden = 'relevantes',
  }) async {
    final params = <String, String>{'orden': orden};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (categoria != null && categoria.isNotEmpty) params['categoria'] = categoria;
    if (ubicacion != null && ubicacion.isNotEmpty) params['ubicacion'] = ubicacion;
    if (calificacionMin != null) params['calificacion_min'] = calificacionMin.toString();

    final uri = Uri.parse('$baseUrl/api/proveedores').replace(queryParameters: params);
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'No se pudieron cargar los proveedores');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return RespuestaProveedores(
      proveedores: ((data['proveedores'] as List?) ?? [])
          .map((p) => ProveedorModelo.fromJson(p as Map<String, dynamic>))
          .toList(),
      total: int.tryParse((data['total'] ?? 0).toString()) ?? 0,
      categorias: ((data['categorias'] as List?) ?? []).map((e) => e.toString()).toList(),
    );
  }

  /// 🔗 POST /api/proveedores
  static Future<ProveedorModelo> crearProveedor({
    required String nombre,
    String? propietario,
    required String categoria,
    required String ubicacion,
    String? descripcion,
    List<String> materiales = const [],
    String? imagenUrl,
    String? telefono,
    String? email,
    String? creadoPor,
  }) async {
    final uri = Uri.parse('$baseUrl/api/proveedores');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombre': nombre,
            'propietario': propietario,
            'categoria': categoria,
            'ubicacion': ubicacion,
            'descripcion': descripcion,
            'materiales': materiales,
            'imagen_url': imagenUrl,
            'telefono': telefono,
            'email': email,
            'creado_por': creadoPor,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'No se pudo agregar el proveedor');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ProveedorModelo.fromJson(data['proveedor'] as Map<String, dynamic>);
  }
}
