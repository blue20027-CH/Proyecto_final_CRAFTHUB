import 'package:flutter/material.dart';
import '../vendedor/pantalla_dashoard_vendedor.dart';
import '../../core/theme/app_theme.dart';
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
  final _ctrlNombres    = TextEditingController();
  final _ctrlApellidos  = TextEditingController();
  final _ctrlCorreo     = TextEditingController();
  final _ctrlUsuario    = TextEditingController();
  final _ctrlPassword   = TextEditingController();
  final _ctrlTelefono   = TextEditingController();
  final _ctrlUbicacion  = TextEditingController();
  final _ctrlId         = TextEditingController();

  // Estados
  bool _verPassword    = false;
  bool _ofrecDelivery  = true;
  String? _genero;
  String? _fechaNac;

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
                        CraftHubColors.fondoClaro.withOpacity(0.5),
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
                      horizontal: 56, vertical: 24),
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
                      fechaNac: _fechaNac,
                      alAlternarPassword: () =>
                          setState(() => _verPassword = !_verPassword),
                      alCambiarDelivery: (v) =>
                          setState(() => _ofrecDelivery = v),
                      alCambiarGenero: (v) =>
                          setState(() => _genero = v),
                      alCambiarFecha: (v) =>
                          setState(() => _fechaNac = v),
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
  final bool verPassword;
  final bool ofrecDelivery;
  final String? genero;
  final String? fechaNac;
  final VoidCallback alAlternarPassword;
  final ValueChanged<bool> alCambiarDelivery;
  final ValueChanged<String?> alCambiarGenero;
  final ValueChanged<String?> alCambiarFecha;

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
    required this.fechaNac,
    required this.alAlternarPassword,
    required this.alCambiarDelivery,
    required this.alCambiarGenero,
    required this.alCambiarFecha,
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
                  fontFamily: 'RocaTwo',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: CraftHubColors.textoClaro,
                ),
              ),
              TextSpan(
                text: 'vendedor',
                style: TextStyle(
                  fontFamily: 'RocaTwo',
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
          derecha: CampoDropdown<String>(
            valorSeleccionado: fechaNac,
            hint: 'Fecha de nacimiento',
            icono: Icons.calendar_today_outlined,
            alCambiar: alCambiarFecha,
            items: _generarAnios(),
          ),
        ),

        const SizedBox(height: 10),

        // ── FILA 5: Ubicación (ancho completo) ───────────────────────
        CampoTexto(
          controlador: ctrlUbicacion,
          hint: 'Ubicación (Ciudad, Provincia)',
          icono: Icons.location_on_outlined,
          esOscuro: esOscuro,
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
              DropdownMenuItem(value: 'femenino',  child: Text('Femenino')),
              DropdownMenuItem(value: 'otro',      child: Text('Prefiero no decir')),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── TOGGLE DELIVERY ───────────────────────────────────────────
        _ToggleDelivery(
          valor: ofrecDelivery,
          alCambiar: alCambiarDelivery,
        ),

        const SizedBox(height: 18),

        // ── BOTÓN CREAR CUENTA ────────────────────────────────────────
        BotonPrimario(
          texto: 'Crear cuenta',
          alPresionar: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PantallaDashboardVendedor(esOscuro: esOscuro),
              ),
            ); // TODO: lógica de registro con FastAPI
          },
          mostrarFlecha: true,
          ancho: double.infinity,
        ),

        const SizedBox(height: 16),

        // ── SEPARADOR ─────────────────────────────────────────────────
        _Separador(),

        const SizedBox(height: 16),

        // ── BOTÓN GOOGLE ──────────────────────────────────────────────
        BotonGoogle(
          esOscuro: esOscuro,
          alPresionar: () {},
        ),

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

  /// Genera años de nacimiento como opciones del dropdown
  List<DropdownMenuItem<String>> _generarAnios() {
    final anioActual = DateTime.now().year;
    return List.generate(80, (i) {
      final anio = (anioActual - 18 - i).toString();
      return DropdownMenuItem(value: anio, child: Text(anio));
    });
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
    return Column(
      children: [
        // Botón volver alineado a la izquierda
        Align(
          alignment: Alignment.centerLeft,
          child: _BotonVolver(),
        ),
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
            const Text(
              'CraftHub',
              style: TextStyle(
                fontFamily: 'RocaTwo',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: CraftHubColors.vinoTinto,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Conectamos talento, creamos impacto',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: CraftHubColors.textoSecClaro,
          ),
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
      onExit:  (_) => setState(() => _sobreEl = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _sobreEl
                ? Colors.black.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded,
                  size: 16, color: CraftHubColors.textoClaro),
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
        const Icon(Icons.delivery_dining_outlined,
            size: 20, color: CraftHubColors.textoSecClaro),
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
          activeColor: CraftHubColors.vinoTinto,
          activeTrackColor: CraftHubColors.vinoTinto.withOpacity(0.3),
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
          child: Divider(
            color: Colors.black.withOpacity(0.10),
            thickness: 1,
          ),
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
          child: Divider(
            color: Colors.black.withOpacity(0.10),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}