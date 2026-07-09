// lib/screens/comprador/pantalla_pago.dart
// Pasarela de pago: se abre desde "Proceder al pago" (carrito) o
// "Comprar ahora" (detalle de producto). Requiere sesión iniciada — los
// que la abren ya validan userId.isNotEmpty antes de navegar aquí.
// 🔌 Backend: GET /api/pagos/metodos, POST /api/pagos/resumen,
//    POST /api/pagos/crear (BACK/CraftHub/pedidos_router.py)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/carrito_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class PantallaPago extends StatefulWidget {
  final String userId;
  const PantallaPago({super.key, required this.userId});

  @override
  State<PantallaPago> createState() => _PantallaPagoState();
}

class _PantallaPagoState extends State<PantallaPago> {
  List<Map<String, dynamic>> _metodos = [];
  String? _metodoSeleccionado;
  bool _cargandoMetodos = true;

  final _ctrlNombre = TextEditingController();
  final _ctrlTelefono = TextEditingController();
  final _ctrlUbicacion = TextEditingController(text: 'Panamá');

  final _ctrlNombreTarjeta = TextEditingController();
  final _ctrlNumeroTarjeta = TextEditingController();
  final _ctrlVenceTarjeta = TextEditingController();
  final _ctrlCvv = TextEditingController();

  String? _bancoSeleccionado;
  final _ctrlTitular = TextEditingController();
  final _ctrlCuenta = TextEditingController();
  final _ctrlReferencia = TextEditingController();

  final _ctrlContactoBilletera = TextEditingController();

  double _subtotal = 0;
  double _envio = 0;
  double _total = 0;
  bool _cargandoResumen = false;

  bool _procesando = false;
  String? _error;
  bool _pagoExitoso = false;
  String _numeroOrden = '';

  @override
  void initState() {
    super.initState();
    _cargarMetodos();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _ctrlNombre.dispose();
    _ctrlTelefono.dispose();
    _ctrlUbicacion.dispose();
    _ctrlNombreTarjeta.dispose();
    _ctrlNumeroTarjeta.dispose();
    _ctrlVenceTarjeta.dispose();
    _ctrlCvv.dispose();
    _ctrlTitular.dispose();
    _ctrlCuenta.dispose();
    _ctrlReferencia.dispose();
    _ctrlContactoBilletera.dispose();
    super.dispose();
  }

  Future<void> _cargarMetodos() async {
    try {
      final metodos = await ApiService.getMetodosPago();
      if (mounted) {
        setState(() {
          _metodos = metodos;
          _metodoSeleccionado = metodos.isNotEmpty ? metodos.first['id'] as String : null;
        });
      }
    } catch (e) {
      debugPrint('Error cargando métodos de pago: $e');
    } finally {
      if (mounted) setState(() => _cargandoMetodos = false);
    }
    _cargarResumen();
  }

  Future<void> _cargarPerfil() async {
    if (widget.userId.isEmpty) return;
    try {
      final perfil = await ApiService.getPerfil(widget.userId);
      if (!mounted) return;
      setState(() {
        _ctrlNombre.text = (perfil['nombre'] ?? '').toString();
        _ctrlTelefono.text = (perfil['telefono'] ?? '').toString();
        final ubic = (perfil['ubicacion'] ?? '').toString();
        if (ubic.isNotEmpty) _ctrlUbicacion.text = ubic;
      });
      _cargarResumen();
    } catch (e) {
      debugPrint('Error cargando perfil para el checkout: $e');
    }
  }

  List<Map<String, dynamic>> get _itemsCarrito {
    final carrito = context.read<CarritoProvider>().carritoActivo;
    return (carrito?.items ?? [])
        .map((i) => {
              'id': i.productoId.toString(),
              'nombre': i.nombreProducto,
              'precio': i.precioUnitario,
              'cantidad': i.cantidad,
              'creador': i.artesanoNombre,
              'img': i.imagenUrl,
            })
        .toList();
  }

  Future<void> _cargarResumen() async {
    final items = _itemsCarrito;
    if (items.isEmpty) return;
    setState(() => _cargandoResumen = true);
    try {
      final data = await ApiService.resumenPedido(
        carrito: items,
        ubicacionComprador: _ctrlUbicacion.text.trim().isEmpty ? 'Panamá' : _ctrlUbicacion.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _subtotal = double.tryParse((data['subtotal'] ?? 0).toString()) ?? 0;
        _envio = double.tryParse((data['envio'] ?? 0).toString()) ?? 0;
        _total = double.tryParse((data['total'] ?? 0).toString()) ?? 0;
      });
    } catch (e) {
      debugPrint('Error calculando el resumen del pedido: $e');
    } finally {
      if (mounted) setState(() => _cargandoResumen = false);
    }
  }

  String get _campoBilletera {
    final metodo = _metodos.firstWhere(
      (m) => m['id'] == _metodoSeleccionado,
      orElse: () => const {},
    );
    return (metodo['campo'] ?? 'telefono').toString();
  }

  bool get _formularioValido {
    if (_metodoSeleccionado == null) return false;
    if (_ctrlNombre.text.trim().isEmpty ||
        _ctrlTelefono.text.trim().isEmpty ||
        _ctrlUbicacion.text.trim().isEmpty) {
      return false;
    }
    switch (_metodoSeleccionado) {
      case 'Tarjeta':
        return _ctrlNombreTarjeta.text.trim().isNotEmpty &&
            _ctrlNumeroTarjeta.text.replaceAll(' ', '').length >= 13 &&
            _ctrlVenceTarjeta.text.trim().isNotEmpty &&
            _ctrlCvv.text.trim().length >= 3;
      case 'Transferencia':
        return _bancoSeleccionado != null &&
            _ctrlTitular.text.trim().isNotEmpty &&
            _ctrlCuenta.text.trim().isNotEmpty;
      default:
        return _ctrlContactoBilletera.text.trim().isNotEmpty;
    }
  }

  Future<void> _pagar() async {
    if (!_formularioValido || _procesando) return;
    setState(() {
      _procesando = true;
      _error = null;
    });

    final pedido = <String, dynamic>{
      'comprador_id': widget.userId,
      'comprador_nombre': _ctrlNombre.text.trim(),
      'ubicacion_comprador': _ctrlUbicacion.text.trim(),
      'telefono': _ctrlTelefono.text.trim(),
      'carrito': _itemsCarrito,
      'metodo_pago': _metodoSeleccionado,
    };

    if (_metodoSeleccionado == 'Tarjeta') {
      pedido['datos_tarjeta'] = {
        'nombre_tarjeta': _ctrlNombreTarjeta.text.trim(),
        'numero': _ctrlNumeroTarjeta.text.replaceAll(' ', ''),
        'vence': _ctrlVenceTarjeta.text.trim(),
        'cvv': _ctrlCvv.text.trim(),
      };
    } else if (_metodoSeleccionado == 'Transferencia') {
      pedido['datos_transferencia'] = {
        'banco': _bancoSeleccionado,
        'titular': _ctrlTitular.text.trim(),
        'cuenta': _ctrlCuenta.text.trim(),
        'referencia': _ctrlReferencia.text.trim().isEmpty ? null : _ctrlReferencia.text.trim(),
      };
    } else {
      pedido['datos_billetera'] = {
        'billetera': _metodoSeleccionado,
        'contacto': _ctrlContactoBilletera.text.trim(),
      };
    }

    try {
      final resultado = await ApiService.crearPedido(pedido);
      if (!mounted) return;
      await context.read<CarritoProvider>().vaciarCarrito();
      if (!mounted) return;
      setState(() {
        _pagoExitoso = true;
        _numeroOrden = (resultado['pedido_id'] ?? '').toString();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: CraftHubColors.fondo(oscuro),
      appBar: AppBar(
        backgroundColor: CraftHubColors.fondo(oscuro),
        elevation: 0,
        iconTheme: IconThemeData(color: CraftHubColors.textoPrincipal(oscuro)),
        title: Text('Finalizar compra',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CraftHubColors.textoPrincipal(oscuro))),
      ),
      body: SafeArea(
        child: _pagoExitoso
            ? _PantallaExito(
                numeroOrden: _numeroOrden,
                total: _total,
                oscuro: oscuro,
                onContinuar: () => Navigator.of(context).pop(),
              )
            : _cargandoMetodos
                ? const Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto))
                : _buildContenido(oscuro),
      ),
    );
  }

  Widget _buildContenido(bool oscuro) {
    final items = context.watch<CarritoProvider>().carritoActivo?.items ?? [];
    if (items.isEmpty) {
      return Center(
        child: Text('Tu carrito está vacío.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: CraftHubColors.textoSecundario(oscuro))),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final compacto = constraints.maxWidth < 900;
      final columnaFormulario = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SeccionCheckout(
              oscuro: oscuro,
              icono: Icons.person_outline_rounded,
              titulo: 'Ingresa tus datos',
              child: Column(children: [
                _CampoPago(controlador: _ctrlNombre, etiqueta: 'Nombre completo', oscuro: oscuro),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _CampoPago(controlador: _ctrlTelefono, etiqueta: 'Teléfono', oscuro: oscuro, tipoTeclado: TextInputType.phone)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CampoPago(
                      controlador: _ctrlUbicacion,
                      etiqueta: 'Provincia / ubicación',
                      oscuro: oscuro,
                      onEditingComplete: _cargarResumen,
                    ),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            _SeccionCheckout(
              oscuro: oscuro,
              icono: Icons.local_shipping_outlined,
              titulo: 'Método de despacho',
              child: Row(children: [
                Icon(Icons.storefront_outlined, size: 18, color: CraftHubColors.vinoTinto),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Envío a domicilio — calculado según la distancia a cada artesano.',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: CraftHubColors.textoSecundario(oscuro))),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _SeccionCheckout(
              oscuro: oscuro,
              icono: Icons.credit_card_outlined,
              titulo: 'Forma de pago',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _metodos
                        .map((m) => _TarjetaMetodoPago(
                              id: m['id'] as String,
                              titulo: m['titulo'] as String,
                              seleccionado: _metodoSeleccionado == m['id'],
                              oscuro: oscuro,
                              onTap: () => setState(() => _metodoSeleccionado = m['id'] as String),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  _formularioMetodo(oscuro),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: CraftHubColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CraftHubColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: CraftHubColors.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: CraftHubColors.error))),
                ]),
              ),
            ],
            if (compacto) ...[
              const SizedBox(height: 20),
              _PanelResumenCheckout(
                items: items,
                subtotal: _subtotal,
                envio: _envio,
                total: _total,
                cargando: _cargandoResumen,
                procesando: _procesando,
                puedePagar: _formularioValido,
                oscuro: oscuro,
                onPagar: _pagar,
              ),
            ],
          ],
        ),
      );

      if (compacto) return columnaFormulario;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: columnaFormulario),
          SizedBox(
            width: 340,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 24, 24),
              child: _PanelResumenCheckout(
                items: items,
                subtotal: _subtotal,
                envio: _envio,
                total: _total,
                cargando: _cargandoResumen,
                procesando: _procesando,
                puedePagar: _formularioValido,
                oscuro: oscuro,
                onPagar: _pagar,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _formularioMetodo(bool oscuro) {
    switch (_metodoSeleccionado) {
      case 'Tarjeta':
        return Column(children: [
          _CampoPago(controlador: _ctrlNombreTarjeta, etiqueta: 'Nombre en la tarjeta', oscuro: oscuro),
          const SizedBox(height: 12),
          _CampoPago(
            controlador: _ctrlNumeroTarjeta,
            etiqueta: 'Número de tarjeta',
            oscuro: oscuro,
            tipoTeclado: TextInputType.number,
            hint: '0000 0000 0000 0000',
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _CampoPago(controlador: _ctrlVenceTarjeta, etiqueta: 'Vence (MM/AA)', oscuro: oscuro, hint: 'MM/AA')),
            const SizedBox(width: 12),
            Expanded(
              child: _CampoPago(
                controlador: _ctrlCvv,
                etiqueta: 'CVV',
                oscuro: oscuro,
                tipoTeclado: TextInputType.number,
                oculto: true,
              ),
            ),
          ]),
        ]);
      case 'Transferencia':
        final metodo = _metodos.firstWhere((m) => m['id'] == 'Transferencia', orElse: () => const {});
        final bancos = ((metodo['bancos'] as List?) ?? []).cast<String>();
        return Column(children: [
          _SelectorPago(
            valor: _bancoSeleccionado,
            etiqueta: 'Banco',
            opciones: bancos,
            oscuro: oscuro,
            onCambiar: (v) => setState(() => _bancoSeleccionado = v),
          ),
          const SizedBox(height: 12),
          _CampoPago(controlador: _ctrlTitular, etiqueta: 'Titular de la cuenta', oscuro: oscuro),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _CampoPago(controlador: _ctrlCuenta, etiqueta: 'Número de cuenta', oscuro: oscuro, tipoTeclado: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _CampoPago(controlador: _ctrlReferencia, etiqueta: 'Referencia (opcional)', oscuro: oscuro)),
          ]),
        ]);
      default:
        if (_metodoSeleccionado == null) return const SizedBox.shrink();
        return _CampoPago(
          controlador: _ctrlContactoBilletera,
          etiqueta: _campoBilletera == 'correo' ? 'Correo de $_metodoSeleccionado' : 'Teléfono de $_metodoSeleccionado',
          oscuro: oscuro,
          tipoTeclado: _campoBilletera == 'correo' ? TextInputType.emailAddress : TextInputType.phone,
        );
    }
  }
}

// ── SECCIÓN DEL FORMULARIO ────────────────────────────────────────────────
class _SeccionCheckout extends StatelessWidget {
  final bool oscuro;
  final IconData icono;
  final String titulo;
  final Widget child;

  const _SeccionCheckout({required this.oscuro, required this.icono, required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(oscuro),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CraftHubColors.borde(oscuro)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: oscuro ? 0.22 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: CraftHubColors.vinoTintoSuave, borderRadius: BorderRadius.circular(10)),
              child: Icon(icono, size: 16, color: CraftHubColors.vinoTinto),
            ),
            const SizedBox(width: 10),
            Text(titulo,
                style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: CraftHubColors.textoPrincipal(oscuro))),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── CAMPO DE TEXTO COMPACTO ────────────────────────────────────────────────
class _CampoPago extends StatelessWidget {
  final TextEditingController controlador;
  final String etiqueta;
  final bool oscuro;
  final TextInputType? tipoTeclado;
  final bool oculto;
  final String? hint;
  final VoidCallback? onEditingComplete;

  const _CampoPago({
    required this.controlador,
    required this.etiqueta,
    required this.oscuro,
    this.tipoTeclado,
    this.oculto = false,
    this.hint,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: CraftHubColors.textoSecundario(oscuro))),
        const SizedBox(height: 6),
        TextField(
          controller: controlador,
          keyboardType: tipoTeclado,
          obscureText: oculto,
          onEditingComplete: onEditingComplete,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, color: CraftHubColors.textoPrincipal(oscuro)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: CraftHubColors.textoSecundario(oscuro)),
            filled: true,
            fillColor: CraftHubColors.fondo(oscuro),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: CraftHubColors.borde(oscuro))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: CraftHubColors.vinoTinto, width: 1.3)),
          ),
        ),
      ],
    );
  }
}

// ── SELECTOR (dropdown) ────────────────────────────────────────────────────
class _SelectorPago extends StatelessWidget {
  final String? valor;
  final String etiqueta;
  final List<String> opciones;
  final bool oscuro;
  final ValueChanged<String?> onCambiar;

  const _SelectorPago({required this.valor, required this.etiqueta, required this.opciones, required this.oscuro, required this.onCambiar});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: CraftHubColors.textoSecundario(oscuro))),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: CraftHubColors.fondo(oscuro),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CraftHubColors.borde(oscuro)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: valor,
              isExpanded: true,
              hint: Text('Selecciona tu banco', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: CraftHubColors.textoSecundario(oscuro))),
              dropdownColor: CraftHubColors.panel(oscuro),
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, color: CraftHubColors.textoPrincipal(oscuro)),
              items: opciones.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: onCambiar,
            ),
          ),
        ),
      ],
    );
  }
}

// ── TARJETA DE MÉTODO DE PAGO (con el "logo" de cada servicio) ─────────────
class _TarjetaMetodoPago extends StatelessWidget {
  final String id;
  final String titulo;
  final bool seleccionado;
  final bool oscuro;
  final VoidCallback onTap;

  const _TarjetaMetodoPago({
    required this.id,
    required this.titulo,
    required this.seleccionado,
    required this.oscuro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 148,
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? CraftHubColors.vinoTinto : CraftHubColors.borde(oscuro),
            width: seleccionado ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (seleccionado ? CraftHubColors.vinoTinto : Colors.black).withValues(alpha: seleccionado ? 0.16 : 0.05),
              blurRadius: seleccionado ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(child: _LogoMetodoPago(id: id, titulo: titulo)),
            if (seleccionado)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: CraftHubColors.vinoTinto, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Marca visual de cada método. Para Yappy, PayPal y Banistmo se dibuja su
// logotipo de texto con los colores reales de marca (sin depender de
// imágenes externas, que podrían romperse); para Tarjeta y Transferencia
// se usa un ícono + etiqueta, ya que no representan una sola marca.
class _LogoMetodoPago extends StatelessWidget {
  final String id;
  final String titulo;
  const _LogoMetodoPago({required this.id, required this.titulo});

  @override
  Widget build(BuildContext context) {
    // Si alguien coloca el logo real en assets/images/logos/<archivo>.png, se
    // usa esa imagen; si no existe todavía, cae automáticamente al logotipo
    // dibujado (ver assets/images/logos/README.txt).
    if (id == 'Tarjeta') {
      // "Tarjeta" no es una sola marca: se muestran los logos de las redes
      // que se aceptan (Visa + Mastercard) uno junto al otro.
      return Row(mainAxisSize: MainAxisSize.min, children: [
        _imagenLogo('visa', alto: 18),
        const SizedBox(width: 8),
        _imagenLogo('mastercard', alto: 24),
      ]);
    }
    return _imagenLogo(id.toLowerCase(), alto: 28);
  }

  // Algunos logos se guardaron como .webp (formato en el que llegaron al
  // descargarlos) — Flutter lo soporta igual que .png, solo hay que apuntar
  // a la extensión correcta de cada archivo.
  static const _extensiones = {
    'mastercard': 'webp',
    'yappy': 'webp',
    'paypal': 'webp',
  };

  Widget _imagenLogo(String archivo, {required double alto}) {
    final extension = _extensiones[archivo] ?? 'png';
    return Image.asset(
      'assets/images/logos/$archivo.$extension',
      height: alto,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _logotipoDibujado(),
    );
  }

  Widget _logotipoDibujado() {
    switch (id) {
      case 'Yappy':
        return const Text('yappy',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF6E2C9C), letterSpacing: -0.5));
      case 'PayPal':
        return RichText(
          text: const TextSpan(
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            children: [
              TextSpan(text: 'Pay', style: TextStyle(color: Color(0xFF003087))),
              TextSpan(text: 'Pal', style: TextStyle(color: Color(0xFF0070E0))),
            ],
          ),
        );
      case 'Banistmo':
        return const Text('Banistmo',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFF47920)));
      case 'Tarjeta':
        return Row(mainAxisSize: MainAxisSize.min, children: [
          _circuloTarjeta(const Color(0xFFEB001B), 0),
          _circuloTarjeta(const Color(0xFFF79E1B), 10),
          const SizedBox(width: 8),
          Text(titulo.split(' ').first,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w700, color: CraftHubColors.textoClaro)),
        ]);
      case 'Transferencia':
      default:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: CraftHubColors.info.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.account_balance_rounded, size: 15, color: CraftHubColors.info),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w700, color: CraftHubColors.textoClaro)),
          ),
        ]);
    }
  }

  Widget _circuloTarjeta(Color color, double desplazamiento) {
    return Transform.translate(
      offset: Offset(desplazamiento, 0),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.85)),
      ),
    );
  }
}

// ── PANEL RESUMEN (columna derecha) ────────────────────────────────────────
class _PanelResumenCheckout extends StatelessWidget {
  final List<dynamic> items;
  final double subtotal;
  final double envio;
  final double total;
  final bool cargando;
  final bool procesando;
  final bool puedePagar;
  final bool oscuro;
  final VoidCallback onPagar;

  const _PanelResumenCheckout({
    required this.items,
    required this.subtotal,
    required this.envio,
    required this.total,
    required this.cargando,
    required this.procesando,
    required this.puedePagar,
    required this.oscuro,
    required this.onPagar,
  });

  @override
  Widget build(BuildContext context) {
    final colorTexto = CraftHubColors.textoPrincipal(oscuro);
    final colorSec = CraftHubColors.textoSecundario(oscuro);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(oscuro),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CraftHubColors.borde(oscuro)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: oscuro ? 0.22 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tu pedido',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: colorTexto)),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = items[i];
                return Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: item.imagenUrl.toString().isNotEmpty
                        ? Image.network(item.imagenUrl, width: 44, height: 44, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(width: 44, height: 44, color: CraftHubColors.borde(oscuro)))
                        : Container(width: 44, height: 44, color: CraftHubColors.borde(oscuro)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.nombreProducto.toString(), maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w600, color: colorTexto)),
                      Text('Cantidad: ${item.cantidad}', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: colorSec)),
                    ]),
                  ),
                  Text('\$${(item.precioUnitario * item.cantidad).toStringAsFixed(2)}',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w700, color: colorTexto)),
                ]);
              },
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: CraftHubColors.borde(oscuro)),
          const SizedBox(height: 12),
          _filaResumen('Subtotal', subtotal, colorTexto, colorSec),
          const SizedBox(height: 8),
          cargando
              ? Row(children: [
                  Text('Envío', style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: colorSec)),
                  const SizedBox(width: 8),
                  SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6, color: colorSec)),
                ])
              : _filaResumen('Envío', envio, colorTexto, colorSec),
          const SizedBox(height: 14),
          Divider(color: CraftHubColors.borde(oscuro)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: colorTexto)),
            Text('\$${total.toStringAsFixed(2)}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, color: CraftHubColors.vinoTinto)),
          ]),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: puedePagar && !procesando ? onPagar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: CraftHubColors.vinoTinto,
                disabledBackgroundColor: CraftHubColors.vinoTinto.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: procesando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Pagar \$${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaResumen(String etiqueta, double valor, Color colorTexto, Color colorSec) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(etiqueta, style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: colorSec)),
      Text('\$${valor.toStringAsFixed(2)}', style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w600, color: colorTexto)),
    ]);
  }
}

// ── PANTALLA DE ÉXITO ──────────────────────────────────────────────────────
class _PantallaExito extends StatelessWidget {
  final String numeroOrden;
  final double total;
  final bool oscuro;
  final VoidCallback onContinuar;

  const _PantallaExito({required this.numeroOrden, required this.total, required this.oscuro, required this.onContinuar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: CraftHubColors.exito, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 22),
            Text('¡Tu pedido fue confirmado!',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: CraftHubColors.textoPrincipal(oscuro))),
            const SizedBox(height: 8),
            Text('Los artesanos ya recibieron tu compra y comenzarán a prepararla.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: CraftHubColors.textoSecundario(oscuro))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: CraftHubColors.panel(oscuro),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CraftHubColors.borde(oscuro)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Total pagado', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: CraftHubColors.textoSecundario(oscuro))),
                  Text('\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: CraftHubColors.vinoTinto)),
                ]),
                if (numeroOrden.isNotEmpty) ...[
                  const SizedBox(width: 28),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('N.º de orden', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: CraftHubColors.textoSecundario(oscuro))),
                    Text(numeroOrden.length > 8 ? numeroOrden.substring(0, 8).toUpperCase() : numeroOrden.toUpperCase(),
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: CraftHubColors.textoPrincipal(oscuro))),
                  ]),
                ],
              ]),
            ),
            const SizedBox(height: 26),
            ElevatedButton(
              onPressed: onContinuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: CraftHubColors.vinoTinto,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              child: const Text('Seguir explorando',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
