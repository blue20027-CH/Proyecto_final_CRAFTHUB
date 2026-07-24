// Tour de bienvenida guiado por Crafty (la rana mascota).
// Se muestra encima del Scaffold como un overlay a página completa: fondo
// oscurecido para poner el foco, Crafty grande cambiando de posición según
// el paso y un globo de texto animado con la explicación y los botones
// Siguiente / Saltar.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// Mismo tinte dorado que el resto de la app (rana pintada) para que las
// imágenes de Crafty se vean parejas con el botón flotante y el header.
const Color _kTinteDorado = Color(0xFFFFD86A);

class PasoTutorial {
  /// Emoji al lado del título (le da carácter al globo).
  final String emoji;

  /// Título corto (2-4 palabras) que va grande arriba del globo.
  final String titulo;

  /// Cuerpo del mensaje. Una o dos frases en español neutro.
  final String mensaje;

  /// Índice de la pestaña del BottomNavigation/Sidebar al que hay que ir
  /// para mostrar este paso. Si es null, no cambia de pantalla.
  final int? indiceSeccion;

  /// Cuál PNG de Crafty mostrar en este paso (para variar la expresión).
  final String rutaExpresion;

  /// Posición de Crafty y el globo en la pantalla — se rota por paso para
  /// que el tour se sienta vivo y no siempre en la misma esquina.
  final Alignment posicion;

  const PasoTutorial({
    required this.emoji,
    required this.titulo,
    required this.mensaje,
    required this.rutaExpresion,
    required this.posicion,
    this.indiceSeccion,
  });
}

// ─── PASOS: COMPRADOR ────────────────────────────────────────────────────
const List<PasoTutorial> _pasosComprador = [
  PasoTutorial(
    emoji: '👋',
    titulo: '¡Hola! Soy Crafty',
    mensaje:
        'Tu asistente en CraftHub. Deja que te muestre lo esencial en un minuto — puedes saltar cuando quieras.',
    rutaExpresion: 'assets/images/crafty_hablando.png',
    posicion: Alignment.center,
  ),
  PasoTutorial(
    emoji: '🛍️',
    titulo: 'Explora productos',
    mensaje:
        'Aquí encuentras todo lo hecho a mano por artesanos panameños. Filtra por categoría o busca lo que necesites.',
    rutaExpresion: 'assets/images/crafty_curiosa.png',
    posicion: Alignment.bottomLeft,
    indiceSeccion: 0,
  ),
  PasoTutorial(
    emoji: '❤️',
    titulo: 'Guarda favoritos',
    mensaje:
        'Toca el corazón en cualquier producto y lo verás aquí para volver más tarde.',
    rutaExpresion: 'assets/images/crafty_enamorada.png',
    posicion: Alignment.topRight,
    indiceSeccion: 1,
  ),
  PasoTutorial(
    emoji: '🛒',
    titulo: 'Tu carrito',
    mensaje:
        'Todo lo que agregues se acumula aquí. Al pagar puedes elegir Yappy, PayPal o tarjeta.',
    rutaExpresion: 'assets/images/crafty_ia.png',
    posicion: Alignment.bottomRight,
    indiceSeccion: 2,
  ),
  PasoTutorial(
    emoji: '💬',
    titulo: 'Chatea con artesanos',
    mensaje:
        'Pregúntale a un artesano sobre su producto, o háblame a mí si necesitas ayuda con la app.',
    rutaExpresion: 'assets/images/crafty_hablando.png',
    posicion: Alignment.topLeft,
    indiceSeccion: 3,
  ),
  PasoTutorial(
    emoji: '✨',
    titulo: '¡Todo listo!',
    mensaje:
        'Mapa de talleres, tutoriales, eventos… lo tienes en el menú lateral. Cualquier duda, toca mi ícono flotante.',
    rutaExpresion: 'assets/images/crafty_ia.png',
    posicion: Alignment.center,
  ),
];

// ─── PASOS: VENDEDOR ─────────────────────────────────────────────────────
const List<PasoTutorial> _pasosVendedor = [
  PasoTutorial(
    emoji: '👋',
    titulo: '¡Bienvenido, artesano!',
    mensaje:
        'Soy Crafty, tu asistente. Te muestro las herramientas principales de tu tienda en un minuto.',
    rutaExpresion: 'assets/images/crafty_hablando.png',
    posicion: Alignment.center,
  ),
  PasoTutorial(
    emoji: '📊',
    titulo: 'Tu dashboard',
    mensaje:
        'Ventas del mes, ingresos y los productos que más piden — todo de un vistazo.',
    rutaExpresion: 'assets/images/crafty_curiosa.png',
    posicion: Alignment.topLeft,
    indiceSeccion: 0,
  ),
  PasoTutorial(
    emoji: '📦',
    titulo: 'Tu inventario',
    mensaje:
        'Agrega, edita o pausa tus productos. Cada uno lleva fotos, precio, stock y tallas.',
    rutaExpresion: 'assets/images/crafty_ia.png',
    posicion: Alignment.bottomRight,
    indiceSeccion: 1,
  ),
  PasoTutorial(
    emoji: '🧾',
    titulo: 'Pedidos entrantes',
    mensaje:
        'Cuando alguien te compra, aparece aquí. Actualiza el estado: preparando, enviado, entregado.',
    rutaExpresion: 'assets/images/crafty_enamorada.png',
    posicion: Alignment.topRight,
    indiceSeccion: 2,
  ),
  PasoTutorial(
    emoji: '✨',
    titulo: 'Perfil con IA',
    mensaje:
        'En Editar perfil puedo escribirte una descripción atractiva para tu marca. Solo toca "Mejorar con IA".',
    rutaExpresion: 'assets/images/crafty_hablando.png',
    posicion: Alignment.bottomLeft,
  ),
  PasoTutorial(
    emoji: '🚀',
    titulo: '¡A vender!',
    mensaje:
        'Estoy en el botón flotante en cada pantalla. Pregúntame lo que necesites. Éxitos con tu tienda.',
    rutaExpresion: 'assets/images/crafty_ia.png',
    posicion: Alignment.center,
  ),
];

/// Widget principal del tour. Se coloca encima del Scaffold usando un
/// `Stack` en el body de la pantalla contenedora.
class OverlayTutorialCrafty extends StatefulWidget {
  final String rol; // 'comprador' o 'vendedor'
  final VoidCallback onCerrar;
  final ValueChanged<int>? onIrASeccion;

  const OverlayTutorialCrafty({
    super.key,
    required this.rol,
    required this.onCerrar,
    this.onIrASeccion,
  });

  @override
  State<OverlayTutorialCrafty> createState() => _OverlayTutorialCraftyState();
}

class _OverlayTutorialCraftyState extends State<OverlayTutorialCrafty>
    with TickerProviderStateMixin {
  int _paso = 0;
  late final AnimationController _pulso;
  late final AnimationController _entrada;

  List<PasoTutorial> get _pasos =>
      widget.rol.toLowerCase() == 'vendedor' ? _pasosVendedor : _pasosComprador;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
  }

  @override
  void dispose() {
    _pulso.dispose();
    _entrada.dispose();
    super.dispose();
  }

  Future<void> _siguiente() async {
    if (_paso >= _pasos.length - 1) {
      widget.onCerrar();
      return;
    }
    // Animación de salida → cambia paso → animación de entrada
    await _entrada.reverse();
    if (!mounted) return;
    setState(() => _paso++);
    final indice = _pasos[_paso].indiceSeccion;
    if (indice != null) widget.onIrASeccion?.call(indice);
    _entrada.forward();
  }

  void _saltar() => widget.onCerrar();

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final paso = _pasos[_paso];
    final total = _pasos.length;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // ── Fondo oscurecido ─────────────────────────────────────────
            Positioned.fill(
              child: GestureDetector(
                onTap: _siguiente,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  color: Colors.black.withValues(alpha: 0.62),
                ),
              ),
            ),

            // ── Crafty + globo (posición cambia por paso) ────────────────
            AnimatedAlign(
              alignment: paso.posicion,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: FadeTransition(
                    opacity: _entrada,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                          parent: _entrada, curve: Curves.easeOutCubic)),
                      child: _burbujaConCrafty(paso, total, esOscuro),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _burbujaConCrafty(PasoTutorial paso, int total, bool esOscuro) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Globo grande arriba
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _Globo(
            emoji: paso.emoji,
            titulo: paso.titulo,
            mensaje: paso.mensaje,
            pasoActual: _paso + 1,
            totalPasos: total,
            esUltimo: _paso == total - 1,
            esOscuro: esOscuro,
            onSaltar: _saltar,
            onSiguiente: _siguiente,
          ),
        ),
        const SizedBox(height: 14),
        // Crafty grande + pulso dorado, debajo del globo
        SizedBox(
          width: 170,
          height: 170,
          child: AnimatedBuilder(
            animation: _pulso,
            builder: (_, __) {
              final t = _pulso.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Halo dorado exterior
                  Container(
                    width: 160 + 20 * t,
                    height: 160 + 20 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          const Color(0xFFFFD86A).withValues(alpha: 0.22 - 0.10 * t),
                    ),
                  ),
                  // Círculo interior donde vive Crafty (que la contiene)
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD86A).withValues(alpha: 0.14),
                      border: Border.all(
                          color: const Color(0xFFFFD86A).withValues(alpha: 0.55),
                          width: 2),
                    ),
                  ),
                  // Bamboleo suave para que se sienta viva
                  Transform.rotate(
                    angle: math.sin(t * math.pi) * 0.06,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                          _kTinteDorado, BlendMode.modulate),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: KeyedSubtree(
                          key: ValueKey(paso.rutaExpresion),
                          child: Image.asset(
                            paso.rutaExpresion,
                            width: 118,
                            height: 118,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Globo extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String mensaje;
  final int pasoActual;
  final int totalPasos;
  final bool esUltimo;
  final bool esOscuro;
  final VoidCallback onSaltar;
  final VoidCallback onSiguiente;

  const _Globo({
    required this.emoji,
    required this.titulo,
    required this.mensaje,
    required this.pasoActual,
    required this.totalPasos,
    required this.esUltimo,
    required this.esOscuro,
    required this.onSaltar,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    final acento =
        esOscuro ? const Color(0xFFE38F8F) : CraftHubColors.vinoTinto;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cuerpo del globo
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
          decoration: BoxDecoration(
            color: CraftHubColors.panel(esOscuro),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: acento.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: acento.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila superior: contador + puntos de progreso
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: acento.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Paso $pasoActual de $totalPasos',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: acento,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Puntitos de progreso
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(totalPasos, (i) {
                      final activo = i == pasoActual - 1;
                      final visitado = i < pasoActual;
                      return Container(
                        margin: const EdgeInsets.only(left: 4),
                        width: activo ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: activo
                              ? acento
                              : (visitado
                                  ? acento.withValues(alpha: 0.5)
                                  : acento.withValues(alpha: 0.18)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Título grande con emoji
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      titulo,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: CraftHubColors.textoPrincipal(esOscuro),
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Mensaje
              Text(
                mensaje,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  height: 1.5,
                  color: CraftHubColors.textoSecundario(esOscuro),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: onSaltar,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    child: Text(
                      esUltimo ? 'Cerrar' : 'Saltar tour',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CraftHubColors.textoSecundario(esOscuro),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onSiguiente,
                    icon: Icon(
                      esUltimo
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(
                      esUltimo ? '¡Empezar!' : 'Siguiente',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: acento,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Puntita del globo apuntando hacia Crafty (que está abajo)
        CustomPaint(
          size: const Size(24, 14),
          painter: _PuntitaGloboPainter(
            color: CraftHubColors.panel(esOscuro),
            borde: acento.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

class _PuntitaGloboPainter extends CustomPainter {
  final Color color;
  final Color borde;

  _PuntitaGloboPainter({required this.color, required this.borde});

  @override
  void paint(Canvas canvas, Size size) {
    final camino = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(
      camino,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0),
      Paint()
        ..color = borde
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
