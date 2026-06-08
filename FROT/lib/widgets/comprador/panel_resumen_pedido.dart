import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/carrito_provider.dart';
import '../../core/theme/app_theme.dart';

// ============================================================
// PANEL DE RESUMEN DEL PEDIDO
// Columna derecha con totales, botones de factura y pago.
// TODO [API]: "Proceder al pago" → navegar a PantallaPasarelaPago
//            "Descargar factura" → ApiService.descargarFactura()
//            "Ver factura completa" → ApiService.verFacturaCompleta()
// ============================================================

class PanelResumenPedido extends StatelessWidget {
  const PanelResumenPedido({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CarritoProvider>();
    final carrito = provider.carritoActivo;
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: esModoOscuro ? AppColors.panelOscuro : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: esModoOscuro
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Encabezado ──────────────────────────────────
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.vinoTinto.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_outlined,
                      color: AppColors.vinoTinto, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'Resumen del pedido',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: esModoOscuro
                        ? AppColors.textoOscuro
                        : AppColors.textoClaro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Desglose de costos ──────────────────────────
            _FilaResumen(
              etiqueta: 'Subtotal',
              valor: '\$${carrito.subtotal.toStringAsFixed(2)}',
              esModoOscuro: esModoOscuro,
            ),
            const SizedBox(height: 10),
            _FilaResumen(
              etiqueta: 'Envío',
              valor: carrito.envio == 0
                  ? 'Gratis'
                  : '\$${carrito.envio.toStringAsFixed(2)}',
              colorValor: carrito.envio == 0 ? Colors.green[600] : null,
              esModoOscuro: esModoOscuro,
            ),
            const SizedBox(height: 10),
            _FilaResumen(
              etiqueta: 'Impuestos (7%)',
              valor: '\$${carrito.impuestos.toStringAsFixed(2)}',
              esModoOscuro: esModoOscuro,
            ),
            const SizedBox(height: 16),
            Divider(
              color: esModoOscuro
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.08),
            ),
            const SizedBox(height: 14),

            // ── Total ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: esModoOscuro
                        ? AppColors.textoOscuro
                        : AppColors.textoClaro,
                  ),
                ),
                Text(
                  '\$${carrito.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.vinoTinto,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Botones de Factura ────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _BotonFactura(
                    icono: Icons.download_outlined,
                    etiqueta: 'Descargar\nfactura',
                    alPresionar: () => provider.descargarFactura(),
                    esSecundario: true,
                    esModoOscuro: esModoOscuro,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BotonFactura(
                    icono: Icons.receipt_long_outlined,
                    etiqueta: 'Ver factura\ncompleta',
                    alPresionar: () => provider.verFacturaCompleta(context),
                    esSecundario: true,
                    esModoOscuro: esModoOscuro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Compra protegida ─────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.vinoTinto.withOpacity(0.05),
                border: Border.all(
                  color: AppColors.vinoTinto.withOpacity(0.12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppColors.vinoTinto, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compra protegida',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: esModoOscuro
                                ? AppColors.textoOscuro
                                : AppColors.textoClaro,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tus pagos están 100% seguros y\ntus artesanos reciben tu apoyo directo.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            color: esModoOscuro
                                ? AppColors.textoSecOscuro
                                : AppColors.textoSecClaro,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Botón principal: Proceder al pago ─────────────
            _BotonProcederPago(
              // TODO [API]: alPresionar → navegar a PantallaPasarelaPago
              alPresionar: () {
                debugPrint('Navegando a pasarela de pago...');
              },
            ),
            const SizedBox(height: 12),

            // Envíos a todo Panamá
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 14,
                      color: esModoOscuro
                          ? AppColors.textoSecOscuro
                          : AppColors.textoSecClaro),
                  const SizedBox(width: 6),
                  Text(
                    'Envíos a todo Panamá',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: esModoOscuro
                          ? AppColors.textoSecOscuro
                          : AppColors.textoSecClaro,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FILA DE RESUMEN (etiqueta — valor)
// ============================================================
class _FilaResumen extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color? colorValor;
  final bool esModoOscuro;

  const _FilaResumen({
    required this.etiqueta,
    required this.valor,
    this.colorValor,
    required this.esModoOscuro,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: esModoOscuro ? AppColors.textoSecOscuro : AppColors.textoSecClaro,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorValor ??
                (esModoOscuro ? AppColors.textoOscuro : AppColors.textoClaro),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// BOTÓN DE FACTURA (Descargar / Ver completa)
// ============================================================
class _BotonFactura extends StatefulWidget {
  final IconData icono;
  final String etiqueta;
  final VoidCallback alPresionar;
  final bool esSecundario;
  final bool esModoOscuro;

  const _BotonFactura({
    required this.icono,
    required this.etiqueta,
    required this.alPresionar,
    this.esSecundario = true,
    required this.esModoOscuro,
  });

  @override
  State<_BotonFactura> createState() => _BotonFacturaState();
}

class _BotonFacturaState extends State<_BotonFactura> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _hover
                ? AppColors.vinoTinto.withOpacity(0.1)
                : (widget.esModoOscuro
                    ? AppColors.panelOscuro2
                    : const Color(0xFFF9F6F0)),
            border: Border.all(
              color: _hover
                  ? AppColors.vinoTinto.withOpacity(0.3)
                  : (widget.esModoOscuro
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.08)),
            ),
          ),
          child: Column(
            children: [
              Icon(
                widget.icono,
                size: 18,
                color: _hover
                    ? AppColors.vinoTinto
                    : (widget.esModoOscuro
                        ? AppColors.textoSecOscuro
                        : AppColors.textoSecClaro),
              ),
              const SizedBox(height: 5),
              Text(
                widget.etiqueta,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: _hover
                      ? AppColors.vinoTinto
                      : (widget.esModoOscuro
                          ? AppColors.textoSecOscuro
                          : AppColors.textoSecClaro),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BOTÓN PRINCIPAL: PROCEDER AL PAGO
// ============================================================
class _BotonProcederPago extends StatefulWidget {
  final VoidCallback alPresionar;
  const _BotonProcederPago({required this.alPresionar});

  @override
  State<_BotonProcederPago> createState() => _BotonProcederPagoState();
}

class _BotonProcederPagoState extends State<_BotonProcederPago> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: _hover
                  ? [const Color(0xFF9E1A1A), AppColors.vinoTinto]
                  : [AppColors.vinoTinto, const Color(0xFF5E0F0F)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.vinoTinto.withOpacity(_hover ? 0.45 : 0.25),
                blurRadius: _hover ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              const Text(
                'Proceder al pago',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                transform: Matrix4.translationValues(_hover ? 4 : 0, 0, 0),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}