// lib/services/eventos_api_service.dart
//
// 🔌 Backend esperado (FastAPI):
//   GET  /api/eventos?categoria=&provincia=&busqueda=   -> List<Evento>
//   POST /api/eventos                                   -> crea evento (vendedor/organizador)
//   POST /api/eventos/{id}/solicitudes-vendedor          -> vendedor solicita espacio
//   POST /api/eventos/{id}/favorito                      -> comprador marca favorito
//
// Mientras el backend no exponga estas rutas, el servicio responde con datos
// de demostración (generarEventosDemo) para que la pantalla sea completamente
// interactiva y demostrable sin depender de la disponibilidad del servidor.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/evento_modelo.dart';

class EventosApiService {
  static const String baseUrl = 'http://127.0.0.1:8080';

  static Future<List<EventoArtesanal>> getEventos({
    String? categoria,
    String? provincia,
    String? busqueda,
  }) async {
    try {
      final params = <String, String>{};
      if (categoria != null && categoria != 'Todos') params['categoria'] = categoria;
      if (provincia != null && provincia.isNotEmpty) params['provincia'] = provincia;
      if (busqueda != null && busqueda.isNotEmpty) params['busqueda'] = busqueda;

      final uri = Uri.parse('$baseUrl/api/eventos').replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        throw Exception('status ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic>
          ? (decoded['eventos'] as List<dynamic>? ?? [])
          : (decoded as List<dynamic>);
      return data
          .map((json) => EventoArtesanal.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('EventosApiService.getEventos → usando datos demo ($e)');
      var eventos = generarEventosDemo();
      if (categoria != null && categoria != 'Todos') {
        eventos = eventos.where((ev) => ev.categoria == categoria).toList();
      }
      if (provincia != null && provincia.isNotEmpty) {
        eventos = eventos.where((ev) => ev.provincia == provincia).toList();
      }
      if (busqueda != null && busqueda.trim().isNotEmpty) {
        final q = busqueda.trim().toLowerCase();
        eventos = eventos.where((ev) =>
            ev.titulo.toLowerCase().contains(q) ||
            ev.ubicacion.toLowerCase().contains(q) ||
            ev.provincia.toLowerCase().contains(q)).toList();
      }
      return eventos;
    }
  }

  static Future<Map<String, dynamic>> solicitarEspacioVendedor({
    required String eventoId,
    required String vendedorId,
    required String mensaje,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/eventos/$eventoId/solicitudes-vendedor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'vendedor_id': vendedorId, 'mensaje': mensaje}),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('status ${response.statusCode}');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('EventosApiService.solicitarEspacioVendedor → modo demo ($e)');
      await Future.delayed(const Duration(milliseconds: 700));
      return {
        'ok': true,
        'mensaje': 'Solicitud enviada al organizador (modo demostración).',
      };
    }
  }

  static Future<EventoArtesanal> crearEvento(Map<String, dynamic> datos) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/eventos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datos),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('status ${response.statusCode}');
      }
      return EventoArtesanal.fromJson(jsonDecode(response.body));
    } catch (e) {
      debugPrint('EventosApiService.crearEvento → modo demo ($e)');
      await Future.delayed(const Duration(milliseconds: 500));
      return EventoArtesanal.fromJson({
        ...datos,
        'id': 'demo-${DateTime.now().millisecondsSinceEpoch}',
      });
    }
  }

  static Future<void> alternarFavorito(String eventoId, String userId, bool esFavorito) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/eventos/$eventoId/favorito'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'es_favorito': esFavorito}),
      ).timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('EventosApiService.alternarFavorito → modo demo ($e)');
    }
  }

  static Future<List<EventoArtesanal>> getFavoritos(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/eventos/favoritos/$userId'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        throw Exception('status ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['eventos'] as List<dynamic>? ?? [];
      return data
          .map((json) => EventoArtesanal.fromJson(json as Map<String, dynamic>)
            ..esFavorito = true)
          .toList();
    } catch (e) {
      debugPrint('EventosApiService.getFavoritos → sin datos ($e)');
      return [];
    }
  }
}
