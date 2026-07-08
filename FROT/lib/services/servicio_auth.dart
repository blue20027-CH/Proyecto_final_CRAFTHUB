import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─── 1. LOGIN CON EMAIL Y CONTRASEÑA ───────────────────────
// Endpoint FastAPI esperado: POST /api/auth/login

// RECUERDA: 
// - Si usas emulador Android, usa: 'http://10.0.2.2:8000'
// - Si usas simulador iOS o Desktop, usa: 'http://localhost:8000'
const String baseUrl = "http://127.0.0.1:8080";

Future<Map<String, dynamic>?> loginConEmailYPassword(
  String email,
  String password, {
  String modo = 'Comprador',
}) async {
  final url = Uri.parse('$baseUrl/api/auth/login');

  try {
    // Enviamos la petición POST con el Body en formato JSON
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'modo': modo,
      }),
    );

    // 200 OK: El login fue un éxito rotundo
    if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
  // ignore: avoid_print
          print("Login exitoso. Bienvenido, ${data['perfil']?['nombre'] ?? data['email']}"); 
      // Retornamos el mapa con el access_token, rol, nombre, email y foto_perfil
      return data;
    } 
    
    // 401: Credenciales incorrectas (Mapeado desde FastAPI)
    else if (response.statusCode == 401 || response.statusCode == 403) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Credenciales incorrectas');
    } 
    
    // 422: Error de validación de Pydantic (Campos mal formateados)
    else if (response.statusCode == 422) {
      throw Exception('El formato del correo o la contraseña no es válido.');
    } 
    
    // Cualquier otro error de servidor (500, 404, etc.)
    else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Error en el servidor (${response.statusCode})');
    }

  } catch (e) {
  // Captura problemas de red (como que el servidor de FastAPI esté apagado) o excepciones lanzadas arriba
  debugPrint("Error en loginConEmailYPassword: $e");
  rethrow; // Reenviamos el error para que tu UI de Flutter pueda mostrar un SnackBar o alerta
}
}

// ─── 2. REGISTRO CON EMAIL Y CONTRASEÑA ────────────────────
// Endpoint FastAPI esperado: POST /api/auth/registro
// Responde con la misma forma que el login (success, user_id, email, modo, perfil)
Future<Map<String, dynamic>?> registrarConEmailYPassword({
  required String nombre,
  required String email,
  required String password,
  required String rol,
  String? telefono,
  String? provincia,
  String? ubicacion,
}) async {
  final url = Uri.parse('$baseUrl/api/auth/registro');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'password': password,
        'rol': rol,
        'telefono': telefono,
        'provincia': provincia,
        'ubicacion': ubicacion,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'No se pudo completar el registro.');
    } else if (response.statusCode == 422) {
      throw Exception('Revisa que todos los campos tengan un formato válido.');
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Error en el servidor (${response.statusCode})');
    }
  } catch (e) {
    debugPrint("Error en registrarConEmailYPassword: $e");
    rethrow;
  }
}
