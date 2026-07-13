import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';
import '../../core/locale_provider.dart';
import '../../../widgets/boton_primario.dart';
import '../auth/pantalla_login.dart';
import '../auth/role.dart';
import '../../../main.dart';

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    final gestor = context.watch<GestorTema>();
    final esOscuro = gestor.esModoOscuro;

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. IMAGEN DE FONDO (insertar manualmente) ──────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo_inicio.png',
              fit: BoxFit.cover,
            ),
          ),

          // ── 2. VELO DIFUMINADO SOBRE LA IMAGEN ─────────────────────────
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: esOscuro
                      ? [
                          const Color(0xFF0D0D0D).withValues(alpha: 0.92),
                          const Color(0xFF1A1A1A).withValues(alpha: 0.70),
                          Colors.transparent,
                        ]
                      : [
                          const Color(0xFFF5EDE3).withValues(alpha: 0.95),
                          const Color(0xFFF0E6D8).withValues(alpha: 0.82),
                          Colors.transparent,
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── 3. BARRA SUPERIOR ───────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _BarraSuperior(esOscuro: esOscuro, gestor: gestor),
          ),

          // ── 4. CONTENIDO CENTRAL ────────────────────────────────────────
          Center(
            child: _ContenidoCentral(esOscuro: esOscuro),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BARRA SUPERIOR
// ─────────────────────────────────────────────────────────────
class _BarraSuperior extends StatelessWidget {
  final bool esOscuro;
  final GestorTema gestor;

  const _BarraSuperior({required this.esOscuro, required this.gestor});

  @override
  Widget build(BuildContext context) {
    final colorTexto =
        esOscuro ? CraftHubColors.textoOscuro : CraftHubColors.textoClaro;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nombre de la plataforma
          Text(
            'Digital Market',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorTexto.withValues(alpha: 0.75),
              letterSpacing: 0.3,
            ),
          ),

          // Controles derecha: idioma + toggle de tema
          Row(
            children: [
              // Selector de idioma simulado
              _SelectorIdioma(esOscuro: esOscuro),
              const SizedBox(width: 16),

              // Toggle tema claro/oscuro
              _ToggleTema(esOscuro: esOscuro, gestor: gestor),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectorIdioma extends StatelessWidget {
  final bool esOscuro;

  const _SelectorIdioma({required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    final colorTexto =
        esOscuro ? CraftHubColors.textoOscuro : CraftHubColors.textoClaro;

    return Tooltip(
      message: tr(context, 'topbar.cambiar_idioma'),
      child: InkWell(
        onTap: () => context.read<LocaleProvider>().alternarIdioma(),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: esOscuro
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: esOscuro
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr(context, 'auth.selector_idioma_label'),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorTexto,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: colorTexto.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTema extends StatelessWidget {
  final bool esOscuro;
  final GestorTema gestor;

  const _ToggleTema({required this.esOscuro, required this.gestor});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: esOscuro ? 'Light' : 'Dark',
      child: InkWell(
        onTap: gestor.alternarTema,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: esOscuro
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: esOscuro
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.10),
            ),
          ),
          child: Icon(
            esOscuro
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            size: 18,
            color: esOscuro
                ? CraftHubColors.textoOscuro
                : CraftHubColors.textoClaro,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONTENIDO CENTRAL
// ─────────────────────────────────────────────────────────────
class _ContenidoCentral extends StatelessWidget {
  final bool esOscuro;

  const _ContenidoCentral({required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    final colorTexto =
        esOscuro ? CraftHubColors.textoOscuro : CraftHubColors.textoClaro;
    final colorTextoSec =
        esOscuro ? CraftHubColors.textoSecOscuro : CraftHubColors.textoSecClaro;

    return SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── LOGO (imagen insertada manualmente) ──────────────────────
          _SeccionLogo(esOscuro: esOscuro, colorTexto: colorTexto),

          const SizedBox(height: 44),

          // ── BOTÓN INICIAR SESIÓN ──────────────────────────────────────
          BotonPrimario(
  texto: tr(context, 'auth.iniciar_sesion'),
  alPresionar: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PantallaLogin(),
      ), // Cierra el MaterialPageRoute
    ); // <-- Aquí faltaba el ")" para cerrar el Navigator.push
  },
  ancho: 340,
),

const SizedBox(height: 22), // Añadida la coma por si estás dentro de un children: [],

          // ── SEPARADOR "o continúa con" ────────────────────────────────
          _SeparadorOContinua(
              colorTextoSec: colorTextoSec, esOscuro: esOscuro),

          const SizedBox(height: 22),

          // ── BOTÓN GOOGLE ──────────────────────────────────────────────
          _BotonGoogle(esOscuro: esOscuro),

          const SizedBox(height: 28),

          // ── LINK CREAR CUENTA ─────────────────────────────────────────
          _LinkCrearCuenta(colorTextoSec: colorTextoSec),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECCIÓN LOGO + NOMBRE + SLOGAN
// ─────────────────────────────────────────────────────────────
class _SeccionLogo extends StatelessWidget {
  final bool esOscuro;
  final Color colorTexto;

  const _SeccionLogo({required this.esOscuro, required this.colorTexto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo insertado como imagen
        Image.asset(
          CraftHubColors.logoPath(esOscuro),
          width: 90,
          height: 90,
          fit: BoxFit.contain,
        ),

        const SizedBox(width: 18),

        // Nombre y slogan
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CRAFTHUB',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 46,
                fontWeight: FontWeight.w700,
                color: colorTexto,
                letterSpacing: 2,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Creativity with Purpose',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: colorTexto.withValues(alpha: 0.65),
                letterSpacing: 3.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SEPARADOR "o continúa con"
// ─────────────────────────────────────────────────────────────
class _SeparadorOContinua extends StatelessWidget {
  final Color colorTextoSec;
  final bool esOscuro;

  const _SeparadorOContinua(
      {required this.colorTextoSec, required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    final colorLinea = esOscuro
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.15);

    return SizedBox(
      width: 340,
      child: Row(
        children: [
          Expanded(child: Divider(color: colorLinea, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              tr(context, 'auth.o_continua_con'),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: colorTextoSec,
              ),
            ),
          ),
          Expanded(child: Divider(color: colorLinea, thickness: 1)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTÓN CONTINUAR CON GOOGLE
// ─────────────────────────────────────────────────────────────
class _BotonGoogle extends StatefulWidget {
  final bool esOscuro;

  const _BotonGoogle({required this.esOscuro});

  @override
  State<_BotonGoogle> createState() => _BotonGoogleState();
}

class _BotonGoogleState extends State<_BotonGoogle> {
  bool _sobreEl = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobreEl = true),
      onExit: (_) => setState(() => _sobreEl = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 340,
        height: 54,
        decoration: BoxDecoration(
          color: widget.esOscuro
              ? (_sobreEl
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFF1E1E1E))
              : (_sobreEl
                  ? const Color(0xFFF5F0E8)
                  : Colors.white),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: widget.esOscuro
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.12),
            width: 1.2,
          ),
          boxShadow: _sobreEl
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: Implementar autenticación con Google
            },
            borderRadius: BorderRadius.circular(50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono G de Google simulado con colores reales
                _IconoGoogle(),
                const SizedBox(width: 12),
                Text(
                  tr(context, 'auth.continuar_con_google'),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
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

/// Ícono de Google dibujado con Canvas para no depender de paquetes externos
class _IconoGoogle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _GoogleIconPainter(),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width / 2;

    // Círculo de clip
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: centro, radius: radio)));

    // Fondo blanco
    canvas.drawCircle(centro, radio, Paint()..color = Colors.white);

    // Segmentos de color
    final pinturas = [
      Paint()..color = const Color(0xFF4285F4), // azul
      Paint()..color = const Color(0xFF34A853), // verde
      Paint()..color = const Color(0xFFFBBC05), // amarillo
      Paint()..color = const Color(0xFFEA4335), // rojo
    ];

    final rect = Rect.fromCircle(center: centro, radius: radio);

    // Cuadrantes simplificados del logo G
    canvas.drawArc(rect, -1.57, 1.57, true, pinturas[0]); // azul arriba-der
    canvas.drawArc(rect, 0.0, 1.57, true, pinturas[1]);   // verde abajo-der
    canvas.drawArc(rect, 1.57, 1.57, true, pinturas[2]);  // amarillo abajo-izq
    canvas.drawArc(rect, 3.14, 1.57, true, pinturas[3]);  // rojo arriba-izq

    // Centro blanco para forma de "G"
    canvas.drawCircle(
      centro,
      radio * 0.58,
      Paint()..color = Colors.white,
    );

    // Barra derecha del "G"
    final pintaAzul = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(centro.dx, centro.dy - radio * 0.15, radio * 0.95, radio * 0.30),
      pintaAzul,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// LINK CREAR CUENTA
// ─────────────────────────────────────────────────────────────
class _LinkCrearCuenta extends StatelessWidget {
  final Color colorTextoSec;

  const _LinkCrearCuenta({required this.colorTextoSec});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          tr(context, 'auth.no_tienes_cuenta'),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13.5,
            color: colorTextoSec,
          ),
        ),
       MouseRegion(
           cursor: SystemMouseCursors.click,
           child: GestureDetector(
            onTap: () {
            Navigator.push(
              context,
                MaterialPageRoute(
                   builder: (_) => const PantallaSeleccionRol(),
                  ),
              );
            },
            child: Text(
              tr(context, 'auth.crear_cuenta'),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: CraftHubColors.vinoTinto,
                decoration: TextDecoration.underline,
                decorationColor: CraftHubColors.vinoTinto,
              ),
            ),
          ),
        ),
      ],
    );
  }
}