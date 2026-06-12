import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SidebarVendedor extends StatelessWidget {
  final int indiceActivo;
  final Function(int) alSeleccionar;
  final VoidCallback alCerrarSesion;

  const SidebarVendedor({
    super.key,
    required this.indiceActivo,
    required this.alSeleccionar,
    required this.alCerrarSesion,
  });

  static const double _ancho = 68.0;

  static const _items = [
    {'icono': Icons.dashboard_outlined,    'label': 'Dashboard'},
    {'icono': Icons.inventory_2_outlined,  'label': 'Productos'},
    {'icono': Icons.receipt_long_outlined, 'label': 'Pedidos'},
    {'icono': Icons.people_outline,        'label': 'Clientes'},
    {'icono': Icons.chat_bubble_outline,   'label': 'Mensajes'},
    {'icono': Icons.bar_chart_rounded,     'label': 'Reportes'},
    {'icono': Icons.settings_outlined,     'label': 'Configuración'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _ancho,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF821515), Color(0xFF5E0F0F)],
        ),
      ),
      child: Column(
        children: [
          _buildAvatar(),

          Divider(
            color: Colors.white.withOpacity(0.12),
            indent: 10,
            endIndent: 10,
            height: 1,
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _items.length,
              itemBuilder: (_, i) => _ItemNav(
                icono:  _items[i]['icono'] as IconData,
                label:  _items[i]['label'] as String,
                activo: indiceActivo == i,
                onTap:  () => alSeleccionar(i),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Icon(Icons.diamond_outlined,
                size: 18, color: Colors.white.withOpacity(0.4)),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
            child: _ItemNav(
              icono:    Icons.logout_rounded,
              label:    'Cerrar sesión',
              activo:   false,
              // 🔌 POST /api/auth/logout → limpiar token
              onTap:    alCerrarSesion,
              esLogout: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    // 🔌 GET /api/vendedor/perfil → fotoUrl, nombre
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Tooltip(
        message: 'María González', // 🔌 vendedor.nombre
        preferBelow: false,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(7),
        ),
        textStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
        child: ClipOval(
          child: Image.network(
            'https://i.pravatar.cc/150?img=25', // 🔌 vendedor.fotoUrl
            width: 40, height: 40, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 40, height: 40, color: Colors.white24,
              child: const Icon(Icons.person, size: 22, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ítem de navegación (solo icono + tooltip) ─────────────────────────────

class _ItemNav extends StatefulWidget {
  final IconData icono;
  final String label;
  final bool activo;
  final VoidCallback onTap;
  final bool esLogout;

  const _ItemNav({
    required this.icono,
    required this.label,
    required this.activo,
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
      message: widget.label,
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
            padding: const EdgeInsets.symmetric(vertical: 10),
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
            child: Center(
              child: Icon(
                widget.icono,
                size: 19,
                color: resaltado ? Colors.white : Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}