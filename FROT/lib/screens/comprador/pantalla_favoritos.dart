import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/comprador/tarjeta_producto.dart';

class PantallaFavoritos extends StatefulWidget {
  final String userId;

  const PantallaFavoritos({super.key, required this.userId});

  @override
  State<PantallaFavoritos> createState() => _PantallaFavoritosState();
}

class _PantallaFavoritosState extends State<PantallaFavoritos> {
  List<ProductoModelo> _favoritos = [];
  bool _cargando = true;
  String? _error;

  // Para usuarios no logueados: favoritos locales en memoria
  final Set<String> _favoritosLocales = {};

  bool get _estaLogueado => widget.userId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_estaLogueado) {
      _cargarFavoritos();
    } else {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cargarFavoritos() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final data = await ApiService.getFavoritos(widget.userId);
      debugPrint('FAVORITOS RAW: $data');
      setState(() {
        _favoritos = data.map((p) {
          final mapa = Map<String, dynamic>.from(p);
          mapa['id'] = mapa['id'].toString();
          return ProductoModelo.fromJson(mapa);
        }).toList();
      });
    } catch (e) {
      debugPrint('ERROR FAVORITOS: $e');
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _quitarFavorito(ProductoModelo producto) async {
    if (!_estaLogueado) {
      setState(() => _favoritosLocales.remove(producto.id));
      return;
    }
    try {
      await ApiService.quitarFavorito(widget.userId, int.parse(producto.id));
      await _cargarFavoritos();
    } catch (e) {
      debugPrint('Error quitando favorito: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = CraftHubColors.fondo(oscuro);

    return Container(
      color: colorFondo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Row(children: [
              Text('Mis favoritos',
                style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: CraftHubColors.textoPrincipal(oscuro))),
              const SizedBox(width: 8),
              const Icon(Icons.favorite, color: CraftHubColors.vinoTinto, size: 22),
              const Spacer(),
              if (_estaLogueado)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CraftHubColors.panel(oscuro),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CraftHubColors.borde(oscuro)),
                  ),
                  child: Text('${_favoritos.length} productos',
                    style: GoogleFonts.poppins(fontSize: 12,
                      color: CraftHubColors.textoSecundario(oscuro))),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              _estaLogueado
                ? 'Productos que has guardado como favoritos.'
                : 'Inicia sesión para guardar tus favoritos.',
              style: GoogleFonts.poppins(fontSize: 13,
                color: CraftHubColors.textoSecundario(oscuro))),
          ),
          const SizedBox(height: 18),

          // ── Contenido ────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _cargando
                ? const Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto))
                : _error != null
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 48, color: CraftHubColors.vinoTinto),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 13,
                            color: CraftHubColors.textoSecundario(oscuro))),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _cargarFavoritos,
                          child: Text('Reintentar', style: GoogleFonts.poppins()),
                        ),
                      ],
                    ))
                  : !_estaLogueado
                    ? _EstadoNoLogueado(oscuro: oscuro)
                    : _favoritos.isEmpty
                      ? _EstadoVacio(oscuro: oscuro)
                      : MasonryGridView.count(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          itemCount: _favoritos.length,
                          itemBuilder: (_, i) {
                            final alturas = [280.0, 220.0, 310.0, 250.0, 290.0, 240.0];
                            return Stack(
                              children: [
                                TarjetaProducto(
                                  producto: _favoritos[i],
                                  altura: alturas[i % alturas.length],
                                  alPresionar: () {},
                                ),
                                Positioned(
                                  top: 8, right: 8,
                                  child: GestureDetector(
                                    onTap: () => _quitarFavorito(_favoritos[i]),
                                    child: Container(
                                      width: 32, height: 32,
                                      decoration: const BoxDecoration(
                                        color: CraftHubColors.vinoTinto,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.favorite,
                                        color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final bool oscuro;
  const _EstadoVacio({required this.oscuro});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 64,
            color: CraftHubColors.textoSecundario(oscuro)),
          const SizedBox(height: 16),
          Text('No tienes favoritos aún',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600,
              color: CraftHubColors.textoPrincipal(oscuro))),
          const SizedBox(height: 8),
          Text('Explora el catálogo y guarda los productos\nque más te gusten.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13,
              color: CraftHubColors.textoSecundario(oscuro))),
        ],
      ),
    );
  }
}

class _EstadoNoLogueado extends StatelessWidget {
  final bool oscuro;
  const _EstadoNoLogueado({required this.oscuro});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 64,
            color: CraftHubColors.textoSecundario(oscuro)),
          const SizedBox(height: 16),
          Text('Inicia sesión para ver tus favoritos',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600,
              color: CraftHubColors.textoPrincipal(oscuro))),
          const SizedBox(height: 8),
          Text('Guarda tus productos favoritos\ny accede a ellos desde cualquier dispositivo.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13,
              color: CraftHubColors.textoSecundario(oscuro))),
        ],
      ),
    );
  }
}