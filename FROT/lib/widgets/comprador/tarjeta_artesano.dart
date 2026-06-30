import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/artesano_modelo.dart';

class TarjetaArtesano extends StatefulWidget {
  final ArtesanoModelo artesano;
  final bool estaSeleccionado;
  final VoidCallback alPresionar;
  final Function(bool) alCambiarFavorito;

  const TarjetaArtesano({
    super.key,
    required this.artesano,
    required this.estaSeleccionado,
    required this.alPresionar,
    required this.alCambiarFavorito,
  });

  @override
  State<TarjetaArtesano> createState() => _TarjetaArtesanoState();
}

class _TarjetaArtesanoState extends State<TarjetaArtesano> {
  bool _hover = false;
  bool _favorito = false;

  @override
  void initState() {
    super.initState();
    _favorito = widget.artesano.esFavorito;
  }

  @override
  Widget build(BuildContext context) {
    final bool oscuro = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: CraftHubColors.panel(oscuro),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.estaSeleccionado
                  ? CraftHubColors.vinoTinto
                  : CraftHubColors.borde(oscuro),
              width: widget.estaSeleccionado ? 1.5 : 0.8,
            ),
          ),
          child: Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Imagen ──
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: widget.artesano.fotoUrl.isEmpty
                    ? _InicialesArtesano(nombre: widget.artesano.nombre, altura: 210)
                    : Image.network(
                        widget.artesano.fotoUrl,
                        height: 210,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _InicialesArtesano(
                          nombre: widget.artesano.nombre,
                          altura: 210,
                        ),
                      ),
              ),

              // ── Info ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.artesano.nombre,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700,
                        color: CraftHubColors.textoPrincipal(oscuro))),
                  Text(widget.artesano.especialidad,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500,
                        color: CraftHubColors.vinoTinto)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_on_outlined, size: 14,
                        color: CraftHubColors.textoSecundario(oscuro)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(widget.artesano.provincia,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 13,
                            color: CraftHubColors.textoSecundario(oscuro))),
                    ),
                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFC9A84C)),
                    const SizedBox(width: 3),
                    Text(widget.artesano.rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700,
                          color: CraftHubColors.textoPrincipal(oscuro))),
                  ]),
                ]),
              ),
            ]),

            // ── Favorito flotante ──
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() => _favorito = !_favorito);
                  widget.alCambiarFavorito(_favorito);
                  // 🔌 POST /api/favoritos/artesanos { artesano_id }
                  // 🔌 DELETE /api/favoritos/artesanos/{id}
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _favorito
                        ? CraftHubColors.vinoTinto
                        : Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4, offset: const Offset(0, 1))],
                  ),
                  child: Icon(
                    _favorito ? Icons.favorite : Icons.favorite_border,
                    size: 13,
                    color: _favorito ? Colors.white : CraftHubColors.vinoTinto,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _InicialesArtesano extends StatelessWidget {
  final String nombre;
  final double altura;

  const _InicialesArtesano({required this.nombre, required this.altura});

  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return 'A';
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: altura,
      width: double.infinity,
      color: CraftHubColors.vinoTintoSuave,
      alignment: Alignment.center,
      child: Text(
        iniciales,
        style: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: CraftHubColors.vinoTinto,
        ),
      ),
    );
  }
}