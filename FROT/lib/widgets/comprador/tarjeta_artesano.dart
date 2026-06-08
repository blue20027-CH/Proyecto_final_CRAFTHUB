import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/artesano_modelo_prueba.dart';

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
                child: Image.network(
                  widget.artesano.fotoUrl, // 🔌 URL desde backend
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: CraftHubColors.vinoTintoSuave,
                    child: const Icon(Icons.person_outline, size: 40,
                        color: CraftHubColors.vinoTinto),
                  ),
                ),
              ),

              // ── Info ──
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.artesano.nombre,
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
                        color: CraftHubColors.textoPrincipal(oscuro))),
                  const SizedBox(height: 1),
                  Text(widget.artesano.especialidad,
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500,
                        color: CraftHubColors.vinoTinto)),
                  const SizedBox(height: 5),
                  Row(children: [
                    Icon(Icons.location_on_outlined, size: 11,
                        color: CraftHubColors.textoSecundario(oscuro)),
                    const SizedBox(width: 2),
                    Text(widget.artesano.provincia,
                      style: GoogleFonts.poppins(fontSize: 10,
                          color: CraftHubColors.textoSecundario(oscuro))),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 13, color: Color(0xFFC9A84C)),
                    const SizedBox(width: 3),
                    Text(widget.artesano.rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600,
                          color: CraftHubColors.textoPrincipal(oscuro))),
                    const SizedBox(width: 2),
                    Text('(${widget.artesano.totalResenas})',
                      style: GoogleFonts.poppins(fontSize: 10,
                          color: CraftHubColors.textoSecundario(oscuro))),
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
                        : Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12),
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