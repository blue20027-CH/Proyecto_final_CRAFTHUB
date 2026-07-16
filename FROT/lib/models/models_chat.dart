// ─────────────────────────────────────────────────────────────────────────────
// MODELOS DE CHAT
// Endpoints sugeridos para conectar con FastAPI:
//   GET  /api/conversaciones/{userId}       → List<ConversacionModelo>
//   GET  /api/mensajes/{conversacionId}     → List<MensajeModelo>
//   POST /api/mensajes                      → enviar MensajeModelo
//   WS   /ws/chat/{conversacionId}          → stream en tiempo real
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// Papel tapiz de fondo compartido por todas las pantallas de chat (panel de
// conversación activa y los estados vacíos), para que se vea consistente.
// Cada tema tiene su propia imagen, ya pensada para ese fondo, así que no
// hace falta aclarar/oscurecer una imagen compartida por opacidad.
const String kFondoChatUrlClaro =
    'https://tcezyirkglpihohuzrqo.supabase.co/storage/v1/object/public/perfiles/ChatGPT%20Image%20Jul%2014,%202026,%2009_38_20%20PM.png';
const String kFondoChatUrlOscuro =
    'https://tcezyirkglpihohuzrqo.supabase.co/storage/v1/object/public/perfiles/ChatGPT%20Image%20Jul%2010,%202026,%2003_30_22%20PM.png';

DecorationImage construirFondoChat(bool isDark) {
  return DecorationImage(
    image: NetworkImage(isDark ? kFondoChatUrlOscuro : kFondoChatUrlClaro),
    fit: BoxFit.cover,
    opacity: 0.40,
  );
}

enum TipoMensaje { texto, imagen, publicacion }

class PublicacionCompartidaModelo {
  final String id;
  final String titulo;
  final String imagenUrl;
  final double precio;
  final String artesano;

  const PublicacionCompartidaModelo({
    required this.id,
    required this.titulo,
    required this.imagenUrl,
    required this.precio,
    required this.artesano,
  });

  factory PublicacionCompartidaModelo.fromJson(Map<String, dynamic> json) {
    return PublicacionCompartidaModelo(
      id: (json['publicacion_id'] ?? json['id'] ?? '').toString(),
      titulo: (json['titulo'] ?? json['publicacion_titulo'] ?? '').toString(),
      imagenUrl: (json['imagen_url'] ?? json['publicacion_imagen_url'] ?? '').toString(),
      precio: double.tryParse((json['precio'] ?? json['publicacion_precio'] ?? 0).toString()) ?? 0,
      artesano: (json['artesano'] ?? json['publicacion_artesano'] ?? '').toString(),
    );
  }
}

TipoMensaje tipoMensajeDesdeTexto(String? valor) {
  switch (valor) {
    case 'imagen':
      return TipoMensaje.imagen;
    case 'publicacion':
      return TipoMensaje.publicacion;
    default:
      return TipoMensaje.texto;
  }
}

String tipoMensajeATexto(TipoMensaje tipo) {
  switch (tipo) {
    case TipoMensaje.imagen:
      return 'imagen';
    case TipoMensaje.publicacion:
      return 'publicacion';
    case TipoMensaje.texto:
      return 'texto';
  }
}

class MensajeModelo {
  final String id;
  final String contenido;
  final TipoMensaje tipo;
  final bool esMio;
  final DateTime hora;
  final bool leido;
  final PublicacionCompartidaModelo? publicacion;

  const MensajeModelo({
    required this.id,
    required this.contenido,
    required this.tipo,
    required this.esMio,
    required this.hora,
    this.leido = false,
    this.publicacion,
  });

  factory MensajeModelo.fromJson(Map<String, dynamic> json) {
    final tipo = tipoMensajeDesdeTexto(json['tipo']?.toString());
    return MensajeModelo(
      id: (json['id'] ?? '').toString(),
      contenido: (json['contenido'] ?? '').toString(),
      tipo: tipo,
      esMio: json['es_mio'] == true,
      hora: DateTime.tryParse((json['hora'] ?? '').toString())?.toLocal() ?? DateTime.now(),
      leido: json['leido'] == true,
      publicacion: tipo == TipoMensaje.publicacion && json['publicacion_titulo'] != null
          ? PublicacionCompartidaModelo.fromJson(json)
          : null,
    );
  }
}

class ConversacionModelo {
  final String id;
  final String nombreContacto;
  final String? idContacto;
  final String rolContacto;
  final String avatarUrl;
  final String ultimoMensaje;
  final DateTime horaUltimo;
  final int mensajesNoLeidos;
  final bool enLinea;

  const ConversacionModelo({
    required this.id,
    required this.nombreContacto,
    this.idContacto,
    required this.rolContacto,
    required this.avatarUrl,
    required this.ultimoMensaje,
    required this.horaUltimo,
    this.mensajesNoLeidos = 0,
    this.enLinea = false,
  });

  factory ConversacionModelo.fromJson(Map<String, dynamic> json) {
    return ConversacionModelo(
      id: (json['id'] ?? '').toString(),
      nombreContacto: (json['nombre_contacto'] ?? 'Usuario CraftHub').toString(),
      idContacto: json['id_contacto']?.toString(),
      rolContacto: (json['rol_contacto'] ?? 'Cliente').toString(),
      avatarUrl: (json['foto_contacto'] ?? '').toString(),
      ultimoMensaje: (json['ultimo_mensaje'] ?? '').toString(),
      horaUltimo: DateTime.tryParse((json['ultimo_mensaje_hora'] ?? '').toString())?.toLocal() ?? DateTime.now(),
      mensajesNoLeidos: int.tryParse((json['mensajes_no_leidos'] ?? 0).toString()) ?? 0,
    );
  }
}

// ─── DATOS MOCK (reemplazar con llamadas reales al backend) ──────────────────

List<ConversacionModelo> mockConversaciones() => [
  ConversacionModelo(
    id: 'c1',
    nombreContacto: 'Rosa Martínez',
    rolContacto: 'Tejedora tradicional',
    avatarUrl: 'assets/images/avatares/rosa.jpg',
    ultimoMensaje: '¡Hola María! Claro que sí, con...',
    horaUltimo: DateTime.now().subtract(const Duration(minutes: 10)),
    mensajesNoLeidos: 2,
    enLinea: true,
  ),
  ConversacionModelo(
    id: 'c2',
    nombreContacto: 'Carlos Ruiz',
    rolContacto: 'Artesano ceramista',
    avatarUrl: 'assets/images/avatares/carlos.jpg',
    ultimoMensaje: 'Gracias por tu interés. Con...',
    horaUltimo: DateTime.now().subtract(const Duration(hours: 20)),
    mensajesNoLeidos: 1,
    enLinea: false,
  ),
  ConversacionModelo(
    id: 'c3',
    nombreContacto: 'Ana Santos',
    rolContacto: 'Bordadora Ngäbe',
    avatarUrl: 'assets/images/avatares/ana.jpg',
    ultimoMensaje: 'Te enviaré las medidas y más...',
    horaUltimo: DateTime.now().subtract(const Duration(hours: 22)),
    mensajesNoLeidos: 0,
    enLinea: true,
  ),
  ConversacionModelo(
    id: 'c4',
    nombreContacto: 'Miguel Torres',
    rolContacto: 'Tallador en madera',
    avatarUrl: 'assets/images/avatares/miguel.jpg',
    ultimoMensaje: 'Perfecto, quedo atento a tu...',
    horaUltimo: DateTime.now().subtract(const Duration(days: 2)),
    mensajesNoLeidos: 0,
    enLinea: false,
  ),
  ConversacionModelo(
    id: 'c5',
    nombreContacto: 'Elena García',
    rolContacto: 'Alfarera tradicional',
    avatarUrl: 'assets/images/avatares/elena.jpg',
    ultimoMensaje: 'Muchas gracias por tu compra...',
    horaUltimo: DateTime.now().subtract(const Duration(days: 3)),
    mensajesNoLeidos: 0,
    enLinea: false,
  ),
  ConversacionModelo(
    id: 'c6',
    nombreContacto: 'Pedro Díaz',
    rolContacto: 'Tejedor de sombreros',
    avatarUrl: 'assets/images/avatares/pedro.jpg',
    ultimoMensaje: 'Con gusto, cualquier duda...',
    horaUltimo: DateTime.now().subtract(const Duration(days: 5)),
    mensajesNoLeidos: 0,
    enLinea: false,
  ),
];

List<MensajeModelo> mockMensajesRosa() => [
  MensajeModelo(
    id: 'm1',
    contenido:
        '¡Hola María! 👋\nGracias por interesarte en mis productos.\n¿En qué puedo ayudarte?',
    tipo: TipoMensaje.texto,
    esMio: false,
    hora: DateTime.now().subtract(const Duration(minutes: 30)),
  ),
  MensajeModelo(
    id: 'm2',
    contenido:
        '¡Hola Rosa! Me encantó este bolso tejido.\n¿Podrías contarme más sobre los materiales\ny el tiempo de elaboración?',
    tipo: TipoMensaje.texto,
    esMio: true,
    hora: DateTime.now().subtract(const Duration(minutes: 29)),
    leido: true,
  ),
  MensajeModelo(
    id: 'm3',
    contenido:
        'Claro que sí, con mucho gusto 😊\nEste bolso está tejido a mano con fibra natural de\niraca, un material resistente y sostenible.\nEl tiempo de elaboración es de 3 a 4 días.',
    tipo: TipoMensaje.texto,
    esMio: false,
    hora: DateTime.now().subtract(const Duration(minutes: 28)),
  ),
  MensajeModelo(
    id: 'm4',
    contenido: 'https://i.imgur.com/ZWRiMCb.jpeg',
    tipo: TipoMensaje.imagen,
    esMio: false,
    hora: DateTime.now().subtract(const Duration(minutes: 27)),
  ),
  MensajeModelo(
    id: 'm5',
    contenido:
        '¡Qué hermoso! 😍\n¿Tienes disponibilidad para envío a Ciudad de Panamá?',
    tipo: TipoMensaje.texto,
    esMio: true,
    hora: DateTime.now().subtract(const Duration(minutes: 17)),
    leido: true,
  ),
  MensajeModelo(
    id: 'm6',
    contenido:
        'Sí, realizo envíos a todo Panamá 🚚\nTe llegará en 2 a 3 días hábiles.',
    tipo: TipoMensaje.texto,
    esMio: false,
    hora: DateTime.now().subtract(const Duration(minutes: 16)),
  ),
];

