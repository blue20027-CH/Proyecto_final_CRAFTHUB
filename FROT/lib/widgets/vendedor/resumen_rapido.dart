import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ResumenRapido extends StatelessWidget {
  final int pedidosTotales;
  final String variacionPedidos;
  final int pendientesEnviar;
  final int productosActivos;
  final int visitasTienda;
  final String variacionVisitas;
  final VoidCallback alVerPedidos;
  final VoidCallback alVerProductos;

  const ResumenRapido({
    super.key,
    required this.pedidosTotales,
    required this.variacionPedidos,
    required this.pendientesEnviar,
    required this.productosActivos,
    required this.visitasTienda,
    required this.variacionVisitas,
    required this.alVerPedidos,
    required this.alVerProductos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CraftHubColors.panelClaro,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CraftHubColors.bordeClaro),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: CraftHubColors.vinoTintoSuave,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.summarize_outlined,
                    size: 16, color: CraftHubColors.vinoTinto),
              ),
              const SizedBox(width: 10),
              const Text(
                'Resumen rápido',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CraftHubColors.textoClaro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ItemResumen(
                  icono: Icons.shopping_cart_outlined,
                  titulo: 'Pedidos totales',
                  valor: '$pedidosTotales',
                  variacion: variacionPedidos,
                  positivo: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ItemResumen(
                  icono: Icons.local_shipping_outlined,
                  titulo: 'Pendientes por enviar',
                  valor: '$pendientesEnviar',
                  linkTexto: 'Ver pedidos',
                  alPresionarLink: alVerPedidos,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ItemResumen(
                  icono: Icons.inventory_2_outlined,
                  titulo: 'Productos activos',
                  valor: '$productosActivos',
                  linkTexto: 'Ver productos',
                  alPresionarLink: alVerProductos,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ItemResumen(
                  icono: Icons.storefront_outlined,
                  titulo: 'Visitas a tu tienda',
                  valor: '${visitasTienda.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                  variacion: variacionVisitas,
                  positivo: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemResumen extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final String? variacion;
  final bool positivo;
  final String? linkTexto;
  final VoidCallback? alPresionarLink;

  const _ItemResumen({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.variacion,
    this.positivo = true,
    this.linkTexto,
    this.alPresionarLink,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: CraftHubColors.vinoTintoSuave,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, size: 20, color: CraftHubColors.vinoTinto),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: CraftHubColors.textoSecClaro,
                ),
              ),
              Text(
                valor,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: CraftHubColors.textoClaro,
                ),
              ),
              Row(
                children: [
                  if (variacion != null) ...[
                    Icon(
                      positivo
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 11,
                      color: positivo
                          ? const Color(0xFF2E7D32)
                          : CraftHubColors.error,
                    ),
                    Text(
                      variacion!,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: positivo
                            ? const Color(0xFF2E7D32)
                            : CraftHubColors.error,
                      ),
                    ),
                  ],
                  if (linkTexto != null)
                    GestureDetector(
                      onTap: alPresionarLink,
                      child: Text(
                        linkTexto!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CraftHubColors.vinoTinto,
                          decoration: TextDecoration.underline,
                          decorationColor: CraftHubColors.vinoTinto,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}