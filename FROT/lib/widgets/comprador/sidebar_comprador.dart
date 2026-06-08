import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


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
  // ── Ancho expandido / colapsado
  static const double _anchoExpandido  = 220.0;
  static const double _anchoColapsado  = 68.0;

  bool _colapsado = false;

  late AnimationController _ctrl;
  late Animation<double>   _animAncho;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _animAncho = Tween<double>(
      begin: _anchoExpandido,
      end: _anchoColapsado,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
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
    {'icono': Icons.home_outlined,          'label': 'Inicio'},
    {'icono': Icons.shopping_cart_outlined, 'label': 'Mi carrito'},
    {'icono': Icons.people_outline,         'label': 'Artesanos'},
    {'icono': Icons.favorite_outline,       'label': 'Favoritos'},
    {'icono': Icons.chat_bubble_outline,    'label': 'Mensajes'},
    {'icono': Icons.history_rounded,        'label': 'Historial'},
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animAncho,
      builder: (context, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Sidebar principal ─────────────────────────────────
            Container(
              width: _animAncho.value,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF821515), Color(0xFF5E0F0F)],
                ),
              ),
              child: Column(
                children: [
                  // Perfil
                  _buildPerfil(),

                  Divider(
                    color: Colors.white.withOpacity(0.12),
                    indent: _colapsado ? 10 : 18,
                    endIndent: _colapsado ? 10 : 18,
                    height: 1,
                  ),
                  const SizedBox(height: 10),

                  // Navegación
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _items.length,
                      itemBuilder: (_, i) => _ItemNav(
                        icono:     _items[i]['icono'] as IconData,
                        label:     _items[i]['label'] as String,
                        activo:    widget.indiceActivo == i,
                        colapsado: _colapsado,
                        progreso:  _ctrl.value, // para fade del texto
                        onTap:     () => widget.alSeleccionar(i),
                      ),
                    ),
                  ),

                  // Logo
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _colapsado ? 0 : 18,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: _colapsado
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Icon(Icons.diamond_outlined,
                            size: 18, color: Colors.white.withOpacity(0.4)),
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

                  // Cerrar sesión
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                    child: _ItemNav(
                      icono:     Icons.logout_rounded,
                      label:     'Cerrar sesión',
                      activo:    false,
                      colapsado: _colapsado,
                      progreso:  _ctrl.value,
                      // 🔌 POST /api/auth/logout → limpiar token
                      onTap:     widget.alCerrarSesion,
                      esLogout:  true,
                    ),
                  ),
                ],
              ),
            ),

            // ── Botón toggle flotante ─────────────────────────────
            Positioned(
              right: -13,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.center,
                child: _BotonToggle(
                  colapsado: _colapsado,
                  onTap: _alternarColapso,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPerfil() {
    // 🔌 GET /api/usuario/perfil → nombre, fotoUrl, verificado
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _colapsado ? 0 : 18,
        28,
        _colapsado ? 0 : 18,
        16,
      ),
      child: _colapsado
          // ── Modo colapsado: solo avatar circular pequeño ──
          ? Column(children: [
              ClipOval(
                child: Image.network(
                  'https://i.pravatar.cc/150?img=47', // 🔌 usuario.fotoUrl
                  width: 40, height: 40, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 40, height: 40, color: Colors.white24,
                    child: const Icon(Icons.person, size: 22, color: Colors.white54)),
                ),
              ),
            ])
          // ── Modo expandido: avatar + nombre + badge ──
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.network(
                    'https://i.pravatar.cc/150?img=47', // 🔌 usuario.fotoUrl
                    width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64, height: 64, color: Colors.white24,
                      child: const Icon(Icons.person, size: 30, color: Colors.white54)),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 17, height: 17,
                    decoration: BoxDecoration(
                      color: const Color(0xFF821515),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF5E0F0F), width: 2),
                    ),
                    child: const Icon(Icons.check, size: 9, color: Color(0xFF86efac)),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Opacity(
                opacity: 1 - _ctrl.value,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    'María López', // 🔌 usuario.nombre
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.22), width: 0.8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: Color(0xFF86efac), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('Compradora verificada', // 🔌 usuario.rol
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.white.withOpacity(0.9))),
                    ]),
                  ),
                ]),
              ),
            ]),
    );
  }
}

// ── Ítem de navegación con tooltip cuando está colapsado ─────────────────

class _ItemNav extends StatefulWidget {
  final IconData icono;
  final String label;
  final bool activo;
  final bool colapsado;
  final double progreso; // 0.0 = expandido, 1.0 = colapsado
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
      // Tooltip solo aparece cuando el sidebar está colapsado
      message: widget.colapsado ? widget.label : '',
      preferBelow: false,
      verticalOffset: 0,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(7),
      ),
      textStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 3),
            padding: EdgeInsets.symmetric(
              // Al colapsar los ítems se centran
              horizontal: widget.colapsado ? 0 : 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: resaltado
                  ? Colors.white.withOpacity(widget.activo ? 0.18 : 0.09)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              border: widget.esLogout
                  ? Border.all(color: Colors.white.withOpacity(0.14), width: 0.8)
                  : (widget.activo
                      ? Border.all(color: Colors.white.withOpacity(0.2), width: 0.8)
                      : null),
            ),
            child: Row(
              mainAxisAlignment: widget.colapsado
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(widget.icono,
                  size: 19,
                  color: resaltado ? Colors.white : Colors.white.withOpacity(0.6)),

                // Texto: se desvanece y desaparece al colapsar
                if (!widget.colapsado)
                  Padding(
                    padding: const EdgeInsets.only(left: 13),
                    child: Opacity(
                      opacity: (1 - widget.progreso).clamp(0.0, 1.0),
                      child: Text(
                        widget.label,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: widget.activo ? FontWeight.w600 : FontWeight.w400,
                          color: resaltado ? Colors.white : Colors.white.withOpacity(0.6),
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

// ── Botón circular flotante para colapsar / expandir ─────────────────────

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
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFF9E1A1A) : const Color(0xFF821515),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF9F6F0), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 280),
            turns: widget.colapsado ? 0.5 : 0.0, // 180° cuando colapsado
            child: const Icon(Icons.chevron_left_rounded,
                size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}