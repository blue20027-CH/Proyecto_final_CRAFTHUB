import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models_chat.dart';
import 'burbuja_mensaje.dart';
import 'cabecera_chat.dart';
import 'barra_input_chat.dart';
import 'modal_compartir_publicacion.dart';

// TODO al montar: GET /api/mensajes/{conversacionId}
// TODO en tiempo real: WS /ws/chat/{conversacionId}
class PanelChat extends StatefulWidget {
  final ConversacionModelo conversacion;
  final List<MensajeModelo> mensajes;
  final List<PublicacionCompartidaModelo> misPublicaciones;

  const PanelChat({
    super.key,
    required this.conversacion,
    required this.mensajes,
    this.misPublicaciones = const [],
  });

  @override
  State<PanelChat> createState() => _PanelChatState();
}

class _PanelChatState extends State<PanelChat> {
  final ScrollController _scroll = ScrollController();
  late List<MensajeModelo> _mensajes;

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

  void _onTexto(String texto) {
    // TODO: POST /api/mensajes {conversacionId, contenido, tipo: "texto"}
    _agregar(
      MensajeModelo(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        contenido: texto,
        tipo: TipoMensaje.texto,
        esMio: true,
        hora: DateTime.now(),
        leido: false,
      ),
    );
  }

  void _onImagen(String path) {
    // TODO: POST /api/mensajes/imagen (multipart) -> URL -> enviar mensaje
    _agregar(
      MensajeModelo(
        id: 'img_${DateTime.now().millisecondsSinceEpoch}',
        contenido: path,
        tipo: TipoMensaje.imagen,
        esMio: true,
        hora: DateTime.now(),
      ),
    );
  }

  void _onCompartir() {
    showDialog(
      context: context,
      builder: (_) => ModalCompartirPublicacion(
        publicaciones: widget.misPublicaciones,
        alCompartir: (pub) {
          // TODO: POST /api/mensajes {conversacionId, tipo: "publicacion", publicacionId: pub.id}
          _agregar(
            MensajeModelo(
              id: 'pub_${DateTime.now().millisecondsSinceEpoch}',
              contenido: pub.imagenUrl,
              tipo: TipoMensaje.publicacion,
              esMio: true,
              hora: DateTime.now(),
              publicacion: pub,
            ),
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
            color: isDark
                ? CraftHubColors.fondoOscuro
                : const Color(0xFFF5EFE9),
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
                          'Inicia la conversacion',
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
                    itemCount: _mensajes.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) return _SeparadorFecha(isDark: isDark);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: BurbujaMensaje(mensaje: _mensajes[i - 1]),
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

class _SeparadorFecha extends StatelessWidget {
  final bool isDark;
  const _SeparadorFecha({required this.isDark});
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
              'Hoy',
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
