import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/favoritos_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';
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
  // Si se llega aquí desde "Enviar mensaje" en el perfil de un artesano, se
  // abre (o encuentra) esa conversación y se selecciona automáticamente.
  final String? contactoIdInicial;
  final String? contactoNombreInicial;
  final String contactoRolInicial;
  const PantallaMensajesComprador({
    super.key,
    this.userId = '',
    this.nombreComprador = '',
    this.contactoIdInicial,
    this.contactoNombreInicial,
    this.contactoRolInicial = 'Vendedor',
  });

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
  Timer? _pollConversaciones;
  Timer? _pollMensajes;

  @override
  void initState() {
    super.initState();
    _iniciar();
    _pollConversaciones = Timer.periodic(const Duration(seconds: 6), (_) => _refrescarConversaciones());
  }

  @override
  void dispose() {
    _pollConversaciones?.cancel();
    _pollMensajes?.cancel();
    super.dispose();
  }

  Future<void> _iniciar() async {
    await _cargarConversaciones();
    if (widget.contactoNombreInicial != null && widget.contactoNombreInicial!.isNotEmpty) {
      await _abrirConversacionInicial();
    }
  }

  Future<void> _abrirConversacionInicial() async {
    if (widget.userId.isEmpty) return;
    try {
      final contactoId = widget.contactoIdInicial;
      final conv = await ChatApiService.abrirConversacion(
        usuarioId: widget.userId,
        usuarioNombre: widget.nombreComprador,
        contactoId: (contactoId == null || contactoId.isEmpty) ? null : contactoId,
        contactoNombre: widget.contactoNombreInicial!,
        contactoRol: widget.contactoRolInicial,
      );
      if (!mounted) return;
      _agregarYSeleccionarConversacion(conv);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'comprador_social.mensajes_error_abrir_chat')}${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  /// Agrega la conversación a la lista si es nueva (no venía del historial)
  /// y la selecciona. Usado tanto al llegar desde "Enviar mensaje" como al
  /// iniciar una conversación nueva desde el buscador de PanelConversaciones.
  void _agregarYSeleccionarConversacion(ConversacionModelo conv) {
    setState(() {
      if (!_conversaciones.any((c) => c.id == conv.id)) {
        _conversaciones = [conv, ..._conversaciones];
      }
    });
    _seleccionar(conv);
  }

  // Refresca la lista de conversaciones en segundo plano (sin spinner) para
  // que las vistas previas y los contadores de no leídos se mantengan al día
  // aunque no haya ninguna conversación abierta.
  Future<void> _refrescarConversaciones() async {
    if (widget.userId.isEmpty) return;
    try {
      final lista = await ChatApiService.cargarConversaciones(widget.userId);
      if (!mounted) return;
      setState(() {
        _conversaciones = lista;
      });
    } catch (_) {
      // Silencioso: es un refresco de fondo, no bloquea la interacción.
    }
  }

  // Sondea la conversación abierta cada pocos segundos para simular tiempo
  // real (el backend todavía no expone WebSocket) — así los mensajes del
  // otro participante aparecen sin tener que cerrar y reabrir el chat.
  void _iniciarSondeoMensajes(String conversacionId) {
    _pollMensajes?.cancel();
    _pollMensajes = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_conversacionActiva?.id != conversacionId) return;
      try {
        final mensajes = await ChatApiService.cargarMensajes(conversacionId, widget.userId);
        if (!mounted || _conversacionActiva?.id != conversacionId) return;
        if (mensajes.length != _mensajesActivos.length) {
          setState(() => _mensajesActivos = mensajes);
          ChatApiService.marcarMensajesLeidos(conversacionId, widget.userId);
        }
      } catch (_) {
        // Silencioso: se reintenta en el próximo ciclo.
      }
    });
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
      _iniciarSondeoMensajes(conv.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoMensajes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'comprador_social.mensajes_error_cargar')}${e.toString().replaceAll('Exception: ', '')}')),
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
                        userId: widget.userId,
                        nombreUsuario: widget.nombreComprador,
                        alAbrirConversacion: _agregarYSeleccionarConversacion,
                        buscarNuevosContactos: true,
                      ),
                Expanded(
                  child: _error != null
                      ? _PantallaError(isDark: isDark, mensaje: _error!, alReintentar: _cargarConversaciones)
                      : _conversacionActiva == null
                          ? _PantallaVacia(
                              isDark: isDark,
                              icono: Icons.forum_outlined,
                              titulo: tr(context, 'comprador_social.mensajes_vacio_titulo'),
                              subtitulo:
                                  tr(context, 'comprador_social.mensajes_vacio_subtitulo'),
                            )
                          : _cargandoMensajes
                              ? const Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto))
                              : PanelChat(
                                  key: ValueKey('${_conversacionActiva!.id}_${_mensajesActivos.length}'),
                                  conversacion: _conversacionActiva!,
                                  mensajes: _mensajesActivos,
                                  // El comprador comparte desde sus favoritos, no
                                  // desde publicaciones propias (no es vendedor).
                                  misPublicaciones: context
                                      .watch<FavoritosProvider>()
                                      .productos
                                      .map((p) => PublicacionCompartidaModelo(
                                            id: p.id,
                                            titulo: p.nombre,
                                            imagenUrl: p.imagenUrl,
                                            precio: p.precio,
                                            artesano: p.artesano,
                                          ))
                                      .toList(),
                                  usuarioId: widget.userId,
                                  usuarioNombre: widget.nombreComprador,
                                  tituloVacioCompartir: tr(context, 'comprador_social.mensajes_sin_favoritos_compartir'),
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
      decoration: BoxDecoration(
        color: isDark ? CraftHubColors.fondoOscuro : const Color(0xFFF5EFE9),
        image: construirFondoChat(isDark),
      ),
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
            TextButton(onPressed: alReintentar, child: Text(tr(context, 'comprador_social.reintentar'))),
          ],
        ),
      ),
    );
  }
}
