import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class VendedorTopbar extends StatelessWidget {
  final VoidCallback? onVerNotificaciones;
  final VoidCallback? onVerMensajes;
  final VoidCallback? onVerPerfil;
  final int cantidadNotif;
  final int cantidadMensajes;

  const VendedorTopbar({
    super.key,
    this.onVerNotificaciones,
    this.onVerMensajes,
    this.onVerPerfil,
    this.cantidadNotif = 0,
    this.cantidadMensajes = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: CraftHubColors.panelClaro,
        border: Border(
          bottom: BorderSide(color: CraftHubColors.bordeClaro, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Buscador ──────────────────────────────────────────────
          SizedBox(
            width: 480,
            child: TextField(
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: CraftHubColors.textoClaro,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar productos, pedidos, clientes...',
                hintStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: CraftHubColors.textoSecClaro,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: CraftHubColors.textoSecClaro,
                ),
                filled: true,
                fillColor: CraftHubColors.fondoClaro,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    color: CraftHubColors.bordeClaro,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    color: CraftHubColors.bordeClaro,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    color: CraftHubColors.vinoTinto,
                    width: 1.3,
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // ── Íconos derecha ────────────────────────────────────────

          // Mensajes con badge
          _IconTopBar(
            icono: Icons.chat_bubble_outline_rounded,
            tooltip: 'Mensajes',
            badge: cantidadMensajes,
            // 🔌 GET /api/vendedor/mensajes/sin-leer
            onTap: onVerMensajes ?? () {},
          ),

          const SizedBox(width: 4),

          // Notificaciones con badge
          _IconTopBar(
            icono: Icons.notifications_none_rounded,
            tooltip: 'Notificaciones',
            badge: cantidadNotif,
            // 🔌 GET /api/vendedor/notificaciones
            onTap: onVerNotificaciones ?? () {},
          ),

          const SizedBox(width: 4),

          // Tienda (acceso rápido)
          _IconTopBar(
            icono: Icons.storefront_outlined,
            tooltip: 'Ver mi tienda',
            onTap: () {
              // TODO: navegar a vista previa de tienda
            },
          ),

          const SizedBox(width: 12),

          // Divider vertical
          Container(width: 1, height: 28, color: CraftHubColors.bordeClaro),

          const SizedBox(width: 12),

          // Avatar + nombre (perfil rápido)
          _PerfilRapido(onTap: onVerPerfil ?? () {}),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ÍCONO CON BADGE OPCIONAL
// ─────────────────────────────────────────────────────────────
class _IconTopBar extends StatefulWidget {
  final IconData icono;
  final String tooltip;
  final int badge;
  final VoidCallback onTap;

  const _IconTopBar({
    required this.icono,
    required this.tooltip,
    required this.onTap,
    this.badge = 0,
  });

  @override
  State<_IconTopBar> createState() => _IconTopBarState();
}

class _IconTopBarState extends State<_IconTopBar> {
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _hover
                  ? CraftHubColors.vinoTintoSuave
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  widget.icono,
                  size: 20,
                  color: _hover
                      ? CraftHubColors.vinoTinto
                      : CraftHubColors.textoSecClaro,
                ),
                if (widget.badge > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: CraftHubColors.vinoTinto,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          widget.badge > 9 ? '9+' : '${widget.badge}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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

// ─────────────────────────────────────────────────────────────
// PERFIL RÁPIDO (avatar + nombre)
// ─────────────────────────────────────────────────────────────
class _PerfilRapido extends StatefulWidget {
  final VoidCallback onTap;
  const _PerfilRapido({required this.onTap});

  @override
  State<_PerfilRapido> createState() => _PerfilRapidoState();
}

class _PerfilRapidoState extends State<_PerfilRapido> {
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
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hover ? CraftHubColors.vinoTintoSuave : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Avatar
              ClipOval(
                child: Image.network(
                  'https://i.pravatar.cc/150?img=25', // 🔌 vendedor.fotoUrl
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 30,
                    height: 30,
                    color: CraftHubColors.bordeClaro,
                    child: const Icon(
                      Icons.person,
                      size: 16,
                      color: CraftHubColors.textoSecClaro,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Nombre + rol
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'María González', // 🔌 vendedor.nombre
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CraftHubColors.textoClaro,
                    ),
                  ),
                  const Text(
                    'Vendedora', // 🔌 vendedor.rol
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: CraftHubColors.textoSecClaro,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: CraftHubColors.textoSecClaro,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
