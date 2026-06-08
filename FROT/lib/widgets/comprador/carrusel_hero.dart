import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

// 🔌 Modelo del banner destacado → GET /api/productos/destacados
class BannerModelo {
  final String titulo;
  final String descripcion;
  final String imagenUrl;
  final String productoId;

  const BannerModelo({
    required this.titulo, required this.descripcion,
    required this.imagenUrl, required this.productoId,
  });

  factory BannerModelo.fromJson(Map<String, dynamic> json) => BannerModelo(
    titulo:      json['titulo'],
    descripcion: json['descripcion'],
    imagenUrl:   json['imagen_url'],
    productoId:  json['producto_id'],
  );
}

class CarruselHero extends StatefulWidget {
  final List<BannerModelo> banners;
  final Function(String productoId)? alVerMas;

  const CarruselHero({super.key, required this.banners, this.alVerMas});

  @override
  State<CarruselHero> createState() => _CarruselHeroState();
}

class _CarruselHeroState extends State<CarruselHero> {
  final PageController _ctrl = PageController();
  int _paginaActual = 0;
  late final _timer = Stream.periodic(const Duration(seconds: 4)).listen((_) {
    if (!mounted) return;
    final siguiente = (_paginaActual + 1) % widget.banners.length;
    _ctrl.animateToPage(siguiente,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  });

  @override
  void dispose() { _timer.cancel(); _ctrl.dispose(); super.dispose(); }

  void _irA(int indice) => _ctrl.animateToPage(indice,
      duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 240,
        child: Stack(children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _paginaActual = i),
            itemBuilder: (_, i) => _Slide(
              banner: widget.banners[i],
              alVerMas: () => widget.alVerMas?.call(widget.banners[i].productoId),
            ),
          ),

          // Flecha izquierda
          Positioned(left: 14, top: 0, bottom: 0,
            child: Center(child: _Flecha(
              icono: Icons.chevron_left_rounded,
              alPresionar: () => _irA(_paginaActual - 1 < 0
                  ? widget.banners.length - 1 : _paginaActual - 1),
            )),
          ),
          // Flecha derecha
          Positioned(right: 14, top: 0, bottom: 0,
            child: Center(child: _Flecha(
              icono: Icons.chevron_right_rounded,
              alPresionar: () => _irA((_paginaActual + 1) % widget.banners.length),
            )),
          ),

          // Indicadores
          Positioned(bottom: 14, left: 0, right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.banners.length, (i) =>
                GestureDetector(
                  onTap: () => _irA(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: _paginaActual == i ? 20 : 6,
                    decoration: BoxDecoration(
                      color: _paginaActual == i
                          ? Colors.white : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final BannerModelo banner;
  final VoidCallback alVerMas;
  const _Slide({required this.banner, required this.alVerMas});

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Image.network(banner.imagenUrl, // 🔌 URL desde backend
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF2d1111))),
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xCC000000), Color(0x22000000)],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(banner.titulo,
            style: GoogleFonts.poppins(fontSize: 26,
                fontWeight: FontWeight.w700, color: Colors.white, height: 1.15)),
          const SizedBox(height: 8),
          Text(banner.descripcion,
            style: GoogleFonts.poppins(fontSize: 13,
                color: Colors.white.withOpacity(0.82)),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: alVerMas, // 🔌 navega al detalle del producto
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: CraftHubColors.vinoTinto,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              elevation: 0,
            ),
            child: Text('Conocer más',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    ]);
  }
}

class _Flecha extends StatefulWidget {
  final IconData icono;
  final VoidCallback alPresionar;
  const _Flecha({required this.icono, required this.alPresionar});

  @override
  State<_Flecha> createState() => _FlechaState();
}
class _FlechaState extends State<_Flecha> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hover ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.8),
          ),
          child: Icon(widget.icono, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}