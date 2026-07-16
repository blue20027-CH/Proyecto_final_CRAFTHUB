import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';
import '../../models/models_chat.dart';
import '../../screens/comprador/pantalla_detalle_producto.dart';

class BurbujaMensaje extends StatelessWidget {
  final MensajeModelo mensaje;
  final String usuarioId;
  const BurbujaMensaje({super.key, required this.mensaje, required this.usuarioId});

  String _fmt(DateTime h) {
    final hh = h.hour.toString().padLeft(2, '0');
    final mm = h.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: mensaje.esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mensaje.esMio
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _buildContenido(context, isDark),
          Padding(
            padding: EdgeInsets.only(
              left: mensaje.esMio ? 0 : 8,
              right: mensaje.esMio ? 8 : 0,
              top: 3,
              bottom: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _fmt(mensaje.hora),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    color: CraftHubColors.textoSecundario(isDark),
                  ),
                ),
                if (mensaje.esMio) ...[
                  const SizedBox(width: 3),
                  Icon(
                    mensaje.leido ? Icons.done_all : Icons.done,
                    size: 13,
                    color: mensaje.leido
                        ? CraftHubColors.vinoTinto
                        : CraftHubColors.textoSecundario(isDark),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido(BuildContext context, bool isDark) {
    switch (mensaje.tipo) {
      case TipoMensaje.imagen:
        return _Imagen(url: mensaje.contenido);
      case TipoMensaje.publicacion:
        return _Publicacion(pub: mensaje.publicacion, isDark: isDark, usuarioId: usuarioId);
      default:
        return _Texto(mensaje: mensaje, isDark: isDark);
    }
  }
}

class _Texto extends StatelessWidget {
  final MensajeModelo mensaje;
  final bool isDark;
  const _Texto({required this.mensaje, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final mio = mensaje.esMio;
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.42,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mio
            ? CraftHubColors.vinoTinto
            : (isDark ? CraftHubColors.panelOscuro2 : const Color(0xFFF1EBE4)),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: mio
              ? const Radius.circular(16)
              : const Radius.circular(4),
          bottomRight: mio
              ? const Radius.circular(4)
              : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        mensaje.contenido,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: mio ? Colors.white : CraftHubColors.textoPrincipal(isDark),
          height: 1.45,
        ),
      ),
    );
  }
}

class _Imagen extends StatelessWidget {
  final String url;
  const _Imagen({required this.url});
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.32,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, p) => p == null
              ? child
              : Container(
                  height: 160,
                  color: CraftHubColors.bordeClaro,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: CraftHubColors.vinoTinto,
                      strokeWidth: 2,
                    ),
                  ),
                ),
          errorBuilder: (_, __, ___) => Container(
            height: 120,
            color: CraftHubColors.vinoTintoSuave,
            child: const Icon(
              Icons.broken_image_outlined,
              color: CraftHubColors.vinoTinto,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}

class _Publicacion extends StatelessWidget {
  final PublicacionCompartidaModelo? pub;
  final bool isDark;
  final String usuarioId;
  const _Publicacion({required this.pub, required this.isDark, required this.usuarioId});
  @override
  Widget build(BuildContext context) {
    if (pub == null) return const SizedBox.shrink();
    final precio = pub!.precio.toStringAsFixed(2);
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.35,
      ),
      decoration: BoxDecoration(
        color: isDark ? CraftHubColors.panelOscuro2 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CraftHubColors.borde(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.network(
              pub!.imagenUrl,
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(height: 130, color: CraftHubColors.vinoTintoSuave),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pub!.titulo,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CraftHubColors.textoPrincipal(isDark),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  pub!.artesano,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: CraftHubColors.textoSecundario(isDark),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$$precio',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CraftHubColors.vinoTinto,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => PantallaDetalleProducto.mostrar(
                      context,
                      productoId: pub!.id,
                      userId: usuarioId,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CraftHubColors.vinoTinto),
                      foregroundColor: CraftHubColors.vinoTinto,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      tr(context, 'compartido.ver_producto_boton'),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
