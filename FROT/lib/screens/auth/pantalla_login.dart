import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';
import '../../widgets/boton_primario.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/boton_google.dart';
import '../../services/servicio_auth.dart';
import '../comprador/inicio_comprador.dart';
import '../vendedor/pantalla_dashoard_vendedor.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// SERVICIO DE AUTENTICACIÃ“N â€” conecta con FastAPI
// Crea este archivo en: lib/services/servicio_auth.dart
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class ServicioAuth {
//   static const String _baseUrl = 'http://TU_IP:8000'; // â† Cambia por tu URL FastAPI
//
//   /// POST /auth/login â†’ retorna token JWT + rol del usuario
//   static Future<Map<String, dynamic>> iniciarSesion(String email, String password) async {
//     final res = await http.post(
//       Uri.parse('$_baseUrl/auth/login'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email, 'password': password}),
//     );
//     if (res.statusCode == 200) return jsonDecode(res.body);
//     throw Exception(jsonDecode(res.body)['detail'] ?? 'Error al iniciar sesiÃ³n');
//   }
//
// /// POST /auth/google â†’ recibe token de Google, retorna JWT propio
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
//   /// POST /auth/reset-password â†’ envÃ­a email de recuperaciÃ³n
//   static Future<void> solicitarResetPassword(String email) async {
//     await http.post(
//       Uri.parse('$_baseUrl/auth/reset-password'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email}),
//     );
//   }
// }

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

  // â”€â”€ API_HOOK: LÃ³gica de inicio de sesiÃ³n â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _iniciarSesion() async {
    if (_ctrlEmail.text.trim().isEmpty || _ctrlPassword.text.isEmpty) {
      setState(() => _errorMensaje = 'Por favor completa todos los campos.');
      return;
    }

    setState(() { _cargando = true; _errorMensaje = null; });

    try {
      // CONECTAR CON FASTAPI â€” descomenta cuando tengas el servicio listo:
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
      // // Navega segÃºn el rol:
      // if (rol == 'vendedor') {
      //   Navigator.pushReplacementNamed(context, '/dashboard-vendedor');
      // } else {
      //   Navigator.pushReplacementNamed(context, '/catalogo');
      // }

      // â”€â”€ SIMULACIÃ“N TEMPORAL (elimina cuando conectes FastAPI) â”€â”€
      final respuesta = await loginConEmailYPassword(
        _ctrlEmail.text.trim(),
        _ctrlPassword.text,
        modo: _modoSeleccionado,
      );

      if (respuesta == null || respuesta['success'] != true) {
        throw Exception('No se pudo iniciar sesion.');
      }

      if (mounted) {
        final perfil = respuesta['perfil'] as Map<String, dynamic>? ?? {};
        final nombre = (perfil['nombre'] ?? respuesta['email'] ?? '').toString();
        final foto = (perfil['foto_perfil'] ?? perfil['fotoUrl'] ?? perfil['avatar'] ?? '').toString();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => _modoSeleccionado == 'Vendedor'
                ? HomeVendedor(
                    esOscuro: context.read<GestorTema>().esModoOscuro,
                    nombreVendedor: nombre,
                    fotoPerfil: foto,
                  )
                : const HomeComprador(),
          ),
        );
      }

    } catch (e) {
      setState(() => _errorMensaje = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // â”€â”€ API_HOOK: Inicio de sesiÃ³n con Google â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _iniciarSesionGoogle() async {
    setState(() { _cargando = true; _errorMensaje = null; });

    try {
      // 1. ObtÃ©n el token de Google con google_sign_in package
      // final googleUser = await GoogleSignIn().signIn();
      // final googleAuth = await googleUser?.authentication;
      // final tokenGoogle = googleAuth?.idToken ?? '';
      //
      // 2. EnvÃ­alo a tu FastAPI:
      // final respuesta = await ServicioAuth.iniciarSesionGoogle(tokenGoogle);
      // final String token = respuesta['access_token'];
      // final String rol   = respuesta['rol'];
      // ...navega segÃºn rol

      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      setState(() => _errorMensaje = 'Error al iniciar con Google.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // â”€â”€ API_HOOK: Recuperar contraseÃ±a â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _recuperarPassword() async {
    if (_ctrlEmail.text.trim().isEmpty) {
      setState(() => _errorMensaje = 'Ingresa tu correo primero para recuperar la contraseÃ±a.');
      return;
    }
    // await ServicioAuth.solicitarResetPassword(_ctrlEmail.text.trim());
    // Muestra confirmaciÃ³n al usuario con toastification
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = context.watch<GestorTema>().esModoOscuro;

    return Scaffold(
      body: SizedBox.expand( // â† Ocupa toda la pantalla sin scroll
        child: Row(
          children: [

            // â”€â”€ LADO IZQUIERDO: imagen + degradado â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                  // y se extiende generosamente para no dejar lÃ­nea visible
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
                          // â† Stops extendidos: el color sÃ³lido llega
                          // hasta 0.5 del ancho, sin corte visible
                          stops: const [0.0, 0.15, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // â”€â”€ LADO DERECHO: panel login (sin scroll, altura fija) â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PANEL PRINCIPAL â€” sin scroll, todo compacto
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
      mainAxisSize: MainAxisSize.min, // â† Sin scroll: se ajusta al contenido
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        // â”€â”€ BOTÃ“N VOLVER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Align(
          alignment: Alignment.centerLeft,
          child: _BotonVolver(esOscuro: esOscuro),
        ),

        const SizedBox(height: 14),

        // â”€â”€ LOGO + NOMBRE + ESLOGAN EN ROW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                  'Creatividad con propÃ³sito',
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

        // â”€â”€ SUBTÃTULO (sin "Bienvenido de nuevo") â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Text(
          'Inicia sesiÃ³n para continuar',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: colorSec,
          ),
        ),

        const SizedBox(height: 16),

        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Comprador', label: Text('Comprador')),
            ButtonSegment(value: 'Vendedor', label: Text('Vendedor')),
          ],
          selected: {modoSeleccionado},
          onSelectionChanged: (seleccion) => alCambiarModo(seleccion.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
          ),
        ),

        const SizedBox(height: 16),
        CampoTexto(
          controlador: ctrlEmail,
          hint: 'Correo o usuario',
          icono: Icons.person_outline_rounded,
          esOscuro: esOscuro,
        ),

        const SizedBox(height: 10),

        // â”€â”€ CAMPO PASSWORD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        CampoTexto(
          controlador: ctrlPassword,
          hint: 'ContraseÃ±a',
          icono: Icons.lock_outline_rounded,
          esOscuro: esOscuro,
          esPassword: true,
          verPassword: verPassword,
          alAlternarVisibilidad: alAlternarPassword,
        ),

        const SizedBox(height: 6),

        // â”€â”€ MENSAJE DE ERROR (visible solo si hay error) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

        // â”€â”€ OLVIDÃ‰ CONTRASEÃ‘A â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: alRecuperarPassword, // â† API_HOOK
            style: TextButton.styleFrom(
              foregroundColor: CraftHubColors.vinoTinto,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Â¿Olvidaste tu contraseÃ±a?',
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

        // â”€â”€ BOTÃ“N ENTRAR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        // API_HOOK: llama a _iniciarSesion() â†’ ServicioAuth.iniciarSesion()
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

        // â”€â”€ SEPARADOR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        _Separador(esOscuro: esOscuro),

        const SizedBox(height: 16),

        // â”€â”€ BOTÃ“N GOOGLE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        // API_HOOK: llama a _iniciarSesionGoogle() â†’ ServicioAuth.iniciarSesionGoogle()
        BotonGoogle(
          esOscuro: esOscuro,
          alPresionar: alIniciarGoogle,
        ),

        const SizedBox(height: 110),

        // â”€â”€ BADGES DE CONFIANZA â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        _BadgesConfianza(esOscuro: esOscuro),

      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// BOTÃ“N VOLVER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// SEPARADOR
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
            'o continÃºa con',
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// BADGES DE CONFIANZA
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _BadgesConfianza extends StatelessWidget {
  final bool esOscuro;
  const _BadgesConfianza({required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    final colorSec = CraftHubColors.textoSecundario(esOscuro);

    final badges = [
      (Icons.verified_user_outlined, 'Seguro y confiable',  'Tu informaciÃ³n estÃ¡ protegida'),
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

