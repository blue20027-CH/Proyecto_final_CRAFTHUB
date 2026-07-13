import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';
import '../../models/carrito_model.dart';

class DialogoFacturaCompleta extends StatelessWidget {
  final CarritoModel carrito;
  const DialogoFacturaCompleta({super.key, required this.carrito});

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);
    final fecha = carrito.fechaCreacion;
    final fechaTexto = '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

    return Dialog(
      backgroundColor: CraftHubColors.panel(esOscuro),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: const BoxDecoration(
                color: CraftHubColors.vinoTinto,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr(context, 'compartido.factura_titulo'),
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 16,
                                fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('${tr(context, 'compartido.factura_carrito')}: ${carrito.nombre} · $fechaTexto',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (carrito.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(tr(context, 'compartido.factura_sin_productos'),
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: colorSec)),
                        ),
                      )
                    else
                      ...carrito.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.nombreProducto,
                                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5,
                                              fontWeight: FontWeight.w600, color: colorTexto)),
                                      if (item.artesanoNombre.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(item.artesanoNombre,
                                            style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: colorSec)),
                                      ],
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.cantidad} × \$${item.precioUnitario.toStringAsFixed(2)}',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: colorSec),
                                      ),
                                    ],
                                  ),
                                ),
                                Text('\$${item.subtotalItem.toStringAsFixed(2)}',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5,
                                        fontWeight: FontWeight.w700, color: colorTexto)),
                              ],
                            ),
                          )),
                    const SizedBox(height: 6),
                    Divider(color: CraftHubColors.borde(esOscuro)),
                    const SizedBox(height: 10),
                    _FilaFactura(etiqueta: tr(context, 'compartido.subtotal'),
                        valor: '\$${carrito.subtotal.toStringAsFixed(2)}', colorTexto: colorTexto, colorSec: colorSec),
                    const SizedBox(height: 8),
                    _FilaFactura(
                      etiqueta: tr(context, 'compartido.envio_label'),
                      valor: carrito.envio == 0
                          ? tr(context, 'compartido.gratis')
                          : '\$${carrito.envio.toStringAsFixed(2)}',
                      colorTexto: colorTexto,
                      colorSec: colorSec,
                    ),
                    const SizedBox(height: 8),
                    _FilaFactura(etiqueta: tr(context, 'compartido.impuestos_label'),
                        valor: '\$${carrito.impuestos.toStringAsFixed(2)}', colorTexto: colorTexto, colorSec: colorSec),
                    const SizedBox(height: 12),
                    Divider(color: CraftHubColors.borde(esOscuro)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tr(context, 'compartido.total_label'),
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 15,
                                fontWeight: FontWeight.w700, color: colorTexto)),
                        Text('\$${carrito.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 20,
                                fontWeight: FontWeight.w800, color: CraftHubColors.vinoTinto)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaFactura extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color colorTexto;
  final Color colorSec;
  const _FilaFactura({required this.etiqueta, required this.valor, required this.colorTexto, required this.colorSec});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiqueta, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: colorSec)),
        Text(valor, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: colorTexto)),
      ],
    );
  }
}
