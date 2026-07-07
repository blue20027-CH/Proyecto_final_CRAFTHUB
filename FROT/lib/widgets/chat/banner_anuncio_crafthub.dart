// Banner con el último anuncio de CraftHub para todos los usuarios
// (comprador y vendedor), arriba de la lista de conversaciones.
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class BannerAnuncioCraftHub extends StatefulWidget {
  final String userId;
  const BannerAnuncioCraftHub({super.key, required this.userId});

  @override
  State<BannerAnuncioCraftHub> createState() => _BannerAnuncioCraftHubState();
}

class _BannerAnuncioCraftHubState extends State<BannerAnuncioCraftHub> {
  Map<String, dynamic>? _ultimoAnuncio;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (widget.userId.isEmpty) {
      setState(() => _cargando = false);
      return;
    }
    try {
      final data = await ApiService.getAnuncios(widget.userId);
      final anuncios = (data['anuncios'] as List<dynamic>? ?? []);
      if (!mounted) return;
      setState(() {
        _ultimoAnuncio = anuncios.isNotEmpty ? Map<String, dynamic>.from(anuncios.first) : null;
      });
    } catch (_) {
      // Sin anuncios o backend no disponible: simplemente no se muestra el banner.
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando || _ultimoAnuncio == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titulo = (_ultimoAnuncio!['titulo'] ?? 'CraftHub').toString();
    final texto = (_ultimoAnuncio!['texto'] ?? '').toString();
    final fecha = (_ultimoAnuncio!['created_at'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CraftHubColors.vinoTintoSuave,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CraftHubColors.vinoTinto.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: CraftHubColors.vinoTinto,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_outlined, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700,
                        color: CraftHubColors.textoPrincipal(isDark))),
                const SizedBox(height: 3),
                Text(texto,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, height: 1.4,
                        color: CraftHubColors.textoPrincipal(isDark))),
                if (fecha.length >= 10) ...[
                  const SizedBox(height: 4),
                  Text(fecha.substring(0, 10),
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5,
                          color: CraftHubColors.textoSecundario(isDark))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
