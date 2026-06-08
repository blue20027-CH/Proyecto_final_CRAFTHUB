import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─── 1. LOGIN CON EMAIL Y CONTRASEÑA ───────────────────────
// Endpoint FastAPI esperado: POST /api/auth/login

// RECUERDA: 
// - Si usas emulador Android, usa: 'http://10.0.2.2:8000'
// - Si usas simulador iOS o Desktop, usa: 'http://localhost:8000'
final String baseUrl = "http://localhost:8000"; 

Future<Map<String, dynamic>?> loginConEmailYPassword(String email, String password) async {
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
      }),
    );

    // 200 OK: El login fue un éxito rotundo
    if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
  // ignore: avoid_print
          print("Login exitoso. Bienvenido, ${data['nombre']}"); 
      // Retornamos el mapa con el access_token, rol, nombre, email y foto_perfil
      return data;
    } 
    
    // 401: Credenciales incorrectas (Mapeado desde FastAPI)
    else if (response.statusCode == 401) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Credenciales incorrectas');
    } 
    
    // 422: Error de validación de Pydantic (Campos mal formateados)
    else if (response.statusCode == 422) {
      throw Exception('El formato del correo o la contraseña no es válido.');
    } 
    
    // Cualquier otro error de servidor (500, 404, etc.)
    else {
      throw Exception('Error en el servidor (${response.statusCode})');
    }

  } catch (e) {
  // Captura problemas de red (como que el servidor de FastAPI esté apagado) o excepciones lanzadas arriba
  debugPrint("Error en loginConEmailYPassword: $e");
  rethrow; // Reenviamos el error para que tu UI de Flutter pueda mostrar un SnackBar o alerta
}
}