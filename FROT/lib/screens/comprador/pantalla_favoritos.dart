import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/favoritos_provider.dart';
import '../../widgets/comprador/tarjeta_producto.dart';
import '../../widgets/eventos/modal_detalle_evento.dart';
import '../../widgets/eventos/tarjeta_evento_proximo.dart';
import 'pantalla_detalle_producto.dart';
import '../../core/i18n/i18n.dart';

// Pantalla "Mis favoritos": lee directamente del FavoritosProvider global,
// así que cualquier corazón que se toque en el resto de la app (tarjetas de
// producto, detalle de producto, detalle de evento) se refleja aquí al
// instante, sin salir y volver a entrar a esta pantalla.
class PantallaFavoritos extends StatelessWidget {
  final String userId;

  const PantallaFavoritos({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = CraftHubColors.fondo(oscuro);
    final provider = context.watch<FavoritosProvider>();
    final estaLogueado = provider.estaLogueado;
    final total = provider.productos.length + provider.eventos.length;

    return Container(
      color: colorFondo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Row(children: [
              Text(tr(context, 'comprador_secundario.mis_favoritos'),
                style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: CraftHubColors.textoPrincipal(oscuro))),
              const SizedBox(width: 8),
              const Icon(Icons.favorite, color: CraftHubColors.vinoTinto, size: 22),
              const Spacer(),
              if (estaLogueado)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CraftHubColors.panel(oscuro),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CraftHubColors.borde(oscuro)),
                  ),
                  child: Text('$total ${tr(context, 'comprador_secundario.guardados')}',
                    style: GoogleFonts.poppins(fontSize: 12,
                      color: CraftHubColors.textoSecundario(oscuro))),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              estaLogueado
                ? tr(context, 'comprador_secundario.productos_eventos_guardados_favoritos')
                : tr(context, 'comprador_secundario.inicia_sesion_guardar_favoritos'),
              style: GoogleFonts.poppins(fontSize: 13,
                color: CraftHubColors.textoSecundario(oscuro))),
          ),
          const SizedBox(height: 18),

          // ── Contenido ────────────────────────────────────────────
          Expanded(
            child: !estaLogueado
                ? _EstadoNoLogueado(oscuro: oscuro)
                : provider.cargando
                    ? const Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto))
                    : total == 0
                        ? _EstadoVacio(oscuro: oscuro)
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (provider.productos.isNotEmpty) ...[
                                  _EncabezadoSeccion(
                                    icono: Icons.shopping_bag_outlined,
                                    titulo: tr(context, 'comprador_secundario.productos_favoritos'),
                                    total: provider.productos.length,
                                    oscuro: oscuro,
                                  ),
                                  const SizedBox(height: 12),
                                  MasonryGridView.count(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    itemCount: provider.productos.length,
                                    itemBuilder: (_, i) {
                                      final alturas = [280.0, 220.0, 310.0, 250.0, 290.0, 240.0];
                                      final producto = provider.productos[i];
                                      return TarjetaProducto(
                                        producto: producto,
                                        altura: alturas[i % alturas.length],
                                        alPresionar: () {
                                          PantallaDetalleProducto.mostrar(
                                            context,
                                            productoId: producto.id,
                                            productoPrevisualizado: producto,
                                            userId: userId,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                ],
                                if (provider.eventos.isNotEmpty) ...[
                                  _EncabezadoSeccion(
                                    icono: Icons.event_outlined,
                                    titulo: tr(context, 'comprador_secundario.eventos_favoritos'),
                                    total: provider.eventos.length,
                                    oscuro: oscuro,
                                  ),
                                  const SizedBox(height: 12),
                                  for (final evento in provider.eventos) ...[
                                    TarjetaEventoProximo(
                                      evento: evento,
                                      textoBotonPrimario: tr(context, 'comprador_secundario.quitar_de_favoritos'),
                                      iconoBotonPrimario: Icons.favorite,
                                      alVerDetalles: () => mostrarDetalleEvento(
                                        context,
                                        evento: evento,
                                        esVendedor: false,
                                        usuarioId: userId,
                                      ),
                                      alPresionarPrimario: () =>
                                          context.read<FavoritosProvider>().alternarEvento(evento),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _EncabezadoSeccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final int total;
  final bool oscuro;

  const _EncabezadoSeccion({
    required this.icono,
    required this.titulo,
    required this.total,
    required this.oscuro,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icono, size: 18, color: CraftHubColors.vinoTinto),
      const SizedBox(width: 8),
      Text(titulo,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700,
              color: CraftHubColors.textoPrincipal(oscuro))),
      const SizedBox(width: 8),
      Text('($total)',
          style: GoogleFonts.poppins(fontSize: 13,
              color: CraftHubColors.textoSecundario(oscuro))),
    ]);
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
          Text(tr(context, 'comprador_secundario.no_tienes_favoritos_aun'),
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600,
              color: CraftHubColors.textoPrincipal(oscuro))),
          const SizedBox(height: 8),
          Text(tr(context, 'comprador_secundario.explora_catalogo_calendario'),
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
          Text(tr(context, 'comprador_secundario.inicia_sesion_ver_favoritos'),
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600,
              color: CraftHubColors.textoPrincipal(oscuro))),
          const SizedBox(height: 8),
          Text(tr(context, 'comprador_secundario.guarda_productos_eventos_favoritos'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13,
              color: CraftHubColors.textoSecundario(oscuro))),
        ],
      ),
    );
  }
}
