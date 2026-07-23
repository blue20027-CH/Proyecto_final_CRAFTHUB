import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models_chat.dart';
import '../../services/chat_api_service.dart';

// Tinte dorado que se aplica a la rana Crafty para que el color se vea más
// vibrante y luminoso. `BlendMode.modulate` multiplica los píxeles de la
// imagen por este color: los tonos dorados existentes se intensifican y las
// zonas blancas se tiñen ligeramente de dorado, sin afectar los transparentes.
const Color _kTinteDorado = Color(0xFFFFD86A);

// Envuelve una imagen de Crafty con el tinte dorado.
Widget _craftyImagen(String ruta, {double? size, Widget? fallback}) {
  return ColorFiltered(
    colorFilter: const ColorFilter.mode(_kTinteDorado, BlendMode.modulate),
    child: Image.asset(
      ruta,
      fit: BoxFit.contain,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => fallback ?? const Icon(
        Icons.auto_awesome_rounded,
        color: Color(0xFFF5C542),
        size: 20,
      ),
    ),
  );
}

/// Botón flotante "Crafty" (asistente IA) que se puede arrastrar por toda la
/// pantalla y, al tocarlo, abre un panel de chat superpuesto con el mismo
/// fondo/estilo que el chat directo, pero con acentos que dejan claro que es IA.
///
/// Se pinta encima de todo el contenido de la app (se usa como raíz del
/// Scaffold: `body: BotonFlotanteIA(userId, nombre, child: ...)`).
///
/// La imagen del logo (rana) la pone el usuario después en
/// `assets/images/crafty_ia.png` — mientras no exista, se muestra un
/// placeholder circular con el degradado de marca.
class BotonFlotanteIA extends StatefulWidget {
  final String userId;
  final String nombreUsuario;
  final Widget child;

  const BotonFlotanteIA({
    super.key,
    required this.userId,
    required this.nombreUsuario,
    required this.child,
  });

  @override
  State<BotonFlotanteIA> createState() => _BotonFlotanteIAState();
}

class _BotonFlotanteIAState extends State<BotonFlotanteIA>
    with SingleTickerProviderStateMixin {
  static const double _tamBoton = 64;
  static const double _margen = 12;
  static const double _panelAncho = 440;
  static const double _panelAlto = 580;

  // Posición del botón (esquina superior-izquierda). Se recuerda entre
  // apertura/cierre del panel y entre cambios de pantalla dentro del mismo shell.
  Offset? _pos;
  bool _abierto = false;

  late final AnimationController _pulso;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  Offset _posInicial(Size s) => Offset(
        s.width - _tamBoton - _margen - 6,
        s.height - _tamBoton - _margen - 90,
      );

  Offset _clamp(Offset p, Size s) {
    final maxX = s.width - _tamBoton - _margen;
    final maxY = s.height - _tamBoton - _margen;
    return Offset(
      p.dx.clamp(_margen, maxX < _margen ? _margen : maxX),
      p.dy.clamp(_margen, maxY < _margen ? _margen : maxY),
    );
  }

  // El panel se ancla al botón: intenta abrirse arriba-a-la-izquierda del
  // botón y, si no cabe, se acomoda hacia el lado con más espacio.
  Offset _posPanel(Offset botonPos, Size s) {
    double x = botonPos.dx + _tamBoton - _panelAncho;
    double y = botonPos.dy - _panelAlto - 8;
    if (x < _margen) x = _margen;
    if (x + _panelAncho > s.width - _margen) {
      x = s.width - _margen - _panelAncho;
    }
    if (y < _margen) {
      y = botonPos.dy + _tamBoton + 8;
      if (y + _panelAlto > s.height - _margen) {
        y = math.max(_margen, s.height - _margen - _panelAlto);
      }
    }
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final pos = _clamp(_pos ?? _posInicial(size), size);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final visible = widget.userId.isNotEmpty;
        return Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (visible && _abierto)
              Positioned(
                left: _posPanel(pos, size).dx,
                top: _posPanel(pos, size).dy,
                width: _panelAncho,
                height: _panelAlto,
                child: _PanelCrafty(
                  isDark: isDark,
                  userId: widget.userId,
                  nombreUsuario: widget.nombreUsuario,
                  alCerrar: () => setState(() => _abierto = false),
                ),
              ),
            if (visible)
              Positioned(
                left: pos.dx,
                top: pos.dy,
                child: _BotonArrastrable(
                  tam: _tamBoton,
                  pulso: _pulso,
                  abierto: _abierto,
                  alArrastrar: (delta) {
                    setState(() => _pos = _clamp(pos + delta, size));
                  },
                  alTocar: () => setState(() => _abierto = !_abierto),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BotonArrastrable extends StatefulWidget {
  final double tam;
  final AnimationController pulso;
  final bool abierto;
  final ValueChanged<Offset> alArrastrar;
  final VoidCallback alTocar;

  const _BotonArrastrable({
    required this.tam,
    required this.pulso,
    required this.abierto,
    required this.alArrastrar,
    required this.alTocar,
  });

  @override
  State<_BotonArrastrable> createState() => _BotonArrastrableState();
}

class _BotonArrastrableState extends State<_BotonArrastrable> {
  Offset _inicioPan = Offset.zero;
  bool _arrastrando = false;

  // Expresiones que se turnan según lo que pase con Crafty:
  //   crafty_ia (sonriente)   → estado por defecto, tranquila
  //   crafty_gritando         → drag rápido
  //   crafty_curiosa          → drag suave
  //   crafty_hablando         → recién soltada (aterrizando)
  //   crafty_dormida          → sin actividad más de _tiempoDormir
  String _rutaExpresion = 'assets/images/crafty_ia.png';
  double _rotacion = 0;
  double _escala = 1;
  double _velocidad = 0;
  DateTime _ultimoMove = DateTime.now();

  Timer? _timerDormir;
  static const _tiempoDormir = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _programarDormir();
  }

  @override
  void dispose() {
    _timerDormir?.cancel();
    super.dispose();
  }

  // Cada vez que hay actividad se reinicia el timer: si pasa el tiempo sin
  // que la muevan ni toquen, Crafty pone cara de dormida.
  void _programarDormir() {
    _timerDormir?.cancel();
    _timerDormir = Timer(_tiempoDormir, () {
      if (!mounted || _arrastrando) return;
      _cambiarExpresion('assets/images/crafty_dormida.png');
    });
  }

  void _despertar() {
    if (_rutaExpresion == 'assets/images/crafty_dormida.png') {
      _cambiarExpresion('assets/images/crafty_ia.png');
    }
    _programarDormir();
  }

  void _cambiarExpresion(String r) {
    if (_rutaExpresion != r) setState(() => _rutaExpresion = r);
  }

  void _actualizarPorArrastre(DragUpdateDetails d) {
    final ahora = DateTime.now();
    final dt = ahora.difference(_ultimoMove).inMicroseconds / 1e6;
    _ultimoMove = ahora;
    final v = dt > 0 ? d.delta.distance / dt : 0.0;
    // Suavizado exponencial: la velocidad no salta bruscamente.
    _velocidad = _velocidad * 0.6 + v * 0.4;

    // Inclinación tipo "bamboleo" y ligero achatado por la aceleración.
    final rot = (d.delta.dx / 60).clamp(-0.35, 0.35);
    setState(() {
      _rotacion = rot;
      _escala = 1 + (_velocidad / 4000).clamp(0.0, 0.15);
      _rutaExpresion = _velocidad > 900
          ? 'assets/images/crafty_gritando.png'
          : 'assets/images/crafty_curiosa.png';
    });
  }

  void _aterrizar() {
    _cambiarExpresion('assets/images/crafty_hablando.png');
    setState(() {
      _rotacion = 0;
      _escala = 1;
      _velocidad = 0;
    });
    // Después de un momento vuelve a la expresión neutral sonriente.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _cambiarExpresion('assets/images/crafty_ia.png');
    });
    _programarDormir();
  }

  @override
  Widget build(BuildContext context) {
    // No se usa onTap junto con onPan* porque el reconocedor de pan
    // reclama la arena de gestos al primer contacto y onTap nunca dispara.
    // En su lugar se detecta el tap manualmente: si el gesto termina sin
    // haber superado el umbral de arrastre, se considera un toque.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) {
        _inicioPan = d.globalPosition;
        _arrastrando = false;
        _ultimoMove = DateTime.now();
        _despertar();
      },
      onPanUpdate: (d) {
        if (!_arrastrando &&
            (d.globalPosition - _inicioPan).distance > 4) {
          _arrastrando = true;
        }
        if (_arrastrando) {
          widget.alArrastrar(d.delta);
          _actualizarPorArrastre(d);
        }
      },
      onPanEnd: (_) {
        if (!_arrastrando) {
          widget.alTocar();
        } else {
          _aterrizar();
        }
        _arrastrando = false;
      },
      onPanCancel: () {
        if (_arrastrando) _aterrizar();
        _arrastrando = false;
      },
      child: AnimatedBuilder(
        animation: widget.pulso,
        builder: (_, __) {
          final t = widget.pulso.value;
          return SizedBox(
            width: widget.tam + 16,
            height: widget.tam + 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Halo dorado pulsante — señal visual de que es IA (especial).
                Container(
                  width: widget.tam + 12 + t * 8,
                  height: widget.tam + 12 + t * 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFF5C542).withValues(alpha: 0.35 - t * 0.15),
                        const Color(0xFFF5C542).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: widget.tam,
                  height: widget.tam,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CraftHubColors.vinoTintoClaro,
                        CraftHubColors.vinoTinto,
                        CraftHubColors.vinoTintoOscuro,
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFF5C542),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CraftHubColors.sombra(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      // Crafty reacciona al arrastre: cambia de expresión y
                      // se inclina/escala con un pequeño bamboleo. Al soltar,
                      // aterriza suavemente y vuelve a su cara sonriente.
                      child: AnimatedScale(
                        scale: _escala,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        child: AnimatedRotation(
                          turns: _rotacion / (2 * math.pi),
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOutBack,
                            switchOutCurve: Curves.easeIn,
                            child: KeyedSubtree(
                              key: ValueKey(_rutaExpresion),
                              child: _craftyImagen(
                                _rutaExpresion,
                                fallback: const Center(
                                  child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFF5C542), size: 30),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Punto verde de "en línea" — refuerza que la IA está lista.
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PanelCrafty extends StatefulWidget {
  final bool isDark;
  final String userId;
  final String nombreUsuario;
  final VoidCallback alCerrar;

  const _PanelCrafty({
    required this.isDark,
    required this.userId,
    required this.nombreUsuario,
    required this.alCerrar,
  });

  @override
  State<_PanelCrafty> createState() => _PanelCraftyState();
}

class _PanelCraftyState extends State<_PanelCrafty> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();
  final FocusNode _foco = FocusNode();

  List<MensajeModelo> _mensajes = [];
  String? _conversacionId;
  bool _cargando = true;
  bool _respondiendo = false;
  String? _error;
  // Cuando Crafty acaba de dar una respuesta exitosa, pone cara de "enamorada"
  // por un momento (♥) antes de volver a la sonriente — feedback positivo.
  bool _enamorada = false;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    _foco.dispose();
    super.dispose();
  }

  // Prepara la conversación con el bot y trae el historial (incluye el
  // mensaje de bienvenida que persiste el backend la primera vez).
  Future<void> _iniciar() async {
    try {
      await ChatApiService.abrirChatbot(widget.userId, widget.nombreUsuario);
      final convs = await ChatApiService.cargarConversaciones(widget.userId);
      final bot = convs.firstWhere(
        (c) => ChatApiService.esBotIA(c.nombreContacto),
        orElse: () => throw Exception('No se encontró la conversación de Crafty.'),
      );
      final mensajes = await ChatApiService.cargarMensajes(bot.id, widget.userId);
      if (!mounted) return;
      setState(() {
        _conversacionId = bot.id;
        _mensajes = mensajes;
        _cargando = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _bajar());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _cargando = false;
      });
    }
  }

  void _bajar() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _enviar() async {
    final texto = _input.text.trim();
    final convId = _conversacionId;
    if (texto.isEmpty || convId == null || _respondiendo) return;
    _input.clear();
    setState(() {
      _mensajes.add(MensajeModelo(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        contenido: texto,
        tipo: TipoMensaje.texto,
        esMio: true,
        hora: DateTime.now(),
        leido: true,
      ));
      _respondiendo = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _bajar());
    try {
      final respuesta = await ChatApiService.enviarMensajeChatbot(
        conversacionId: convId,
        usuarioId: widget.userId,
        usuarioNombre: widget.nombreUsuario,
        mensaje: texto,
      );
      if (!mounted) return;
      setState(() {
        _mensajes.add(MensajeModelo(
          id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
          contenido: respuesta,
          tipo: TipoMensaje.texto,
          esMio: false,
          hora: DateTime.now(),
          leido: true,
        ));
        _enamorada = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _bajar());
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _enamorada = false);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _respondiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: CraftHubColors.panel(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF5C542).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: CraftHubColors.sombra(0.35),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _CabeceraCrafty(
              isDark: isDark,
              respondiendo: _respondiendo,
              enamorada: _enamorada,
              alCerrar: widget.alCerrar,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? CraftHubColors.fondoOscuro
                      : const Color(0xFFF5EFE9),
                  image: construirFondoChat(isDark),
                ),
                child: _cargando
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: CraftHubColors.vinoTinto,
                        ),
                      )
                    : _error != null
                        ? _Error(mensaje: _error!, isDark: isDark, alReintentar: () {
                            setState(() {
                              _error = null;
                              _cargando = true;
                            });
                            _iniciar();
                          })
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            itemCount:
                                _mensajes.length + (_respondiendo ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == _mensajes.length) {
                                return _Escribiendo(isDark: isDark);
                              }
                              final m = _mensajes[i];
                              return _Burbuja(mensaje: m, isDark: isDark);
                            },
                          ),
              ),
            ),
            _InputCrafty(
              isDark: isDark,
              controlador: _input,
              foco: _foco,
              deshabilitado: _cargando || _error != null,
              alEnviar: _enviar,
            ),
          ],
        ),
      ),
    );
  }
}

class _CabeceraCrafty extends StatelessWidget {
  final bool isDark;
  final bool respondiendo;
  final bool enamorada;
  final VoidCallback alCerrar;
  const _CabeceraCrafty({
    required this.isDark,
    required this.respondiendo,
    required this.enamorada,
    required this.alCerrar,
  });

  String get _rutaExpresion {
    if (respondiendo) return 'assets/images/crafty_hablando.png';
    if (enamorada) return 'assets/images/crafty_enamorada.png';
    return 'assets/images/crafty_ia.png';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CraftHubColors.vinoTintoClaro,
            CraftHubColors.vinoTinto,
            CraftHubColors.vinoTintoOscuro,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CraftHubColors.vinoTintoOscuro,
              border: Border.all(
                color: const Color(0xFFF5C542),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(4),
                // Crafty en el header: si está generando respuesta, cambia a
                // la expresión "hablando" (boca abierta) para transmitir que
                // está trabajando; si no, muestra la expresión sonriente.
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey(_rutaExpresion),
                    child: _craftyImagen(_rutaExpresion),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Crafty',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5C542),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: CraftHubColors.vinoTintoOscuro,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Tu asistente de CraftHub',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: alCerrar,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  final MensajeModelo mensaje;
  final bool isDark;
  const _Burbuja({required this.mensaje, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final esMio = mensaje.esMio;
    final colorFondo = esMio
        ? CraftHubColors.vinoTinto
        : (isDark ? CraftHubColors.panelOscuro2 : Colors.white);
    final colorTexto = esMio
        ? Colors.white
        : CraftHubColors.textoPrincipal(isDark);
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!esMio) _AvatarMini(isDark: isDark),
          if (!esMio) const SizedBox(width: 6),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: colorFondo,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(esMio ? 16 : 4),
                  bottomRight: Radius.circular(esMio ? 4 : 16),
                ),
                border: esMio
                    ? null
                    : Border.all(
                        color: CraftHubColors.borde(isDark),
                        width: 0.8,
                      ),
              ),
              child: Text(
                mensaje.contenido,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  height: 1.4,
                  color: colorTexto,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarMini extends StatelessWidget {
  final bool isDark;
  const _AvatarMini({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CraftHubColors.vinoTintoOscuro,
        border: Border.all(
          color: const Color(0xFFF5C542),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: _craftyImagen(
            'assets/images/crafty_neutral.png',
            fallback: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFF5C542), size: 14),
          ),
        ),
      ),
    );
  }
}

class _Escribiendo extends StatelessWidget {
  final bool isDark;
  const _Escribiendo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? CraftHubColors.panelOscuro2 : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(
            color: CraftHubColors.borde(isDark),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Crafty con cara "hablando" mientras piensa la respuesta.
            SizedBox(
              width: 22,
              height: 22,
              child: ClipOval(
                child: _craftyImagen(
                  'assets/images/crafty_hablando.png',
                  fallback: Icon(
                    Icons.auto_awesome_rounded,
                    color: CraftHubColors.vinoTinto.withValues(alpha: 0.7),
                    size: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Crafty está escribiendo…',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: CraftHubColors.textoSecundario(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputCrafty extends StatelessWidget {
  final bool isDark;
  final TextEditingController controlador;
  final FocusNode foco;
  final bool deshabilitado;
  final VoidCallback alEnviar;

  const _InputCrafty({
    required this.isDark,
    required this.controlador,
    required this.foco,
    required this.deshabilitado,
    required this.alEnviar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(isDark),
        border: Border(
          top: BorderSide(color: CraftHubColors.borde(isDark)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            // Con `maxLines > 1` el TextField consume el Enter para hacer
            // salto de línea, así que interceptamos la tecla acá para mandar.
            // Shift+Enter sigue funcionando como salto de línea.
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed &&
                    !deshabilitado) {
                  alEnviar();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
              controller: controlador,
              focusNode: foco,
              enabled: !deshabilitado,
              onSubmitted: (_) => alEnviar(),
              minLines: 1,
              maxLines: 4,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: CraftHubColors.textoPrincipal(isDark),
              ),
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje…',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: CraftHubColors.textoSecundario(isDark),
                ),
                filled: true,
                fillColor: isDark
                    ? CraftHubColors.panelOscuro2
                    : CraftHubColors.fondoClaro,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: CraftHubColors.vinoTinto,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: deshabilitado ? null : alEnviar,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String mensaje;
  final bool isDark;
  final VoidCallback alReintentar;
  const _Error({required this.mensaje, required this.isDark, required this.alReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Crafty se molesta cuando algo falla — más simpático que un
            // ícono rojo genérico y mantiene la personalidad del asistente.
            SizedBox(
              width: 72,
              height: 72,
              child: _craftyImagen(
                'assets/images/crafty_molesta.png',
                fallback: const Icon(Icons.error_outline_rounded, size: 40, color: CraftHubColors.error),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: CraftHubColors.textoSecundario(isDark),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: alReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
