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

  Future<void> _enviarYPersistir(MensajeModelo optimista, String contenido, TipoMensaje tipo, {String? publicacionId}) async {
    _agregar(optimista);
    try {
      await ChatApiService.enviarMensaje(
        conversacionId: widget.conversacion.id,
        autorId: widget.usuarioId,
        autorNombre: widget.usuarioNombre,
        contenido: contenido,
        tipo: tipo,
        publicacionId: publicacionId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'compartido.error_guardar_mensaje')}${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  void _onTexto(String texto) {
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
                    itemCount: _mensajes.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _SeparadorFecha(isDark: isDark, fecha: _mensajes.first.hora);
                      }
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
