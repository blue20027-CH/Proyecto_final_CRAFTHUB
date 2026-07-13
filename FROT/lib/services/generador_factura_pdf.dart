// lib/services/generador_factura_pdf.dart
// Genera el PDF de un recibo de compra (factura) a partir de un pedido del
// historial (GET /api/pagos/historial/{userId}, ver pedidos_router.py) y el
// perfil del comprador. Se genera 100% en el cliente (paquete `pdf`) — no
// hay endpoint de backend para esto.
//
// Nota legal: esto es un RECIBO DE COMPRA de CraftHub, no una factura fiscal
// electrónica oficial ante la DGI de Panamá (el sistema no maneja RUC, punto
// de facturación ni CUFE). El PDF lo dice explícitamente en el pie.
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

String _texto(dynamic v, [String vacio = '']) => (v == null || v.toString().trim().isEmpty) ? vacio : v.toString();

double _numero(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0.0;
}

String _moneda(dynamic v) => '\$${_numero(v).toStringAsFixed(2)}';

/// Arma el detalle enmascarado del método de pago usado en el pedido.
/// Nunca incluye número completo de tarjeta ni CVV — esos datos jamás se
/// persisten en el backend (ver tarjetas_router.py y pedidos_router.py).
String _detallePago(String metodo, Map<String, dynamic> datosPago) {
  switch (metodo) {
    case 'Tarjeta':
      final ultimos4 = _texto(datosPago['ultimos_4'], '----');
      final vence = _texto(datosPago['vence'], '--/--');
      return 'Tarjeta terminada en $ultimos4 (vence $vence)';
    case 'Transferencia':
      final banco = _texto(datosPago['banco'], 'Banco no especificado');
      final referencia = _texto(datosPago['referencia'], 'Sin referencia');
      return 'Transferencia bancaria — $banco (ref. $referencia)';
    case 'Yappy':
    case 'PayPal':
    case 'Banistmo':
      final contacto = _texto(datosPago['contacto'], 'No especificado');
      return '$metodo — $contacto';
    default:
      return metodo;
  }
}

Future<Uint8List> generarFacturaPdf({
  required Map<String, dynamic> pedido,
  required Map<String, dynamic> perfilComprador,
}) async {
  final doc = pw.Document();

  final id = pedido['id']?.toString() ?? '-';
  final fecha = _texto(pedido['created_at'], '').length >= 10
      ? _texto(pedido['created_at']).substring(0, 10)
      : 'Fecha no disponible';

  // Datos del comprador: se prefiere lo que quedó guardado en el propio
  // pedido (refleja lo que era cierto al momento de la compra) y se
  // completa con el perfil vivo solo lo que el pedido no guarda.
  final nombreComprador = _texto(pedido['comprador_nombre'], _texto(perfilComprador['nombre'], 'Cliente CraftHub'));
  final direccionComprador = _texto(pedido['direccion'], _texto(perfilComprador['ubicacion'], 'No especificada'));
  final telefonoComprador = _texto(pedido['telefono'], _texto(perfilComprador['telefono'], 'No especificado'));
  final emailComprador = _texto(perfilComprador['email'], 'No especificado');
  final cedulaComprador = _texto(perfilComprador['cedula'], 'No especificada');
  final provinciaComprador = _texto(perfilComprador['provincia'], '');

  final metodoPago = _texto(pedido['metodo_pago'], 'No especificado');
  final datosPago = (pedido['datos_pago'] is Map)
      ? Map<String, dynamic>.from(pedido['datos_pago'] as Map)
      : <String, dynamic>{};
  final subtotal = datosPago['subtotal'];
  final envio = datosPago['envio'];
  final total = pedido['total'];

  final productos = (pedido['productos'] is List)
      ? List<Map<String, dynamic>>.from(
          (pedido['productos'] as List).map((p) => Map<String, dynamic>.from(p as Map)))
      : <Map<String, dynamic>>[];

  final vinoTinto = PdfColor.fromHex('#821515');
  final grisTexto = PdfColor.fromHex('#4A4A4A');
  final grisClaro = PdfColor.fromHex('#EDE8E2');

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Encabezado ────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CraftHub', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: vinoTinto)),
                    pw.SizedBox(height: 2),
                    pw.Text('Artesanías panameñas', style: pw.TextStyle(fontSize: 10, color: grisTexto)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Recibo de compra', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('N.º de pedido: $id', style: pw.TextStyle(fontSize: 10, color: grisTexto)),
                    pw.Text('Fecha: $fecha', style: pw.TextStyle(fontSize: 10, color: grisTexto)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: grisClaro, thickness: 1.2),
            pw.SizedBox(height: 14),

            // ── Datos del comprador ───────────────────────────────────
            pw.Text('Datos del comprador', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: vinoTinto)),
            pw.SizedBox(height: 6),
            pw.Table(
              columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1.4)},
              children: [
                _filaDatos('Nombre', nombreComprador, grisTexto),
                _filaDatos('Cédula', cedulaComprador, grisTexto),
                _filaDatos('Correo', emailComprador, grisTexto),
                _filaDatos('Teléfono', telefonoComprador, grisTexto),
                _filaDatos('Dirección', provinciaComprador.isEmpty ? direccionComprador : '$direccionComprador, $provinciaComprador', grisTexto),
              ],
            ),
            pw.SizedBox(height: 18),

            // ── Productos ──────────────────────────────────────────────
            pw.Text('Productos', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: vinoTinto)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: grisClaro, width: 0.8),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.6),
                1: pw.FlexColumnWidth(1.8),
                2: pw.FlexColumnWidth(0.9),
                3: pw.FlexColumnWidth(1.1),
                4: pw.FlexColumnWidth(1.1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: grisClaro),
                  children: [
                    _celda('Producto', esEncabezado: true),
                    _celda('Creador', esEncabezado: true),
                    _celda('Cant.', esEncabezado: true, alinear: pw.TextAlign.center),
                    _celda('Precio unit.', esEncabezado: true, alinear: pw.TextAlign.right),
                    _celda('Subtotal', esEncabezado: true, alinear: pw.TextAlign.right),
                  ],
                ),
                ...productos.map((p) {
                  final cantidad = (p['cantidad'] as num?)?.toInt() ?? 1;
                  final precio = _numero(p['precio']);
                  return pw.TableRow(
                    children: [
                      _celda(_texto(p['nombre'], 'Producto')),
                      _celda(_texto(p['creador'], 'No especificado')),
                      _celda(cantidad.toString(), alinear: pw.TextAlign.center),
                      _celda(_moneda(precio), alinear: pw.TextAlign.right),
                      _celda(_moneda(precio * cantidad), alinear: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 18),

            // ── Pago ───────────────────────────────────────────────────
            pw.Text('Método de pago', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: vinoTinto)),
            pw.SizedBox(height: 4),
            pw.Text(_detallePago(metodoPago, datosPago), style: pw.TextStyle(fontSize: 10.5, color: grisTexto)),
            pw.SizedBox(height: 18),

            // ── Totales ─────────────────────────────────────────────────
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 220,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _filaTotal('Subtotal', _moneda(subtotal)),
                    _filaTotal('Envío', _moneda(envio)),
                    pw.Divider(color: grisClaro, thickness: 1),
                    _filaTotal('Total', _moneda(total), destacado: true),
                  ],
                ),
              ),
            ),

            pw.Spacer(),
            pw.Divider(color: grisClaro, thickness: 1),
            pw.SizedBox(height: 6),
            pw.Text(
              'Este documento es un recibo de compra generado por CraftHub y no constituye una '
              'factura fiscal electrónica oficial ante la DGI de Panamá (no incluye RUC, punto de '
              'facturación ni CUFE).',
              style: pw.TextStyle(fontSize: 8, color: grisTexto, fontStyle: pw.FontStyle.italic),
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

pw.TableRow _filaDatos(String etiqueta, String valor, PdfColor colorTexto) {
  return pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(etiqueta, style: pw.TextStyle(fontSize: 10, color: colorTexto, fontWeight: pw.FontWeight.bold)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(valor, style: pw.TextStyle(fontSize: 10, color: colorTexto)),
      ),
    ],
  );
}

pw.Widget _celda(String texto, {bool esEncabezado = false, pw.TextAlign alinear = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    child: pw.Text(
      texto,
      textAlign: alinear,
      style: pw.TextStyle(fontSize: 9.5, fontWeight: esEncabezado ? pw.FontWeight.bold : pw.FontWeight.normal),
    ),
  );
}

pw.Widget _filaTotal(String etiqueta, String valor, {bool destacado = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(etiqueta,
            style: pw.TextStyle(fontSize: destacado ? 12 : 10.5, fontWeight: destacado ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(valor,
            style: pw.TextStyle(fontSize: destacado ? 12 : 10.5, fontWeight: destacado ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    ),
  );
}
