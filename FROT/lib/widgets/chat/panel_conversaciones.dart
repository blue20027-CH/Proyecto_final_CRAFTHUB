import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';
import '../../models/artesano_modelo.dart';
import '../../models/models_chat.dart';
import '../../services/api_service.dart';
import '../../services/chat_api_service.dart';
import 'tarjeta_conversacion.dart';

/// Panel izquierdo: lista de conversaciones + buscador. Cuando
/// [buscarNuevosContactos] está activo (lado comprador), el buscador también
/// sugiere vendedores con los que aún no hay conversación (busca dentro de
/// GET /api/artesanos), para poder iniciar un chat nuevo desde aquí mismo.
/// Del lado vendedor no hay un directorio equivalente de compradores, así
/// que se deja desactivado (valor por defecto) y solo filtra conversaciones
/// existentes, como antes.
class PanelConversaciones extends StatefulWidget {
  final List<ConversacionModelo> conversaciones;
  final String? idSeleccionado;
  final ValueChanged<ConversacionModelo> alSeleccionar;
  final String userId;
  final String nombreUsuario;
  final ValueChanged<ConversacionModelo> alAbrirConversacion;
  final bool buscarNuevosContactos;

  const PanelConversaciones({
    super.key,
    required this.conversaciones,
    required this.alSeleccionar,
    required this.userId,
    required this.nombreUsuario,
    required this.alAbrirConversacion,
    this.idSeleccionado,
    this.buscarNuevosContactos = false,
  });

  @override
  State<PanelConversaciones> createState() => _PanelConversacionesState();
}

class _PanelConversacionesState extends State<PanelConversaciones> {
  final TextEditingController _busqueda = TextEditingController();
  String _query = '';
  List<ArtesanoModelo> _artesanosDisponibles = [];
  String? _abriendoContactoId;

  @override
  void initState() {
    super.initState();
    if (widget.buscarNuevosContactos) _cargarArtesanosDisponibles();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  // Se cargan una sola vez para filtrar en el cliente mientras el usuario
  // escribe (mismo patrón que topbar_flotante.dart para sugerencias).
  Future<void> _cargarArtesanosDisponibles() async {
    try {
      final lista = await ApiService.getArtesanos(limite: 60);
      if (mounted) setState(() => _artesanosDisponibles = lista);
    } catch (_) {
      // Silencioso: si falla, simplemente no aparecen sugerencias de
      // vendedores nuevos, pero la lista de conversaciones existentes sigue
      // funcionando con normalidad.
    }
  }

  List<ConversacionModelo> get _filtradas {
    if (_query.isEmpty) return widget.conversaciones;
    final q = _query.toLowerCase();
    return widget.conversaciones
        .where((c) =>
            c.nombreContacto.toLowerCase().contains(q) ||
            c.ultimoMensaje.toLowerCase().contains(q))
        .toList();
  }

  /// Vendedores que coinciden con la búsqueda y con los que todavía no hay
  /// una conversación (para no duplicar lo que ya se ve en `_filtradas`).
  List<ArtesanoModelo> get _artesanosSugeridos {
    if (!widget.buscarNuevosContactos) return const [];
    final q = _query.trim().toLowerCase();
    if (q.length < 2) return const [];
    final idsConEnConversacion = widget.conversaciones
        .map((c) => c.idContacto)
        .whereType<String>()
        .toSet();
    final nombresConConversacion =
        widget.conversaciones.map((c) => c.nombreContacto.toLowerCase()).toSet();
    return _artesanosDisponibles.where((a) {
      final coincide = a.nombre.toLowerCase().contains(q) || a.especialidad.toLowerCase().contains(q);
      final yaTieneConversacion = (a.id.isNotEmpty && idsConEnConversacion.contains(a.id)) ||
          nombresConConversacion.contains(a.nombre.toLowerCase());
      return coincide && !yaTieneConversacion;
    }).take(6).toList();
  }

  Future<void> _iniciarConversacionCon(ArtesanoModelo artesano) async {
    if (widget.userId.isEmpty || _abriendoContactoId != null) return;
    setState(() => _abriendoContactoId = artesano.id.isEmpty ? artesano.nombre : artesano.id);
    try {
      final conv = await ChatApiService.abrirConversacion(
        usuarioId: widget.userId,
        usuarioNombre: widget.nombreUsuario,
        contactoId: artesano.id.isEmpty ? null : artesano.id,
        contactoNombre: artesano.nombre,
        contactoRol: 'Vendedor',
      );
      widget.alAbrirConversacion(conv);
      if (!mounted) return;
      _busqueda.clear();
      setState(() => _query = '');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'compartido.error_abrir_conversacion_prefijo')}${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _abriendoContactoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: CraftHubColors.panel(isDark),
        border: Border(right: BorderSide(color: CraftHubColors.borde(isDark))),
      ),
      child: Column(
        children: [
          // Cabecera
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Text(
                  tr(context, 'compartido.mensajes_titulo'),
                  style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CraftHubColors.textoPrincipal(isDark),
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: tr(context, 'compartido.nueva_conversacion_tooltip'),
                  child: InkWell(
                    // TODO: abrir modal para buscar usuarios y crear conversación
                    // POST /api/conversaciones con {userId, contactoId}
                    onTap: () {},
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isDark
                            ? CraftHubColors.panelOscuro2
                            : CraftHubColors.fondoClaro,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit_outlined, size: 18,
                          color: CraftHubColors.textoSecundario(isDark)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Buscador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              controller: _busqueda,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(
                fontFamily: 'Poppins', fontSize: 13,
                color: CraftHubColors.textoPrincipal(isDark),
              ),
              decoration: InputDecoration(
                hintText: tr(context, 'compartido.buscar_conversaciones_hint'),
                hintStyle: TextStyle(
                  fontFamily: 'Poppins', fontSize: 13,
                  color: CraftHubColors.textoSecundario(isDark),
                ),
                prefixIcon: Icon(Icons.search_rounded, size: 18,
                    color: CraftHubColors.textoSecundario(isDark)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, size: 16,
                            color: CraftHubColors.textoSecundario(isDark)),
                        onPressed: () {
                          _busqueda.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: isDark ? CraftHubColors.panelOscuro2 : CraftHubColors.fondoClaro,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Lista
          Expanded(
            child: (_filtradas.isEmpty && _artesanosSugeridos.isEmpty)
                ? Center(
                    child: Text(tr(context, 'compartido.sin_resultados'),
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                            color: CraftHubColors.textoSecundario(isDark))),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    children: [
                      ..._filtradas.map((c) => TarjetaConversacion(
                            conversacion: c,
                            seleccionada: c.id == widget.idSeleccionado,
                            alTap: () => widget.alSeleccionar(c),
                          )),
                      if (_artesanosSugeridos.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
                          child: Text(tr(context, 'compartido.iniciar_conversacion'),
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600,
                                  color: CraftHubColors.textoSecundario(isDark))),
                        ),
                        ..._artesanosSugeridos.map((a) => _FilaArtesanoSugerido(
                              artesano: a,
                              cargando: _abriendoContactoId == (a.id.isEmpty ? a.nombre : a.id),
                              esOscuro: isDark,
                              onTap: () => _iniciarConversacionCon(a),
                            )),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilaArtesanoSugerido extends StatelessWidget {
  final ArtesanoModelo artesano;
  final bool cargando;
  final bool esOscuro;
  final VoidCallback onTap;
  const _FilaArtesanoSugerido({
    required this.artesano,
    required this.cargando,
    required this.esOscuro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: cargando ? null : onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: CraftHubColors.vinoTintoSuave,
        backgroundImage: artesano.fotoUrl.isEmpty ? null : NetworkImage(artesano.fotoUrl),
        child: artesano.fotoUrl.isEmpty
            ? Text(
                artesano.nombre.trim().isEmpty ? '?' : artesano.nombre.trim()[0].toUpperCase(),
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: CraftHubColors.vinoTinto),
              )
            : null,
      ),
      title: Text(artesano.nombre,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600,
              color: CraftHubColors.textoPrincipal(esOscuro))),
      subtitle: Text(artesano.especialidad,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: CraftHubColors.textoSecundario(esOscuro))),
      trailing: cargando
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: CraftHubColors.vinoTinto),
    );
  }
}
