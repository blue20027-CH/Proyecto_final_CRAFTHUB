// Tour de bienvenida guiado por Crafty (la rana mascota).
// Se muestra encima del Scaffold como un overlay a página completa: fondo
// oscurecido para poner el foco, Crafty grande abajo a la derecha y un
// globo de texto arriba de ella con la explicación del paso actual y los
// botones Siguiente / Saltar.
//
// Los pasos son distintos para comprador y vendedor; ver `_pasosComprador`
// y `_pasosVendedor`. Cuando el usuario cambia de paso, el overlay puede
// pedirle a la pantalla que hace de host que navegue a la sección
// correspondiente vía el callback `onIrASeccion`.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// Mismo tinte dorado que el resto de la app (rana pintada) para que las
// imágenes de Crafty se vean parejas con el botón flotante y el header.
const Color _kTinteDorado = Color(0xFFFFD86A);

class PasoTutorial {
  /// Título corto (2-4 palabras) que va grande arriba del globo.
  final String titulo;

  /// Cuerpo del mensaje. Una o dos frases, en primera persona (Crafty
  /// hablando).
  final String mensaje;

  /// Índice de la pestaña del BottomNavigation/Sidebar al que hay que ir
  /// para mostrar este paso (0 = inicio, 1 = favoritos, etc). Si es null,
  /// el paso no cambia de pantalla — solo muestra el mensaje encima de la
  /// pantalla actual.
  final int? indiceSeccion;

  /// Cuál PNG de Crafty mostrar en este paso (para variar la expresión).
  final String rutaExpresion;

  const PasoTutorial({
    required this.titulo,
    required this.mensaje,
    required this.rutaExpresion,
    this.indiceSeccion,
  });
}

// ─── PASOS: COMPRADOR ────────────────────────────────────────────────────
const List<PasoTutorial> _pasosComprador = [
  PasoTutorial(
    titulo: '¡Hola! Soy Crafty 👋',
    mensaje:
        'Te voy a mostrar cómo usar CraftHub en un minuto. Podés saltar en cualquier momento.',
    rutaExpresion: 'assets/images/crafty_hablando.png',
  ),
  PasoTutorial(
    titulo: 'Explorá productos',
    mensaje:
        'Acá vas a ver todo lo hecho a mano por artesanos panameños. Filtrá por categoría o buscá algo específico.',
    rutaExpresion: 'assets/images/crafty_curiosa.png',
    indiceSeccion: 0,
  ),
  PasoTutorial(
    titulo: 'Guardá favoritos',
    mensaje:
        'Tocá el corazón en cualquier producto y lo vas a encontrar acá para volver después.',
    rutaExpresion: 'assets/images/crafty_enamorada.png',
    indiceSeccion: 1,
  ),
  PasoTutorial(
    titulo: 'Tu carrito',
    mensaje:
        'Todo lo que vayas a comprar se acumula acá. Al pagar podés elegir Yappy, PayPal o tarjeta.',
    rutaExpresion: 'assets/images/crafty_ia.png',
    indiceSeccion: 2,
  ),
  PasoTutorial(
    titulo: 'Hablá con artesanos',
    mensaje:
        'Podés preguntarle a un artesano sobre su producto, o hablarme a mí para ayuda general.',
    rutaExpresion: 'assets/images/crafty_hablando.png',
    indiceSeccion: 3,
  ),
  PasoTutorial(
    titulo: 'Y mucho más',
    mensaje:
        'Mapa de talleres, tutoriales en video, eventos… Explorá el menú lateral. ¡Éxitos!',
    rutaExpresion: 'assets/images/crafty_ia.png',
  ),
];

// ─── PASOS: VENDEDOR ─────────────────────────────────────────────────────
const List<PasoTutorial> _pasosVendedor = [
  PasoTutorial(
    titulo: '¡Bienvenido, artesano!',
    mensaje:
        'Soy Crafty, tu asistente. Te muestro las herramientas principales en un minuto.',
    rutaExpresion: 'assets/images/crafty_hablando.png',
  ),
  PasoTutorial(
    titulo: 'Tu dashboard',
    mensaje:
        'Acá ves ventas del mes, ingresos y qué productos son los que más se piden.',
    rutaExpresion: 'assets/images/crafty_curiosa.png',
    indiceSeccion: 0,
  ),
  PasoTutorial(
    titulo: 'Inventario',
    mensaje:
        'Agregá, editá o pausá tus productos. Cada uno puede tener fotos, precio, stock y tallas.',
    rutaExpresion: 'assets/images/crafty_ia.png',
    indiceSeccion: 1,
  ),
  PasoTutorial(
    titulo: 'Pedidos',
    mensaje:
        'Cuando alguien te compra, aparece acá. Podés marcar los estados (preparando, enviado, entregado).',
    rutaExpresion: 'assets/images/crafty_enamorada.png',
    indiceSeccion: 2,
  ),
  PasoTutorial(
    titulo: 'Editá tu perfil con IA',
    mensaje:
        'En Editar perfil podés pedirme que te escriba una descripción atractiva para tu marca. Solo tocá "✨ Mejorar con IA".',
    rutaExpresion: 'assets/images/crafty_hablando.png',
  ),
  PasoTutorial(
    titulo: 'Contá conmigo',
    mensaje:
        'Estoy en el botón flotante en cada pantalla. Preguntame lo que necesites. ¡A vender!',
    rutaExpresion: 'assets/images/crafty_ia.png',
  ),
];

/// Widget principal del tour. Se coloca encima del Scaffold usando un
/// `Overlay` o simplemente apilándolo en un Stack al hijo del Scaffold.
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
    with SingleTickerProviderStateMixin {
  int _paso = 0;
  late final AnimationController _pulso;

  List<PasoTutorial> get _pasos =>
      widget.rol.toLowerCase() == 'vendedor' ? _pasosVendedor : _pasosComprador;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  void _siguiente() {
    if (_paso >= _pasos.length - 1) {
      widget.onCerrar();
      return;
    }
    setState(() => _paso++);
    final indice = _pasos[_paso].indiceSeccion;
    if (indice != null) widget.onIrASeccion?.call(indice);
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
            // ── Fondo oscurecido para poner el foco ─────────────────────
            Positioned.fill(
              child: GestureDetector(
                onTap: _siguiente,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  color: Colors.black.withValues(alpha: 0.60),
                ),
              ),
            ),

            // ── Crafty grande abajo a la derecha + globo de texto ───────
            Positioned(
              right: 24,
              bottom: 24,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Globo de texto
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: _Globo(
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
                    const SizedBox(height: 12),
                    // Crafty grande + pulso dorado
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: AnimatedBuilder(
                        animation: _pulso,
                        builder: (_, __) {
                          final t = _pulso.value;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 140 + 20 * t,
                                height: 140 + 20 * t,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFFD86A)
                                      .withValues(alpha: 0.22 - 0.10 * t),
                                ),
                              ),
                              // Bamboleo suave para que se sienta viva
                              Transform.rotate(
                                angle: math.sin(t * math.pi) * 0.05,
                                child: ColorFiltered(
                                  colorFilter: const ColorFilter.mode(
                                      _kTinteDorado, BlendMode.modulate),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: KeyedSubtree(
                                      key: ValueKey(paso.rutaExpresion),
                                      child: Image.asset(
                                        paso.rutaExpresion,
                                        width: 120,
                                        height: 120,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Globo extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final int pasoActual;
  final int totalPasos;
  final bool esUltimo;
  final bool esOscuro;
  final VoidCallback onSaltar;
  final VoidCallback onSiguiente;

  const _Globo({
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
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cuerpo del globo
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          decoration: BoxDecoration(
            color: CraftHubColors.panel(esOscuro),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: acento.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contador arriba
              Text(
                'Paso $pasoActual de $totalPasos',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: acento,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                titulo,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: CraftHubColors.textoPrincipal(esOscuro),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mensaje,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  height: 1.45,
                  color: CraftHubColors.textoSecundario(esOscuro),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onSaltar,
                    child: Text(
                      esUltimo ? 'Cerrar' : 'Saltar',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: CraftHubColors.textoSecundario(esOscuro),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: onSiguiente,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: acento,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      esUltimo ? '¡Empezar!' : 'Siguiente',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Puntita del globo apuntando a Crafty
        Padding(
          padding: const EdgeInsets.only(right: 40),
          child: CustomPaint(
            size: const Size(18, 12),
            painter: _PuntitaGloboPainter(
              color: CraftHubColors.panel(esOscuro),
              borde: acento.withValues(alpha: 0.35),
            ),
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
      camino,
      Paint()
        ..color = borde
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
