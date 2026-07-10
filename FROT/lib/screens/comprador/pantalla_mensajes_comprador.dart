import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models_chat.dart';
import '../../services/chat_api_service.dart';
import '../../widgets/chat/panel_conversaciones.dart';
import '../../widgets/chat/panel_chat.dart';
import '../../widgets/chat/banner_anuncio_crafthub.dart';

// Layout desktop: [Sidebar] | [PanelConversaciones] | [PanelChat]
// 🔌 Backend: BACK/CraftHub/chat_router.py
class PantallaMensajesComprador extends StatefulWidget {
  final String userId;
  final String nombreComprador;
  const PantallaMensajesComprador({super.key, this.userId = '', this.nombreComprador = ''});

  @override
  State<PantallaMensajesComprador> createState() =>
      _PantallaMensajesCompradorState();
}

class _PantallaMensajesCompradorState extends State<PantallaMensajesComprador> {
  ConversacionModelo? _conversacionActiva;
  List<ConversacionModelo> _conversaciones = [];
  List<MensajeModelo> _mensajesActivos = [];
  bool _cargandoConversaciones = true;
  bool _cargandoMensajes = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarConversaciones();
  }

  Future<void> _cargarConversaciones() async {
    if (widget.userId.isEmpty) {
      setState(() => _cargandoConversaciones = false);
      return;
    }
    setState(() {
      _cargandoConversaciones = true;
      _error = null;
    });
    try {
      final lista = await ChatApiService.cargarConversaciones(widget.userId);
      if (!mounted) return;
      setState(() {
        _conversaciones = lista;
        _cargandoConversaciones = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _cargandoConversaciones = false;
      });
    }
  }

  Future<void> _seleccionar(ConversacionModelo conv) async {
    setState(() {
      _conversacionActiva = conv;
      _cargandoMensajes = true;
      _mensajesActivos = [];
    });
    try {
      final mensajes = await ChatApiService.cargarMensajes(conv.id, widget.userId);
      if (!mounted) return;
      setState(() {
        _mensajesActivos = mensajes;
        _cargandoMensajes = false;
        _conversaciones = _conversaciones
            .map((c) => c.id == conv.id
                ? ConversacionModelo(
                    id: c.id,
                    nombreContacto: c.nombreContacto,
                    idContacto: c.idContacto,
                    rolContacto: c.rolContacto,
                    avatarUrl: c.avatarUrl,
                    ultimoMensaje: c.ultimoMensaje,
                    horaUltimo: c.horaUltimo,
                    mensajesNoLeidos: 0,
                    enLinea: c.enLinea,
                  )
                : c)
            .toList();
      });
      if (conv.mensajesNoLeidos > 0) {
        ChatApiService.marcarMensajesLeidos(conv.id, widget.userId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoMensajes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los mensajes: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
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
                _cargandoConversaciones
                    ? const SizedBox(
                        width: 320,
                        child: Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto)),
                      )
                    : PanelConversaciones(
                        conversaciones: _conversaciones,
                        idSeleccionado: _conversacionActiva?.id,
                        alSeleccionar: _seleccionar,
                      ),
                Expanded(
                  child: _error != null
                      ? _PantallaError(isDark: isDark, mensaje: _error!, alReintentar: _cargarConversaciones)
                      : _conversacionActiva == null
                          ? _PantallaVacia(
                              isDark: isDark,
                              icono: Icons.forum_outlined,
                              titulo: 'Tus mensajes',
                              subtitulo:
                                  'Selecciona una conversación para chatear\ncon un artesano.',
                            )
                          : _cargandoMensajes
                              ? const Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto))
                              : PanelChat(
                                  key: ValueKey(_conversacionActiva!.id),
                                  conversacion: _conversacionActiva!,
                                  mensajes: _mensajesActivos,
                                  usuarioId: widget.userId,
                                  usuarioNombre: widget.nombreComprador,
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
  final IconData icono;
  final String titulo;
  final String subtitulo;

  const _PantallaVacia({
    required this.isDark,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
  });

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
              child: Icon(icono, size: 52, color: CraftHubColors.vinoTinto),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: CraftHubColors.textoPrincipal(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
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

class _PantallaError extends StatelessWidget {
  final bool isDark;
  final String mensaje;
  final VoidCallback alReintentar;
  const _PantallaError({required this.isDark, required this.mensaje, required this.alReintentar});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? CraftHubColors.fondoOscuro : const Color(0xFFF5EFE9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 44, color: CraftHubColors.error),
            const SizedBox(height: 12),
            Text(mensaje,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: CraftHubColors.textoSecundario(isDark))),
            const SizedBox(height: 14),
            TextButton(onPressed: alReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
