// lib/widgets/comprador/tarjeta_pago_visual.dart
// Mockup visual de una tarjeta bancaria real, usado tanto en "Mis tarjetas"
// (pantalla de perfil/configuración) como en el selector de la pasarela de
// pago. El diseño (gradiente + logo) cambia según la marca de la tarjeta.
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';

class TarjetaPagoVisual extends StatelessWidget {
  final String marca;
  final String ultimos4;
  final String nombreTitular;
  final int mesVencimiento;
  final int anioVencimiento;
  final String? alias;
  final bool predeterminada;
  final bool seleccionada;
  final bool compacta;
  final VoidCallback? onTap;

  const TarjetaPagoVisual({
    super.key,
    required this.marca,
    required this.ultimos4,
    required this.nombreTitular,
    required this.mesVencimiento,
    required this.anioVencimiento,
    this.alias,
    this.predeterminada = false,
    this.seleccionada = false,
    this.compacta = false,
    this.onTap,
  });

  List<Color> get _gradiente {
    switch (marca) {
      case 'Visa':
        return const [Color(0xFF1E5FAE), Color(0xFF0C3A76)];
      case 'Mastercard':
        return const [Color(0xFF2C2C2C), Color(0xFF0A0A0A)];
      case 'Amex':
        return const [Color(0xFF12786A), Color(0xFF0A4A40)];
      default:
        return const [CraftHubColors.vinoTinto, CraftHubColors.vinoTintoOscuro];
    }
  }

  String get _vence =>
      '${mesVencimiento.toString().padLeft(2, '0')}/${anioVencimiento.toString().substring(anioVencimiento.toString().length - 2)}';

  @override
  Widget build(BuildContext context) {
    return compacta ? _buildCompacta(context) : _buildCompleta(context);
  }

  Widget _buildCompacta(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 230,
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: _gradiente, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          border: seleccionada ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: (seleccionada ? _gradiente.first : Colors.black).withValues(alpha: seleccionada ? 0.35 : 0.15),
              blurRadius: seleccionada ? 14 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•••• $ultimos4',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700,
                            color: Colors.white, letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Text(nombreTitular.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5,
                            color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
                _logoMarca(alto: 16),
              ],
            ),
            if (seleccionada)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, size: 13, color: _gradiente.last),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleta(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 172,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: _gradiente, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _chip(),
                if (predeterminada)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tr(context, 'comprador_secundario.predeterminada_badge'),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 9.5, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
              ],
            ),
            const Spacer(),
            Text('•••• •••• •••• $ultimos4',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: 2)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (alias != null && alias!.isNotEmpty) ...[
                        Text(alias!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 9.5, color: Colors.white.withValues(alpha: 0.7))),
                        const SizedBox(height: 2),
                      ],
                      Text(nombreTitular.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('${tr(context, 'comprador_secundario.vence_prefijo')} $_vence',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: Colors.white.withValues(alpha: 0.75))),
                    ],
                  ),
                ),
                _logoMarca(alto: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip() {
    return Container(
      width: 34,
      height: 24,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE9D8A6), Color(0xFFBBA35C)]),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Icon(Icons.memory_outlined, size: 14, color: Color(0xFF5A4A1F)),
    );
  }

  Widget _logoMarca({required double alto}) {
    switch (marca) {
      case 'Visa':
        return Image.asset('assets/images/logos/visa.png', height: alto, fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _logotipoTexto('VISA'));
      case 'Mastercard':
        return Image.asset('assets/images/logos/mastercard.webp', height: alto, fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _logotipoTexto('Mastercard'));
      case 'Amex':
        return _logotipoTexto('AMEX');
      default:
        return Icon(Icons.credit_card_rounded, size: alto, color: Colors.white.withValues(alpha: 0.85));
    }
  }

  Widget _logotipoTexto(String texto) {
    return Text(texto,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5));
  }
}
