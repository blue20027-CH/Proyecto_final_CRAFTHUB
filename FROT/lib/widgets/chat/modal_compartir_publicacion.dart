import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models_chat.dart';

/// Modal para compartir un producto propio en el chat.
/// TODO: cargar lista real con GET /api/productos/mios?userId={id}
class ModalCompartirPublicacion extends StatelessWidget {
  final List<PublicacionCompartidaModelo> publicaciones;
  final ValueChanged<PublicacionCompartidaModelo> alCompartir;

  static final _mock = [
    PublicacionCompartidaModelo(
      id: 'p1',
      titulo: 'Bolso tejido iraca',
      imagenUrl: 'https://i.imgur.com/ZWRiMCb.jpeg',
      precio: 45.00,
      artesano: 'Rosa Martinez',
    ),
    PublicacionCompartidaModelo(
      id: 'p2',
      titulo: 'Mola Guna Yala',
      imagenUrl:
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
      precio: 38.00,
      artesano: 'Rosa Martinez',
    ),
    PublicacionCompartidaModelo(
      id: 'p3',
      titulo: 'Cesta de fibra natural',
      imagenUrl:
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
      precio: 22.50,
      artesano: 'Rosa Martinez',
    ),
  ];

  const ModalCompartirPublicacion({
    super.key,
    required this.alCompartir,
    this.publicaciones = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lista = publicaciones.isEmpty ? _mock : publicaciones;
    return Dialog(
      backgroundColor: CraftHubColors.panel(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'Compartir publicacion',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CraftHubColors.textoPrincipal(isDark),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: CraftHubColors.textoSecundario(isDark),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _Tarjeta(
                  pub: lista[i],
                  isDark: isDark,
                  alCompartir: () {
                    Navigator.pop(context);
                    alCompartir(lista[i]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final PublicacionCompartidaModelo pub;
  final bool isDark;
  final VoidCallback alCompartir;
  const _Tarjeta({
    required this.pub,
    required this.isDark,
    required this.alCompartir,
  });

  @override
  Widget build(BuildContext context) {
    final precio = pub.precio.toStringAsFixed(2);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? CraftHubColors.panelOscuro2 : CraftHubColors.fondoClaro,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CraftHubColors.borde(isDark)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: Image.network(
              pub.imagenUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: CraftHubColors.vinoTintoSuave,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pub.titulo,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CraftHubColors.textoPrincipal(isDark),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$$precio',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CraftHubColors.vinoTinto,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: alCompartir,
              style: ElevatedButton.styleFrom(
                backgroundColor: CraftHubColors.vinoTinto,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Compartir',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
