// lib/screens/vendedor/pantalla_inventario.dart
// Panel de inventario del vendedor — se inserta en _obtenerPantallaActual()
// NO contiene Scaffold, Sidebar ni TopBar propios

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/modelo_producto_inventario.dart';
import '../../../widgets/vendedor/widgets_inventario.dart';
import '../../services/vendedor_api_service.dart';
import '../../services/api_service.dart';
import '../../services/exportador_inventario.dart';
import '../comprador/pantalla_detalle_producto.dart';
import '../../core/i18n/i18n.dart';

class PantallaInventario extends StatefulWidget {
  final String nombreVendedor;

  const PantallaInventario({
    super.key,
    required this.nombreVendedor,
  });

  @override
  State<PantallaInventario> createState() => _PantallaInventarioState();
}

class _PantallaInventarioState extends State<PantallaInventario> {
  // ── Estado de la tabla ────────────────────────────────────────────────────
  List<ProductoInventario> _productos = [];
  List<ProductoInventario> _productosFiltrados = [];
  bool _cargando = true;
  String? _error;

  // ── Filtros ───────────────────────────────────────────────────────────────
  String _busqueda = '';
  String _coleccionFiltro = 'Todas las colecciones';
  String _estadoFiltro = 'Todos';
  String _categoriaFiltro = 'Todas';

  // ── Paginación ────────────────────────────────────────────────────────────
  int _paginaActual = 1;
  int _registrosPorPagina = 25;

  // ── Ordenamiento ─────────────────────────────────────────────────────────
  String _columnaOrden = 'nombre';
  bool _ordenAscendente = true;

  // ── Estadísticas (vendrán del backend) ───────────────────────────────────
  int _totalProductos = 0;
  int _productosActivos = 0;
  int _productosAgotados = 0;
  int _visitasMes = 0;
  double _ventasTotales = 0;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  // ── Carga de datos ────────────────────────────────────────────────────────
  // 🔌 API: GET /api/vendedor/{vendedorId}/productos
  // Headers: { 'Authorization': 'Bearer $token' }
  // Respuesta: { "productos": [...], "estadisticas": { "total": N, ... } }
  Future<void> _cargarProductos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final respuesta = await VendedorApiService.cargarProductos(widget.nombreVendedor);
      final stats = respuesta.estadisticas;

      _productos = respuesta.productos;
      _totalProductos = int.tryParse((stats['total'] ?? 0).toString()) ?? 0;
      _productosActivos = int.tryParse((stats['activos'] ?? 0).toString()) ?? 0;
      _productosAgotados = int.tryParse((stats['agotados'] ?? 0).toString()) ?? 0;
      _visitasMes = int.tryParse((stats['visitas_mes'] ?? 0).toString()) ?? 0;
      _ventasTotales = double.tryParse((stats['ventas_totales'] ?? 0).toString()) ?? 0;

      _aplicarFiltros();
    } catch (e) {
      _productos = [];
      _productosFiltrados = [];
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
  void _aplicarFiltros() {
    var lista = _productos.where((p) {
      final coincideBusqueda =
          p.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
          p.sku.toLowerCase().contains(_busqueda.toLowerCase());
      final coincideColeccion =
          _coleccionFiltro == 'Todas las colecciones' ||
          p.coleccion == _coleccionFiltro;
      final coincideEstado =
          _estadoFiltro == 'Todos' ||
          p.estado.name.toLowerCase() == _estadoFiltro.toLowerCase();
      final coincideCategoria =
          _categoriaFiltro == 'Todas' || p.categoria == _categoriaFiltro;
      return coincideBusqueda &&
          coincideColeccion &&
          coincideEstado &&
          coincideCategoria;
    }).toList();

    // Ordenar
    lista.sort((a, b) {
      int cmp = 0;
      switch (_columnaOrden) {
        case 'nombre':
          cmp = a.nombre.compareTo(b.nombre);
          break;
        case 'precio':
          cmp = a.precio.compareTo(b.precio);
          break;
        case 'stock':
          cmp = a.stock.compareTo(b.stock);
          break;
        case 'ventas':
          cmp = a.ventas.compareTo(b.ventas);
          break;
        default:
          cmp = 0;
      }
      return _ordenAscendente ? cmp : -cmp;
    });

    setState(() {
      _productosFiltrados = lista;
      _paginaActual = 1;
    });
  }

  List<ProductoInventario> get _paginaProductos {
    final inicio = (_paginaActual - 1) * _registrosPorPagina;
    final fin = (inicio + _registrosPorPagina).clamp(
      0,
      _productosFiltrados.length,
    );
    return _productosFiltrados.sublist(inicio, fin);
  }

  int get _totalPaginas =>
      (_productosFiltrados.length / _registrosPorPagina).ceil().clamp(1, 999);

  void _ordenarPor(String columna) {
    setState(() {
      if (_columnaOrden == columna) {
        _ordenAscendente = !_ordenAscendente;
      } else {
        _columnaOrden = columna;
        _ordenAscendente = true;
      }
    });
    _aplicarFiltros();
  }

  Future<void> _confirmarEliminarProducto(ProductoInventario producto) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr(context, 'vendedor_inventario.eliminar_producto_titulo'),
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
            '${tr(context, 'vendedor_inventario.confirmar_eliminar_prefijo')}${producto.nombre}${tr(context, 'vendedor_inventario.confirmar_eliminar_sufijo')}',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr(context, 'vendedor_inventario.cancelar'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828), foregroundColor: Colors.white),
            child: Text(tr(context, 'vendedor_inventario.eliminar')),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    try {
      await ApiService.eliminarProducto(producto.id);
      setState(() => _productos.removeWhere((p) => p.id == producto.id));
      _aplicarFiltros();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'vendedor_inventario.no_se_pudo_eliminar_prefijo')}${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  Future<void> _nuevoProducto() async {
    final creado = await showDialog<ProductoInventario>(
      context: context,
      builder: (_) => DialogoNuevoProducto(nombreVendedor: widget.nombreVendedor),
    );
    if (creado == null) return;
    setState(() => _productos.add(creado));
    _aplicarFiltros();
  }

  Future<void> _exportarInventario() async {
    try {
      await ExportadorInventario.exportarCsv(_productosFiltrados);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'vendedor_inventario.exportado_correctamente'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'vendedor_inventario.no_se_pudo_exportar_prefijo')}${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = esModoOscuro
        ? const Color(0xFF121212)
        : const Color(0xFFF9F6F0);

    if (_cargando) {
      return Container(
        color: colorFondo,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF821515)),
        ),
      );
    }

    if (_error != null) {
      return Container(
        color: colorFondo,
        child: Center(
          child: Text(
            '${tr(context, 'vendedor_inventario.no_se_pudo_cargar_prefijo')}$_error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    return Container(
      color: colorFondo,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Encabezado ──────────────────────────────────────────
                  _construirEncabezado(
                    esModoOscuro,
                  ).animate().fadeIn(duration: 350.ms),

                  const SizedBox(height: 28),

                  // ── Estadísticas ────────────────────────────────────────
                  _construirEstadisticas()
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 80.ms)
                      .slideY(begin: 0.04, end: 0),

                  const SizedBox(height: 28),

                  // ── Barra de filtros ────────────────────────────────────
                  _construirBarraFiltros(
                    esModoOscuro,
                  ).animate().fadeIn(duration: 400.ms, delay: 140.ms),

                  const SizedBox(height: 16),

                  // ── Grilla de productos ─────────────────────────────────
                  _construirGrid(
                    esModoOscuro,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Encabezado ──────────────────────────────────────────────────────────────
  Widget _construirEncabezado(bool esModoOscuro) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(context, 'vendedor_inventario.titulo_pantalla'),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: esModoOscuro
                    ? Colors.white
                    : const Color(0xFF2C1810),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr(context, 'vendedor_inventario.subtitulo_pantalla'),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: esModoOscuro ? Colors.white54 : const Color(0xFF6B5A52),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Botón exportar
        OutlinedButton.icon(
          onPressed: _exportarInventario,
          icon: const Icon(Icons.upload_outlined, size: 16),
          label: Text(
            tr(context, 'vendedor_inventario.exportar_inventario'),
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: esModoOscuro
                ? Colors.white70
                : const Color(0xFF4A4A4A),
            side: BorderSide(
              color: esModoOscuro
                  ? const Color(0xFF3A3A3A)
                  : const Color(0xFFDDD5CC),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Botón agregar
        ElevatedButton.icon(
          onPressed: _nuevoProducto,
          icon: const Icon(Icons.add, size: 16),
          label: Text(
            tr(context, 'vendedor_inventario.agregar_producto'),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF821515),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ── Estadísticas ─────────────────────────────────────────────────────────────
  Widget _construirEstadisticas() {
    return Row(
      children: [
        TarjetaEstadistica(
          icono: Icons.inventory_2_outlined,
          colorIcono: const Color(0xFF7B5EA7),
          valor: '$_totalProductos',
          etiqueta: tr(context, 'vendedor_inventario.stat_productos_totales'),
        ),
        const SizedBox(width: 16),
        TarjetaEstadistica(
          icono: Icons.check_circle_outline,
          colorIcono: const Color(0xFF2E7D32),
          valor: '$_productosActivos',
          etiqueta: tr(context, 'vendedor_inventario.stat_activos'),
        ),
        const SizedBox(width: 16),
        TarjetaEstadistica(
          icono: Icons.label_off_outlined,
          colorIcono: const Color(0xFFE65100),
          valor: '$_productosAgotados',
          etiqueta: tr(context, 'vendedor_inventario.stat_agotados'),
        ),
        const SizedBox(width: 16),
        TarjetaEstadistica(
          icono: Icons.visibility_outlined,
          colorIcono: const Color(0xFF1565C0),
          valor: '${(_visitasMes / 1000).toStringAsFixed(1)}K',
          etiqueta: tr(context, 'vendedor_inventario.stat_visitas_mes'),
        ),
        const SizedBox(width: 16),
        TarjetaEstadistica(
          icono: Icons.attach_money,
          colorIcono: const Color(0xFF821515),
          valor: '\$${_ventasTotales.toStringAsFixed(2)}',
          etiqueta: tr(context, 'vendedor_inventario.stat_ventas_totales'),
        ),
      ],
    );
  }

  // ── Barra de filtros ──────────────────────────────────────────────────────────
  Widget _construirBarraFiltros(bool esModoOscuro) {
    final colorTarjeta = esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white;
    final estiloCampo = InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: esModoOscuro
              ? const Color(0xFF3A3A3A)
              : const Color(0xFFE0D8D0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: esModoOscuro
              ? const Color(0xFF3A3A3A)
              : const Color(0xFFE0D8D0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF821515)),
      ),
      filled: true,
      fillColor: colorTarjeta,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorTarjeta,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esModoOscuro
              ? const Color(0xFF2E2E2E)
              : const Color(0xFFEDE8E2),
        ),
      ),
      child: Row(
        children: [
          // Búsqueda
          SizedBox(
            width: 240,
            child: TextField(
              onChanged: (v) {
                _busqueda = v;
                _aplicarFiltros();
              },
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: esModoOscuro ? Colors.white : const Color(0xFF1A1A1A),
              ),
              decoration: estiloCampo.copyWith(
                hintText: tr(context, 'vendedor_inventario.buscar_producto_hint'),
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: esModoOscuro
                      ? Colors.white38
                      : const Color(0xFFBBB0A8),
                ),
                suffixIcon: const Icon(Icons.search, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Filtro colección
          // 🔌 API: GET /api/vendedor/{vendedorId}/colecciones → poblar el DropdownButton
          _DropdownFiltro(
            valor: _coleccionFiltro,
            opciones: const [
              'Todas las colecciones',
              'Joyas de mi Tierra',
              'Tejidos Ancestrales',
              'Molas Guna',
              'Raíces y Manos',
              'Arte y Cultura',
              'Tradiciones de Panamá',
            ],
            alCambiar: (v) {
              setState(() => _coleccionFiltro = v!);
              _aplicarFiltros();
            },
            esModoOscuro: esModoOscuro,
          ),
          const SizedBox(width: 12),

          // Filtro estado
          _DropdownFiltro(
            valor: 'Estado: $_estadoFiltro',
            opciones: const [
              'Estado: Todos',
              'Estado: activo',
              'Estado: agotado',
              'Estado: borrador',
            ],
            alCambiar: (v) {
              setState(() => _estadoFiltro = v!.replaceFirst('Estado: ', ''));
              _aplicarFiltros();
            },
            esModoOscuro: esModoOscuro,
          ),
          const SizedBox(width: 12),

          // Filtro categoría
          // 🔌 API: GET /api/categorias → poblar el DropdownButton
          _DropdownFiltro(
            valor: 'Categoría: $_categoriaFiltro',
            opciones: const [
              'Categoría: Todas',
              'Categoría: Accesorios',
              'Categoría: Bolsos',
              'Categoría: Textiles',
              'Categoría: Cerámica',
              'Categoría: Decoración',
              'Categoría: Sombreros',
            ],
            alCambiar: (v) {
              setState(
                () => _categoriaFiltro = v!.replaceFirst('Categoría: ', ''),
              );
              _aplicarFiltros();
            },
            esModoOscuro: esModoOscuro,
          ),

          const Spacer(),

          // Limpiar filtros
          TextButton.icon(
            onPressed: () {
              setState(() {
                _busqueda = '';
                _coleccionFiltro = 'Todas las colecciones';
                _estadoFiltro = 'Todos';
                _categoriaFiltro = 'Todas';
              });
              _aplicarFiltros();
            },
            icon: const Icon(Icons.refresh, size: 15),
            label: Text(
              tr(context, 'vendedor_inventario.limpiar_filtros'),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
            style: TextButton.styleFrom(
              foregroundColor: esModoOscuro
                  ? Colors.white54
                  : const Color(0xFF6B5A52),
            ),
          ),

          const SizedBox(width: 8),

          // Filtros avanzados
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Abrir panel de filtros avanzados
            },
            icon: const Icon(Icons.filter_list, size: 15),
            label: Text(
              tr(context, 'vendedor_inventario.filtros_avanzados'),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: esModoOscuro
                  ? Colors.white60
                  : const Color(0xFF4A4A4A),
              side: BorderSide(
                color: esModoOscuro
                    ? const Color(0xFF3A3A3A)
                    : const Color(0xFFDDD5CC),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ── Grilla de productos ──────────────────────────────────────────────────────
  Widget _construirGrid(bool esModoOscuro) {
    final colorTarjeta = esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorTarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esModoOscuro
              ? const Color(0xFF2E2E2E)
              : const Color(0xFFEDE8E2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esModoOscuro ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Productos ─────────────────────────────────────────────────
          if (_paginaProductos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  tr(context, 'vendedor_inventario.sin_productos_filtrados'),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: esModoOscuro
                        ? Colors.white38
                        : const Color(0xFF9E8E85),
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _paginaProductos.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (_, i) {
                final producto = _paginaProductos[i];
                return TarjetaProductoInventario(
                  producto: producto,
                  alVer: () => _verProducto(producto),
                  alEditar: () => _editarProducto(producto),
                  alEliminar: () => _confirmarEliminarProducto(producto),
                );
              },
            ),

          const SizedBox(height: 12),

          // ── Paginador ─────────────────────────────────────────────────
          PaginadorTabla(
            paginaActual: _paginaActual,
            totalPaginas: _totalPaginas,
            totalRegistros: _totalProductos,
            registrosPorPagina: _registrosPorPagina,
            alCambiarPagina: (p) => setState(() => _paginaActual = p),
            alCambiarRegistrosPorPagina: (n) => setState(() {
              _registrosPorPagina = n;
              _paginaActual = 1;
            }),
          ),
        ],
      ),
    );
  }

  void _verProducto(ProductoInventario producto) {
    PantallaDetalleProducto.mostrar(context, productoId: producto.id);
  }

  Future<void> _editarProducto(ProductoInventario producto) async {
    final resultado = await showDialog<ProductoInventario>(
      context: context,
      builder: (_) => DialogoEditarProducto(producto: producto),
    );
    if (resultado == null) return;
    setState(() {
      final indice = _productos.indexWhere((p) => p.id == producto.id);
      if (indice != -1) _productos[indice] = resultado;
    });
    _aplicarFiltros();
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares privados
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownFiltro extends StatelessWidget {
  final String valor;
  final List<String> opciones;
  final ValueChanged<String?> alCambiar;
  final bool esModoOscuro;

  const _DropdownFiltro({
    required this.valor,
    required this.opciones,
    required this.alCambiar,
    required this.esModoOscuro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: esModoOscuro
              ? const Color(0xFF3A3A3A)
              : const Color(0xFFE0D8D0),
        ),
        borderRadius: BorderRadius.circular(8),
        color: esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      child: DropdownButton<String>(
        value: opciones.contains(valor) ? valor : opciones.first,
        underline: const SizedBox(),
        isDense: true,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: esModoOscuro ? Colors.white70 : const Color(0xFF4A4A4A),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          size: 16,
          color: esModoOscuro ? Colors.white38 : const Color(0xFF9E8E85),
        ),
        items: opciones
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: alCambiar,
      ),
    );
  }
}

// ── DIÁLOGO: EDITAR PRODUCTO (humilde: solo lo que de verdad se guarda) ──────
class DialogoEditarProducto extends StatefulWidget {
  final ProductoInventario producto;
  const DialogoEditarProducto({super.key, required this.producto});

  @override
  State<DialogoEditarProducto> createState() => _DialogoEditarProductoState();
}

class _DialogoEditarProductoState extends State<DialogoEditarProducto> {
  static const _categorias = [
    'Vestir', 'Artesanía', 'Muebles', 'Joyería', 'Alimentos', 'Accesorios', 'Calzado',
  ];

  late final TextEditingController _ctrlNombre;
  late final TextEditingController _ctrlPrecio;
  late final TextEditingController _ctrlStock;
  late final TextEditingController _ctrlImagen;
  late final TextEditingController _ctrlDescripcion;
  late String _categoria;
  bool _guardando = false;
  bool _subiendoImagen = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrlNombre = TextEditingController(text: widget.producto.nombre);
    _ctrlPrecio = TextEditingController(text: widget.producto.precio.toStringAsFixed(2));
    _ctrlStock = TextEditingController(text: widget.producto.stock.toString());
    _ctrlImagen = TextEditingController(text: widget.producto.rutaImagen);
    _ctrlDescripcion = TextEditingController(text: widget.producto.descripcion);
    _categoria = _categorias.contains(widget.producto.categoria)
        ? widget.producto.categoria
        : _categorias.first;
  }

  @override
  void dispose() {
    _ctrlNombre.dispose();
    _ctrlPrecio.dispose();
    _ctrlStock.dispose();
    _ctrlImagen.dispose();
    _ctrlDescripcion.dispose();
    super.dispose();
  }

  Future<void> _subirDesdePC() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (resultado == null || resultado.files.isEmpty) return;
    final archivo = resultado.files.single;
    if (archivo.bytes == null) return;
    await _subirImagen(archivo.bytes!, archivo.name);
  }

  Future<void> _tomarFoto() async {
    final foto = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
    if (foto == null) return;
    final bytes = await foto.readAsBytes();
    await _subirImagen(bytes, foto.name);
  }

  Future<void> _subirImagen(Uint8List bytes, String nombreArchivo) async {
    setState(() => _subiendoImagen = true);
    try {
      final url = await ApiService.subirFotoProducto(bytes, nombreArchivo);
      if (!mounted) return;
      setState(() => _ctrlImagen.text = url);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _subiendoImagen = false);
    }
  }

  Future<void> _guardar() async {
    final precio = double.tryParse(_ctrlPrecio.text.trim().replaceAll(',', '.'));
    final stock = int.tryParse(_ctrlStock.text.trim());
    if (_ctrlNombre.text.trim().isEmpty || precio == null || stock == null) {
      setState(() => _error = 'vendedor_inventario.error_validacion_producto');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ApiService.actualizarProducto(
        productoId: widget.producto.id,
        nombre: _ctrlNombre.text.trim(),
        precio: precio,
        stock: stock,
        categoria: _categoria,
        imagenUrl: _ctrlImagen.text.trim(),
        descripcion: _ctrlDescripcion.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        ProductoInventario(
          id: widget.producto.id,
          sku: widget.producto.sku,
          nombre: _ctrlNombre.text.trim(),
          coleccion: widget.producto.coleccion,
          categoria: _categoria,
          precio: precio,
          stock: stock,
          ventas: widget.producto.ventas,
          estado: widget.producto.estado,
          rutaImagen: _ctrlImagen.text.trim().isEmpty
              ? widget.producto.rutaImagen
              : _ctrlImagen.text.trim(),
          descripcion: _ctrlDescripcion.text.trim(),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = esModoOscuro ? Colors.white : const Color(0xFF1A1A1A);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF821515).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Color(0xFF821515), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'vendedor_inventario.editar_producto_titulo'),
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 17,
                              fontWeight: FontWeight.w700, color: colorTexto),
                        ),
                        Text(
                          widget.producto.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                              color: esModoOscuro ? Colors.white54 : const Color(0xFF9E8E85)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      _SeccionFormulario(
                        icono: Icons.info_outline_rounded,
                        titulo: tr(context, 'vendedor_inventario.seccion_informacion_basica'),
                        child: TextField(
                          controller: _ctrlNombre,
                          decoration: InputDecoration(labelText: tr(context, 'vendedor_inventario.label_nombre_producto')),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SeccionFormulario(
                        icono: Icons.sell_outlined,
                        titulo: tr(context, 'vendedor_inventario.seccion_precio_inventario'),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _ctrlPrecio,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(labelText: tr(context, 'vendedor_inventario.label_precio'), prefixText: '\$'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _ctrlStock,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(labelText: tr(context, 'vendedor_inventario.label_stock')),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _categoria,
                              decoration: InputDecoration(labelText: tr(context, 'vendedor_inventario.label_categoria')),
                              items: _categorias
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (v) => setState(() => _categoria = v ?? _categoria),
                            ),
                          ],
                        ),
                        tip: tr(context, 'vendedor_inventario.tip_precio'),
                      ),
                      const SizedBox(height: 20),
                      _SeccionFormulario(
                        icono: Icons.image_outlined,
                        titulo: tr(context, 'vendedor_inventario.seccion_imagen_producto'),
                        child: _SelectorImagenProducto(
                          ctrlImagen: _ctrlImagen,
                          subiendo: _subiendoImagen,
                          alSubirDesdePC: _subirDesdePC,
                          alTomarFoto: _tomarFoto,
                        ),
                        tip: tr(context, 'vendedor_inventario.tip_imagen'),
                      ),
                      const SizedBox(height: 20),
                      _SeccionFormulario(
                        icono: Icons.description_outlined,
                        titulo: tr(context, 'vendedor_inventario.seccion_descripcion'),
                        child: TextField(
                          controller: _ctrlDescripcion,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: tr(context, 'vendedor_inventario.seccion_descripcion'),
                            hintText: tr(context, 'vendedor_inventario.hint_descripcion_producto'),
                          ),
                        ),
                        tip: tr(context, 'vendedor_inventario.tip_descripcion'),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(tr(context, _error!), style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFFC62828))),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(tr(context, 'vendedor_inventario.cancelar')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: _guardando
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_guardando
                        ? tr(context, 'vendedor_inventario.guardando')
                        : tr(context, 'vendedor_inventario.guardar_cambios')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF821515),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SECCIÓN DE FORMULARIO: encabezado con ícono + tip de ayuda opcional ──────
class _SeccionFormulario extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Widget child;
  final String? tip;

  const _SeccionFormulario({
    required this.icono,
    required this.titulo,
    required this.child,
    this.tip,
  });

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 15, color: const Color(0xFF821515)),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: esModoOscuro ? Colors.white60 : const Color(0xFF9E8E85),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
        if (tip != null) _TipAyuda(texto: tip!),
      ],
    );
  }
}

// ── TIP DE AYUDA: consejo corto y amable, no un error ni una advertencia ─────
class _TipAyuda extends StatelessWidget {
  final String texto;
  const _TipAyuda({required this.texto});

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: esModoOscuro ? const Color(0xFF2A2116) : const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: esModoOscuro ? const Color(0xFF4A3B1E) : const Color(0xFFF0E0B0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, size: 15, color: Color(0xFFB8860B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                height: 1.45,
                color: esModoOscuro ? Colors.white70 : const Color(0xFF7A6414),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SELECTOR DE IMAGEN: vista previa + URL + subir de PC/cámara ──────────────
class _SelectorImagenProducto extends StatelessWidget {
  final TextEditingController ctrlImagen;
  final bool subiendo;
  final VoidCallback alSubirDesdePC;
  final VoidCallback alTomarFoto;

  const _SelectorImagenProducto({
    required this.ctrlImagen,
    required this.subiendo,
    required this.alSubirDesdePC,
    required this.alTomarFoto,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrlImagen,
      builder: (context, valor, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: subiendo
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF821515)))
                        : (valor.text.isEmpty
                            ? Container(
                                color: const Color(0xFF821515).withValues(alpha: 0.08),
                                child: const Icon(Icons.image_outlined, color: Color(0xFF821515), size: 26),
                              )
                            : Image.network(
                                valor.text,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: const Color(0xFF821515).withValues(alpha: 0.08),
                                  child: const Icon(Icons.image_outlined, color: Color(0xFF821515), size: 26),
                                ),
                              )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: ctrlImagen,
                    decoration: InputDecoration(labelText: tr(context, 'vendedor_inventario.label_url_imagen')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: subiendo ? null : alSubirDesdePC,
              icon: const Icon(Icons.upload_outlined, size: 16, color: Color(0xFF821515)),
              label: Text(tr(context, 'vendedor_inventario.subir_imagen_pc'),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF821515))),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                side: const BorderSide(color: Color(0xFFE3B8B8)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: subiendo ? null : alTomarFoto,
              icon: const Icon(Icons.photo_camera_outlined, size: 16, color: Color(0xFF821515)),
              label: Text(tr(context, 'vendedor_inventario.tomar_foto_camara'),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF821515))),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                side: const BorderSide(color: Color(0xFFE3B8B8)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── DIÁLOGO: NUEVO PRODUCTO ───────────────────────────────────────────────────
class DialogoNuevoProducto extends StatefulWidget {
  final String nombreVendedor;
  const DialogoNuevoProducto({super.key, required this.nombreVendedor});

  @override
  State<DialogoNuevoProducto> createState() => _DialogoNuevoProductoState();
}

class _DialogoNuevoProductoState extends State<DialogoNuevoProducto> {
  static const _categorias = [
    'Vestir', 'Artesanía', 'Muebles', 'Joyería', 'Alimentos', 'Accesorios', 'Calzado',
  ];

  final _ctrlNombre = TextEditingController();
  final _ctrlPrecio = TextEditingController();
  final _ctrlStock = TextEditingController(text: '0');
  final _ctrlImagen = TextEditingController();
  final _ctrlDescripcion = TextEditingController();
  String _categoria = _categorias.first;
  bool _guardando = false;
  bool _subiendoImagen = false;
  bool _generandoIA = false;
  List<String> _nombresSugeridos = [];
  String? _error;

  @override
  void dispose() {
    _ctrlNombre.dispose();
    _ctrlPrecio.dispose();
    _ctrlStock.dispose();
    _ctrlImagen.dispose();
    _ctrlDescripcion.dispose();
    super.dispose();
  }

  Future<void> _subirDesdePC() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (resultado == null || resultado.files.isEmpty) return;
    final archivo = resultado.files.single;
    if (archivo.bytes == null) return;
    await _subirImagen(archivo.bytes!, archivo.name);
  }

  Future<void> _tomarFoto() async {
    final foto = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
    if (foto == null) return;
    final bytes = await foto.readAsBytes();
    await _subirImagen(bytes, foto.name);
  }

  Future<void> _subirImagen(Uint8List bytes, String nombreArchivo) async {
    setState(() => _subiendoImagen = true);
    try {
      final url = await ApiService.subirFotoProducto(bytes, nombreArchivo);
      if (!mounted) return;
      setState(() => _ctrlImagen.text = url);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _subiendoImagen = false);
    }
  }

  Future<void> _generarConIA() async {
    final borrador = _ctrlNombre.text.trim().isNotEmpty
        ? _ctrlNombre.text.trim()
        : _ctrlDescripcion.text.trim();
    if (borrador.isEmpty) {
      setState(() => _error = 'vendedor_inventario.error_ia_falta_borrador');
      return;
    }
    setState(() {
      _generandoIA = true;
      _error = null;
    });
    try {
      final datos = await ApiService.generarProductoConIA(
        borrador: borrador,
        categoria: _categoria,
      );
      if (!mounted) return;
      setState(() {
        _nombresSugeridos = (datos['nombres'] as List? ?? []).cast<String>();
        final descripcion = (datos['descripcion'] ?? '').toString();
        if (descripcion.isNotEmpty) _ctrlDescripcion.text = descripcion;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _generandoIA = false);
    }
  }

  Future<void> _guardar() async {
    final precio = double.tryParse(_ctrlPrecio.text.trim().replaceAll(',', '.'));
    final stock = int.tryParse(_ctrlStock.text.trim());
    if (_ctrlNombre.text.trim().isEmpty || precio == null || stock == null) {
      setState(() => _error = 'vendedor_inventario.error_validacion_producto');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final respuesta = await ApiService.crearProducto(
        nombre: _ctrlNombre.text.trim(),
        precio: precio,
        stock: stock,
        categoria: _categoria,
        creador: widget.nombreVendedor,
        imagenUrl: _ctrlImagen.text.trim(),
        descripcion: _ctrlDescripcion.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, ProductoInventario.fromJson(respuesta));
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = esModoOscuro ? Colors.white : const Color(0xFF1A1A1A);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF821515).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_box_outlined, color: Color(0xFF821515), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'vendedor_inventario.nuevo_producto_titulo'),
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 17,
                              fontWeight: FontWeight.w700, color: colorTexto),
                        ),
                        Text(
                          tr(context, 'vendedor_inventario.nuevo_producto_subtitulo'),
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                              color: esModoOscuro ? Colors.white54 : const Color(0xFF9E8E85)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      _SeccionFormulario(
                        icono: Icons.info_outline_rounded,
                        titulo: tr(context, 'vendedor_inventario.seccion_informacion_basica'),
                        child: TextField(
                          controller: _ctrlNombre,
                          decoration: InputDecoration(labelText: tr(context, 'vendedor_inventario.label_nombre_producto')),
                        ),
                        tip: tr(context, 'vendedor_inventario.tip_nombre'),
                      ),
                      const SizedBox(height: 20),
                      _SeccionFormulario(
                        icono: Icons.sell_outlined,
                        titulo: tr(context, 'vendedor_inventario.seccion_precio_inventario'),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _ctrlPrecio,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(labelText: tr(context, 'vendedor_inventario.label_precio'), prefixText: '\$'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _ctrlStock,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(labelText: tr(context, 'vendedor_inventario.label_stock')),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _categoria,
                              decoration: InputDecoration(labelText: tr(context, 'vendedor_inventario.label_categoria')),
                              items: _categorias
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (v) => setState(() => _categoria = v ?? _categoria),
                            ),
                          ],
                        ),
                        tip: tr(context, 'vendedor_inventario.tip_precio'),
                      ),
                      const SizedBox(height: 20),
                      _SeccionFormulario(
                        icono: Icons.image_outlined,
                        titulo: tr(context, 'vendedor_inventario.seccion_imagen_producto'),
                        child: _SelectorImagenProducto(
                          ctrlImagen: _ctrlImagen,
                          subiendo: _subiendoImagen,
                          alSubirDesdePC: _subirDesdePC,
                          alTomarFoto: _tomarFoto,
                        ),
                        tip: tr(context, 'vendedor_inventario.tip_imagen'),
                      ),
                      const SizedBox(height: 20),
                      _SeccionFormulario(
                        icono: Icons.description_outlined,
                        titulo: tr(context, 'vendedor_inventario.seccion_descripcion'),
                        child: TextField(
                          controller: _ctrlDescripcion,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: tr(context, 'vendedor_inventario.seccion_descripcion'),
                            hintText: tr(context, 'vendedor_inventario.hint_descripcion_producto'),
                          ),
                        ),
                        tip: tr(context, 'vendedor_inventario.tip_descripcion'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _generandoIA ? null : _generarConIA,
                        icon: _generandoIA
                            ? const SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF821515)),
                        label: Text(_generandoIA
                            ? tr(context, 'vendedor_inventario.generando_ia')
                            : tr(context, 'vendedor_inventario.generar_con_ia')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF821515),
                          side: const BorderSide(color: Color(0xFF821515)),
                        ),
                      ),
                      if (_nombresSugeridos.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          tr(context, 'vendedor_inventario.nombres_sugeridos'),
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                              color: esModoOscuro ? Colors.white54 : const Color(0xFF9E8E85)),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _nombresSugeridos
                              .map((n) => ActionChip(
                                    label: Text(n, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5)),
                                    onPressed: () => setState(() {
                                      _ctrlNombre.text = n;
                                      _nombresSugeridos = [];
                                    }),
                                  ))
                              .toList(),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(tr(context, _error!), style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFFC62828))),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(tr(context, 'vendedor_inventario.cancelar')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: _guardando
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add_rounded, size: 18),
                    label: Text(_guardando
                        ? tr(context, 'vendedor_inventario.creando')
                        : tr(context, 'vendedor_inventario.crear_producto')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF821515),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

