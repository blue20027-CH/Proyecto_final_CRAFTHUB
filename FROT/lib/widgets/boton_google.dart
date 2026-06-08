import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class BotonGoogle extends StatefulWidget {
  final bool esOscuro;
  final VoidCallback alPresionar;

  const BotonGoogle({
    super.key,
    required this.esOscuro,
    required this.alPresionar,
  });

  @override
  State<BotonGoogle> createState() => _BotonGoogleState();
}

class _BotonGoogleState extends State<BotonGoogle> {
  bool _sobreEl = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobreEl = true),
      onExit:  (_) => setState(() => _sobreEl = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: widget.esOscuro
              ? (_sobreEl ? const Color(0xFF2A2A2A) : CraftHubColors.panelOscuro)
              : (_sobreEl ? const Color(0xFFF5F0E8) : CraftHubColors.panelClaro),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: widget.esOscuro
                ? CraftHubColors.bordeOscuro
                : CraftHubColors.bordeClaro,
            width: 1.2,
          ),
          boxShadow: _sobreEl
              ? [BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.alPresionar,
            borderRadius: BorderRadius.circular(50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LogoGoogle(),
                const SizedBox(width: 10),
                Text(
                  'Continuar con Google',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.esOscuro
                        ? CraftHubColors.textoOscuro
                        : CraftHubColors.textoClaro,
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

class _LogoGoogle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: _GooglePainter(),
    );
  }
}

class _GooglePainter extends StatelessWidget {
  const _GooglePainter();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GPainter());
  }
}

class _GPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    canvas.drawCircle(c, r, Paint()..color = Colors.white);

    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(rect, -1.57, 1.57, true, Paint()..color = const Color(0xFF4285F4));
    canvas.drawArc(rect, 0.00, 1.57, true, Paint()..color = const Color(0xFF34A853));
    canvas.drawArc(rect, 1.57, 1.57, true, Paint()..color = const Color(0xFFFBBC05));
    canvas.drawArc(rect, 3.14, 1.57, true, Paint()..color = const Color(0xFFEA4335));
    canvas.drawCircle(c, r * 0.58, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - r * 0.15, r * 0.95, r * 0.30),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}