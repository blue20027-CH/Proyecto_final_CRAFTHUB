import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models_chat.dart';
import 'tarjeta_conversacion.dart';

/// Panel izquierdo: lista de conversaciones + buscador.
/// TODO: cargar conversaciones con GET /api/conversaciones/{userId}
class PanelConversaciones extends StatefulWidget {
  final List<ConversacionModelo> conversaciones;
  final String? idSeleccionado;
  final ValueChanged<ConversacionModelo> alSeleccionar;

  const PanelConversaciones({
    super.key,
    required this.conversaciones,
    required this.alSeleccionar,
    this.idSeleccionado,
  });

  @override
  State<PanelConversaciones> createState() => _PanelConversacionesState();
}

class _PanelConversacionesState extends State<PanelConversaciones> {
  final TextEditingController _busqueda = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
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
                  'Mensajes',
                  style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CraftHubColors.textoPrincipal(isDark),
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Nueva conversación',
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
                hintText: 'Buscar conversaciones...',
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
            child: _filtradas.isEmpty
                ? Center(
                    child: Text('Sin resultados',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                            color: CraftHubColors.textoSecundario(isDark))),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    itemCount: _filtradas.length,
                    itemBuilder: (_, i) => TarjetaConversacion(
                      conversacion: _filtradas[i],
                      seleccionada: _filtradas[i].id == widget.idSeleccionado,
                      alTap: () => widget.alSeleccionar(_filtradas[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
