import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/i18n/i18n.dart';
import '../main.dart';
import '../models/artesano_modelo.dart';
import '../services/api_service.dart';
import 'comprador/tarjeta_producto.dart' show ProductoModelo;
import '../screens/comprador/pantalla_detalle_producto.dart';
import '../screens/navegacion_artesano.dart';

// Un ítem del menú desplegable "Explorar" (secciones de la app).
class ItemExplorar {
  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  const ItemExplorar({required this.icono, required this.etiqueta, required this.onTap});
}

// ──────────────────────────────────────────────────────────────────────────
// TOPBAR FLOTANTE — barra superior tipo "cápsula" compartida por comprador
// y vendedor: botón de búsqueda + campo (con sugerencias en vivo debajo,
// del mismo ancho que la cápsula) + "Explorar"/"Crear producto" + accesos
// rápidos + logo de CraftHub en la esquina.
// ──────────────────────────────────────────────────────────────────────────
class TopbarFlotante extends StatefulWidget {
  final TextEditingController controladorBusqueda;
  final ValueChanged<String>? alBuscar;

  /// Id del usuario actual (comprador o vendedor); se usa para abrir el
  /// detalle de un producto sugerido igual que en la pantalla de inicio.
  final String userId;

  final List<ItemExplorar> itemsExplorar;
  final bool mostrarExplorar;

  /// Si se provee, reemplaza el botón "Explorar" por uno de "Crear producto"
  /// (solo vendedor).
  final VoidCallback? alCrearProducto;

  final VoidCallback? alPresionarEventos;
  final VoidCallback? alPresionarNotificaciones;
  final bool tieneNotificaciones;
  final VoidCallback? alPresionarUbicacion;
  final VoidCallback? alPresionarLogo;

  const TopbarFlotante({
    super.key,
    required this.controladorBusqueda,
    this.alBuscar,
    this.userId = '',
    this.itemsExplorar = const [],
    this.mostrarExplorar = true,
    this.alCrearProducto,
    this.alPresionarEventos,
    this.alPresionarNotificaciones,
    this.tieneNotificaciones = true,
    this.alPresionarUbicacion,
    this.alPresionarLogo,
  });

  @override
  State<TopbarFlotante> createState() => _TopbarFlotanteState();
}

class _TopbarFlotanteState extends State<TopbarFlotante> {
  final LayerLink _link = LayerLink();
  final GlobalKey _capsulaKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  bool _buscando = false;
  List<ProductoModelo> _productosSugeridos = [];
  List<ArtesanoModelo> _artesanosSugeridos = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _cerrarSugerencias();
    super.dispose();
  }

  void _onCambioTexto(String texto) {
    widget.alBuscar?.call(texto);
    _debounce?.cancel();
    final q = texto.trim();
    if (q.length < 2) {
      _cerrarSugerencias();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _buscarSugerencias(q));
  }

  Future<void> _buscarSugerencias(String q) async {
    setState(() => _buscando = true);
    _mostrarSugerencias();
    try {
      final resultados = await Future.wait([
        ApiService.getProductos(busqueda: q),
        ApiService.getArtesanos(limite: 60),
      ]);
      if (!mounted) return;
      final ql = q.toLowerCase();
      final artesanos = (resultados[1] as List<ArtesanoModelo>).where((a) {
        return a.nombre.toLowerCase().contains(ql) ||
            a.especialidad.toLowerCase().contains(ql) ||
            a.provincia.toLowerCase().contains(ql);
      }).take(4).toList();
      setState(() {
        _productosSugeridos = (resultados[0] as List<ProductoModelo>).take(5).toList();
        _artesanosSugeridos = artesanos;
        _buscando = false;
      });
      _mostrarSugerencias();
    } catch (_) {
      if (!mounted) return;
      setState(() => _buscando = false);
    }
  }

  void _mostrarSugerencias() {
    _overlayEntry?.remove();
    final capsulaBox = _capsulaKey.currentContext?.findRenderObject() as RenderBox?;
    final ancho = capsulaBox?.size.width ?? 400.0;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Velo que oscurece el resto de la pantalla para que el panel de
          // sugerencias no se confunda con el contenido de fondo.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _cerrarSugerencias,
              child: Container(color: Colors.black.withValues(alpha: esOscuro ? 0.45 : 0.22)),
            ),
          ),
          Positioned(
            width: ancho,
            child: CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: TapRegion(
                onTapOutside: (_) => _cerrarSugerencias(),
                child: _PanelSugerencias(
                  cargando: _buscando,
                  productos: _productosSugeridos,
                  artesanos: _artesanosSugeridos,
                  esOscuro: esOscuro,
                  alSeleccionarProducto: _abrirProducto,
                  alSeleccionarArtesano: _abrirArtesano,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _cerrarSugerencias() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _abrirProducto(ProductoModelo p) {
    _cerrarSugerencias();
    widget.controladorBusqueda.clear();
    PantallaDetalleProducto.mostrar(
      context,
      productoId: p.id,
      productoPrevisualizado: p,
      userId: widget.userId,
    );
  }

  void _abrirArtesano(ArtesanoModelo a) {
    _cerrarSugerencias();
    widget.controladorBusqueda.clear();
    abrirPerfilArtesano(context, a);
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final colorPanel = CraftHubColors.panel(oscuro);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Cápsula: búsqueda + botón de acción principal ──
          Expanded(
            child: CompositedTransformTarget(
              link: _link,
              child: SizedBox(
                key: _capsulaKey,
                height: 68,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: ColoredBox(
                    color: colorPanel,
                    child: Row(
                      children: [
                        // ── Botón de búsqueda (círculo vino tinto flotando en la cápsula) ──
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: _BotonBusqueda(
                            onTap: () => _onCambioTexto(widget.controladorBusqueda.text),
                          ),
                        ),
                        // ── Campo de búsqueda ──
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: TextField(
                              controller: widget.controladorBusqueda,
                              onChanged: _onCambioTexto,
                              textInputAction: TextInputAction.search,
                              style: GoogleFonts.poppins(
                                  fontSize: 13.5, color: CraftHubColors.textoPrincipal(oscuro)),
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: tr(context, 'topbar.buscar_hint'),
                                hintStyle: GoogleFonts.poppins(
                                    fontSize: 13.5, color: CraftHubColors.textoSecundario(oscuro)),
                              ),
                            ),
                          ),
                        ),
                        // ── Botón de acción: Crear producto (vendedor) o Explorar ──
                        if (widget.alCrearProducto != null)
                          _BotonCrearProducto(oscuro: oscuro, onTap: widget.alCrearProducto!)
                        else if (widget.mostrarExplorar)
                          _BotonExplorar(oscuro: oscuro, items: widget.itemsExplorar),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ── Accesos rápidos (fuera de la cápsula, cada uno con su propio círculo) ──
          _IconTopbarFlotante(
            icono: Icons.calendar_month_outlined,
            tooltip: tr(context, 'topbar.eventos'),
            onTap: widget.alPresionarEventos ?? () {},
          ),
          _IconTopbarFlotante(
            icono: Icons.notifications_none_rounded,
            tooltip: tr(context, 'topbar.notificaciones'),
            tieneNotif: widget.tieneNotificaciones,
            onTap: widget.alPresionarNotificaciones ?? () {},
          ),
          if (widget.alPresionarUbicacion != null)
            _IconTopbarFlotante(
              icono: Icons.location_on_outlined,
              tooltip: tr(context, 'topbar.mapa_artesanos'),
              onTap: widget.alPresionarUbicacion!,
            ),
          _IconTopbarFlotante(
            icono: oscuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            tooltip: tr(context, 'topbar.cambiar_tema'),
            onTap: () => context.read<GestorTema>().alternarTema(),
          ),
          const SizedBox(width: 6),
          // ── Logo CraftHub ──
          _LogoTopbar(onTap: widget.alPresionarLogo),
        ],
      ),
    );
  }
}

// ── PANEL DE SUGERENCIAS (aparece debajo de la cápsula, mismo ancho) ─────
class _PanelSugerencias extends StatelessWidget {
  final bool cargando;
  final List<ProductoModelo> productos;
  final List<ArtesanoModelo> artesanos;
  final bool esOscuro;
  final ValueChanged<ProductoModelo> alSeleccionarProducto;
  final ValueChanged<ArtesanoModelo> alSeleccionarArtesano;

  const _PanelSugerencias({
    required this.cargando,
    required this.productos,
    required this.artesanos,
    required this.esOscuro,
    required this.alSeleccionarProducto,
    required this.alSeleccionarArtesano,
  });

  @override
  Widget build(BuildContext context) {
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);
    final sinResultados = !cargando && productos.isEmpty && artesanos.isEmpty;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 380),
        decoration: BoxDecoration(
          color: CraftHubColors.panel(esOscuro),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: CraftHubColors.borde(esOscuro)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: esOscuro ? 0.4 : 0.14), blurRadius: 22, offset: const Offset(0, 10)),
          ],
        ),
        child: cargando
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto, strokeWidth: 2.4)),
              )
            : sinResultados
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(tr(context, 'topbar.sin_resultados'),
                        style: GoogleFonts.poppins(fontSize: 13, color: colorSec)),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    children: [
                      if (artesanos.isNotEmpty) ...[
                        _EtiquetaSeccion(texto: tr(context, 'topbar.artesanos'), esOscuro: esOscuro),
                        ...artesanos.map((a) => _FilaSugerencia(
                              imagenUrl: a.fotoUrl,
                              icono: Icons.storefront_outlined,
                              titulo: a.nombre,
                              subtitulo: '${a.especialidad} · ${a.provincia}',
                              colorTexto: colorTexto,
                              colorSec: colorSec,
                              onTap: () => alSeleccionarArtesano(a),
                            )),
                      ],
                      if (productos.isNotEmpty) ...[
                        _EtiquetaSeccion(texto: tr(context, 'topbar.productos'), esOscuro: esOscuro),
                        ...productos.map((p) => _FilaSugerencia(
                              imagenUrl: p.imagenUrl,
                              icono: Icons.shopping_bag_outlined,
                              titulo: p.nombre,
                              subtitulo: '\$${p.precio.toStringAsFixed(2)} · ${p.artesano}',
                              colorTexto: colorTexto,
                              colorSec: colorSec,
                              onTap: () => alSeleccionarProducto(p),
                            )),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _EtiquetaSeccion extends StatelessWidget {
  final String texto;
  final bool esOscuro;
  const _EtiquetaSeccion({required this.texto, required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        texto.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: CraftHubColors.vinoTinto,
        ),
      ),
    );
  }
}

class _FilaSugerencia extends StatefulWidget {
  final String imagenUrl;
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color colorTexto;
  final Color colorSec;
  final VoidCallback onTap;

  const _FilaSugerencia({
    required this.imagenUrl,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.colorTexto,
    required this.colorSec,
    required this.onTap,
  });

  @override
  State<_FilaSugerencia> createState() => _FilaSugerenciaState();
}

class _FilaSugerenciaState extends State<_FilaSugerencia> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          color: _hover ? CraftHubColors.vinoTintoSuave.withValues(alpha: 0.5) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: widget.imagenUrl.isNotEmpty
                    ? Image.network(widget.imagenUrl, width: 38, height: 38, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _respaldo())
                    : _respaldo(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.titulo, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: widget.colorTexto)),
                    Text(widget.subtitulo, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 11.5, color: widget.colorSec)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _respaldo() => Container(
        width: 38,
        height: 38,
        color: CraftHubColors.vinoTintoSuave,
        alignment: Alignment.center,
        child: Icon(widget.icono, size: 17, color: CraftHubColors.vinoTinto),
      );
}

// ── BOTÓN DE BÚSQUEDA (círculo vino tinto) ───────────────────────────────
class _BotonBusqueda extends StatefulWidget {
  final VoidCallback onTap;
  const _BotonBusqueda({required this.onTap});

  @override
  State<_BotonBusqueda> createState() => _BotonBusquedaState();
}

class _BotonBusquedaState extends State<_BotonBusqueda> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hover ? CraftHubColors.vinoTintoOscuro : CraftHubColors.vinoTinto,
            boxShadow: [
              BoxShadow(
                  color: CraftHubColors.vinoTinto.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ── BOTÓN "EXPLORAR" (menú desplegable de secciones) ─────────────────────
class _BotonExplorar extends StatelessWidget {
  final bool oscuro;
  final List<ItemExplorar> items;
  const _BotonExplorar({required this.oscuro, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<int>(
      tooltip: tr(context, 'topbar.explorar_secciones'),
      offset: const Offset(0, 46),
      color: CraftHubColors.panel(oscuro),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (i) => items[i].onTap(),
      itemBuilder: (_) => List.generate(items.length, (i) {
        final item = items[i];
        return PopupMenuItem<int>(
          value: i,
          child: Row(children: [
            Icon(item.icono, size: 17, color: CraftHubColors.vinoTinto),
            const SizedBox(width: 10),
            Text(item.etiqueta,
                style: GoogleFonts.poppins(fontSize: 13, color: CraftHubColors.textoPrincipal(oscuro))),
          ]),
        );
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: oscuro ? CraftHubColors.panelOscuro2 : CraftHubColors.vinoTintoSuave,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.grid_view_rounded, size: 16, color: CraftHubColors.vinoTinto),
            const SizedBox(width: 8),
            Text(tr(context, 'topbar.explorar'),
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: CraftHubColors.vinoTinto)),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: CraftHubColors.vinoTinto),
          ],
        ),
      ),
    );
  }
}

// ── BOTÓN "CREAR PRODUCTO" (vendedor) ─────────────────────────────────────
class _BotonCrearProducto extends StatefulWidget {
  final bool oscuro;
  final VoidCallback onTap;
  const _BotonCrearProducto({required this.oscuro, required this.onTap});

  @override
  State<_BotonCrearProducto> createState() => _BotonCrearProductoState();
}

class _BotonCrearProductoState extends State<_BotonCrearProducto> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hover ? CraftHubColors.vinoTintoOscuro : CraftHubColors.vinoTinto,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                  color: CraftHubColors.vinoTinto.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(tr(context, 'topbar.crear_producto'),
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── ÍCONO CIRCULAR DE ACCESO RÁPIDO ──────────────────────────────────────
class _IconTopbarFlotante extends StatefulWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;
  final bool tieneNotif;

  const _IconTopbarFlotante({
    required this.icono,
    required this.tooltip,
    required this.onTap,
    this.tieneNotif = false,
  });

  @override
  State<_IconTopbarFlotante> createState() => _IconTopbarFlotanteState();
}

class _IconTopbarFlotanteState extends State<_IconTopbarFlotante> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hover
                  ? (oscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05))
                  : (oscuro ? CraftHubColors.panelOscuro2 : CraftHubColors.fondoClaro),
              border: Border.all(color: CraftHubColors.borde(oscuro), width: 0.8),
            ),
            child: Stack(alignment: Alignment.center, children: [
              Icon(widget.icono, size: 19, color: CraftHubColors.textoPrincipal(oscuro)),
              if (widget.tieneNotif)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CraftHubColors.vinoTinto,
                      border: Border.all(
                          color: oscuro ? CraftHubColors.panelOscuro2 : CraftHubColors.fondoClaro, width: 1.5),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── LOGO CRAFTHUB (esquina) ──────────────────────────────────────────────
class _LogoTopbar extends StatefulWidget {
  final VoidCallback? onTap;
  const _LogoTopbar({this.onTap});

  @override
  State<_LogoTopbar> createState() => _LogoTopbarState();
}

class _LogoTopbarState extends State<_LogoTopbar> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: 'CraftHub',
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            scale: _hover ? 1.05 : 1.0,
            child: Image.asset(
              CraftHubColors.logoPath(oscuro),
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
