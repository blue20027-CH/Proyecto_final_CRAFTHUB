import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/i18n/i18n.dart';
import 'panel_lateral_favoritos.dart';

/// Modal que muestra TODOS los artesanos que el usuario sigue.
/// Se abre desde el botón "Ver todos" del panel lateral.
/// 🔗 API: GET /api/v1/artesanos/seguidos/{usuarioId}?page=1&limit=50
void mostrarModalArtesanosSeguidos({
  required BuildContext context,
  required List<ModeloArtesanoSeguido> artesanos,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _ModalArtesanosSeguidos(artesanos: artesanos),
  );
}

class _ModalArtesanosSeguidos extends StatefulWidget {
  final List<ModeloArtesanoSeguido> artesanos;

  const _ModalArtesanosSeguidos({required this.artesanos});

  @override
  State<_ModalArtesanosSeguidos> createState() =>
      _ModalArtesanosSeguidosState();
}

class _ModalArtesanosSeguidosState extends State<_ModalArtesanosSeguidos> {
  final _controladorBusqueda = TextEditingController();
  List<ModeloArtesanoSeguido> _artesanosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _artesanosFiltrados = widget.artesanos;
  }

  void _filtrar(String texto) {
    setState(() {
      _artesanosFiltrados = widget.artesanos
          .where((a) =>
              a.nombre.toLowerCase().contains(texto.toLowerCase()) ||
              a.provincia.toLowerCase().contains(texto.toLowerCase()) ||
              a.categoria.toLowerCase().contains(texto.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esTemaOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondo =
        esTemaOscuro ? const Color(0xFF1E1E1E) : Colors.white;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 640,
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Encabezado
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              decoration: BoxDecoration(
                color: esTemaOscuro
                    ? const Color(0xFF2A1010)
                    : const Color(0xFFFDF0F0),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_outline_rounded,
                      color: Color(0xFF821515), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr(context, 'comprador_secundario.artesanos_que_sigues_titulo'),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF821515),
                      ),
                    ),
                  ),
                  Text(
                    '${widget.artesanos.length} ${tr(context, 'comprador_secundario.artesanos_sufijo')}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: esTemaOscuro ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: esTemaOscuro
                          ? const Color(0xFF2A2A2A)
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Buscador
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: TextField(
                controller: _controladorBusqueda,
                onChanged: _filtrar,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                decoration: InputDecoration(
                  hintText: tr(context, 'comprador_secundario.buscar_artesanos_seguidos_hint'),
                  hintStyle: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: esTemaOscuro
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF9F6F0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Grid de artesanos
            Expanded(
              child: _artesanosFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 48,
                              color: esTemaOscuro
                                  ? Colors.white24
                                  : Colors.black26),
                          const SizedBox(height: 12),
                          Text(
                            tr(context, 'comprador_secundario.no_se_encontraron_artesanos'),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: esTemaOscuro
                                  ? Colors.white38
                                  : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.05,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _artesanosFiltrados.length,
                      itemBuilder: (context, i) {
                        final artesano = _artesanosFiltrados[i];
                        return _TarjetaArtesanoModal(
                          artesano: artesano,
                          esTemaOscuro: esTemaOscuro,
                        )
                            .animate()
                            .fadeIn(delay: (i * 40).ms)
                            .slideY(begin: 0.05);
                      },
                    ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ).animate().fadeIn(duration: 200.ms).scale(
            begin: const Offset(0.96, 0.96),
            duration: 200.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }
}

/// Tarjeta de artesano dentro del modal (versión grande con más info).
class _TarjetaArtesanoModal extends StatefulWidget {
  final ModeloArtesanoSeguido artesano;
  final bool esTemaOscuro;

  const _TarjetaArtesanoModal({
    required this.artesano,
    required this.esTemaOscuro,
  });

  @override
  State<_TarjetaArtesanoModal> createState() => _TarjetaArtesanoModalState();
}

class _TarjetaArtesanoModalState extends State<_TarjetaArtesanoModal> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colorFondoTarjeta = widget.esTemaOscuro
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF9F6F0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovering
              ? const Color(0xFF821515).withValues(alpha: 0.08)
              : colorFondoTarjeta,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovering
                ? const Color(0xFF821515).withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: AssetImage(widget.artesano.rutaFoto),
              backgroundColor:
                  const Color(0xFF821515).withValues(alpha: 0.15),
              onBackgroundImageError: (_, _) {},
            ),
            const SizedBox(height: 8),
            Text(
              widget.artesano.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              widget.artesano.provincia,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: widget.esTemaOscuro
                    ? Colors.white54
                    : Colors.black45,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFF821515), size: 13),
                const SizedBox(width: 3),
                Text(
                  widget.artesano.calificacion.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

