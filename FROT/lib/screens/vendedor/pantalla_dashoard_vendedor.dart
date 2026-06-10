import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
// COLORES / TEMA
// ═══════════════════════════════════════════════════════════════
class _C {
  static const vino        = Color(0xFF821515);
  static const vinoOscuro  = Color(0xFF5E0F0F);
  static const vinoSuave   = Color(0xFFF9F0F0);
  static const fondo       = Color(0xFFF5F0EB);
  static const panel       = Color(0xFFFFFFFF);
  static const borde       = Color(0xFFEDE8E2);
  static const texto       = Color(0xFF1A1A1A);
  static const textoSec    = Color(0xFF7A6E66);
  static const dorado      = Color(0xFFD4A843);
}

// ═══════════════════════════════════════════════════════════════
// PUNTO DE ENTRADA  —  pantalla raíz
// ═══════════════════════════════════════════════════════════════
class PantallaPrincipalComprador extends StatefulWidget {
  const PantallaPrincipalComprador({super.key});

  @override
  State<PantallaPrincipalComprador> createState() =>
      _PantallaPrincipalCompradorState();
}

class _PantallaPrincipalCompradorState
    extends State<PantallaPrincipalComprador> {
  int _indiceActivo = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.fondo,
      body: Row(
        children: [
          // ── Sidebar ───────────────────────────────────────────
          SidebarComprador(
            indiceActivo: _indiceActivo,
            alSeleccionar: (i) => setState(() => _indiceActivo = i),
            alCerrarSesion: () {
              // TODO: POST /api/auth/logout
            },
          ),

          // ── Área de contenido ─────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Topbar
                Container(
                  height: 72,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: _C.panel,
                    border: Border(
                        bottom: BorderSide(color: _C.borde, width: 1.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const CompradorTopbar(colorVino: _C.vino),
                ),

                // Cuerpo principal
                Expanded(
                  child: _CuerpoInicio(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOPBAR
// ═══════════════════════════════════════════════════════════════
class CompradorTopbar extends StatelessWidget {
  final Color colorVino;
  final VoidCallback? onIrAMapa;

  const CompradorTopbar({super.key, required this.colorVino, this.onIrAMapa});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Buscador
        SizedBox(
          width: 480,
          height: 44,
          child: TextField(
            style: GoogleFonts.poppins(fontSize: 13, color: _C.texto),
            decoration: InputDecoration(
              hintText: 'Buscar productos, artesanos...',
              hintStyle:
                  GoogleFonts.poppins(fontSize: 13, color: _C.textoSec),
              prefixIcon:
                  const Icon(Icons.search_rounded, size: 18, color: _C.textoSec),
              filled: true,
              fillColor: _C.fondo,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.borde)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.borde, width: 1.2)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.vino, width: 1.4)),
            ),
          ),
        ),

        const Spacer(),

        // Acciones
        _TopbarAction(
          icono: Icons.chat_bubble_outline_rounded,
          badge: 3,
          tooltip: 'Mensajes',
          onTap: () {},
        ),
        const SizedBox(width: 4),
        _TopbarAction(
          icono: Icons.calendar_month_outlined,
          tooltip: 'Reservas',
          onTap: () {},
        ),
        const SizedBox(width: 4),
        _TopbarAction(
          icono: Icons.map_outlined,
          tooltip: 'Mapa artesanos',
          onTap: onIrAMapa ?? () {},
        ),
        const SizedBox(width: 4),
        _TopbarAction(
          icono: Icons.favorite_rounded,
          tooltip: 'Favoritos',
          color: colorVino,
          onTap: () {},
        ),
        const SizedBox(width: 12),

        // Carrito
        _BotonCarrito(cantidad: 2),
      ],
    );
  }
}

class _TopbarAction extends StatefulWidget {
  final IconData icono;
  final int? badge;
  final String tooltip;
  final Color? color;
  final VoidCallback onTap;

  const _TopbarAction({
    required this.icono,
    required this.tooltip,
    required this.onTap,
    this.badge,
    this.color,
  });

  @override
  State<_TopbarAction> createState() => _TopbarActionState();
}

class _TopbarActionState extends State<_TopbarAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hover ? _C.vinoSuave : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(widget.icono,
                    size: 20, color: widget.color ?? _C.textoSec),
                if (widget.badge != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                          color: _C.vino, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '${widget.badge}',
                          style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotonCarrito extends StatefulWidget {
  final int cantidad;
  const _BotonCarrito({required this.cantidad});

  @override
  State<_BotonCarrito> createState() => _BotonCarritoState();
}

class _BotonCarritoState extends State<_BotonCarrito> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hover
                  ? [const Color(0xFF9E1A1A), _C.vino]
                  : [_C.vino, _C.vinoOscuro],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _C.vino.withOpacity(_hover ? 0.35 : 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(children: [
            const Icon(Icons.shopping_bag_outlined,
                size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Carrito',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(5)),
              child: Center(
                child: Text(
                  '${widget.cantidad}',
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SIDEBAR COMPRADOR
// ═══════════════════════════════════════════════════════════════
class SidebarComprador extends StatefulWidget {
  final int indiceActivo;
  final Function(int) alSeleccionar;
  final VoidCallback alCerrarSesion;

  const SidebarComprador({
    super.key,
    required this.indiceActivo,
    required this.alSeleccionar,
    required this.alCerrarSesion,
  });

  @override
  State<SidebarComprador> createState() => _SidebarCompradorState();
}

class _SidebarCompradorState extends State<SidebarComprador>
    with SingleTickerProviderStateMixin {
  static const double _anchoExpandido = 220.0;
  static const double _anchoColapsado = 68.0;

  bool _colapsado = false;
  late AnimationController _ctrl;
  late Animation<double> _animAncho;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _animAncho = Tween<double>(
            begin: _anchoExpandido, end: _anchoColapsado)
        .animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _alternarColapso() {
    setState(() => _colapsado = !_colapsado);
    _colapsado ? _ctrl.forward() : _ctrl.reverse();
  }

  static const _items = [
    {'icono': Icons.home_outlined, 'label': 'Inicio'},
    {'icono': Icons.shopping_cart_outlined, 'label': 'Mi carrito'},
    {'icono': Icons.people_outline, 'label': 'Artesanos'},
    {'icono': Icons.favorite_outline, 'label': 'Favoritos'},
    {'icono': Icons.chat_bubble_outline, 'label': 'Mensajes'},
    {'icono': Icons.history_rounded, 'label': 'Historial'},
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animAncho,
      builder: (context, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: _animAncho.value,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF821515), Color(0xFF5E0F0F)],
                ),
              ),
              child: Column(children: [
                _buildPerfil(),
                Divider(
                  color: Colors.white.withOpacity(0.12),
                  indent: _colapsado ? 10 : 18,
                  endIndent: _colapsado ? 10 : 18,
                  height: 1,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _ItemNav(
                      icono: _items[i]['icono'] as IconData,
                      label: _items[i]['label'] as String,
                      activo: widget.indiceActivo == i,
                      colapsado: _colapsado,
                      progreso: _ctrl.value,
                      onTap: () => widget.alSeleccionar(i),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: _colapsado ? 0 : 18, vertical: 12),
                  child: Row(
                    mainAxisAlignment: _colapsado
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      Icon(Icons.diamond_outlined,
                          size: 18,
                          color: Colors.white.withOpacity(0.4)),
                      if (!_colapsado) ...[
                        const SizedBox(width: 8),
                        Opacity(
                          opacity: 1 - _ctrl.value,
                          child: Text(
                            'CraftHub',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.4),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                  child: _ItemNav(
                    icono: Icons.logout_rounded,
                    label: 'Cerrar sesión',
                    activo: false,
                    colapsado: _colapsado,
                    progreso: _ctrl.value,
                    onTap: widget.alCerrarSesion,
                    esLogout: true,
                  ),
                ),
              ]),
            ),
            Positioned(
              right: -13,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.center,
                child: _BotonToggle(
                    colapsado: _colapsado, onTap: _alternarColapso),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPerfil() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          _colapsado ? 0 : 18, 28, _colapsado ? 0 : 18, 16),
      child: _colapsado
          ? Column(children: [
              ClipOval(
                child: Image.network(
                  'https://i.pravatar.cc/150?img=47',
                  width: 40, height: 40, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.white24,
                      child: const Icon(Icons.person,
                          size: 22, color: Colors.white54)),
                ),
              ),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.network(
                    'https://i.pravatar.cc/150?img=47',
                    width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.white24,
                        child: const Icon(Icons.person,
                            size: 30, color: Colors.white54)),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      color: const Color(0xFF821515),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF5E0F0F), width: 2),
                    ),
                    child: const Icon(Icons.check,
                        size: 9, color: Color(0xFF86efac)),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Opacity(
                opacity: 1 - _ctrl.value,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'María López',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.22),
                              width: 0.8),
                        ),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                      color: Color(0xFF86efac),
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Text('Compradora verificada',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color:
                                          Colors.white.withOpacity(0.9))),
                            ]),
                      ),
                    ]),
              ),
            ]),
    );
  }
}

class _ItemNav extends StatefulWidget {
  final IconData icono;
  final String label;
  final bool activo;
  final bool colapsado;
  final double progreso;
  final VoidCallback onTap;
  final bool esLogout;

  const _ItemNav({
    required this.icono,
    required this.label,
    required this.activo,
    required this.colapsado,
    required this.progreso,
    required this.onTap,
    this.esLogout = false,
  });

  @override
  State<_ItemNav> createState() => _ItemNavState();
}

class _ItemNavState extends State<_ItemNav> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final resaltado = widget.activo || _hover;
    return Tooltip(
      message: widget.colapsado ? widget.label : '',
      preferBelow: false,
      verticalOffset: 0,
      decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(7)),
      textStyle:
          GoogleFonts.poppins(fontSize: 12, color: Colors.white),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 3),
            padding: EdgeInsets.symmetric(
                horizontal: widget.colapsado ? 0 : 14, vertical: 10),
            decoration: BoxDecoration(
              color: resaltado
                  ? Colors.white
                      .withOpacity(widget.activo ? 0.18 : 0.09)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              border: widget.esLogout
                  ? Border.all(
                      color: Colors.white.withOpacity(0.14), width: 0.8)
                  : (widget.activo
                      ? Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 0.8)
                      : null),
            ),
            child: Row(
              mainAxisAlignment: widget.colapsado
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(widget.icono,
                    size: 19,
                    color: resaltado
                        ? Colors.white
                        : Colors.white.withOpacity(0.6)),
                if (!widget.colapsado)
                  Padding(
                    padding: const EdgeInsets.only(left: 13),
                    child: Opacity(
                      opacity: (1 - widget.progreso).clamp(0.0, 1.0),
                      child: Text(
                        widget.label,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: widget.activo
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: resaltado
                              ? Colors.white
                              : Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotonToggle extends StatefulWidget {
  final bool colapsado;
  final VoidCallback onTap;
  const _BotonToggle({required this.colapsado, required this.onTap});

  @override
  State<_BotonToggle> createState() => _BotonToggleState();
}

class _BotonToggleState extends State<_BotonToggle> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: _hover
                ? const Color(0xFF9E1A1A)
                : const Color(0xFF821515),
            shape: BoxShape.circle,
            border:
                Border.all(color: const Color(0xFFF9F6F0), width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 280),
            turns: widget.colapsado ? 0.5 : 0.0,
            child: const Icon(Icons.chevron_left_rounded,
                size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CUERPO / DASHBOARD COMPRADOR
// ═══════════════════════════════════════════════════════════════
class _CuerpoInicio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Saludo ─────────────────────────────────────────────
          _Saludo(),
          const SizedBox(height: 24),

          // ── Tarjetas de estadísticas ──────────────────────────
          Row(children: [
            Expanded(
              child: _TarjetaStat(
                icono: Icons.shopping_bag_outlined,
                titulo: 'Pedidos activos',
                valor: '3',
                subtitulo: '1 en camino',
                color: _C.vino,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _TarjetaStat(
                icono: Icons.favorite_rounded,
                titulo: 'Favoritos',
                valor: '24',
                subtitulo: '5 con descuento',
                color: const Color(0xFFD4686A),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _TarjetaStat(
                icono: Icons.people_outline,
                titulo: 'Artesanos seguidos',
                valor: '8',
                subtitulo: '2 publicaron hoy',
                color: const Color(0xFF5B7FA6),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _TarjetaStat(
                icono: Icons.star_outline_rounded,
                titulo: 'Reseñas escritas',
                valor: '12',
                subtitulo: 'Último hace 2 días',
                color: _C.dorado,
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Fila principal ─────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Productos recomendados
                Expanded(
                  flex: 7,
                  child: _PanelRecomendados(),
                ),
                const SizedBox(width: 16),

                // Actividad reciente
                Expanded(
                  flex: 3,
                  child: _PanelActividad(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Artesanos destacados ───────────────────────────────
          _PanelArtesanos(),
        ],
      ),
    );
  }
}

// ── Saludo ────────────────────────────────────────────────────
class _Saludo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '¡Buenos días, María! 👋',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _C.texto,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Descubre nuevas piezas artesanales hechas con amor.',
            style: GoogleFonts.poppins(
                fontSize: 13, color: _C.textoSec),
          ),
        ]),
        const Spacer(),
        // Chips de categoría rápida
        Wrap(spacing: 8, children: [
          _ChipCategoria('Bolsos', Icons.shopping_bag_outlined),
          _ChipCategoria('Joyería', Icons.diamond_outlined),
          _ChipCategoria('Hogar', Icons.home_outlined),
          _ChipCategoria('Cerámica', Icons.local_fire_department_outlined),
        ]),
      ],
    );
  }
}

class _ChipCategoria extends StatefulWidget {
  final String label;
  final IconData icono;
  const _ChipCategoria(this.label, this.icono);

  @override
  State<_ChipCategoria> createState() => _ChipCategoriaState();
}

class _ChipCategoriaState extends State<_ChipCategoria> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _hover ? _C.vinoSuave : _C.panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _hover ? _C.vino : _C.borde, width: 1.2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(widget.icono,
              size: 13,
              color: _hover ? _C.vino : _C.textoSec),
          const SizedBox(width: 5),
          Text(
            widget.label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _hover ? _C.vino : _C.textoSec,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Tarjeta estadística ───────────────────────────────────────
class _TarjetaStat extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final String subtitulo;
  final Color color;

  const _TarjetaStat({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borde),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, size: 20, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: _C.textoSec)),
                Text(valor,
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _C.texto)),
                Text(subtitulo,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: _C.textoSec)),
              ]),
        ),
      ]),
    );
  }
}

// ── Panel productos recomendados ──────────────────────────────
class _PanelRecomendados extends StatelessWidget {
  final _productos = const [
    {
      'nombre': 'Bolso tejido tradicional',
      'artesano': 'Ana García',
      'precio': '\$19.99',
      'rating': '4.9',
      'img':
          'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=200',
    },
    {
      'nombre': 'Vasija decorativa',
      'artesano': 'Carlos Ruiz',
      'precio': '\$34.00',
      'rating': '4.7',
      'img':
          'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=200',
    },
    {
      'nombre': 'Aretes de filigrana',
      'artesano': 'Sofía Torres',
      'precio': '\$15.50',
      'rating': '4.8',
      'img':
          'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=200',
    },
    {
      'nombre': 'Taza artesanal',
      'artesano': 'Pedro Mora',
      'precio': '\$12.00',
      'rating': '4.6',
      'img':
          'https://images.unsplash.com/photo-1514228742587-6b1558fcca3d?w=200',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borde),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: _C.vinoSuave,
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 16, color: _C.vino),
          ),
          const SizedBox(width: 10),
          Text('Para ti',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _C.texto)),
          const Spacer(),
          _BotonTexto(texto: 'Ver más', alPresionar: () {}),
        ]),
        const SizedBox(height: 16),
        Row(
          children: _productos
              .map((p) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _TarjetaProducto(datos: p),
                    ),
                  ))
              .toList(),
        ),
      ]),
    );
  }
}

class _TarjetaProducto extends StatefulWidget {
  final Map<String, String> datos;
  const _TarjetaProducto({required this.datos});

  @override
  State<_TarjetaProducto> createState() => _TarjetaProductoState();
}

class _TarjetaProductoState extends State<_TarjetaProducto> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _hover ? _C.fondo : _C.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _hover ? _C.vino.withOpacity(0.3) : _C.borde,
              width: 1.2),
          boxShadow: _hover
              ? [
                  BoxShadow(
                      color: _C.vino.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Imagen
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(13)),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                widget.datos['img']!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: _C.fondo,
                    child: const Icon(Icons.image_outlined,
                        color: _C.textoSec, size: 32)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.datos['nombre']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.texto)),
              const SizedBox(height: 2),
              Text(widget.datos['artesano']!,
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: _C.textoSec)),
              const SizedBox(height: 6),
              Row(children: [
                Text(widget.datos['precio']!,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.vino)),
                const Spacer(),
                const Icon(Icons.star_rounded,
                    size: 12, color: _C.dorado),
                const SizedBox(width: 2),
                Text(widget.datos['rating']!,
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _C.textoSec)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Panel actividad reciente ──────────────────────────────────
class _PanelActividad extends StatelessWidget {
  final _actividad = const [
    {
      'icono': 'pedido',
      'texto': 'Pedido #1042 enviado',
      'tiempo': 'Hace 2 h',
    },
    {
      'icono': 'favorito',
      'texto': 'Guardaste "Collar artesanal"',
      'tiempo': 'Hace 5 h',
    },
    {
      'icono': 'reseña',
      'texto': 'Dejaste una reseña de 5★',
      'tiempo': 'Ayer',
    },
    {
      'icono': 'pedido',
      'texto': 'Pedido #1038 entregado',
      'tiempo': 'Hace 3 días',
    },
    {
      'icono': 'artesano',
      'texto': 'Empezaste a seguir a Luis C.',
      'tiempo': 'Hace 4 días',
    },
  ];

  IconData _icono(String tipo) {
    return switch (tipo) {
      'pedido'   => Icons.local_shipping_outlined,
      'favorito' => Icons.favorite_outline,
      'reseña'   => Icons.star_outline_rounded,
      'artesano' => Icons.person_add_outlined,
      _          => Icons.notifications_none_rounded,
    };
  }

  Color _color(String tipo) {
    return switch (tipo) {
      'pedido'   => _C.vino,
      'favorito' => const Color(0xFFD4686A),
      'reseña'   => _C.dorado,
      'artesano' => const Color(0xFF5B7FA6),
      _          => _C.textoSec,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borde),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: _C.vinoSuave,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.timeline_rounded,
                  size: 16, color: _C.vino),
            ),
            const SizedBox(width: 10),
            Text('Actividad',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.texto)),
          ]),
          const SizedBox(height: 16),
          ..._actividad.map((a) => _FilaActividad(
                icono: _icono(a['icono']!),
                color: _color(a['icono']!),
                texto: a['texto']!,
                tiempo: a['tiempo']!,
              )),
        ],
      ),
    );
  }
}

class _FilaActividad extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String texto;
  final String tiempo;

  const _FilaActividad({
    required this.icono,
    required this.color,
    required this.texto,
    required this.tiempo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icono, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texto,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _C.texto)),
                Text(tiempo,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: _C.textoSec)),
              ]),
        ),
      ]),
    );
  }
}

// ── Panel artesanos destacados ────────────────────────────────
class _PanelArtesanos extends StatelessWidget {
  final _artesanos = const [
    {
      'nombre': 'Ana García',
      'especialidad': 'Tejidos',
      'productos': '34',
      'rating': '4.9',
      'avatar': 'https://i.pravatar.cc/150?img=5',
    },
    {
      'nombre': 'Carlos Ruiz',
      'especialidad': 'Cerámica',
      'productos': '21',
      'rating': '4.8',
      'avatar': 'https://i.pravatar.cc/150?img=12',
    },
    {
      'nombre': 'Sofía Torres',
      'especialidad': 'Joyería',
      'productos': '48',
      'rating': '4.9',
      'avatar': 'https://i.pravatar.cc/150?img=9',
    },
    {
      'nombre': 'Luis Castillo',
      'especialidad': 'Madera',
      'productos': '15',
      'rating': '4.7',
      'avatar': 'https://i.pravatar.cc/150?img=15',
    },
    {
      'nombre': 'Pedro Mora',
      'especialidad': 'Pintura',
      'productos': '29',
      'rating': '4.6',
      'avatar': 'https://i.pravatar.cc/150?img=20',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borde),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: _C.vinoSuave,
                borderRadius: BorderRadius.circular(8)),
            child:
                const Icon(Icons.people_outline, size: 16, color: _C.vino),
          ),
          const SizedBox(width: 10),
          Text('Artesanos destacados',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _C.texto)),
          const Spacer(),
          _BotonTexto(texto: 'Ver todos', alPresionar: () {}),
        ]),
        const SizedBox(height: 16),
        Row(
          children: _artesanos
              .map((a) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _TarjetaArtesano(datos: a),
                    ),
                  ))
              .toList(),
        ),
      ]),
    );
  }
}

class _TarjetaArtesano extends StatefulWidget {
  final Map<String, String> datos;
  const _TarjetaArtesano({required this.datos});

  @override
  State<_TarjetaArtesano> createState() => _TarjetaArtesanoState();
}

class _TarjetaArtesanoState extends State<_TarjetaArtesano> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hover ? _C.vinoSuave : _C.fondo,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _hover ? _C.vino.withOpacity(0.35) : _C.borde,
              width: 1.2),
        ),
        child: Column(children: [
          ClipOval(
            child: Image.network(
              widget.datos['avatar']!,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  width: 52,
                  height: 52,
                  color: _C.borde,
                  child: const Icon(Icons.person,
                      size: 28, color: _C.textoSec)),
            ),
          ),
          const SizedBox(height: 8),
          Text(widget.datos['nombre']!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _C.texto)),
          Text(widget.datos['especialidad']!,
              style:
                  GoogleFonts.poppins(fontSize: 10, color: _C.textoSec)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.star_rounded, size: 11, color: _C.dorado),
            const SizedBox(width: 2),
            Text(widget.datos['rating']!,
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _C.textoSec)),
            const SizedBox(width: 6),
            Text('·',
                style: GoogleFonts.poppins(
                    fontSize: 10, color: _C.textoSec)),
            const SizedBox(width: 6),
            Text('${widget.datos['productos']} productos',
                style: GoogleFonts.poppins(
                    fontSize: 10, color: _C.textoSec)),
          ]),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: _hover ? _C.vino : _C.panel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _hover ? _C.vino : _C.borde, width: 1),
            ),
            child: Text('Ver tienda',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _hover ? Colors.white : _C.texto)),
          ),
        ]),
      ),
    );
  }
}

// ── Botón texto reutilizable ───────────────────────────────────
class _BotonTexto extends StatefulWidget {
  final String texto;
  final VoidCallback alPresionar;
  const _BotonTexto({required this.texto, required this.alPresionar});

  @override
  State<_BotonTexto> createState() => _BotonTextoState();
}

class _BotonTextoState extends State<_BotonTexto> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _sobre ? _C.vinoSuave : _C.fondo,
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: _C.borde, width: 1),
          ),
          child: Text(widget.texto,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _C.texto)),
        ),
      ),
    );
  }
}