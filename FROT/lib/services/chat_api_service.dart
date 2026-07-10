import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models_chat.dart';

class ChatApiService {
  static const String baseUrl = 'http://127.0.0.1:8080';

  /// 🔗 GET /api/chat/conversaciones/{userId}
  static Future<List<ConversacionModelo>> cargarConversaciones(String userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/chat/conversaciones/$userId'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar las conversaciones: ${response.statusCode} ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ((data['conversaciones'] as List?) ?? [])
        .map((c) => ConversacionModelo.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// 🔗 POST /api/chat/conversaciones/abrir — busca o crea la conversación
  /// con ese contacto y la devuelve lista para seleccionar.
  static Future<ConversacionModelo> abrirConversacion({
    required String usuarioId,
    required String usuarioNombre,
    String? contactoId,
    required String contactoNombre,
    String contactoRol = 'Cliente',
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/chat/conversaciones/abrir'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'usuario_id': usuarioId,
            'usuario_nombre': usuarioNombre,
            'contacto_id': contactoId,
            'contacto_nombre': contactoNombre,
            'contacto_rol': contactoRol,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('No se pudo abrir la conversación: ${response.statusCode} ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ConversacionModelo.fromJson(data['conversacion'] as Map<String, dynamic>);
  }

  /// 🔗 GET /api/chat/mensajes/{conversacionId}?para_usuario_id=...
  static Future<List<MensajeModelo>> cargarMensajes(String conversacionId, String paraUsuarioId) async {
    final uri = Uri.parse('$baseUrl/api/chat/mensajes/$conversacionId')
        .replace(queryParameters: {'para_usuario_id': paraUsuarioId});
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los mensajes: ${response.statusCode} ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ((data['mensajes'] as List?) ?? [])
        .map((m) => MensajeModelo.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// 🔗 POST /api/chat/mensajes
  static Future<MensajeModelo> enviarMensaje({
    required String conversacionId,
    required String autorId,
    required String autorNombre,
    required String contenido,
    TipoMensaje tipo = TipoMensaje.texto,
    String? publicacionId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/chat/mensajes'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'conversacion_id': conversacionId,
            'autor_id': autorId,
            'autor_nombre': autorNombre,
            'contenido': contenido,
            'tipo': tipoMensajeATexto(tipo),
            'publicacion_id': publicacionId,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('No se pudo enviar el mensaje: ${response.statusCode} ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return MensajeModelo.fromJson(data['mensaje'] as Map<String, dynamic>);
  }

  /// 🔗 PATCH /api/chat/mensajes/{conversacionId}/leidos?usuario_id=...
  static Future<void> marcarMensajesLeidos(String conversacionId, String usuarioId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/chat/mensajes/$conversacionId/leidos')
          .replace(queryParameters: {'usuario_id': usuarioId});
      await http.patch(uri).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Silencioso: en el peor caso el contador tarda un poco en actualizarse.
    }
  }
}
