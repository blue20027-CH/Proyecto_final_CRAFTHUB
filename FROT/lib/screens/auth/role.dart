import 'package:abi_frotend_nd/screens/auth/pantalla_gustos.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../screens/auth/registro_vendedor.dart';
import '../../screens/auth/registro_comprador.dart';
import '../../main.dart';

class PantallaSeleccionRol extends StatefulWidget {
  const PantallaSeleccionRol({super.key});

  @override
  State<PantallaSeleccionRol> createState() => _PantallaSeleccionRolState();
}

class _PantallaSeleccionRolState extends State<PantallaSeleccionRol> {
  @override
  Widget build(BuildContext context) {
    final esOscuro = context.watch<GestorTema>().esModoOscuro;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/rol_back.png', fit: BoxFit.cover),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              color: esOscuro
                  ? Colors.black.withValues(alpha: 0.72)
                  : CraftHubColors.fondoClaro.withValues(alpha: 0.88),
            ),
          ),
          Column(
            children: [
              _BarraSuperior(esOscuro: esOscuro),
              Expanded(
                child: Center(child: _CuerpoSeleccion(esOscuro: esOscuro)),
              ),
            ],
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
  const _BarraSuperior({required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        children: [
          _BotonVolver(esOscuro: esOscuro),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_crafthub.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'CraftHub',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: CraftHubColors.textoPrincipal(esOscuro),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 80),
        ],
      ),
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
    final colorTexto = CraftHubColors.textoPrincipal(widget.esOscuro);
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
                ? (widget.esOscuro
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded, size: 16, color: colorTexto),
              const SizedBox(width: 6),
              Text(
                'Volver',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorTexto,
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
// CUERPO CENTRAL
// ─────────────────────────────────────────────────────────────
class _CuerpoSeleccion extends StatelessWidget {
  final bool esOscuro;
  const _CuerpoSeleccion({required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '¿Cuál es tu rol en CraftHub?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: CraftHubColors.textoPrincipal(esOscuro),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Selecciona la opción que mejor te describa para personalizar tu experiencia.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: CraftHubColors.textoSecundario(esOscuro),
          ),
        ),
        const SizedBox(height: 48),

        // ── TARJETAS SIMÉTRICAS ───────────────────────────────────────
        // IntrinsicHeight hace que ambas tarjetas adopten
        // la altura de la más alta automáticamente
        IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // ← ambas se estiran igual
            children: [
              SizedBox(
                width: 380,
                child: _TarjetaRol(
                  esOscuro: esOscuro,
                  icono: Icons.storefront_outlined,
                  titulo: 'Vendedor',
                  descripcion:
                      'Crea tu tienda, muestra tus productos\ny conecta con personas que valoran\nlo hecho a mano.',
                  botones: [
                    _DatoBoton(
                      texto: 'Registrarme como vendedor',
                      icono: Icons.person_add_outlined,
                      esPrimario: true,
                      alPresionar: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaRegistroVendedor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 380,
                child: _TarjetaRol(
                  esOscuro: esOscuro,
                  icono: Icons.shopping_bag_outlined,
                  titulo: 'Comprador',
                  descripcion:
                      'Descubre historias, apoya a los artesanos\ny encuentra piezas únicas hechas\ncon pasión.',
                  botones: [
                    _DatoBoton(
                      texto: 'Explorar como invitado',
                      icono: Icons.search_rounded,
                      esPrimario: true,
                      alPresionar: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaIntereses(userId: ''),
                        ),
                      ),
                    ),
                    _DatoBoton(
                      texto: 'Registrarme como comprador',
                      icono: Icons.person_add_outlined,
                      esPrimario: false,
                      alPresionar: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaRegistroComprador(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODELO BOTÓN
// ─────────────────────────────────────────────────────────────
class _DatoBoton {
  final String texto;
  final IconData icono;
  final bool esPrimario;
  final VoidCallback alPresionar;

  const _DatoBoton({
    required this.texto,
    required this.icono,
    required this.esPrimario,
    required this.alPresionar,
  });
}

// ─────────────────────────────────────────────────────────────
// TARJETA ROL — corregida para altura simétrica
// ─────────────────────────────────────────────────────────────
class _TarjetaRol extends StatefulWidget {
  final bool esOscuro;
  final IconData icono;
  final String titulo;
  final String descripcion;
  final List<_DatoBoton> botones;

  const _TarjetaRol({
    required this.esOscuro,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.botones,
  });

  @override
  State<_TarjetaRol> createState() => _TarjetaRolState();
}

class _TarjetaRolState extends State<_TarjetaRol> {
  bool _sobreEl = false;

  @override
  Widget build(BuildContext context) {
    final colorFondo = widget.esOscuro
        ? CraftHubColors.panelOscuro
        : CraftHubColors.panelClaro;
    final colorBorde = widget.esOscuro
        ? CraftHubColors.bordeOscuro
        : CraftHubColors.bordeClaro;
    final colorTexto = CraftHubColors.textoPrincipal(widget.esOscuro);
    final colorSec = CraftHubColors.textoSecundario(widget.esOscuro);

    return MouseRegion(
      onEnter: (_) => setState(() => _sobreEl = true),
      onExit: (_) => setState(() => _sobreEl = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _sobreEl
                ? CraftHubColors.vinoTinto.withValues(alpha: 0.4)
                : colorBorde,
            width: 1.5,
          ),
          boxShadow: _sobreEl
              ? [
                  BoxShadow(
                    color: CraftHubColors.vinoTinto.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        // Column con MainAxisSize.max + Spacer empuja botones siempre abajo
        child: Column(
          mainAxisSize: MainAxisSize.max, // ← ocupa todo el alto disponible
          children: [
            _CirculoIcono(icono: widget.icono, esOscuro: widget.esOscuro),
            const SizedBox(height: 20),
            Text(
              widget.titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorTexto,
              ),
            ),
            const SizedBox(height: 10),
            _SeparadorDiamante(),
            const SizedBox(height: 14),
            Text(
              widget.descripcion,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                height: 1.6,
                color: colorSec,
              ),
            ),
            const Spacer(), // ← empuja los botones al fondo siempre
            const SizedBox(height: 28),
            ...widget.botones.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BotonTarjeta(
                  texto: b.texto,
                  icono: b.icono,
                  esPrimario: b.esPrimario,
                  esOscuro: widget.esOscuro,
                  alPresionar: b.alPresionar,
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
// CÍRCULO CON ÍCONO
// ─────────────────────────────────────────────────────────────
class _CirculoIcono extends StatelessWidget {
  final IconData icono;
  final bool esOscuro;
  const _CirculoIcono({required this.icono, required this.esOscuro});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: esOscuro
            ? CraftHubColors.vinoTinto.withValues(alpha: 0.15)
            : CraftHubColors.vinoTintoSuave,
      ),
      child: Icon(icono, size: 40, color: CraftHubColors.vinoTinto),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SEPARADOR DIAMANTE
// ─────────────────────────────────────────────────────────────
class _SeparadorDiamante extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 1,
          color: CraftHubColors.vinoTinto.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 6),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              border: Border.all(color: CraftHubColors.vinoTinto, width: 1.5),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 40,
          height: 1,
          color: CraftHubColors.vinoTinto.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTÓN DENTRO DE TARJETA
// ─────────────────────────────────────────────────────────────
class _BotonTarjeta extends StatefulWidget {
  final String texto;
  final IconData icono;
  final bool esPrimario;
  final bool esOscuro;
  final VoidCallback alPresionar;

  const _BotonTarjeta({
    required this.texto,
    required this.icono,
    required this.esPrimario,
    required this.esOscuro,
    required this.alPresionar,
  });

  @override
  State<_BotonTarjeta> createState() => _BotonTarjetaState();
}

class _BotonTarjetaState extends State<_BotonTarjeta> {
  bool _sobreEl = false;

  @override
  Widget build(BuildContext context) {
    final colorFondo = widget.esPrimario
        ? (_sobreEl ? CraftHubColors.vinoTintoOscuro : CraftHubColors.vinoTinto)
        : Colors.transparent;

    final colorBorde = widget.esPrimario
        ? Colors.transparent
        : (_sobreEl
              ? CraftHubColors.vinoTinto
              : (widget.esOscuro
                    ? CraftHubColors.bordeOscuro
                    : CraftHubColors.bordeClaro));

    final colorTexto = widget.esPrimario
        ? Colors.white
        : CraftHubColors.textoPrincipal(widget.esOscuro);

    return MouseRegion(
      onEnter: (_) => setState(() => _sobreEl = true),
      onExit: (_) => setState(() => _sobreEl = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorBorde, width: 1.3),
          boxShadow: widget.esPrimario && _sobreEl
              ? [
                  BoxShadow(
                    color: CraftHubColors.vinoTinto.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.alPresionar,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icono, size: 17, color: colorTexto),
                const SizedBox(width: 8),
                Text(
                  widget.texto,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorTexto,
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