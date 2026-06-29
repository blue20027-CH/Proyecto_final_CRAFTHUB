import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/artesano_modelo.dart';

/// Panel lateral derecho con el perfil del artesano seleccionado
class PanelPerfilArtesano extends StatelessWidget {
  final ArtesanoModelo artesano;
  final VoidCallback alVerProductos;
  final VoidCallback alEnviarMensaje;

  const PanelPerfilArtesano({
    super.key,
    required this.artesano,
    required this.alVerProductos,
    required this.alEnviarMensaje,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = CraftHubColors.panel(oscuro);
    final colorBorde = CraftHubColors.borde(oscuro);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colorFondo,
        border: Border(left: BorderSide(color: colorBorde, width: 0.8)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // â”€â”€ Foto portada â”€â”€
          // ðŸ”Œ artesano.fotoPortadaUrl viene del backend
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:artesano.bannerEfectivo.isEmpty
                ? _BloqueIniciales(nombre: artesano.nombre, altura: 158)
             : Image.network(
                      artesano.bannerEfectivo,
                    height: 158,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _BloqueIniciales(
                      nombre: artesano.nombre,
                      altura: 158,
                    ),
                  ),
          ),
          const SizedBox(height: 14),

          // â”€â”€ Avatar + nombre â”€â”€
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: CraftHubColors.vinoTintoSuave,
                backgroundImage: artesano.fotoUrl.isEmpty
                    ? null
                    : NetworkImage(artesano.fotoUrl),
                onBackgroundImageError:
                    artesano.fotoUrl.isEmpty ? null : (_, _) {},
                child: artesano.fotoUrl.isEmpty
                    ? Text(
                        _inicialesArtesano(artesano.nombre),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: CraftHubColors.vinoTinto,
                        ),
                      )
                    : null,
              ),
              if (artesano.estaVerificado)
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 17, height: 17,
                    decoration: BoxDecoration(
                      color: CraftHubColors.vinoTinto,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.check, size: 9, color: Color(0xFF86efac)),
                  ),
                ),
            ]),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(artesano.nombre,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700,
                      color: CraftHubColors.textoPrincipal(oscuro))),
                Text(artesano.especialidad,
                  style: GoogleFonts.poppins(fontSize: 11,
                      color: CraftHubColors.textoSecundario(oscuro))),
                const SizedBox(height: 5),
                if (artesano.estaVerificado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: CraftHubColors.vinoTintoSuave,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: CraftHubColors.vinoTinto, width: 0.8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.shield_outlined, size: 10,
                          color: CraftHubColors.vinoTinto),
                      const SizedBox(width: 3),
                      Text('Artesana verificada',
                        style: GoogleFonts.poppins(fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: CraftHubColors.vinoTinto)),
                    ]),
                  ),
              ]),
            ),
          ]),

          _Separador(),
          const SizedBox(height: 4),

          // â”€â”€ UbicaciÃ³n y rating â”€â”€
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 13,
                color: CraftHubColors.vinoTinto),
            const SizedBox(width: 4),
            Expanded(child: Text('${artesano.provincia}, PanamÃ¡',
              style: GoogleFonts.poppins(fontSize: 11,
                  color: CraftHubColors.textoSecundario(oscuro)))),
            const Icon(Icons.star_rounded, size: 13, color: Color(0xFFC9A84C)),
            const SizedBox(width: 3),
            Text(artesano.rating.toStringAsFixed(1),
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600,
                  color: CraftHubColors.textoPrincipal(oscuro))),
            const SizedBox(width: 2),
            Text('(${artesano.totalResenas} reseÃ±as)',
              style: GoogleFonts.poppins(fontSize: 10,
                  color: CraftHubColors.textoSecundario(oscuro))),
          ]),
          const SizedBox(height: 10),

          // â”€â”€ DescripciÃ³n â”€â”€
          Text(artesano.descripcion,
            style: GoogleFonts.poppins(fontSize: 11, height: 1.65,
                color: CraftHubColors.textoSecundario(oscuro))),
          const SizedBox(height: 14),

          // â”€â”€ Especialidades â”€â”€
          Text('Especialidades',
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600,
                color: CraftHubColors.textoPrincipal(oscuro))),
          const SizedBox(height: 7),
          Wrap(
            spacing: 5, runSpacing: 5,
            children: artesano.especialidades.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: CraftHubColors.fondo(oscuro),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorBorde, width: 0.8),
              ),
              child: Text(e,
                style: GoogleFonts.poppins(fontSize: 10,
                    color: CraftHubColors.textoSecundario(oscuro))),
            )).toList(),
          ),
          const SizedBox(height: 16),

          // â”€â”€ Stats: reseÃ±as, ventas, experiencia â”€â”€
          Row(children: [
            _StatItem(
              icono: Icons.star_outline_rounded,
              valor: '${artesano.totalResenas}',
              etiqueta: 'ReseÃ±as',
            ),
            const SizedBox(width: 8),
            _StatItem(
              icono: Icons.shopping_bag_outlined,
              valor: '${artesano.totalVentas}',
              etiqueta: 'Ventas',
            ),
            const SizedBox(width: 8),
            _StatItem(
              icono: Icons.emoji_events_outlined,
              valor: '${artesano.anosExperiencia}+',
              etiqueta: 'AÃ±os de exp.',
            ),
          ]),
          const SizedBox(height: 16),

          // â”€â”€ BotÃ³n Ver productos â”€â”€
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: alVerProductos,
              // ðŸ”Œ navegar a CatÃ¡logoArtesano(artesanoId: artesano.id)
              icon: const SizedBox.shrink(),
              label: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Ver productos',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Colors.white)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white),
              ]),
              style: ElevatedButton.styleFrom(
                backgroundColor: CraftHubColors.vinoTinto,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // â”€â”€ BotÃ³n Enviar mensaje â”€â”€
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: alEnviarMensaje,
              // ðŸ”Œ navegar a ChatPrivado(artesanoId: artesano.id)
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14,
                  color: CraftHubColors.vinoTinto),
              label: Text('Enviar mensaje',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
                    color: CraftHubColors.vinoTinto)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: CraftHubColors.vinoTinto, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// â”€â”€ Widgets internos del panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Separador extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: CraftHubColors.borde(oscuro), height: 0.8, thickness: 0.8),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;

  const _StatItem({
    required this.icono,
    required this.valor,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: CraftHubColors.fondo(oscuro),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Icon(icono, size: 17, color: CraftHubColors.vinoTinto),
          const SizedBox(height: 3),
          Text(valor,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700,
                color: CraftHubColors.textoPrincipal(oscuro))),
          Text(etiqueta,
            style: GoogleFonts.poppins(fontSize: 9,
                color: CraftHubColors.textoSecundario(oscuro)),
            textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

String _inicialesArtesano(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+'));
  if (partes.isEmpty || partes.first.isEmpty) return 'A';
  return partes.take(2).map((p) => p[0].toUpperCase()).join();
}

class _BloqueIniciales extends StatelessWidget {
  final String nombre;
  final double altura;

  const _BloqueIniciales({required this.nombre, required this.altura});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: altura,
      width: double.infinity,
      color: CraftHubColors.vinoTintoSuave,
      alignment: Alignment.center,
      child: Text(
        _inicialesArtesano(nombre),
        style: GoogleFonts.poppins(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: CraftHubColors.vinoTinto,
        ),
      ),
    );
  }
}
