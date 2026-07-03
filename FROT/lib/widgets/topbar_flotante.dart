import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../main.dart';

// Un ítem del menú desplegable "Explorar" (secciones de la app).
class ItemExplorar {
  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  const ItemExplorar({required this.icono, required this.etiqueta, required this.onTap});
}

// ──────────────────────────────────────────────────────────────────────────
// TOPBAR FLOTANTE — barra superior tipo "cápsula" compartida por comprador
// y vendedor: botón de búsqueda + campo + "Explorar" + accesos rápidos +
// logo de CraftHub en la esquina.
// ──────────────────────────────────────────────────────────────────────────
class TopbarFlotante extends StatelessWidget {
  final TextEditingController controladorBusqueda;
  final ValueChanged<String>? alBuscar;
  final List<ItemExplorar> itemsExplorar;
  final VoidCallback? alPresionarMensajes;
  final VoidCallback? alPresionarEventos;
  final VoidCallback? alPresionarNotificaciones;
  final bool tieneNotificaciones;
  final VoidCallback? alPresionarUbicacion;
  final VoidCallback? alPresionarLogo;

  const TopbarFlotante({
    super.key,
    required this.controladorBusqueda,
    this.alBuscar,
    this.itemsExplorar = const [],
    this.alPresionarMensajes,
    this.alPresionarEventos,
    this.alPresionarNotificaciones,
    this.tieneNotificaciones = true,
    this.alPresionarUbicacion,
    this.alPresionarLogo,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final colorPanel = CraftHubColors.panel(oscuro);
    final colorBorde = CraftHubColors.borde(oscuro);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: SizedBox(
        height: 64,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: ColoredBox(
                  color: colorPanel,
                  child: Row(
                    children: [
                      // ── Botón de búsqueda (círculo vino tinto flotando en la cápsula) ──
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: _BotonBusqueda(
                          onTap: () => alBuscar?.call(controladorBusqueda.text),
                        ),
                      ),
                      // ── Campo de búsqueda ──
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: TextField(
                            controller: controladorBusqueda,
                            onChanged: alBuscar,
                            style: GoogleFonts.poppins(
                                fontSize: 13.5, color: CraftHubColors.textoPrincipal(oscuro)),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: 'Buscar productos, artesanos, provincias...',
                              hintStyle: GoogleFonts.poppins(
                                  fontSize: 13.5, color: CraftHubColors.textoSecundario(oscuro)),
                            ),
                          ),
                        ),
                      ),
                      // ── Explorar ──
                      _BotonExplorar(oscuro: oscuro, items: itemsExplorar),
                      const SizedBox(width: 12),
                      // ── Separador ──
                      Container(width: 1, height: 26, color: colorBorde),
                      const SizedBox(width: 4),
                      // ── Accesos rápidos ──
                      _IconTopbarFlotante(
                        icono: Icons.chat_bubble_outline_rounded,
                        tooltip: 'Mensajes',
                        onTap: alPresionarMensajes ?? () {},
                      ),
                      _IconTopbarFlotante(
                        icono: Icons.calendar_month_outlined,
                        tooltip: 'Eventos',
                        onTap: alPresionarEventos ?? () {},
                      ),
                      _IconTopbarFlotante(
                        icono: Icons.notifications_none_rounded,
                        tooltip: 'Notificaciones',
                        tieneNotif: tieneNotificaciones,
                        onTap: alPresionarNotificaciones ?? () {},
                      ),
                      _IconTopbarFlotante(
                        icono: Icons.location_on_outlined,
                        tooltip: 'Mapa de artesanos',
                        onTap: alPresionarUbicacion ?? () {},
                      ),
                      _IconTopbarFlotante(
                        icono: oscuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        tooltip: 'Cambiar tema',
                        onTap: () => context.read<GestorTema>().alternarTema(),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // ── Logo CraftHub ──
            _LogoTopbar(onTap: alPresionarLogo),
          ],
        ),
      ),
    );
  }
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
      tooltip: 'Explorar secciones',
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
            Text('Explorar',
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
              'assets/images/logo_crafthub.png',
              width: 44,
              height: 44,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
