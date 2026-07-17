import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';
import '../../models/models_chat.dart';
import '../../services/chat_api_service.dart';
import 'burbuja_mensaje.dart';
import 'cabecera_chat.dart';
import 'barra_input_chat.dart';
import 'modal_compartir_publicacion.dart';

// TODO en tiempo real: WS /ws/chat/{conversacionId}
class PanelChat extends StatefulWidget {
  final ConversacionModelo conversacion;
  final List<MensajeModelo> mensajes;
  final List<PublicacionCompartidaModelo> misPublicaciones;
  final String usuarioId;
  final String usuarioNombre;
  final String tituloVacioCompartir;

  const PanelChat({
    super.key,
    required this.conversacion,
    required this.mensajes,
    this.misPublicaciones = const [],
    required this.usuarioId,
    required this.usuarioNombre,
    this.tituloVacioCompartir = 'No tienes nada para compartir todavía.',
  });

  @override
  State<PanelChat> createState() => _PanelChatState();
}

class _PanelChatState extends State<PanelChat> {
  final ScrollController _scroll = ScrollController();
  late List<MensajeModelo> _mensajes;
  bool _botRespondiendo = false;

  bool get _esChatBot =>
      widget.conversacion.nombreContacto == ChatApiService.nombreBotIA;

  @override
  void initState() {
    super.initState();
    _mensajes = List.of(widget.mensajes);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bajar());
  }

  @override
  void didUpdateWidget(PanelChat old) {
    super.didUpdateWidget(old);
    if (old.conversacion.id != widget.conversacion.id) {
      setState(() => _mensajes = List.of(widget.mensajes));
      WidgetsBinding.instance.addPostFrameCallback((_) => _bajar());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _bajar() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _agregar(MensajeModelo msg) {
    setState(() => _mensajes.add(msg));
    WidgetsBinding.instance.addPostFrameCallback((_) => _bajar());
  }

  Future<void> _enviarYPersistir(
    MensajeModelo optimista,
    String contenido,
    TipoMensaje tipo, {
    String? publicacionId,
    PublicacionCompartidaModelo? publicacion,
  }) async {
    _agregar(optimista);
    try {
      await ChatApiService.enviarMensaje(
        conversacionId: widget.conversacion.id,
        autorId: widget.usuarioId,
        autorNombre: widget.usuarioNombre,
        contenido: contenido,
        tipo: tipo,
        publicacionId: publicacionId,
        publicacion: publicacion,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'compartido.error_guardar_mensaje')}${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  void _onTexto(String texto) {
    if (_esChatBot) {
      _enviarAlBot(texto);
      return;
    }
    _enviarYPersistir(
      MensajeModelo(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        contenido: texto,
        tipo: TipoMensaje.texto,
        esMio: true,
        hora: DateTime.now(),
        leido: false,
      ),
      texto,
      TipoMensaje.texto,
    );
  }

  // Conversación con CraftHub IA: el backend guarda el mensaje del usuario,
  // genera la respuesta con el historial y también la persiste — aquí solo
  // se pinta de forma optimista y se agrega la respuesta cuando llega.
  Future<void> _enviarAlBot(String texto) async {
    _agregar(MensajeModelo(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      contenido: texto,
      tipo: TipoMensaje.texto,
      esMio: true,
      hora: DateTime.now(),
      leido: true,
    ));
    setState(() => _botRespondiendo = true);
    try {
      final respuesta = await ChatApiService.enviarMensajeChatbot(
        conversacionId: widget.conversacion.id,
        usuarioId: widget.usuarioId,
        usuarioNombre: widget.usuarioNombre,
        mensaje: texto,
      );
      if (!mounted) return;
      _agregar(MensajeModelo(
        id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
        contenido: respuesta,
        tipo: TipoMensaje.texto,
        esMio: false,
        hora: DateTime.now(),
        leido: true,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _botRespondiendo = false);
    }
  }

  // `url` ya es la URL pública en Supabase Storage (BarraInputChat sube la
  // imagen antes de llamar este callback), así que se persiste igual que
  // cualquier otro mensaje y el otro participante también la ve.
  void _onImagen(String url) {
    _enviarYPersistir(
      MensajeModelo(
        id: 'img_${DateTime.now().millisecondsSinceEpoch}',
        contenido: url,
        tipo: TipoMensaje.imagen,
        esMio: true,
        hora: DateTime.now(),
        leido: false,
      ),
      url,
      TipoMensaje.imagen,
    );
  }

  void _onCompartir() {
    showDialog(
      context: context,
      builder: (_) => ModalCompartirPublicacion(
        publicaciones: widget.misPublicaciones,
        tituloVacio: widget.tituloVacioCompartir,
        alCompartir: (pub) {
          _enviarYPersistir(
            MensajeModelo(
              id: 'pub_${DateTime.now().millisecondsSinceEpoch}',
              contenido: pub.imagenUrl,
              tipo: TipoMensaje.publicacion,
              esMio: true,
              hora: DateTime.now(),
              publicacion: pub,
            ),
            pub.imagenUrl,
            TipoMensaje.publicacion,
            publicacionId: pub.id,
            publicacion: pub,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        CabeceraChat(conversacion: widget.conversacion),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? CraftHubColors.fondoOscuro : const Color(0xFFF5EFE9),
              image: construirFondoChat(isDark),
            ),
            child: _mensajes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: CraftHubColors.textoSecundario(
                            isDark,
                          ).withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tr(context, 'compartido.inicia_conversacion'),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: CraftHubColors.textoSecundario(isDark),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    itemCount: _mensajes.length + 1 + (_botRespondiendo ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _SeparadorFecha(isDark: isDark, fecha: _mensajes.first.hora);
                      }
                      if (i == _mensajes.length + 1) {
                        return _BurbujaEscribiendo(isDark: isDark);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: BurbujaMensaje(
                          mensaje: _mensajes[i - 1],
                          usuarioId: widget.usuarioId,
                        ),
                      );
                    },
                  ),
          ),
        ),
        BarraInputChat(
          alEnviarTexto: _onTexto,
          alEnviarImagen: _onImagen,
          alCompartirPublicacion: _onCompartir,
        ),
      ],
    );
  }
}

// Burbuja "escribiendo..." que aparece mientras CraftHub IA genera su respuesta.
class _BurbujaEscribiendo extends StatelessWidget {
  final bool isDark;
  const _BurbujaEscribiendo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? CraftHubColors.panelOscuro2 : const Color(0xFFF1EBE4),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CraftHubColors.vinoTinto.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              tr(context, 'compartido.ia_escribiendo'),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: CraftHubColors.textoSecundario(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeparadorFecha extends StatelessWidget {
  final bool isDark;
  final DateTime fecha;
  const _SeparadorFecha({required this.isDark, required this.fecha});

  String _etiqueta(BuildContext context) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final diferencia = hoy.difference(dia).inDays;
    if (diferencia == 0) return tr(context, 'compartido.hoy');
    if (diferencia == 1) return tr(context, 'compartido.ayer');
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: CraftHubColors.borde(isDark), thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _etiqueta(context),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                color: CraftHubColors.textoSecundario(isDark),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: CraftHubColors.borde(isDark), thickness: 1),
          ),
        ],
      ),
    );
  }
}
