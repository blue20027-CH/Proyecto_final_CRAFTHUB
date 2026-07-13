// lib/screens/vendedor/pantalla_proveedores.dart
// Red de Proveedores: los vendedores buscan y agregan proveedores de
// materiales (cuero, hilos, cerámica, etc.) para su taller.
// Se inserta en _obtenerPantallaActual() — NO contiene Scaffold/Sidebar/TopBar propios.
// 🔌 Backend: BACK/CraftHub/proveedores_router.py

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/provincias_panama.dart';
import '../../core/i18n/i18n.dart';
import '../../models/proveedor_model.dart';
import '../../services/proveedores_api_service.dart';

const List<String> kCategoriasProveedor = [
  'Cuero',
  'Textiles',
  'Cerámica',
  'Cuentas y abalorios',
  'Metales',
  'Madera',
  'Ceras y velas',
  'Pinturas y tintes',
  'Herramientas',
  'Otros',
];

class PantallaProveedores extends StatefulWidget {
  final bool esOscuro;
  final String nombreVendedor;

  /// Se invoca cuando el vendedor quiere chatear con un proveedor; recibe el
  /// nombre de contacto para abrir/crear esa conversación.
  final ValueChanged<String>? alAbrirChat;

  const PantallaProveedores({
    super.key,
    required this.esOscuro,
    required this.nombreVendedor,
    this.alAbrirChat,
  });

  @override
  State<PantallaProveedores> createState() => _PantallaProveedoresState();
}

class _PantallaProveedoresState extends State<PantallaProveedores> {
  List<ProveedorModelo> _proveedores = [];
  bool _cargando = true;
  String? _error;

  final TextEditingController _busquedaCtrl = TextEditingController();
  String _busqueda = '';
  String _categoriaFiltro = 'Todas las categorías';
  String _ubicacionFiltro = 'Todas';
  double? _calificacionMin;
  String _orden = 'relevantes';
  Timer? _debounce;
  final Set<String> _favoritos = {};

  // No puede ser `const`: un Map<double, ...> const no es válido en Dart
  // porque double sobrescribe == / hashCode.
  static final _opcionesCalificacion = <double?, String>{
    null: 'vendedor_operaciones.proveedores_calificacion_cualquiera',
    3.0: 'vendedor_operaciones.proveedores_calificacion_3',
    4.0: 'vendedor_operaciones.proveedores_calificacion_4',
    4.5: 'vendedor_operaciones.proveedores_calificacion_45',
  };

  static const _opcionesOrden = {
    'relevantes': 'vendedor_operaciones.proveedores_orden_relevantes',
    'calificacion': 'vendedor_operaciones.proveedores_orden_calificacion',
    'recientes': 'vendedor_operaciones.proveedores_orden_recientes',
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resp = await ProveedoresApiService.cargarProveedores(
        q: _busqueda.isEmpty ? null : _busqueda,
        categoria: _categoriaFiltro == 'Todas las categorías' ? null : _categoriaFiltro,
        ubicacion: _ubicacionFiltro == 'Todas' ? null : _ubicacionFiltro,
        calificacionMin: _calificacionMin,
        orden: _orden,
      );
      if (!mounted) return;
      setState(() => _proveedores = resp.proveedores);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _onBuscar(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _busqueda = v);
      _cargar();
    });
  }

  void _chatear(ProveedorModelo p) {
    final nombreContacto = p.propietario.isNotEmpty ? p.propietario : p.nombre;
    widget.alAbrirChat?.call(nombreContacto);
  }

  Future<void> _enviarCorreo(String email) async {
    try {
      await launchUrl(Uri(scheme: 'mailto', path: email));
    } catch (_) {
      _mostrarSnack(tr(context, 'vendedor_operaciones.proveedores_snack_error_correo'), esError: true);
    }
  }

  void _mostrarSnack(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje),
      backgroundColor: esError ? CraftHubColors.error : CraftHubColors.vinoTinto,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _abrirDialogoAgregar() {
    showDialog(
      context: context,
      builder: (_) => _DialogoAgregarProveedor(
        esOscuro: widget.esOscuro,
        nombreVendedor: widget.nombreVendedor,
        onCreado: () {
          _mostrarSnack(tr(context, 'vendedor_operaciones.proveedores_snack_agregado'));
          _cargar();
        },
      ),
    );
  }

  void _abrirDialogoContactar(ProveedorModelo p) {
    showDialog(
      context: context,
      builder: (_) => _DialogoContactar(
        proveedor: p,
        esOscuro: widget.esOscuro,
        onChatear: () => _chatear(p),
        onCorreo: () => _enviarCorreo(p.email),
      ),
    );
  }

  void _abrirDialogoPerfil(ProveedorModelo p) {
    showDialog(
      context: context,
      builder: (_) => _DialogoPerfilProveedor(
        proveedor: p,
        esOscuro: widget.esOscuro,
        alContactar: () {
          Navigator.of(context).pop();
          _abrirDialogoContactar(p);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = widget.esOscuro;
    return Container(
      color: CraftHubColors.fondo(esOscuro),
      child: LayoutBuilder(builder: (context, constraints) {
        final padHorizontal = constraints.maxWidth < 600 ? 14.0 : 24.0;
        return RefreshIndicator(
          color: CraftHubColors.vinoTinto,
          onRefresh: _cargar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(padHorizontal, 20, padHorizontal, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroProveedores(esOscuro: esOscuro, alAgregar: _abrirDialogoAgregar),
                const SizedBox(height: 20),
                _BarraFiltrosProveedores(
                  esOscuro: esOscuro,
                  controladorBusqueda: _busquedaCtrl,
                  alBuscar: _onBuscar,
                  categorias: ['Todas las categorías', ...kCategoriasProveedor],
                  categoriaSeleccionada: _categoriaFiltro,
                  alCambiarCategoria: (v) {
                    setState(() => _categoriaFiltro = v ?? 'Todas las categorías');
                    _cargar();
                  },
                  ubicacionSeleccionada: _ubicacionFiltro,
                  alCambiarUbicacion: (v) {
                    setState(() => _ubicacionFiltro = v ?? 'Todas');
                    _cargar();
                  },
                  calificacionSeleccionada: _calificacionMin,
                  opcionesCalificacion: _opcionesCalificacion,
                  alCambiarCalificacion: (v) {
                    setState(() => _calificacionMin = v);
                    _cargar();
                  },
                  ordenSeleccionado: _orden,
                  opcionesOrden: _opcionesOrden,
                  alCambiarOrden: (v) {
                    setState(() => _orden = v ?? 'relevantes');
                    _cargar();
                  },
                ),
                const SizedBox(height: 20),
                if (_cargando)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto)),
                  )
                else if (_error != null)
                  _EstadoErrorProveedores(mensaje: _error!, esOscuro: esOscuro, alReintentar: _cargar)
                else if (_proveedores.isEmpty)
                  _EstadoVacioProveedores(esOscuro: esOscuro, alAgregar: _abrirDialogoAgregar)
                else
                  _GridProveedores(
                    proveedores: _proveedores,
                    esOscuro: esOscuro,
                    favoritos: _favoritos,
                    alToggleFavorito: (id) => setState(() {
                      _favoritos.contains(id) ? _favoritos.remove(id) : _favoritos.add(id);
                    }),
                    alContactar: _abrirDialogoContactar,
                    alVerPerfil: _abrirDialogoPerfil,
                  ),
                const SizedBox(height: 24),
                _BannerQuieroSerProveedor(esOscuro: esOscuro, alPresionar: _abrirDialogoAgregar),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── HÉROE ────────────────────────────────────────────────────────────────────
class _HeroProveedores extends StatelessWidget {
  final bool esOscuro;
  final VoidCallback alAgregar;
  const _HeroProveedores({required this.esOscuro, required this.alAgregar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(esOscuro),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CraftHubColors.borde(esOscuro)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: esOscuro ? 0.22 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [CraftHubColors.vinoTinto, CraftHubColors.vinoTintoOscuro]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_2_rounded, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(tr(context, 'vendedor_operaciones.proveedores_titulo'),
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 21, fontWeight: FontWeight.w700, color: CraftHubColors.textoPrincipal(esOscuro))),
                    const SizedBox(width: 6),
                    const Icon(Icons.auto_awesome_rounded, size: 17, color: CraftHubColors.vinoTinto),
                  ]),
                  Text(tr(context, 'vendedor_operaciones.proveedores_subtitulo'),
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: CraftHubColors.textoSecundario(esOscuro))),
                ],
              ),
            ),
          ]),
          _BotonAgregarProveedor(esOscuro: esOscuro, onTap: alAgregar),
        ],
      ),
    );
  }
}

class _BotonAgregarProveedor extends StatefulWidget {
  final bool esOscuro;
  final VoidCallback onTap;
  const _BotonAgregarProveedor({required this.esOscuro, required this.onTap});

  @override
  State<_BotonAgregarProveedor> createState() => _BotonAgregarProveedorState();
}

class _BotonAgregarProveedorState extends State<_BotonAgregarProveedor> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: _hover ? CraftHubColors.vinoTintoOscuro : CraftHubColors.vinoTinto,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [BoxShadow(color: CraftHubColors.vinoTinto.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(tr(context, 'vendedor_operaciones.proveedores_agregar_boton'),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ),
    );
  }
}

// ── BARRA DE FILTROS ──────────────────────────────────────────────────────
class _BarraFiltrosProveedores extends StatelessWidget {
  final bool esOscuro;
  final TextEditingController controladorBusqueda;
  final ValueChanged<String> alBuscar;
  final List<String> categorias;
  final String categoriaSeleccionada;
  final ValueChanged<String?> alCambiarCategoria;
  final String ubicacionSeleccionada;
  final ValueChanged<String?> alCambiarUbicacion;
  final double? calificacionSeleccionada;
  final Map<double?, String> opcionesCalificacion;
  final ValueChanged<double?> alCambiarCalificacion;
  final String ordenSeleccionado;
  final Map<String, String> opcionesOrden;
  final ValueChanged<String?> alCambiarOrden;

  const _BarraFiltrosProveedores({
    required this.esOscuro,
    required this.controladorBusqueda,
    required this.alBuscar,
    required this.categorias,
    required this.categoriaSeleccionada,
    required this.alCambiarCategoria,
    required this.ubicacionSeleccionada,
    required this.alCambiarUbicacion,
    required this.calificacionSeleccionada,
    required this.opcionesCalificacion,
    required this.alCambiarCalificacion,
    required this.ordenSeleccionado,
    required this.opcionesOrden,
    required this.alCambiarOrden,
  });

  Widget _caja(Widget child, {double? ancho}) => Container(
        width: ancho,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: CraftHubColors.panel(esOscuro),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CraftHubColors.borde(esOscuro)),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final campoBusqueda = _caja(Row(children: [
      Icon(Icons.search_rounded, size: 18, color: CraftHubColors.textoSecundario(esOscuro)),
      const SizedBox(width: 8),
      Expanded(
        child: TextField(
          controller: controladorBusqueda,
          onChanged: alBuscar,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: CraftHubColors.textoPrincipal(esOscuro)),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hintText: tr(context, 'vendedor_operaciones.proveedores_buscar_hint'),
            hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: CraftHubColors.textoSecundario(esOscuro)),
          ),
        ),
      ),
    ]));

    Widget dropdown<T>(T valor, List<T> opciones, String Function(T) etiqueta, ValueChanged<T?> onChanged, {double ancho = 170}) {
      return _caja(
        DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: valor,
            isDense: true,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            dropdownColor: CraftHubColors.panel(esOscuro),
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: CraftHubColors.textoPrincipal(esOscuro)),
            items: opciones.map((o) => DropdownMenuItem(value: o, child: Text(etiqueta(o), overflow: TextOverflow.ellipsis))).toList(),
            onChanged: onChanged,
          ),
        ),
        ancho: ancho,
      );
    }

    final dropdownCategoria = dropdown(categoriaSeleccionada, categorias, (v) => v, alCambiarCategoria);
    final dropdownUbicacion = dropdown(ubicacionSeleccionada, ['Todas', ...kProvinciasPanama], (v) => v, alCambiarUbicacion);
    final dropdownCalificacion = dropdown<double?>(
      calificacionSeleccionada,
      opcionesCalificacion.keys.toList(),
      (v) => tr(context, opcionesCalificacion[v]!),
      alCambiarCalificacion,
    );
    final dropdownOrden = dropdown(ordenSeleccionado, opcionesOrden.keys.toList(), (v) => tr(context, opcionesOrden[v]!), alCambiarOrden);

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 900) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          campoBusqueda,
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: [
            SizedBox(width: (constraints.maxWidth - 10) / 2, child: dropdownCategoria),
            SizedBox(width: (constraints.maxWidth - 10) / 2, child: dropdownUbicacion),
            SizedBox(width: (constraints.maxWidth - 10) / 2, child: dropdownCalificacion),
            SizedBox(width: (constraints.maxWidth - 10) / 2, child: dropdownOrden),
          ]),
        ]);
      }
      return Row(children: [
        Expanded(flex: 3, child: campoBusqueda),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: dropdownCategoria),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: dropdownUbicacion),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: dropdownCalificacion),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: dropdownOrden),
      ]);
    });
  }
}

// ── ESTADOS VACÍO / ERROR ─────────────────────────────────────────────────
class _EstadoVacioProveedores extends StatelessWidget {
  final bool esOscuro;
  final VoidCallback alAgregar;
  const _EstadoVacioProveedores({required this.esOscuro, required this.alAgregar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(esOscuro),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CraftHubColors.borde(esOscuro)),
      ),
      child: Column(children: [
        Icon(Icons.groups_2_outlined, size: 42, color: CraftHubColors.textoSecundario(esOscuro)),
        const SizedBox(height: 10),
        Text(tr(context, 'vendedor_operaciones.proveedores_vacio_titulo'),
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, color: CraftHubColors.textoSecundario(esOscuro))),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: alAgregar,
          icon: const Icon(Icons.add_rounded, color: CraftHubColors.vinoTinto),
          label: Text(tr(context, 'vendedor_operaciones.proveedores_vacio_agregar_primero'), style: const TextStyle(fontFamily: 'Poppins', color: CraftHubColors.vinoTinto, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _EstadoErrorProveedores extends StatelessWidget {
  final String mensaje;
  final bool esOscuro;
  final VoidCallback alReintentar;
  const _EstadoErrorProveedores({required this.mensaje, required this.esOscuro, required this.alReintentar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(esOscuro),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CraftHubColors.borde(esOscuro)),
      ),
      child: Column(children: [
        const Icon(Icons.error_outline_rounded, size: 36, color: CraftHubColors.error),
        const SizedBox(height: 10),
        Text(tr(context, 'vendedor_operaciones.proveedores_error_titulo'),
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: CraftHubColors.textoPrincipal(esOscuro))),
        const SizedBox(height: 4),
        Text(mensaje, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: CraftHubColors.textoSecundario(esOscuro))),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: alReintentar,
          icon: const Icon(Icons.refresh_rounded, color: CraftHubColors.vinoTinto),
          label: Text(tr(context, 'vendedor_operaciones.proveedores_reintentar'), style: const TextStyle(fontFamily: 'Poppins', color: CraftHubColors.vinoTinto, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

// ── GRID DE TARJETAS ──────────────────────────────────────────────────────
class _GridProveedores extends StatelessWidget {
  final List<ProveedorModelo> proveedores;
  final bool esOscuro;
  final Set<String> favoritos;
  final ValueChanged<String> alToggleFavorito;
  final ValueChanged<ProveedorModelo> alContactar;
  final ValueChanged<ProveedorModelo> alVerPerfil;

  const _GridProveedores({
    required this.proveedores,
    required this.esOscuro,
    required this.favoritos,
    required this.alToggleFavorito,
    required this.alContactar,
    required this.alVerPerfil,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columnas = constraints.maxWidth >= 1100 ? 3 : (constraints.maxWidth >= 700 ? 2 : 1);
      const espacio = 16.0;
      final ancho = (constraints.maxWidth - espacio * (columnas - 1)) / columnas;
      return Wrap(
        spacing: espacio,
        runSpacing: espacio,
        children: proveedores
            .map((p) => SizedBox(
                  width: ancho,
                  child: _TarjetaProveedor(
                    proveedor: p,
                    esOscuro: esOscuro,
                    esFavorito: favoritos.contains(p.id),
                    alToggleFavorito: () => alToggleFavorito(p.id),
                    alContactar: () => alContactar(p),
                    alVerPerfil: () => alVerPerfil(p),
                  ),
                ))
            .toList(),
      );
    });
  }
}

class _TarjetaProveedor extends StatelessWidget {
  final ProveedorModelo proveedor;
  final bool esOscuro;
  final bool esFavorito;
  final VoidCallback alToggleFavorito;
  final VoidCallback alContactar;
  final VoidCallback alVerPerfil;

  const _TarjetaProveedor({
    required this.proveedor,
    required this.esOscuro,
    required this.esFavorito,
    required this.alToggleFavorito,
    required this.alContactar,
    required this.alVerPerfil,
  });

  @override
  Widget build(BuildContext context) {
    final p = proveedor;
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);

    return Container(
      decoration: BoxDecoration(
        color: CraftHubColors.panel(esOscuro),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CraftHubColors.borde(esOscuro)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: esOscuro ? 0.22 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Image.network(p.imagenEfectiva, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _imagenPlaceholder()),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: alToggleFavorito,
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle),
                  child: Icon(esFavorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 16, color: CraftHubColors.vinoTinto),
                ),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(p.nombre, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: colorTexto)),
                  ),
                  if (p.verificado) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, size: 16, color: CraftHubColors.vinoTinto),
                  ],
                ]),
                if (p.propietario.isNotEmpty)
                  Text(p.propietario, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: colorSec)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: CraftHubColors.vinoTinto),
                  const SizedBox(width: 3),
                  Text(p.ubicacion, style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: colorSec)),
                ]),
                const SizedBox(height: 8),
                Text(p.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, height: 1.4, color: colorSec)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 15, color: Color(0xFFD4A843)),
                  const SizedBox(width: 3),
                  Text(p.calificacion.toStringAsFixed(1),
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w700, color: colorTexto)),
                  Text(' (${p.totalResenas})', style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: colorSec)),
                ]),
                if (p.materiales.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: p.materiales.take(3).map((m) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: CraftHubColors.vinoTintoSuave, borderRadius: BorderRadius.circular(20)),
                          child: Text(m, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.5, fontWeight: FontWeight.w600, color: CraftHubColors.vinoTinto)),
                        )).toList(),
                  ),
                ],
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: alContactar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CraftHubColors.vinoTinto,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.white),
                      label: Text(tr(context, 'vendedor_operaciones.proveedores_tarjeta_contactar'), style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: alVerPerfil,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: CraftHubColors.borde(esOscuro)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(Icons.expand_more_rounded, size: 15, color: colorTexto),
                      label: Text(tr(context, 'vendedor_operaciones.proveedores_tarjeta_ver_perfil'), style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: colorTexto)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagenPlaceholder() => Container(
        color: CraftHubColors.vinoTintoSuave,
        alignment: Alignment.center,
        child: const Icon(Icons.inventory_2_outlined, size: 32, color: CraftHubColors.vinoTinto),
      );
}

// ── BANNER INFERIOR ────────────────────────────────────────────────────────
class _BannerQuieroSerProveedor extends StatelessWidget {
  final bool esOscuro;
  final VoidCallback alPresionar;
  const _BannerQuieroSerProveedor({required this.esOscuro, required this.alPresionar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(esOscuro),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CraftHubColors.borde(esOscuro)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: CraftHubColors.vinoTintoSuave, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.handshake_outlined, size: 22, color: CraftHubColors.vinoTinto),
            ),
            const SizedBox(width: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(tr(context, 'vendedor_operaciones.proveedores_banner_titulo'),
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: CraftHubColors.textoPrincipal(esOscuro))),
                Text(tr(context, 'vendedor_operaciones.proveedores_banner_subtitulo'),
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: CraftHubColors.textoSecundario(esOscuro))),
              ]),
            ),
          ]),
          OutlinedButton(
            onPressed: alPresionar,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CraftHubColors.vinoTinto),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
            child: Text(tr(context, 'vendedor_operaciones.proveedores_banner_boton'),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: CraftHubColors.vinoTinto)),
          ),
        ],
      ),
    );
  }
}

// ── DIÁLOGO: AGREGAR PROVEEDOR ────────────────────────────────────────────
class _DialogoAgregarProveedor extends StatefulWidget {
  final bool esOscuro;
  final String nombreVendedor;
  final VoidCallback onCreado;

  const _DialogoAgregarProveedor({required this.esOscuro, required this.nombreVendedor, required this.onCreado});

  @override
  State<_DialogoAgregarProveedor> createState() => _DialogoAgregarProveedorState();
}

class _DialogoAgregarProveedorState extends State<_DialogoAgregarProveedor> {
  final _ctrlNombre = TextEditingController();
  final _ctrlPropietario = TextEditingController();
  final _ctrlDescripcion = TextEditingController();
  final _ctrlMateriales = TextEditingController();
  final _ctrlTelefono = TextEditingController();
  final _ctrlEmail = TextEditingController();
  final _ctrlImagen = TextEditingController();
  String _categoria = kCategoriasProveedor.first;
  String _ubicacion = kProvinciasPanama.first;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _ctrlNombre.dispose();
    _ctrlPropietario.dispose();
    _ctrlDescripcion.dispose();
    _ctrlMateriales.dispose();
    _ctrlTelefono.dispose();
    _ctrlEmail.dispose();
    _ctrlImagen.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_ctrlNombre.text.trim().isEmpty) {
      setState(() => _error = tr(context, 'vendedor_operaciones.proveedores_error_nombre_obligatorio'));
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ProveedoresApiService.crearProveedor(
        nombre: _ctrlNombre.text.trim(),
        propietario: _ctrlPropietario.text.trim().isEmpty ? null : _ctrlPropietario.text.trim(),
        categoria: _categoria,
        ubicacion: _ubicacion,
        descripcion: _ctrlDescripcion.text.trim().isEmpty ? null : _ctrlDescripcion.text.trim(),
        materiales: _ctrlMateriales.text.split(',').map((m) => m.trim()).where((m) => m.isNotEmpty).toList(),
        imagenUrl: _ctrlImagen.text.trim().isEmpty ? null : _ctrlImagen.text.trim(),
        telefono: _ctrlTelefono.text.trim().isEmpty ? null : _ctrlTelefono.text.trim(),
        email: _ctrlEmail.text.trim().isEmpty ? null : _ctrlEmail.text.trim(),
        creadoPor: widget.nombreVendedor,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCreado();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Widget _campo(String etiqueta, TextEditingController ctrl, {TextInputType? tipo, int maxLines = 1}) {
    final esOscuro = widget.esOscuro;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(etiqueta, style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: CraftHubColors.textoSecundario(esOscuro))),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: tipo,
        maxLines: maxLines,
        style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, color: CraftHubColors.textoPrincipal(esOscuro)),
        decoration: InputDecoration(
          filled: true,
          fillColor: CraftHubColors.fondo(esOscuro),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: CraftHubColors.borde(esOscuro))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: CraftHubColors.vinoTinto, width: 1.3)),
        ),
      ),
    ]);
  }

  Widget _selector(String etiqueta, String valor, List<String> opciones, ValueChanged<String?> onChanged) {
    final esOscuro = widget.esOscuro;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(etiqueta, style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: CraftHubColors.textoSecundario(esOscuro))),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: CraftHubColors.fondo(esOscuro),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CraftHubColors.borde(esOscuro)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: valor,
            isExpanded: true,
            dropdownColor: CraftHubColors.panel(esOscuro),
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, color: CraftHubColors.textoPrincipal(esOscuro)),
            items: opciones.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = widget.esOscuro;
    return Dialog(
      backgroundColor: CraftHubColors.panel(esOscuro),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(tr(context, 'vendedor_operaciones.proveedores_agregar_boton'),
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700, color: CraftHubColors.textoPrincipal(esOscuro))),
                  ),
                  GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close_rounded, size: 20, color: CraftHubColors.textoSecundario(esOscuro))),
                ]),
                const SizedBox(height: 16),
                _campo(tr(context, 'vendedor_operaciones.proveedores_campo_nombre_negocio'), _ctrlNombre),
                const SizedBox(height: 12),
                _campo(tr(context, 'vendedor_operaciones.proveedores_campo_nombre_contacto'), _ctrlPropietario),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _selector(tr(context, 'vendedor_operaciones.proveedores_campo_categoria'), _categoria, kCategoriasProveedor, (v) => setState(() => _categoria = v!))),
                  const SizedBox(width: 12),
                  Expanded(child: _selector(tr(context, 'vendedor_operaciones.proveedores_campo_ubicacion'), _ubicacion, kProvinciasPanama, (v) => setState(() => _ubicacion = v!))),
                ]),
                const SizedBox(height: 12),
                _campo(tr(context, 'vendedor_operaciones.proveedores_campo_descripcion'), _ctrlDescripcion, maxLines: 3),
                const SizedBox(height: 12),
                _campo(tr(context, 'vendedor_operaciones.proveedores_campo_materiales'), _ctrlMateriales),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _campo(tr(context, 'vendedor_operaciones.proveedores_campo_telefono'), _ctrlTelefono, tipo: TextInputType.phone)),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(tr(context, 'vendedor_operaciones.proveedores_campo_correo'), _ctrlEmail, tipo: TextInputType.emailAddress)),
                ]),
                const SizedBox(height: 12),
                _campo(tr(context, 'vendedor_operaciones.proveedores_campo_imagen_url'), _ctrlImagen),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: CraftHubColors.error)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _enviando ? null : _guardar,
                    style: ElevatedButton.styleFrom(backgroundColor: CraftHubColors.vinoTinto, padding: const EdgeInsets.symmetric(vertical: 13)),
                    child: _enviando
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(tr(context, 'vendedor_operaciones.proveedores_dialogo_boton_agregar'), style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600)),
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

// ── DIÁLOGO: CONTACTAR ────────────────────────────────────────────────────
class _DialogoContactar extends StatelessWidget {
  final ProveedorModelo proveedor;
  final bool esOscuro;
  final VoidCallback onChatear;
  final VoidCallback onCorreo;

  const _DialogoContactar({required this.proveedor, required this.esOscuro, required this.onChatear, required this.onCorreo});

  @override
  Widget build(BuildContext context) {
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);
    return Dialog(
      backgroundColor: CraftHubColors.panel(esOscuro),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${tr(context, 'vendedor_operaciones.proveedores_contactar_a_prefijo')}${proveedor.nombre}',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: colorTexto)),
            const SizedBox(height: 4),
            Text(tr(context, 'vendedor_operaciones.proveedores_contactar_subtitulo'), style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: colorSec)),
            const SizedBox(height: 18),
            _OpcionContacto(icono: Icons.forum_outlined, titulo: tr(context, 'vendedor_operaciones.proveedores_opcion_chatear_titulo'), subtitulo: tr(context, 'vendedor_operaciones.proveedores_opcion_chatear_subtitulo'), esOscuro: esOscuro, onTap: () {
              Navigator.pop(context);
              onChatear();
            }),
            if (proveedor.email.isNotEmpty) ...[
              const SizedBox(height: 10),
              _OpcionContacto(icono: Icons.mail_outline_rounded, titulo: tr(context, 'vendedor_operaciones.proveedores_campo_correo'), subtitulo: proveedor.email, esOscuro: esOscuro, onTap: () {
                Navigator.pop(context);
                onCorreo();
              }),
            ],
          ]),
        ),
      ),
    );
  }
}

class _OpcionContacto extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final bool esOscuro;
  final VoidCallback onTap;

  const _OpcionContacto({required this.icono, required this.titulo, required this.subtitulo, required this.esOscuro, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CraftHubColors.fondo(esOscuro),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CraftHubColors.borde(esOscuro)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: CraftHubColors.vinoTintoSuave, borderRadius: BorderRadius.circular(10)),
            child: Icon(icono, size: 17, color: CraftHubColors.vinoTinto),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: CraftHubColors.textoPrincipal(esOscuro))),
              Text(subtitulo, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: CraftHubColors.textoSecundario(esOscuro))),
            ]),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: CraftHubColors.textoSecundario(esOscuro)),
        ]),
      ),
    );
  }
}

// ── DIÁLOGO: VER PERFIL ───────────────────────────────────────────────────
class _DialogoPerfilProveedor extends StatelessWidget {
  final ProveedorModelo proveedor;
  final bool esOscuro;
  final VoidCallback alContactar;

  const _DialogoPerfilProveedor({required this.proveedor, required this.esOscuro, required this.alContactar});

  @override
  Widget build(BuildContext context) {
    final p = proveedor;
    final colorTexto = CraftHubColors.textoPrincipal(esOscuro);
    final colorSec = CraftHubColors.textoSecundario(esOscuro);
    return Dialog(
      backgroundColor: CraftHubColors.panel(esOscuro),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Row(children: [
                    Text(p.nombre, style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: colorTexto)),
                    if (p.verificado) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, size: 18, color: CraftHubColors.vinoTinto),
                    ],
                  ]),
                ),
                GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close_rounded, size: 20, color: colorSec)),
              ]),
              if (p.propietario.isNotEmpty) Text(p.propietario, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: colorSec)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Image.network(p.imagenEfectiva, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(color: CraftHubColors.vinoTintoSuave,
                          child: const Icon(Icons.inventory_2_outlined, color: CraftHubColors.vinoTinto))),
                ),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: CraftHubColors.vinoTintoSuave, borderRadius: BorderRadius.circular(20)),
                  child: Text(p.categoria, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: CraftHubColors.vinoTinto)),
                ),
                const SizedBox(width: 8),
                Icon(Icons.location_on_outlined, size: 14, color: colorSec),
                const SizedBox(width: 2),
                Text(p.ubicacion, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: colorSec)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.star_rounded, size: 17, color: Color(0xFFD4A843)),
                const SizedBox(width: 4),
                Text(p.calificacion.toStringAsFixed(1), style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w700, color: colorTexto)),
                Text(' (${p.totalResenas} ${tr(context, 'vendedor_operaciones.proveedores_resenas_palabra')})', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: colorSec)),
              ]),
              if (p.descripcion.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(p.descripcion, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, height: 1.5, color: colorTexto)),
              ],
              if (p.materiales.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(tr(context, 'vendedor_operaciones.proveedores_materiales_header'), style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: colorSec)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: p.materiales.map((m) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: CraftHubColors.borde(esOscuro))),
                        child: Text(m, style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: colorTexto)),
                      )).toList(),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: alContactar,
                  style: ElevatedButton.styleFrom(backgroundColor: CraftHubColors.vinoTinto, padding: const EdgeInsets.symmetric(vertical: 13)),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                  label: Text(tr(context, 'vendedor_operaciones.proveedores_contactar_proveedor_boton'), style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
