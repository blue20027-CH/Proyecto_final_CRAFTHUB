import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/models_chat.dart';

class ChatApiService {
  static const String baseUrl = ApiConfig.baseUrl;

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
    PublicacionCompartidaModelo? publicacion,
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
            if (publicacion != null) 'publicacion_titulo': publicacion.titulo,
            if (publicacion != null) 'publicacion_imagen_url': publicacion.imagenUrl,
            if (publicacion != null) 'publicacion_precio': publicacion.precio,
            if (publicacion != null) 'publicacion_artesano': publicacion.artesano,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('No se pudo enviar el mensaje: ${response.statusCode} ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return MensajeModelo.fromJson(data['mensaje'] as Map<String, dynamic>);
  }

  /// Sube una imagen de chat y devuelve su URL pública en Supabase Storage.
  /// Reutiliza el endpoint genérico de subida de fotos de producto.
  static Future<String> subirImagenChat(List<int> bytes, String nombreArchivo) async {
    final uri = Uri.parse('$baseUrl/productos/subir-foto');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: nombreArchivo));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('No se pudo subir la imagen: ${response.statusCode}');
    }
    final data = jsonDecode(body) as Map<String, dynamic>;
    return (data['url'] ?? '').toString();
  }

  /// Nombre con el que el asistente IA aparece como contacto en el chat.
  static const String nombreBotIA = 'Crafty';
  // Nombre legado del asistente (antes de rebautizarlo "Crafty"). Se sigue
  // detectando por compatibilidad con conversaciones creadas antes del cambio.
  static const String nombreBotIALegado = 'CraftHub IA';
  static bool esBotIA(String nombre) =>
      nombre == nombreBotIA || nombre == nombreBotIALegado;

  /// 🔗 POST /api/ia/chatbot/abrir — garantiza que exista la conversación
  /// del usuario con CraftHub IA (con mensaje de bienvenida si es nueva).
  static Future<void> abrirChatbot(String usuarioId, String usuarioNombre) async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/api/ia/chatbot/abrir'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'usuario_id': usuarioId,
              'usuario_nombre': usuarioNombre,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Silencioso: si falla, el chat de la IA simplemente no aparece aún.
    }
  }

  /// 🔗 POST /api/ia/chatbot/mensaje — envía un mensaje a CraftHub IA y
  /// devuelve su respuesta (ambos quedan guardados en la conversación).
  static Future<String> enviarMensajeChatbot({
    required String conversacionId,
    required String usuarioId,
    required String usuarioNombre,
    required String mensaje,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/ia/chatbot/mensaje'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: utf8.encode(jsonEncode({
            'conversacion_id': conversacionId,
            'usuario_id': usuarioId,
            'usuario_nombre': usuarioNombre,
            'mensaje': mensaje,
          })),
        )
        .timeout(const Duration(seconds: 30));
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['detail'] ?? 'La IA no pudo responder.');
    }
    return (data['respuesta'] ?? '').toString();
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
