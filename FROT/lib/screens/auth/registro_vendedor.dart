import 'package:flutter/material.dart';
import '../vendedor/pantalla_dashoard_vendedor.dart';
import '../../core/theme/app_theme.dart';
import '../../core/provincias_panama.dart';
import '../../services/servicio_auth.dart';
import '../../widgets/boton_primario.dart';
import '../../widgets/boton_google.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/campo_dropdown.dart';

class PantallaRegistroVendedor extends StatefulWidget {
  const PantallaRegistroVendedor({super.key});

  @override
  State<PantallaRegistroVendedor> createState() =>
      _PantallaRegistroVendedorState();
  
}

class _PantallaRegistroVendedorState extends State<PantallaRegistroVendedor> {
  // Controladores de texto
  final _ctrlNombres = TextEditingController();
  final _ctrlApellidos = TextEditingController();
  final _ctrlCorreo = TextEditingController();
  final _ctrlUsuario = TextEditingController();
  final _ctrlPassword = TextEditingController();
  final _ctrlTelefono = TextEditingController();
  final _ctrlUbicacion = TextEditingController();
  final _ctrlId = TextEditingController();
  final _ctrlFechaNacimiento = TextEditingController();

  // Estados
  bool _verPassword = false;
  bool _ofrecDelivery = true;
  String? _genero;
  String? _fechaNac;
  String? _provincia;
  bool _registrando = false;
  String? _errorMensaje;

  Future<void> _registrar() async {
    if (_ctrlNombres.text.trim().isEmpty ||
        _ctrlCorreo.text.trim().isEmpty ||
        _ctrlPassword.text.isEmpty) {
      setState(() => _errorMensaje = 'Completa nombre, correo y contraseña.');
      return;
    }
    if (_provincia == null) {
      setState(() => _errorMensaje = 'Selecciona tu provincia o comarca.');
      return;
    }

    setState(() { _registrando = true; _errorMensaje = null; });

    try {
      final nombreCompleto =
          '${_ctrlNombres.text.trim()} ${_ctrlApellidos.text.trim()}'.trim();

      final respuesta = await registrarConEmailYPassword(
        nombre: nombreCompleto,
        email: _ctrlCorreo.text.trim(),
        password: _ctrlPassword.text,
        rol: 'Vendedor',
        telefono: _ctrlTelefono.text.trim().isEmpty ? null : _ctrlTelefono.text.trim(),
        provincia: _provincia,
        ubicacion: _ctrlUbicacion.text.trim().isEmpty ? null : _ctrlUbicacion.text.trim(),
      );

      if (respuesta == null || respuesta['success'] != true) {
        throw Exception('No se pudo completar el registro.');
      }

      if (!mounted) return;

      final String userId = respuesta['user_id'] ?? '';
      final perfil = respuesta['perfil'] as Map<String, dynamic>? ?? {};
      final nombre = (perfil['nombre'] ?? nombreCompleto).toString();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeVendedor(
            esOscuro: false,
            nombreVendedor: nombre,
            userId: userId,
          ),
        ),
      );
    } catch (e) {
      setState(() => _errorMensaje = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  @override
  void dispose() {
    _ctrlNombres.dispose();
    _ctrlApellidos.dispose();
    _ctrlCorreo.dispose();
    _ctrlUsuario.dispose();
    _ctrlPassword.dispose();
    _ctrlTelefono.dispose();
    _ctrlUbicacion.dispose();
    _ctrlId.dispose();
    _ctrlFechaNacimiento.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Solo tema claro según indicación
    const esOscuro = false;

    return Scaffold(
      backgroundColor: CraftHubColors.fondoClaro,
      body: Row(
        children: [
          // ── LADO IZQUIERDO: imagen ──────────────────────────────────
          Expanded(
            flex: 45,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/fondo_inicio.png',
                  fit: BoxFit.cover,
                ),
                // Degradado desde la izquierda hacia la derecha
                // para fundirse con el panel blanco
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        CraftHubColors.fondoClaro.withValues(alpha: 0.5),
                        CraftHubColors.fondoClaro,
                      ],
                      stops: const [0.0, 0.65, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── LADO DERECHO: formulario ────────────────────────────────
          Expanded(
            flex: 55,
            child: Container(
              color: CraftHubColors.fondoClaro,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 56,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: _FormularioRegistro(
                      esOscuro: esOscuro,
                      ctrlNombres: _ctrlNombres,
                      ctrlApellidos: _ctrlApellidos,
                      ctrlCorreo: _ctrlCorreo,
                      ctrlUsuario: _ctrlUsuario,
                      ctrlPassword: _ctrlPassword,
                      ctrlTelefono: _ctrlTelefono,
                      ctrlUbicacion: _ctrlUbicacion,
                      ctrlId: _ctrlId,
                      verPassword: _verPassword,
                      ofrecDelivery: _ofrecDelivery,
                      genero: _genero,
                      provincia: _provincia,
                      registrando: _registrando,
                      errorMensaje: _errorMensaje,
                      fechaNac: _fechaNac,
                      ctrlFechaNacimiento: _ctrlFechaNacimiento,
                      alAlternarPassword: () =>
                          setState(() => _verPassword = !_verPassword),
                      alCambiarDelivery: (v) =>
                          setState(() => _ofrecDelivery = v),
                      alCambiarGenero: (v) => setState(() => _genero = v),
                      alCambiarProvincia: (v) => setState(() => _provincia = v),
                      alCambiarFecha: (v) => setState(() => _fechaNac = v),
                      alRegistrar: _registrar,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FORMULARIO
// ─────────────────────────────────────────────────────────────
class _FormularioRegistro extends StatelessWidget {
  final bool esOscuro;
  final TextEditingController ctrlNombres;
  final TextEditingController ctrlApellidos;
  final TextEditingController ctrlCorreo;
  final TextEditingController ctrlUsuario;
  final TextEditingController ctrlPassword;
  final TextEditingController ctrlTelefono;
  final TextEditingController ctrlUbicacion;
  final TextEditingController ctrlId;
  final TextEditingController ctrlFechaNacimiento;
  final bool verPassword;
  final bool ofrecDelivery;
  final String? genero;
  final String? provincia;
  final bool registrando;
  final String? errorMensaje;
  final String? fechaNac;
  final VoidCallback alAlternarPassword;
  final ValueChanged<bool> alCambiarDelivery;
  final ValueChanged<String?> alCambiarGenero;
  final ValueChanged<String?> alCambiarProvincia;
  final ValueChanged<String?> alCambiarFecha;
  final VoidCallback alRegistrar;

  const _FormularioRegistro({
    required this.esOscuro,
    required this.ctrlNombres,
    required this.ctrlApellidos,
    required this.ctrlCorreo,
    required this.ctrlUsuario,
    required this.ctrlPassword,
    required this.ctrlTelefono,
    required this.ctrlUbicacion,
    required this.ctrlId,
    required this.verPassword,
    required this.ofrecDelivery,
    required this.genero,
    required this.provincia,
    required this.registrando,
    required this.errorMensaje,
    required this.fechaNac,
    required this.alAlternarPassword,
    required this.alCambiarDelivery,
    required this.alCambiarGenero,
    required this.alCambiarProvincia,
    required this.alCambiarFecha,
    required this.ctrlFechaNacimiento,
    required this.alRegistrar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── ENCABEZADO ──────────────────────────────────────────────
        _Encabezado(esOscuro: esOscuro),

        const SizedBox(height: 10),

        // ── TÍTULO ───────────────────────────────────────────────────
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Crea tu cuenta como ',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: CraftHubColors.textoClaro,
                ),
              ),
              TextSpan(
                text: 'vendedor',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: CraftHubColors.vinoTinto,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Completa tu información para empezar a compartir tus creaciones.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: CraftHubColors.textoSecClaro,
          ),
        ),

        const SizedBox(height: 22),

        // ── FILA 1: Nombres | Apellidos ───────────────────────────────
        _FilaDos(
          izquierda: CampoTexto(
            controlador: ctrlNombres,
            hint: 'Nombres',
            icono: Icons.person_outline_rounded,
            esOscuro: esOscuro,
          ),
          derecha: CampoTexto(
            controlador: ctrlApellidos,
            hint: 'Apellidos',
            icono: Icons.person_outline_rounded,
            esOscuro: esOscuro,
          ),
        ),

        const SizedBox(height: 10),

        // ── FILA 2: Correo (ancho completo) ──────────────────────────
        CampoTexto(
          controlador: ctrlCorreo,
          hint: 'Correo electrónico',
          icono: Icons.mail_outline_rounded,
          esOscuro: esOscuro,
        ),

        const SizedBox(height: 10),

        // ── FILA 3: Usuario | Contraseña ─────────────────────────────
        _FilaDos(
          izquierda: CampoTexto(
            controlador: ctrlUsuario,
            hint: 'Nombre de usuario',
            icono: Icons.badge_outlined,
            esOscuro: esOscuro,
          ),
          derecha: CampoTexto(
            controlador: ctrlPassword,
            hint: 'Contraseña',
            icono: Icons.lock_outline_rounded,
            esOscuro: esOscuro,
            esPassword: true,
            verPassword: verPassword,
            alAlternarVisibilidad: alAlternarPassword,
          ),
        ),

        const SizedBox(height: 10),

        // ── FILA 4: Teléfono | Fecha nacimiento ──────────────────────
        _FilaDos(
  izquierda: CampoTexto(
    controlador: ctrlTelefono,
    hint: 'Número de teléfono',
    icono: Icons.phone_outlined,
    esOscuro: esOscuro,
  ),
  derecha: CampoTexto(
    controlador: ctrlFechaNacimiento,
    hint: 'Fecha de nacimiento',
    icono: Icons.calendar_today_outlined,
    esOscuro: esOscuro,
    readOnly: true,
    onTap: () async {
      final fecha = await showDatePicker(
        context: context,
        initialDate: DateTime(2000),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );

      if (fecha != null) {
        ctrlFechaNacimiento.text =
            '${fecha.day.toString().padLeft(2, '0')}/'
            '${fecha.month.toString().padLeft(2, '0')}/'
            '${fecha.year}';
      }
    },
  ),
),

        const SizedBox(height: 10),

        // ── FILA 5: Provincia/comarca | Ciudad o dirección (detalle) ──
        _FilaDos(
          izquierda: CampoDropdown<String>(
            valorSeleccionado: provincia,
            hint: 'Provincia / comarca',
            icono: Icons.map_outlined,
            alCambiar: alCambiarProvincia,
            items: kProvinciasPanama
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
          ),
          derecha: CampoTexto(
            controlador: ctrlUbicacion,
            hint: 'Ciudad / dirección (opcional)',
            icono: Icons.location_on_outlined,
            esOscuro: esOscuro,
          ),
        ),

        const SizedBox(height: 10),

        // ── FILA 6: ID | Género ───────────────────────────────────────
        _FilaDos(
          izquierda: CampoTexto(
            controlador: ctrlId,
            hint: 'ID / Número de identificación',
            icono: Icons.badge_outlined,
            esOscuro: esOscuro,
          ),
          derecha: CampoDropdown<String>(
            valorSeleccionado: genero,
            hint: 'Género',
            icono: Icons.wc_outlined,
            alCambiar: alCambiarGenero,
            items: const [
              DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
              DropdownMenuItem(value: 'femenino', child: Text('Femenino')),
              DropdownMenuItem(value: 'otro', child: Text('Prefiero no decir')),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── TOGGLE DELIVERY ───────────────────────────────────────────
        _ToggleDelivery(valor: ofrecDelivery, alCambiar: alCambiarDelivery),

        const SizedBox(height: 10),

        if (errorMensaje != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              errorMensaje!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.redAccent,
              ),
            ),
          ),

        // ── BOTÓN CREAR CUENTA ────────────────────────────────────────
        registrando
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
                texto: 'Crear cuenta',
                alPresionar: alRegistrar,
              ),

        const SizedBox(height: 16),

        // ── SEPARADOR ─────────────────────────────────────────────────
        _Separador(),

        const SizedBox(height: 16),

        // ── BOTÓN GOOGLE ──────────────────────────────────────────────
        BotonGoogle(esOscuro: esOscuro, alPresionar: () {}),

        const SizedBox(height: 18),

        // ── LINK INICIAR SESIÓN ───────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¿Ya tienes una cuenta? ',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: CraftHubColors.textoSecClaro,
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: const Text(
                  'Inicia sesión',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CraftHubColors.vinoTinto,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

}

// ─────────────────────────────────────────────────────────────
// ENCABEZADO: volver + logo
// ─────────────────────────────────────────────────────────────
class _Encabezado extends StatelessWidget {
  final bool esOscuro;
  const _Encabezado({required this.esOscuro});
  

  @override
  Widget build(BuildContext context) {
  final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
  final colorSec   = CraftHubColors.textoSecundario(esOscuro);
    return Column(
      children: [
        // Botón volver alineado a la izquierda
        Align(alignment: Alignment.centerLeft, child: _BotonVolver()),
        const SizedBox(height: 8),
        // Logo centrado
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_crafthub.png',
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 10),
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
      ],
    );
    

  }
}

// ─────────────────────────────────────────────────────────────
// BOTÓN VOLVER
// ─────────────────────────────────────────────────────────────
class _BotonVolver extends StatefulWidget {
  @override
  State<_BotonVolver> createState() => _BotonVolverState();
}

class _BotonVolverState extends State<_BotonVolver> {
  bool _sobreEl = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobreEl = true),
      onExit: (_) => setState(() => _sobreEl = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _sobreEl
                ? Colors.black.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: CraftHubColors.textoClaro,
              ),
              SizedBox(width: 6),
              Text(
                'Volver',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CraftHubColors.textoClaro,
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
// FILA DE DOS CAMPOS
// ─────────────────────────────────────────────────────────────
class _FilaDos extends StatelessWidget {
  final Widget izquierda;
  final Widget derecha;

  const _FilaDos({required this.izquierda, required this.derecha});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: izquierda),
        const SizedBox(width: 12),
        Expanded(child: derecha),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOGGLE DELIVERY
// ─────────────────────────────────────────────────────────────
class _ToggleDelivery extends StatelessWidget {
  final bool valor;
  final ValueChanged<bool> alCambiar;

  const _ToggleDelivery({required this.valor, required this.alCambiar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.delivery_dining_outlined,
          size: 20,
          color: CraftHubColors.textoSecClaro,
        ),
        const SizedBox(width: 10),
        const Text(
          '¿Ofreces delivery?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: CraftHubColors.textoClaro,
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: valor,
          onChanged: alCambiar,
          activeThumbColor: CraftHubColors.vinoTinto,
          activeTrackColor: CraftHubColors.vinoTinto.withValues(alpha: 0.3),
          inactiveThumbColor: CraftHubColors.textoSecClaro,
          inactiveTrackColor: CraftHubColors.bordeClaro,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SEPARADOR
// ─────────────────────────────────────────────────────────────
class _Separador extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.black.withValues(alpha: 0.10), thickness: 1),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'o continúa con',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: CraftHubColors.textoSecClaro,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.black.withValues(alpha: 0.10), thickness: 1),
        ),
      ],
    );
  }
}
