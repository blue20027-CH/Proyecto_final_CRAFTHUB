import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models_chat.dart';
import '../../widgets/comprador/sidebar_comprador.dart';
import '../../widgets/chat/panel_conversaciones.dart';
import '../../widgets/chat/panel_chat.dart';

// Layout desktop: [Sidebar] | [PanelConversaciones] | [PanelChat]
// TODO al iniciar: GET /api/conversaciones/{compradorId}
// TODO en tiempo real: WS /ws/chat/{conversacionId}
class PantallaMensajesComprador extends StatefulWidget {
  const PantallaMensajesComprador({super.key});

  @override
  State<PantallaMensajesComprador> createState() =>
      _PantallaMensajesCompradorState();
}

class _PantallaMensajesCompradorState extends State<PantallaMensajesComprador> {
  int _indiceActivo = 4; // 4 = Mensajes en sidebar comprador

  ConversacionModelo? _conversacionActiva;
  late List<ConversacionModelo> _conversaciones;
  List<MensajeModelo> _mensajesActivos = [];

  @override
  void initState() {
    super.initState();
    // TODO: reemplazar con GET /api/conversaciones/{compradorId}
    _conversaciones = mockConversaciones();
  }

  void _seleccionar(ConversacionModelo conv) {
    setState(() {
      _conversacionActiva = conv;
      // TODO: GET /api/mensajes/{conv.id}
      _mensajesActivos = conv.id == 'c1' ? mockMensajesRosa() : [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: CraftHubColors.fondo(isDark),
      body: Row(
        children: [
          PanelConversaciones(
            conversaciones: _conversaciones,
            idSeleccionado: _conversacionActiva?.id,
            alSeleccionar: _seleccionar,
          ),
          Expanded(
            child: _conversacionActiva == null
                ? _PantallaVacia(
                    isDark: isDark,
                    icono: Icons.forum_outlined,
                    titulo: 'Tus mensajes',
                    subtitulo:
                        'Selecciona una conversación para chatear\ncon un artesano.',
                  )
                : PanelChat(
                    key: ValueKey(_conversacionActiva!.id),
                    conversacion: _conversacionActiva!,
                    mensajes: _mensajesActivos,
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
