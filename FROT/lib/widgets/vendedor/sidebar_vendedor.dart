import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SidebarVendedor extends StatelessWidget {
  final String nombre;
  final String fotoUrl;
  final int indiceActivo;
  final Function(int) alSeleccionar;
  final VoidCallback alCerrarSesion;
  final bool tieneNotificacionMensajes;
  final VoidCallback? alTocarAvatar;

  const SidebarVendedor({
    super.key,
    this.nombre = 'Vendedor',
    this.fotoUrl = '',
    required this.indiceActivo,
    required this.alSeleccionar,
    required this.alCerrarSesion,
    this.tieneNotificacionMensajes = false,
    this.alTocarAvatar,
  });

  static const double _ancho = 68.0;
  static const int _indiceMensajes = 3;

  // Solo se listan las secciones que realmente existen (mismo orden que el
  // menú "Explorar" del topbar y que el switch de _obtenerPantallaActual en
  // pantalla_dashoard_vendedor.dart) — así ningún ítem lleva a un callejón
  // sin salida.
  static const _items = [
    {'icono': Icons.dashboard_outlined,      'label': 'Dashboard'},
    {'icono': Icons.inventory_2_outlined,    'label': 'Productos'},
    {'icono': Icons.video_library_outlined,  'label': 'Tutoriales'},
    {'icono': Icons.forum_outlined,          'label': 'Mensajes'},
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
            color: Colors.white.withValues(alpha: 0.12),
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
                mostrarPunto: i == _indiceMensajes && tieneNotificacionMensajes,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Icon(Icons.diamond_outlined,
                size: 18, color: Colors.white.withValues(alpha: 0.4)),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
            child: _ItemNav(
              icono:    Icons.logout_rounded,
              label:    'Cerrar sesiÃ³n',
              activo:   false,
              // ðŸ”Œ POST /api/auth/logout â†’ limpiar token
              onTap:    alCerrarSesion,
              esLogout: true,
            ),
          ),
        ],
      ),
    );
  }

  String _iniciales(String valor) {
    final partes = valor.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    final texto = partes.map((p) => p[0].toUpperCase()).join();
    return texto.isEmpty ? 'V' : texto;
  }

  Widget _buildAvatar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Tooltip(
        message: 'Editar perfil',
        preferBelow: false,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(7),
        ),
        textStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: alTocarAvatar,
            child: ClipOval(
              child: fotoUrl.isNotEmpty
                  ? Image.network(
                      fotoUrl,
                      width: 40, height: 40, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _AvatarIniciales(texto: _iniciales(nombre)),
                    )
                  : _AvatarIniciales(texto: _iniciales(nombre)),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarIniciales extends StatelessWidget {
  final String texto;

  const _AvatarIniciales({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      color: Colors.white24,
      alignment: Alignment.center,
      child: Text(
        texto,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// â”€â”€ Ãtem de navegaciÃ³n (solo icono + tooltip) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ItemNav extends StatefulWidget {
  final IconData icono;
  final String label;
  final bool activo;
  final VoidCallback onTap;
  final bool esLogout;
  final bool mostrarPunto;

  const _ItemNav({
    required this.icono,
    required this.label,
    required this.activo,
    required this.onTap,
    this.esLogout = false,
    this.mostrarPunto = false,
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
                  ? Colors.white.withValues(alpha: widget.activo ? 0.18 : 0.09)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              border: widget.esLogout
                  ? Border.all(color: Colors.white.withValues(alpha: 0.14), width: 0.8)
                  : (widget.activo
                      ? Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.8)
                      : null),
            ),
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    widget.icono,
                    size: 19,
                    color: resaltado ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  ),
                  if (widget.mostrarPunto)
                    Positioned(
                      top: -2,
                      right: -3,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE53935),
                          border: Border.all(color: const Color(0xFF821515), width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

