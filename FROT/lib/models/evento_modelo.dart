// lib/models/evento_modelo.dart
//
// Modelo de eventos artesanales y culturales (ferias, talleres, exposiciones,
// bazares, festivales) mostrados en la pantalla de calendario.
// 🔌 API: GET /api/eventos  (ver services/eventos_api_service.dart)

import 'package:flutter/material.dart';

/// Ícono representativo por categoría de evento.
IconData iconoCategoriaEvento(String categoria) {
  switch (categoria) {
    case 'Feria':
      return Icons.storefront_outlined;
    case 'Taller':
      return Icons.handyman_outlined;
    case 'Exposición':
      return Icons.museum_outlined;
    case 'Bazar':
      return Icons.shopping_bag_outlined;
    case 'Festival':
      return Icons.celebration_outlined;
    case 'Mercado':
      return Icons.storefront_rounded;
    default:
      return Icons.event_outlined;
  }
}

const List<String> categoriasEvento = [
  'Todos',
  'Feria',
  'Taller',
  'Exposición',
  'Bazar',
  'Festival',
  'Mercado',
];

const List<String> provinciasEvento = [
  'Bocas del Toro', 'Chiriquí', 'Coclé', 'Colón', 'Darién',
  'Herrera', 'Los Santos', 'Panamá', 'Panamá Oeste', 'Veraguas',
  'Guna Yala', 'Emberá-Wounaan', 'Ngäbe-Buglé',
];

/// Entidad u organización que organiza el evento (municipio, asociación de
/// artesanos, ministerio, etc.) — el vendedor necesita su contacto directo
/// para poder solicitar un espacio de venta.
class OrganizadorEvento {
  final String nombre;
  final String tipo;
  final String telefono;
  final String whatsapp;
  final String email;
  final String sitioWeb;
  final String fotoUrl;

  const OrganizadorEvento({
    required this.nombre,
    required this.tipo,
    this.telefono = '',
    this.whatsapp = '',
    this.email = '',
    this.sitioWeb = '',
    this.fotoUrl = '',
  });

  factory OrganizadorEvento.fromJson(Map<String, dynamic> json) {
    return OrganizadorEvento(
      nombre: (json['nombre'] ?? 'Organizador').toString(),
      tipo: (json['tipo'] ?? 'Organización').toString(),
      telefono: (json['telefono'] ?? '').toString(),
      whatsapp: (json['whatsapp'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      sitioWeb: (json['sitio_web'] ?? '').toString(),
      fotoUrl: (json['foto_url'] ?? '').toString(),
    );
  }
}

class EventoArtesanal {
  final String id;
  final String titulo;
  final String descripcion;
  final String categoria;
  final String imagenUrl;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String ubicacion;
  final String provincia;
  final double latitud;
  final double longitud;
  final bool esGratuito;
  final double precioEntrada;
  final int cuposVendedorTotal;
  final int cuposVendedorDisponibles;
  final OrganizadorEvento organizador;
  final int? descuentoPorcentaje;
  final DateTime? descuentoDesde;
  final DateTime? descuentoHasta;
  bool esFavorito;
  bool solicitudEnviada;

  EventoArtesanal({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.imagenUrl,
    required this.fechaInicio,
    required this.fechaFin,
    required this.ubicacion,
    required this.provincia,
    required this.organizador,
    this.latitud = 8.9824,
    this.longitud = -79.5199,
    this.esGratuito = true,
    this.precioEntrada = 0,
    this.cuposVendedorTotal = 0,
    this.cuposVendedorDisponibles = 0,
    this.descuentoPorcentaje,
    this.descuentoDesde,
    this.descuentoHasta,
    this.esFavorito = false,
    this.solicitudEnviada = false,
  });

  static const _mesesAbrev = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  DateTime get soloFechaInicio =>
      DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
  DateTime get soloFechaFin =>
      DateTime(fechaFin.year, fechaFin.month, fechaFin.day);

  bool ocurreEnDia(DateTime dia) {
    final d = DateTime(dia.year, dia.month, dia.day);
    return !d.isBefore(soloFechaInicio) && !d.isAfter(soloFechaFin);
  }

  bool get haTerminado => DateTime.now().isAfter(fechaFin);

  /// Indica si el evento tiene una promoción de descuento configurada.
  bool get tieneDescuento => descuentoPorcentaje != null && descuentoPorcentaje! > 0;

  /// Indica si el [dia] dado cae dentro de la ventana de descuento.
  bool estaEnDescuento(DateTime dia) {
    if (!tieneDescuento || descuentoDesde == null || descuentoHasta == null) return false;
    final d = DateTime(dia.year, dia.month, dia.day);
    final desde = DateTime(descuentoDesde!.year, descuentoDesde!.month, descuentoDesde!.day);
    final hasta = DateTime(descuentoHasta!.year, descuentoHasta!.month, descuentoHasta!.day);
    return !d.isBefore(desde) && !d.isAfter(hasta);
  }

  double precioConDescuento(DateTime dia) {
    if (!estaEnDescuento(dia)) return precioEntrada;
    return precioEntrada * (1 - descuentoPorcentaje! / 100);
  }

  /// Precio promocional del evento (independiente de la fecha actual) — útil
  /// para mostrar "antes/ahora" en las tarjetas y el detalle del evento.
  double get precioPromocional =>
      tieneDescuento ? precioEntrada * (1 - descuentoPorcentaje! / 100) : precioEntrada;

  String get etiquetaDescuento => '-$descuentoPorcentaje%';

  String get rangoDescuentoTexto {
    if (descuentoDesde == null || descuentoHasta == null) return '';
    final desde = descuentoDesde!;
    final hasta = descuentoHasta!;
    final mesIni = _mesesAbrev[desde.month - 1];
    if (desde.year == hasta.year && desde.month == hasta.month && desde.day == hasta.day) {
      return '$mesIni ${desde.day}';
    }
    final mesFin = _mesesAbrev[hasta.month - 1];
    return '$mesIni ${desde.day} – $mesFin ${hasta.day}';
  }

  String get mesAbreviado => _mesesAbrev[fechaInicio.month - 1];

  String _horaTexto(DateTime d) {
    final hora12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minutos = d.minute.toString().padLeft(2, '0');
    final sufijo = d.hour < 12 ? 'AM' : 'PM';
    return '$hora12:$minutos $sufijo';
  }

  String get rangoHorarioTexto =>
      '${_horaTexto(fechaInicio)} – ${_horaTexto(fechaFin)}';

  String get rangoFechasTexto {
    final mesIni = _mesesAbrev[fechaInicio.month - 1];
    final mesFin = _mesesAbrev[fechaFin.month - 1];
    if (soloFechaInicio == soloFechaFin) {
      return '${fechaInicio.day} $mesIni ${fechaInicio.year}';
    }
    if (fechaInicio.month == fechaFin.month && fechaInicio.year == fechaFin.year) {
      return '${fechaInicio.day} – ${fechaFin.day} $mesIni ${fechaInicio.year}';
    }
    return '${fechaInicio.day} $mesIni – ${fechaFin.day} $mesFin ${fechaFin.year}';
  }

  factory EventoArtesanal.fromJson(Map<String, dynamic> json) {
    return EventoArtesanal(
      id: (json['id'] ?? '').toString(),
      titulo: (json['titulo'] ?? 'Evento artesanal').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      categoria: (json['categoria'] ?? 'Feria').toString(),
      imagenUrl: (json['imagen_url'] ?? json['imagen'] ?? '').toString(),
      fechaInicio: DateTime.tryParse((json['fecha_inicio'] ?? '').toString()) ??
          DateTime.now(),
      fechaFin: DateTime.tryParse((json['fecha_fin'] ?? '').toString()) ??
          DateTime.now(),
      ubicacion: (json['ubicacion'] ?? '').toString(),
      provincia: (json['provincia'] ?? '').toString(),
      latitud: double.tryParse((json['latitud'] ?? '8.9824').toString()) ?? 8.9824,
      longitud: double.tryParse((json['longitud'] ?? '-79.5199').toString()) ?? -79.5199,
      esGratuito: json['es_gratuito'] ?? true,
      precioEntrada: double.tryParse((json['precio_entrada'] ?? 0).toString()) ?? 0,
      cuposVendedorTotal: int.tryParse((json['cupos_vendedor_total'] ?? 0).toString()) ?? 0,
      cuposVendedorDisponibles:
          int.tryParse((json['cupos_vendedor_disponibles'] ?? 0).toString()) ?? 0,
      organizador: OrganizadorEvento.fromJson(
          json['organizador'] as Map<String, dynamic>? ?? const {}),
      descuentoPorcentaje: json['descuento_porcentaje'] != null
          ? int.tryParse(json['descuento_porcentaje'].toString())
          : null,
      descuentoDesde: json['descuento_desde'] != null
          ? DateTime.tryParse(json['descuento_desde'].toString())
          : null,
      descuentoHasta: json['descuento_hasta'] != null
          ? DateTime.tryParse(json['descuento_hasta'].toString())
          : null,
      esFavorito: json['es_favorito'] ?? false,
      solicitudEnviada: json['solicitud_enviada'] ?? false,
    );
  }
}

/// Datos de demostración usados mientras el backend expone /api/eventos.
/// Se generan en torno a la fecha actual para que el calendario siempre
/// muestre actividad "hoy" y en los próximos meses sin importar cuándo
/// se ejecute la app.
List<EventoArtesanal> generarEventosDemo() {
  final hoy = DateTime.now();
  DateTime enDias(int dias, {int hora = 9, int minuto = 0}) {
    final base = hoy.add(Duration(days: dias));
    return DateTime(base.year, base.month, base.day, hora, minuto);
  }

  const municipioPanama = OrganizadorEvento(
    nombre: 'Municipio de Panamá',
    tipo: 'Entidad gubernamental',
    telefono: '+507 512-8000',
    whatsapp: '50751280000',
    email: 'eventos@mupa.gob.pa',
    sitioWeb: 'https://mupa.gob.pa',
  );
  const artesaniasPanama = OrganizadorEvento(
    nombre: 'Artesanías de Panamá',
    tipo: 'Asociación de artesanos',
    telefono: '+507 315-4444',
    whatsapp: '50763154444',
    email: 'contacto@artesaniaspanama.org',
    sitioWeb: 'https://artesaniaspanama.org',
  );
  const asociacionGuna = OrganizadorEvento(
    nombre: 'Asociación Guna de Artesanas',
    tipo: 'Asociación indígena',
    telefono: '+507 299-9500',
    whatsapp: '50762999500',
    email: 'molas@gunayala.org',
  );
  const miciTurismo = OrganizadorEvento(
    nombre: 'MICI – Viceministerio de Comercio Interior',
    tipo: 'Entidad gubernamental',
    telefono: '+507 560-0600',
    whatsapp: '50765600600',
    email: 'ferias@mici.gob.pa',
    sitioWeb: 'https://mici.gob.pa',
  );
  const camaraColon = OrganizadorEvento(
    nombre: 'Cámara de Comercio de Colón',
    tipo: 'Cámara de comercio',
    telefono: '+507 441-0322',
    whatsapp: '50764410322',
    email: 'info@camaracolon.org',
  );

  return [
    EventoArtesanal(
      id: 'ev-01',
      titulo: 'Feria de Arte y Artesanía de Panamá',
      descripcion:
          'La feria artesanal más grande del país reúne a más de 120 talleres '
          'de las 10 provincias y comarcas. Música en vivo, gastronomía típica '
          'y demostraciones de técnicas tradicionales en vivo.',
      categoria: 'Feria',
      imagenUrl: 'https://images.unsplash.com/photo-1533903345306-15d1c30952de?w=900',
      fechaInicio: enDias(2, hora: 9),
      fechaFin: enDias(6, hora: 18),
      ubicacion: 'Casco Antiguo, Ciudad de Panamá',
      provincia: 'Panamá',
      latitud: 8.9518, longitud: -79.5347,
      esGratuito: true,
      cuposVendedorTotal: 120, cuposVendedorDisponibles: 14,
      organizador: municipioPanama,
    ),
    EventoArtesanal(
      id: 'ev-02',
      titulo: 'Taller de Cerámica Tradicional',
      descripcion:
          'Aprende de maestros ceramistas las técnicas ancestrales de modelado '
          'y quemado a leña. Cupos limitados, materiales incluidos.',
      categoria: 'Taller',
      imagenUrl: 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=900',
      fechaInicio: enDias(6, hora: 10),
      fechaFin: enDias(6, hora: 13),
      ubicacion: 'Centro de Arte y Cultura, Coclé',
      provincia: 'Coclé',
      latitud: 8.4197, longitud: -80.4694,
      esGratuito: false,
      precioEntrada: 15,
      cuposVendedorTotal: 20, cuposVendedorDisponibles: 3,
      organizador: artesaniasPanama,
      // Los primeros dos días del taller tienen 25% de descuento por reserva anticipada.
      descuentoPorcentaje: 25,
      descuentoDesde: enDias(6),
      descuentoHasta: enDias(6),
    ),
    EventoArtesanal(
      id: 'ev-03',
      titulo: 'Exposición Nacional de Artesanías',
      descripcion:
          'Muestra itinerante con piezas seleccionadas de molas, tejidos, '
          'talla en madera y joyería ancestral de todas las comarcas.',
      categoria: 'Exposición',
      imagenUrl: 'https://images.unsplash.com/photo-1528444702795-51c1b6da1d05?w=900',
      fechaInicio: enDias(11, hora: 9),
      fechaFin: enDias(13, hora: 19),
      ubicacion: 'Centro de Convenciones Atlapa, Ciudad de Panamá',
      provincia: 'Panamá',
      latitud: 8.9880, longitud: -79.4877,
      esGratuito: true,
      cuposVendedorTotal: 60, cuposVendedorDisponibles: 0,
      organizador: miciTurismo,
    ),
    EventoArtesanal(
      id: 'ev-04',
      titulo: 'Bazar Artesanal de Molas',
      descripcion:
          'Venta directa de molas originales confeccionadas por artesanas '
          'de Guna Yala. Todo lo recaudado apoya a la comunidad.',
      categoria: 'Bazar',
      imagenUrl: 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=900',
      fechaInicio: enDias(-3, hora: 8),
      fechaFin: enDias(-1, hora: 17),
      ubicacion: 'Plaza Guna Yala, Comarca Guna Yala',
      provincia: 'Guna Yala',
      latitud: 9.5535, longitud: -78.9631,
      esGratuito: true,
      cuposVendedorTotal: 40, cuposVendedorDisponibles: 6,
      organizador: asociacionGuna,
    ),
    EventoArtesanal(
      id: 'ev-05',
      titulo: 'Festival de Talento Artesanal de Colón',
      descripcion:
          'Celebración cultural con desfile de trajes típicos, danza '
          'folclórica y venta de artesanías costeras.',
      categoria: 'Festival',
      imagenUrl: 'https://images.unsplash.com/photo-1531058020387-3be344556be6?w=900',
      fechaInicio: enDias(18, hora: 11),
      fechaFin: enDias(20, hora: 22),
      ubicacion: 'Paseo Centenario, Colón',
      provincia: 'Colón',
      latitud: 9.3592, longitud: -79.9014,
      esGratuito: true,
      cuposVendedorTotal: 80, cuposVendedorDisponibles: 22,
      organizador: camaraColon,
    ),
    EventoArtesanal(
      id: 'ev-06',
      titulo: 'Mercado Artesanal de Herrera',
      descripcion:
          'Mercado semanal con máscaras de diablicos, sombreros pintados '
          'y cerámica de La Arena.',
      categoria: 'Mercado',
      imagenUrl: 'https://images.unsplash.com/photo-1516575334481-f85287c2c82d?w=900',
      fechaInicio: enDias(25, hora: 7),
      fechaFin: enDias(25, hora: 15),
      ubicacion: 'La Arena, Herrera',
      provincia: 'Herrera',
      latitud: 7.9333, longitud: -80.4333,
      esGratuito: true,
      cuposVendedorTotal: 50, cuposVendedorDisponibles: 19,
      organizador: municipioPanama,
    ),
    EventoArtesanal(
      id: 'ev-07',
      titulo: 'Taller de Tejido en Fibras Naturales',
      descripcion:
          'Curso intensivo de tejido con paja toquilla y junco, incluye '
          'certificado de participación.',
      categoria: 'Taller',
      imagenUrl: 'https://images.unsplash.com/photo-1528283648649-33347faa5d9e?w=900',
      fechaInicio: enDias(33, hora: 9),
      fechaFin: enDias(34, hora: 16),
      ubicacion: 'Casa de la Cultura, Los Santos',
      provincia: 'Los Santos',
      latitud: 7.9333, longitud: -80.4167,
      esGratuito: false,
      precioEntrada: 25,
      cuposVendedorTotal: 15, cuposVendedorDisponibles: 5,
      organizador: artesaniasPanama,
      // El segundo día del taller tiene 25% de descuento para grupos.
      descuentoPorcentaje: 25,
      descuentoDesde: enDias(34),
      descuentoHasta: enDias(34),
    ),
    EventoArtesanal(
      id: 'ev-08',
      titulo: 'Feria Binacional de Artesanos Ngäbe-Buglé',
      descripcion:
          'Encuentro de artesanos de la comarca con chácaras, collares de '
          'chaquiras y sombreros tradicionales.',
      categoria: 'Feria',
      imagenUrl: 'https://images.unsplash.com/photo-1509281373149-e957c6296406?w=900',
      fechaInicio: enDias(40, hora: 8),
      fechaFin: enDias(42, hora: 18),
      ubicacion: 'Chichica, Ngäbe-Buglé',
      provincia: 'Ngäbe-Buglé',
      latitud: 8.4167, longitud: -81.7833,
      esGratuito: true,
      cuposVendedorTotal: 70, cuposVendedorDisponibles: 31,
      organizador: miciTurismo,
    ),
  ];
}
