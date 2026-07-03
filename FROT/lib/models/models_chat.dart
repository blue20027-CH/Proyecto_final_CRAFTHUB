// ─────────────────────────────────────────────────────────────────────────────
// MODELOS DE CHAT
// Endpoints sugeridos para conectar con FastAPI:
//   GET  /api/conversaciones/{userId}       → List<ConversacionModelo>
//   GET  /api/mensajes/{conversacionId}     → List<MensajeModelo>
//   POST /api/mensajes                      → enviar MensajeModelo
//   WS   /ws/chat/{conversacionId}          → stream en tiempo real
// ─────────────────────────────────────────────────────────────────────────────

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
  // TODO: factory PublicacionCompartidaModelo.fromJson(Map<String, dynamic> json) { ... }
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
  // TODO: factory MensajeModelo.fromJson(Map<String, dynamic> json) { ... }
  // TODO: Map<String, dynamic> toJson() { ... }
}

class ConversacionModelo {
  final String id;
  final String nombreContacto;
  final String rolContacto;
  final String avatarUrl;
  final String ultimoMensaje;
  final DateTime horaUltimo;
  final int mensajesNoLeidos;
  final bool enLinea;

  const ConversacionModelo({
    required this.id,
    required this.nombreContacto,
    required this.rolContacto,
    required this.avatarUrl,
    required this.ultimoMensaje,
    required this.horaUltimo,
    this.mensajesNoLeidos = 0,
    this.enLinea = false,
  });
  // TODO: factory ConversacionModelo.fromJson(Map<String, dynamic> json) { ... }
}

// ─── DATOS MOCK (reemplazar con llamadas reales al backend) ──────────────────

List<ConversacionModelo> mockConversaciones() => [
  ConversacionModelo(
    id: 'c1',
    nombreContacto: 'Rosa Martínez',
    rolContacto: 'Tejedora tradicional',
    avatarUrl: 'https://i.pravatar.cc/150?img=5',
    ultimoMensaje: '¡Hola María! Claro que sí, con...',
    horaUltimo: DateTime.now().subtract(const Duration(minutes: 10)),
    mensajesNoLeidos: 2,
    enLinea: true,
  ),
  ConversacionModelo(
    id: 'c2',
    nombreContacto: 'Carlos Ruiz',
    rolContacto: 'Artesano ceramista',
    avatarUrl: 'https://i.pravatar.cc/150?img=3',
    ultimoMensaje: 'Gracias por tu interés. Con...',
    horaUltimo: DateTime.now().subtract(const Duration(hours: 20)),
    mensajesNoLeidos: 1,
    enLinea: false,
  ),
  ConversacionModelo(
    id: 'c3',
    nombreContacto: 'Ana Santos',
    rolContacto: 'Bordadora Ngäbe',
    avatarUrl: 'https://i.pravatar.cc/150?img=1',
    ultimoMensaje: 'Te enviaré las medidas y más...',
    horaUltimo: DateTime.now().subtract(const Duration(hours: 22)),
    mensajesNoLeidos: 0,
    enLinea: true,
  ),
  ConversacionModelo(
    id: 'c4',
    nombreContacto: 'Miguel Torres',
    rolContacto: 'Tallador en madera',
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
    ultimoMensaje: 'Perfecto, quedo atento a tu...',
    horaUltimo: DateTime.now().subtract(const Duration(days: 2)),
    mensajesNoLeidos: 0,
    enLinea: false,
  ),
  ConversacionModelo(
    id: 'c5',
    nombreContacto: 'Elena García',
    rolContacto: 'Alfarera tradicional',
    avatarUrl: 'https://i.pravatar.cc/150?img=9',
    ultimoMensaje: 'Muchas gracias por tu compra...',
    horaUltimo: DateTime.now().subtract(const Duration(days: 3)),
    mensajesNoLeidos: 0,
    enLinea: false,
  ),
  ConversacionModelo(
    id: 'c6',
    nombreContacto: 'Pedro Díaz',
    rolContacto: 'Tejedor de sombreros',
    avatarUrl: 'https://i.pravatar.cc/150?img=15',
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
