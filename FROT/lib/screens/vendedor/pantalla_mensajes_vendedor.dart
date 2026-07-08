import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models_chat.dart';
import '../../widgets/chat/panel_conversaciones.dart';
import '../../widgets/chat/panel_chat.dart';
import '../../widgets/chat/banner_anuncio_crafthub.dart';

// Contenido (sin Scaffold/Sidebar propios): se inserta dentro del switch de
// _obtenerPantallaActual() en pantalla_dashoard_vendedor.dart, igual que
// PantallaMensajesComprador se inserta en el switch de HomeComprador.
// Layout desktop: [PanelConversaciones] | [PanelChat]
// TODO al iniciar: GET /api/conversaciones/{vendedorId}
// TODO en tiempo real: WS /ws/chat/{conversacionId}
class PantallaMensajesVendedor extends StatefulWidget {
  final String userId;
  const PantallaMensajesVendedor({super.key, this.userId = ''});

  @override
  State<PantallaMensajesVendedor> createState() =>
      _PantallaMensajesVendedorState();
}

class _PantallaMensajesVendedorState extends State<PantallaMensajesVendedor> {
  ConversacionModelo? _conversacionActiva;
  late List<ConversacionModelo> _conversaciones;
  List<MensajeModelo> _mensajesActivos = [];

  // Publicaciones del vendedor para compartir en chat
  // TODO: GET /api/productos/mios?vendedorId={id}
  final List<PublicacionCompartidaModelo> _misPublicaciones = [
    PublicacionCompartidaModelo(
      id: 'vp1',
      titulo: 'Bolso tejido iraca',
      imagenUrl: 'https://i.imgur.com/ZWRiMCb.jpeg',
      precio: 45.00,
      artesano: 'Rosa Martinez',
    ),
    PublicacionCompartidaModelo(
      id: 'vp2',
      titulo: 'Mola Guna Yala',
      imagenUrl:
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
      precio: 38.00,
      artesano: 'Rosa Martinez',
    ),
    PublicacionCompartidaModelo(
      id: 'vp3',
      titulo: 'Cesta de fibra natural',
      imagenUrl:
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
      precio: 22.50,
      artesano: 'Rosa Martinez',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // TODO: reemplazar con GET /api/conversaciones/{vendedorId}
    _conversaciones = _convsMock();
  }

  // Las conversaciones del vendedor muestran a sus compradores
  List<ConversacionModelo> _convsMock() => [
    ConversacionModelo(
      id: 'vc1',
      nombreContacto: 'Maria Lopez',
      rolContacto: 'Compradora',
      avatarUrl: 'https://i.pravatar.cc/150?img=25',
      ultimoMensaje: 'Me encanto el bolso tejido...',
      horaUltimo: DateTime.now().subtract(const Duration(minutes: 10)),
      mensajesNoLeidos: 2,
      enLinea: true,
    ),
    ConversacionModelo(
      id: 'vc2',
      nombreContacto: 'Jorge Herrera',
      rolContacto: 'Comprador',
      avatarUrl: 'https://i.pravatar.cc/150?img=33',
      ultimoMensaje: 'Tienen envio a Chiriqui?',
      horaUltimo: DateTime.now().subtract(const Duration(hours: 5)),
      mensajesNoLeidos: 1,
      enLinea: false,
    ),
    ConversacionModelo(
      id: 'vc3',
      nombreContacto: 'Valentina Cruz',
      rolContacto: 'Compradora',
      avatarUrl: 'https://i.pravatar.cc/150?img=47',
      ultimoMensaje: 'Muchas gracias, quedo precioso.',
      horaUltimo: DateTime.now().subtract(const Duration(hours: 20)),
      mensajesNoLeidos: 0,
      enLinea: true,
    ),
    ConversacionModelo(
      id: 'vc4',
      nombreContacto: 'Andres Rios',
      rolContacto: 'Comprador',
      avatarUrl: 'https://i.pravatar.cc/150?img=52',
      ultimoMensaje: 'Perfecto, hago el pedido ahora.',
      horaUltimo: DateTime.now().subtract(const Duration(days: 1)),
      mensajesNoLeidos: 0,
      enLinea: false,
    ),
    ConversacionModelo(
      id: 'vc5',
      nombreContacto: 'Paola Jimenez',
      rolContacto: 'Compradora',
      avatarUrl: 'https://i.pravatar.cc/150?img=60',
      ultimoMensaje: 'El precio incluye el envio?',
      horaUltimo: DateTime.now().subtract(const Duration(days: 3)),
      mensajesNoLeidos: 0,
      enLinea: false,
    ),
  ];

  void _seleccionar(ConversacionModelo conv) {
    setState(() {
      _conversacionActiva = conv;
      // TODO: GET /api/mensajes/{conv.id}
      // Invertimos esMio para mostrar desde perspectiva del vendedor
      _mensajesActivos = conv.id == 'vc1'
          ? mockMensajesRosa()
                .map(
                  (m) => MensajeModelo(
                    id: m.id,
                    contenido: m.contenido,
                    tipo: m.tipo,
                    esMio: !m.esMio,
                    hora: m.hora,
                    leido: m.leido,
                    publicacion: m.publicacion,
                  ),
                )
                .toList()
          : [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: CraftHubColors.fondo(isDark),
      body: Column(
        children: [
          BannerAnuncioCraftHub(userId: widget.userId),
          Expanded(
            child: Row(
              children: [
                PanelConversaciones(
                  conversaciones: _conversaciones,
                  idSeleccionado: _conversacionActiva?.id,
                  alSeleccionar: _seleccionar,
                ),
                Expanded(
                  child: _conversacionActiva == null
                      ? _PantallaVacia(isDark: isDark)
                      : PanelChat(
                          key: ValueKey(_conversacionActiva!.id),
                          conversacion: _conversacionActiva!,
                          mensajes: _mensajesActivos,
                          misPublicaciones: _misPublicaciones,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PantallaVacia extends StatelessWidget {
  final bool isDark;
  const _PantallaVacia({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? CraftHubColors.fondoOscuro : const Color(0xFFF5EFE9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: CraftHubColors.vinoTintoSuave,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_chat_unread_outlined,
                size: 52,
                color: CraftHubColors.vinoTinto,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Mensajes de clientes',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: CraftHubColors.textoPrincipal(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona una conversacion para responder\na tus compradores y compartir tus productos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13.5,
                color: CraftHubColors.textoSecundario(isDark),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
