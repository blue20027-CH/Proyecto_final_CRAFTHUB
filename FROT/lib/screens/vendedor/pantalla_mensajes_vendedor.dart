import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models_chat.dart';
import '../../services/chat_api_service.dart';
import '../../services/vendedor_api_service.dart';
import '../../widgets/chat/panel_conversaciones.dart';
import '../../widgets/chat/panel_chat.dart';
import '../../widgets/chat/banner_anuncio_crafthub.dart';

// Contenido (sin Scaffold/Sidebar propios): se inserta dentro del switch de
// _obtenerPantallaActual() en pantalla_dashoard_vendedor.dart, igual que
// PantallaMensajesComprador se inserta en el switch de HomeComprador.
// Layout desktop: [PanelConversaciones] | [PanelChat]
// 🔌 Backend: BACK/CraftHub/chat_router.py
class PantallaMensajesVendedor extends StatefulWidget {
  final String userId;
  final String nombreVendedor;

  /// Nombre de contacto con el que se debe abrir (o crear) una conversación
  /// apenas se entra a esta pantalla — usado cuando se llega aquí desde el
  /// botón "Chatear" de Proveedores o el ícono de chat de Mis Órdenes.
  final String? contactoInicial;
  final String? contactoIdInicial;
  final String? rolContactoInicial;
  final VoidCallback? alConsumirContactoInicial;

  const PantallaMensajesVendedor({
    super.key,
    this.userId = '',
    this.nombreVendedor = '',
    this.contactoInicial,
    this.contactoIdInicial,
    this.rolContactoInicial,
    this.alConsumirContactoInicial,
  });

  @override
  State<PantallaMensajesVendedor> createState() =>
      _PantallaMensajesVendedorState();
}

class _PantallaMensajesVendedorState extends State<PantallaMensajesVendedor> {
  ConversacionModelo? _conversacionActiva;
  List<ConversacionModelo> _conversaciones = [];
  List<MensajeModelo> _mensajesActivos = [];
  bool _cargandoConversaciones = true;
  bool _cargandoMensajes = false;
  String? _error;

  // Publicaciones propias del vendedor para compartir en chat.
  // 🔌 GET /api/vendedor/{nombreVendedor}/productos
  List<PublicacionCompartidaModelo> _misPublicaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarConversaciones();
    _cargarMisPublicaciones();
  }

  Future<void> _cargarMisPublicaciones() async {
    if (widget.nombreVendedor.isEmpty) return;
    try {
      final respuesta = await VendedorApiService.cargarProductos(widget.nombreVendedor);
      if (!mounted) return;
      setState(() {
        _misPublicaciones = respuesta.productos
            .map((p) => PublicacionCompartidaModelo(
                  id: p.id,
                  titulo: p.nombre,
                  imagenUrl: p.rutaImagen,
                  precio: p.precio,
                  artesano: widget.nombreVendedor,
                ))
            .toList();
      });
    } catch (e) {
      debugPrint('Error cargando mis publicaciones para compartir: $e');
    }
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

      final contacto = widget.contactoInicial?.trim();
      if (contacto != null && contacto.isNotEmpty) {
        final idContacto = widget.contactoIdInicial;
        widget.alConsumirContactoInicial?.call();
        await _abrirConversacionCon(contacto, widget.rolContactoInicial ?? 'Cliente', idContacto: idContacto);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _cargandoConversaciones = false;
      });
    }
  }

  // Busca (o crea en el backend) la conversación con ese contacto y la deja
  // seleccionada — usado al llegar desde "Chatear" en Proveedores o el
  // ícono de chat en Mis Órdenes.
  //
  // El vendedor NUNCA puede iniciar una conversación con un Cliente: solo
  // puede responder a quien ya le escribió primero. Por eso, cuando
  // rolContacto == 'Cliente', esto solo busca una conversación EXISTENTE en
  // la lista ya cargada y nunca llama a abrirConversacion() (que crearía una
  // nueva). Con un Proveedor sí se puede crear, porque los proveedores son
  // un directorio sin cuenta propia con la que "escribir primero".
  Future<void> _abrirConversacionCon(String nombreContacto, String rolContacto, {String? idContacto}) async {
    if (rolContacto == 'Cliente') {
      ConversacionModelo? existente;
      for (final c in _conversaciones) {
        final mismoId = idContacto != null && idContacto.isNotEmpty && c.idContacto == idContacto;
        final mismoNombre = c.nombreContacto.trim().toLowerCase() == nombreContacto.trim().toLowerCase();
        if (mismoId || mismoNombre) {
          existente = c;
          break;
        }
      }
      if (existente == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aún no puedes escribirle a $nombreContacto: debe enviarte un mensaje primero.')),
        );
        return;
      }
      await _seleccionar(existente);
      return;
    }

    try {
      final conv = await ChatApiService.abrirConversacion(
        usuarioId: widget.userId,
        usuarioNombre: widget.nombreVendedor,
        contactoId: idContacto,
        contactoNombre: nombreContacto,
        contactoRol: rolContacto,
      );
      if (!mounted) return;
      final yaExiste = _conversaciones.any((c) => c.id == conv.id);
      setState(() {
        if (!yaExiste) _conversaciones = [conv, ..._conversaciones];
      });
      await _seleccionar(conv);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el chat: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  // Usado por el buscador de PanelConversaciones para iniciar una
  // conversación nueva con un contacto que todavía no tenía una.
  void _agregarYSeleccionarConversacion(ConversacionModelo conv) {
    final yaExiste = _conversaciones.any((c) => c.id == conv.id);
    setState(() {
      if (!yaExiste) _conversaciones = [conv, ..._conversaciones];
    });
    _seleccionar(conv);
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
                        userId: widget.userId,
                        nombreUsuario: widget.nombreVendedor,
                        alAbrirConversacion: _agregarYSeleccionarConversacion,
                      ),
                Expanded(
                  child: _error != null
                      ? _PantallaError(isDark: isDark, mensaje: _error!, alReintentar: _cargarConversaciones)
                      : _conversacionActiva == null
                          ? _PantallaVacia(isDark: isDark)
                          : _cargandoMensajes
                              ? const Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto))
                              : PanelChat(
                                  key: ValueKey(_conversacionActiva!.id),
                                  conversacion: _conversacionActiva!,
                                  mensajes: _mensajesActivos,
                                  misPublicaciones: _misPublicaciones,
                                  usuarioId: widget.userId,
                                  usuarioNombre: widget.nombreVendedor,
                                  tituloVacioCompartir: 'Aún no tienes productos publicados para compartir.',
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
