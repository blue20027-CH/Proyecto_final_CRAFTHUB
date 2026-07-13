// lib/widgets/comprador/seccion_historial_pedidos.dart
// Sección "Facturación" de Mi perfil/Configuración: historial de pedidos del
// comprador con botón para descargar el recibo/factura de cada uno en PDF.
// 🔌 GET /api/pagos/historial/{userId} (BACK/CraftHub/pedidos_router.py)
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/generador_factura_pdf.dart';
import 'tarjeta_seccion.dart';

class SeccionHistorialPedidos extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> perfilComprador;
  final bool esOscuro;
  const SeccionHistorialPedidos({
    super.key,
    required this.userId,
    required this.perfilComprador,
    required this.esOscuro,
  });

  @override
  State<SeccionHistorialPedidos> createState() => _SeccionHistorialPedidosState();
}

class _SeccionHistorialPedidosState extends State<SeccionHistorialPedidos> {
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _pedidos = [];
  final Set<int> _expandidos = {};
  int? _descargando;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final pedidos = await ApiService.getHistorialPedidos(widget.userId);
      if (!mounted) return;
      setState(() => _pedidos = pedidos);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _descargarFactura(Map<String, dynamic> pedido, int indice) async {
    setState(() => _descargando = indice);
    try {
      final bytes = await generarFacturaPdf(pedido: pedido, perfilComprador: widget.perfilComprador);
      await Printing.layoutPdf(
        name: 'factura_pedido_${pedido['id']}.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar la factura: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _descargando = null);
    }
  }

  String _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'entregado':
        return '🟢';
      case 'cancelado':
        return '🔴';
      case 'enviado':
      case 'en camino':
        return '🔵';
      default:
        return '🟡';
    }
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = widget.esOscuro;
    return TarjetaSeccion(
      esOscuro: esOscuro,
      icono: Icons.receipt_long_outlined,
      titulo: 'Historial de facturas',
      subtitulo: 'Tus pedidos anteriores. Descarga el recibo de compra de cualquiera en PDF.',
      colapsable: true,
      child: _cargando
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto, strokeWidth: 2)),
            )
          : _error != null
              ? Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: CraftHubColors.error))
              : _pedidos.isEmpty
                  ? Text('Aún no tienes pedidos.',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: CraftHubColors.textoSecundario(esOscuro)))
                  : Column(
                      children: List.generate(_pedidos.length, (i) {
                        final pedido = _pedidos[i];
                        final expandido = _expandidos.contains(i);
                        final productos = (pedido['productos'] is List) ? (pedido['productos'] as List) : [];
                        final fecha = (pedido['created_at']?.toString() ?? '');
                        final fechaCorta = fecha.length >= 10 ? fecha.substring(0, 10) : 'Sin fecha';
                        final estado = (pedido['estado'] ?? 'pendiente').toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: CraftHubColors.borde(esOscuro)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => setState(() {
                                  if (expandido) {
                                    _expandidos.remove(i);
                                  } else {
                                    _expandidos.add(i);
                                  }
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Pedido #${pedido['id']} · $fechaCorta',
                                                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600,
                                                    color: CraftHubColors.textoPrincipal(esOscuro))),
                                            const SizedBox(height: 3),
                                            Text('${_colorEstado(estado)} ${estado[0].toUpperCase()}${estado.substring(1)} · ${productos.length} producto(s)',
                                                style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5,
                                                    color: CraftHubColors.textoSecundario(esOscuro))),
                                          ],
                                        ),
                                      ),
                                      Text('\$${(pedido['total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700,
                                              color: CraftHubColors.vinoTinto)),
                                      Icon(expandido ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                          color: CraftHubColors.textoSecundario(esOscuro)),
                                    ],
                                  ),
                                ),
                              ),
                              if (expandido)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Divider(height: 18),
                                      ...productos.map((p) {
                                        final m = Map<String, dynamic>.from(p as Map);
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text(
                                            '${m['cantidad'] ?? 1}× ${m['nombre'] ?? 'Producto'} — ${m['creador'] ?? 'Artesano'}',
                                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: CraftHubColors.textoPrincipal(esOscuro)),
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: _descargando == i ? null : () => _descargarFactura(pedido, i),
                                          icon: _descargando == i
                                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                              : const Icon(Icons.download_outlined, size: 17, color: CraftHubColors.vinoTinto),
                                          label: const Text('Descargar factura',
                                              style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: CraftHubColors.vinoTinto, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),
    );
  }
}
