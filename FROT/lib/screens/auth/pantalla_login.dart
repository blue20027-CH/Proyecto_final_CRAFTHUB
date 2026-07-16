import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';
import '../../main.dart';
import '../../widgets/boton_primario.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/boton_google.dart';
import '../../services/servicio_auth.dart';
import '../../services/api_service.dart';
import '../comprador/inicio_comprador.dart';
import '../vendedor/pantalla_dashoard_vendedor.dart';
import 'pantalla_gustos.dart';

class PantallaLogin extends StatefulWidget {
  final String modo;

  const PantallaLogin({
    super.key,
    this.modo = 'Comprador',
  });

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final TextEditingController _ctrlEmail    = TextEditingController();
  final TextEditingController _ctrlPassword = TextEditingController();
  bool _verPassword  = false;
  bool _cargando     = false;
  late String _modoSeleccionado;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _modoSeleccionado = widget.modo;
  }

  @override
  void dispose() {
    _ctrlEmail.dispose();
    _ctrlPassword.dispose();
    super.dispose();
  }

  // ── API_HOOK: Lógica de inicio de sesión ────────────────────────────────────────────────────
  Future<void> _iniciarSesion() async {
    if (_ctrlEmail.text.trim().isEmpty || _ctrlPassword.text.isEmpty) {
      setState(() => _errorMensaje = 'auth.completa_campos');
      return;
    }

    setState(() { _cargando = true; _errorMensaje = null; });

    try {
      // ── SIMULACIÓN TEMPORAL (elimina cuando conectes FastAPI) ──
      final respuesta = await loginConEmailYPassword(
        _ctrlEmail.text.trim(),
        _ctrlPassword.text,
        modo: _modoSeleccionado,
      );

      if (respuesta == null || respuesta['success'] != true) {
        throw Exception('auth.no_pudo_iniciar_sesion');
      }

      if (mounted) {
        // ✅ CAMBIO #1: EXTRAER user_id de la respuesta
        final String userId = respuesta['user_id'] ?? '';
        
        final perfil = respuesta['perfil'] as Map<String, dynamic>? ?? {};
        final nombre = (perfil['nombre'] ?? respuesta['email'] ?? '').toString();
        final foto = (perfil['foto'] ?? perfil['foto_perfil'] ?? perfil['fotoUrl'] ?? perfil['avatar'] ?? '').toString();

        if (_modoSeleccionado == 'Vendedor') {
          final esOscuroActual = context.read<GestorTema>().esModoOscuro;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeVendedor(
                esOscuro: esOscuroActual,
                nombreVendedor: nombre,
                fotoPerfil: foto,
                userId: userId,  // ✅ NUEVO: para tutoriales, mis-videos, etc.
              ),
            ),
          );
        } else {
          // Las preferencias solo se piden una vez: si el usuario ya tiene
          // algo guardado, se salta directo al home sin volver a mostrarlas.
          bool yaTienePreferencias = false;
          try {
            final prefs = await ApiService.getPreferencias(userId);
            yaTienePreferencias =
                (prefs['provincias'] as List?)?.isNotEmpty == true ||
                (prefs['comarcas'] as List?)?.isNotEmpty == true ||
                (prefs['categorias'] as List?)?.isNotEmpty == true;
          } catch (_) {
            yaTienePreferencias = false;
          }

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => yaTienePreferencias
                  ? HomeComprador(userId: userId)
                  : PantallaIntereses(userId: userId),
            ),
          );
        }
      }

    } catch (e) {
      setState(() => _errorMensaje = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── API_HOOK: Inicio de sesión con Google ──────────────────────────────────────────────────
  Future<void> _iniciarSesionGoogle() async {
    setState(() { _cargando = true; _errorMensaje = null; });

    try {
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      setState(() => _errorMensaje = 'auth.error_google');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── API_HOOK: Recuperar contraseña ──────────────────────────────────────────────────────────
  Future<void> _recuperarPassword() async {
    if (_ctrlEmail.text.trim().isEmpty) {
      setState(() => _errorMensaje = 'auth.ingresa_correo_recuperar');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = context.watch<GestorTema>().esModoOscuro;

    return Scaffold(
      body: SizedBox.expand(
        child: Row(
          children: [

            // ── LADO IZQUIERDO: imagen + degradado ──────────────────────────────
            Expanded(
              flex: 55,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/fondo_in.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: esOscuro
                              ? [
                                  CraftHubColors.fondoOscuro,
                                  CraftHubColors.fondoOscuro.withValues(alpha: 0.92),
                                  CraftHubColors.fondoOscuro.withValues(alpha: 0.55),
                                  Colors.transparent,
                                ]
                              : [
                                  CraftHubColors.fondoClaro,
                                  CraftHubColors.fondoClaro.withValues(alpha: 0.92),
                                  CraftHubColors.fondoClaro.withValues(alpha: 0.55),
                                  Colors.transparent,
                                ],
                          stops: const [0.0, 0.15, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── LADO DERECHO: panel login (sin scroll, altura fija) ─────────────
            Expanded(
              flex: 45,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                color: esOscuro
                    ? CraftHubColors.fondoOscuro
                    : CraftHubColors.fondoClaro,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: _PanelLogin(
                        esOscuro: esOscuro,
                        ctrlEmail: _ctrlEmail,
                        ctrlPassword: _ctrlPassword,
                        verPassword: _verPassword,
                        cargando: _cargando,
                        errorMensaje: _errorMensaje,
                        modoSeleccionado: _modoSeleccionado,
                        alCambiarModo: (modo) =>
                            setState(() => _modoSeleccionado = modo),
                        alAlternarPassword: () =>
                            setState(() => _verPassword = !_verPassword),
                        alIniciarSesion: _iniciarSesion,
                        alIniciarGoogle: _iniciarSesionGoogle,
                        alRecuperarPassword: _recuperarPassword,
                      ),
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
}

class _PanelLogin extends StatelessWidget {
  final bool esOscuro;
  final TextEditingController ctrlEmail;
  final TextEditingController ctrlPassword;
  final bool verPassword;
  final bool cargando;
  final String? errorMensaje;
  final String modoSeleccionado;
  final ValueChanged<String> alCambiarModo;
  final VoidCallback alAlternarPassword;
  final VoidCallback alIniciarSesion;
  final VoidCallback alIniciarGoogle;
  final VoidCallback alRecuperarPassword;

  const _PanelLogin({
    required this.esOscuro,
    required this.ctrlEmail,
    required this.ctrlPassword,
    required this.verPassword,
    required this.cargando,
    required this.errorMensaje,
    required this.modoSeleccionado,
    required this.alCambiarModo,
    required this.alAlternarPassword,
    required this.alIniciarSesion,
    required this.alIniciarGoogle,
    required this.alRecuperarPassword,
  });

  @override
  Widget build(BuildContext context) {
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec   = CraftHubColors.textoSecundario(esOscuro);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        Align(
          alignment: Alignment.centerLeft,
          child: _BotonVolver(esOscuro: esOscuro),
        ),

        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              CraftHubColors.logoPath(esOscuro),
              width: 44,
              height: 44,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'CRAFT',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colorTexto,
                          letterSpacing: 1.5,
                          height: 1.0,
                        ),
                      ),
                      const TextSpan(
                        text: 'HUB',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: CraftHubColors.vinoTinto,
                          letterSpacing: 1.5,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr(context, 'auth.creatividad_proposito'),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: colorSec,
                    letterSpacing: 0.2,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 22),

        Text(
          tr(context, 'auth.inicia_sesion_continuar'),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: colorSec,
          ),
        ),

        const SizedBox(height: 16),

        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'Comprador', label: Text(tr(context, 'auth.rol_comprador'))),
            ButtonSegment(value: 'Vendedor', label: Text(tr(context, 'auth.rol_vendedor'))),
          ],
          selected: {modoSeleccionado},
          onSelectionChanged: (seleccion) => alCambiarModo(seleccion.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? CraftHubColors.vinoTinto
                    : Colors.transparent),
            foregroundColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? Colors.white
                    : CraftHubColors.textoPrincipal(esOscuro)),
            side: WidgetStateProperty.all(
              BorderSide(color: CraftHubColors.vinoTinto.withValues(alpha: 0.4)),
            ),
          ),
        ),

        const SizedBox(height: 16),
        CampoTexto(
          controlador: ctrlEmail,
          hint: tr(context, 'auth.correo_usuario_hint'),
          icono: Icons.person_outline_rounded,
          esOscuro: esOscuro,
        ),

        const SizedBox(height: 10),

        CampoTexto(
          controlador: ctrlPassword,
          hint: tr(context, 'auth.contrasena_hint'),
          icono: Icons.lock_outline_rounded,
          esOscuro: esOscuro,
          esPassword: true,
          verPassword: verPassword,
          alAlternarVisibilidad: alAlternarPassword,
        ),

        const SizedBox(height: 6),

        if (errorMensaje != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              tr(context, errorMensaje!),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.redAccent,
              ),
            ),
          ),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: alRecuperarPassword,
            style: TextButton.styleFrom(
              foregroundColor: CraftHubColors.vinoTinto,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              tr(context, 'auth.olvidaste_contrasena'),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: CraftHubColors.vinoTinto,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        cargando
            ? const SizedBox(
                height: 48,
                child: Center(
                  child: CircularProgressIndicator(
                    color: CraftHubColors.vinoTinto,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : BotonPrimario(
                texto: tr(context, 'auth.entrar'),
                alPresionar: alIniciarSesion,
                ancho: double.infinity,
              ),

        const SizedBox(height: 16),

        _Separador(esOscuro: esOscuro),

        const SizedBox(height: 16),

        BotonGoogle(
          esOscuro: esOscuro,
          alPresionar: alIniciarGoogle,
        ),

        const SizedBox(height: 110),

        _BadgesConfianza(esOscuro: esOscuro),

      ],
    );
  }
}

class _BotonVolver extends StatefulWidget {
  final bool esOscuro;
  const _BotonVolver({required this.esOscuro});

  @override
  State<_BotonVolver> createState() => _BotonVolverState();
}

class _BotonVolverState extends State<_BotonVolver> {
  bool _sobreEl = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobreEl = true),
      onExit:  (_) => setState(() => _sobreEl = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _sobreEl
                ? (widget.esOscuro
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: CraftHubColors.textoPrincipal(widget.esOscuro),
              ),
              const SizedBox(width: 6),
              Text(
                tr(context, 'auth.volver'),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: CraftHubColors.textoPrincipal(widget.esOscuro),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Separador extends StatelessWidget {
  final bool esOscuro;
  const _Separador({required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    final colorLinea = esOscuro
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.10);

    return Row(
      children: [
        Expanded(child: Divider(color: colorLinea, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            tr(context, 'auth.o_continua_con'),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: CraftHubColors.textoSecundario(esOscuro),
            ),
          ),
        ),
        Expanded(child: Divider(color: colorLinea, thickness: 1)),
      ],
    );
  }
}

class _BadgesConfianza extends StatelessWidget {
  final bool esOscuro;
  const _BadgesConfianza({required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    final colorSec = CraftHubColors.textoSecundario(esOscuro);

    final badges = [
      (Icons.verified_user_outlined, tr(context, 'auth.badge_seguro_titulo'),  tr(context, 'auth.badge_seguro_subtitulo')),
      (Icons.group_outlined,          tr(context, 'auth.badge_comunidad_titulo'),  tr(context, 'auth.badge_comunidad_subtitulo')),
      (Icons.handshake_outlined,      tr(context, 'auth.badge_apoya_titulo'),  tr(context, 'auth.badge_apoya_subtitulo')),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: badges.map((b) {
        return Expanded(
          child: Column(
            children: [
              Icon(b.$1, size: 18, color: CraftHubColors.vinoTinto),
              const SizedBox(height: 5),
              Text(
                b.$2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: CraftHubColors.textoPrincipal(esOscuro),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                b.$3,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  color: colorSec,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}