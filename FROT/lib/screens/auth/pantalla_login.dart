import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';
import '../../widgets/boton_primario.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/boton_google.dart';

// ─────────────────────────────────────────────────────────────
// SERVICIO DE AUTENTICACIÓN — conecta con FastAPI
// Crea este archivo en: lib/services/servicio_auth.dart
// ─────────────────────────────────────────────────────────────
//
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class ServicioAuth {
//   static const String _baseUrl = 'http://TU_IP:8000'; // ← Cambia por tu URL FastAPI
//
//   /// POST /auth/login → retorna token JWT + rol del usuario
//   static Future<Map<String, dynamic>> iniciarSesion(String email, String password) async {
//     final res = await http.post(
//       Uri.parse('$_baseUrl/auth/login'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email, 'password': password}),
//     );
//     if (res.statusCode == 200) return jsonDecode(res.body);
//     throw Exception(jsonDecode(res.body)['detail'] ?? 'Error al iniciar sesión');
//   }
//
// /// POST /auth/google → recibe token de Google, retorna JWT propio
//   static Future<Map<String, dynamic>> iniciarSesionGoogle(String tokenGoogle) async {
//     final res = await http.post(
//       Uri.parse('$_baseUrl/auth/google'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'token': tokenGoogle}),
//     );
//     if (res.statusCode == 200) return jsonDecode(res.body);
//     throw Exception('Error con Google Login');
//   }
//
//   /// POST /auth/reset-password → envía email de recuperación
//   static Future<void> solicitarResetPassword(String email) async {
//     await http.post(
//       Uri.parse('$_baseUrl/auth/reset-password'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email}),
//     );
//   }
// }

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final TextEditingController _ctrlEmail    = TextEditingController();
  final TextEditingController _ctrlPassword = TextEditingController();
  bool _verPassword  = false;
  bool _cargando     = false;
  String? _errorMensaje;

  @override
  void dispose() {
    _ctrlEmail.dispose();
    _ctrlPassword.dispose();
    super.dispose();
  }

  // ── API_HOOK: Lógica de inicio de sesión ─────────────────────────────────
  Future<void> _iniciarSesion() async {
    if (_ctrlEmail.text.trim().isEmpty || _ctrlPassword.text.isEmpty) {
      setState(() => _errorMensaje = 'Por favor completa todos los campos.');
      return;
    }

    setState(() { _cargando = true; _errorMensaje = null; });

    try {
      // CONECTAR CON FASTAPI — descomenta cuando tengas el servicio listo:
      //
      // final respuesta = await ServicioAuth.iniciarSesion(
      //   _ctrlEmail.text.trim(),
      //   _ctrlPassword.text,
      // );
      // final String token = respuesta['access_token'];
      // final String rol   = respuesta['rol']; // 'comprador' o 'vendedor'
      //
      // // Guarda el token (shared_preferences recomendado):
      // // await PrefsService.guardarToken(token);
      //
      // // Navega según el rol:
      // if (rol == 'vendedor') {
      //   Navigator.pushReplacementNamed(context, '/dashboard-vendedor');
      // } else {
      //   Navigator.pushReplacementNamed(context, '/catalogo');
      // }

      // ── SIMULACIÓN TEMPORAL (elimina cuando conectes FastAPI) ──
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pushReplacementNamed(context, '/catalogo');

    } catch (e) {
      setState(() => _errorMensaje = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── API_HOOK: Inicio de sesión con Google ────────────────────────────────
  Future<void> _iniciarSesionGoogle() async {
    setState(() { _cargando = true; _errorMensaje = null; });

    try {
      // 1. Obtén el token de Google con google_sign_in package
      // final googleUser = await GoogleSignIn().signIn();
      // final googleAuth = await googleUser?.authentication;
      // final tokenGoogle = googleAuth?.idToken ?? '';
      //
      // 2. Envíalo a tu FastAPI:
      // final respuesta = await ServicioAuth.iniciarSesionGoogle(tokenGoogle);
      // final String token = respuesta['access_token'];
      // final String rol   = respuesta['rol'];
      // ...navega según rol

      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      setState(() => _errorMensaje = 'Error al iniciar con Google.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── API_HOOK: Recuperar contraseña ───────────────────────────────────────
  Future<void> _recuperarPassword() async {
    if (_ctrlEmail.text.trim().isEmpty) {
      setState(() => _errorMensaje = 'Ingresa tu correo primero para recuperar la contraseña.');
      return;
    }
    // await ServicioAuth.solicitarResetPassword(_ctrlEmail.text.trim());
    // Muestra confirmación al usuario con toastification
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = context.watch<GestorTema>().esModoOscuro;

    return Scaffold(
      body: SizedBox.expand( // ← Ocupa toda la pantalla sin scroll
        child: Row(
          children: [

            // ── LADO IZQUIERDO: imagen + degradado ─────────────────────────
            Expanded(
              flex: 55,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/fondo_inicio.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                  // Degradado fusionado: arranca desde el borde derecho
                  // y se extiende generosamente para no dejar línea visible
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: esOscuro
                              ? [
                                  CraftHubColors.fondoOscuro,
                                  CraftHubColors.fondoOscuro.withOpacity(0.92),
                                  CraftHubColors.fondoOscuro.withOpacity(0.55),
                                  Colors.transparent,
                                ]
                              : [
                                  CraftHubColors.fondoClaro,
                                  CraftHubColors.fondoClaro.withOpacity(0.92),
                                  CraftHubColors.fondoClaro.withOpacity(0.55),
                                  Colors.transparent,
                                ],
                          // ← Stops extendidos: el color sólido llega
                          // hasta 0.5 del ancho, sin corte visible
                          stops: const [0.0, 0.15, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── LADO DERECHO: panel login (sin scroll, altura fija) ────────
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

// ─────────────────────────────────────────────────────────────
// PANEL PRINCIPAL — sin scroll, todo compacto
// ─────────────────────────────────────────────────────────────
class _PanelLogin extends StatelessWidget {
  final bool esOscuro;
  final TextEditingController ctrlEmail;
  final TextEditingController ctrlPassword;
  final bool verPassword;
  final bool cargando;
  final String? errorMensaje;
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
      mainAxisSize: MainAxisSize.min, // ← Sin scroll: se ajusta al contenido
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        // ── BOTÓN VOLVER ────────────────────────────────────────────────
        Align(
          alignment: Alignment.centerLeft,
          child: _BotonVolver(esOscuro: esOscuro),
        ),

        const SizedBox(height: 14),

        // ── LOGO + NOMBRE + ESLOGAN EN ROW ──────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo_crafthub.png',
              width: 44,
              height: 44,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            // Nombre y eslogan apilados verticalmente, proporcionales al logo
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
                          fontFamily: 'RocaTwo',
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
                          fontFamily: 'RocaTwo',
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
                  'Creatividad con propósito',
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

        // ── SUBTÍTULO (sin "Bienvenido de nuevo") ───────────────────────
        Text(
          'Inicia sesión para continuar',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: colorSec,
          ),
        ),

        const SizedBox(height: 22),

        // ── CAMPO EMAIL ─────────────────────────────────────────────────
        CampoTexto(
          controlador: ctrlEmail,
          hint: 'Correo o usuario',
          icono: Icons.person_outline_rounded,
          esOscuro: esOscuro,
        ),

        const SizedBox(height: 10),

        // ── CAMPO PASSWORD ──────────────────────────────────────────────
        CampoTexto(
          controlador: ctrlPassword,
          hint: 'Contraseña',
          icono: Icons.lock_outline_rounded,
          esOscuro: esOscuro,
          esPassword: true,
          verPassword: verPassword,
          alAlternarVisibilidad: alAlternarPassword,
        ),

        const SizedBox(height: 6),

        // ── MENSAJE DE ERROR (visible solo si hay error) ─────────────────
        if (errorMensaje != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              errorMensaje!,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.redAccent,
              ),
            ),
          ),

        // ── OLVIDÉ CONTRASEÑA ───────────────────────────────────────────
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: alRecuperarPassword, // ← API_HOOK
            style: TextButton.styleFrom(
              foregroundColor: CraftHubColors.vinoTinto,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '¿Olvidaste tu contraseña?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: CraftHubColors.vinoTinto,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── BOTÓN ENTRAR ────────────────────────────────────────────────
        // API_HOOK: llama a _iniciarSesion() → ServicioAuth.iniciarSesion()
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
                texto: 'Entrar',
                alPresionar: alIniciarSesion,
                ancho: double.infinity,
              ),

        const SizedBox(height: 16),

        // ── SEPARADOR ───────────────────────────────────────────────────
        _Separador(esOscuro: esOscuro),

        const SizedBox(height: 16),

        // ── BOTÓN GOOGLE ─────────────────────────────────────────────────
        // API_HOOK: llama a _iniciarSesionGoogle() → ServicioAuth.iniciarSesionGoogle()
        BotonGoogle(
          esOscuro: esOscuro,
          alPresionar: alIniciarGoogle,
        ),

        const SizedBox(height: 110),

        // ── BADGES DE CONFIANZA ──────────────────────────────────────────
        _BadgesConfianza(esOscuro: esOscuro),

      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTÓN VOLVER
// ─────────────────────────────────────────────────────────────
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
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05))
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
                'Volver',
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

// ─────────────────────────────────────────────────────────────
// SEPARADOR
// ─────────────────────────────────────────────────────────────
class _Separador extends StatelessWidget {
  final bool esOscuro;
  const _Separador({required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    final colorLinea = esOscuro
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.10);

    return Row(
      children: [
        Expanded(child: Divider(color: colorLinea, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'o continúa con',
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

// ─────────────────────────────────────────────────────────────
// BADGES DE CONFIANZA
// ─────────────────────────────────────────────────────────────
class _BadgesConfianza extends StatelessWidget {
  final bool esOscuro;
  const _BadgesConfianza({required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    final colorSec = CraftHubColors.textoSecundario(esOscuro);

    final badges = [
      (Icons.verified_user_outlined, 'Seguro y confiable',  'Tu información está protegida'),
      (Icons.group_outlined,          'Comunidad creativa',  'Conecta con artesanos'),
      (Icons.handshake_outlined,      'Apoya lo artesanal',  'Hecho a mano, hecho con amor'),
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