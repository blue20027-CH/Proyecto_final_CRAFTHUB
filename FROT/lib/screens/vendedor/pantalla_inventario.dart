// lib/screens/vendedor/pantalla_inventario.dart
// Panel de inventario del vendedor — se inserta en _obtenerPantallaActual()
// NO contiene Scaffold, Sidebar ni TopBar propios

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// 🔌 API: Descomentar cuando conectes el backend
// import 'package:http/http.dart' as http;
// import 'dart:convert';

import '../../../models/modelo_producto_inventario.dart';
import '../../../widgets/vendedor/widgets_inventario.dart';
import '../../services/vendedor_api_service.dart';
import '../../services/api_service.dart';
import '../../services/exportador_inventario.dart';
import '../comprador/pantalla_detalle_producto.dart';

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
  final Set<String> _seleccionados = {};
  bool _todosSeleccionados = false;
  bool _cargando = true;
  String? _error;

  // ── Filtros ───────────────────────────────────────────────────────────────
  String _busqueda = '';
  String _coleccionFiltro = 'Todas las colecciones';
  String _estadoFiltro = 'Todos';
  String _categoriaFiltro = 'Todas';

  // ── Paginación ────────────────────────────────────────────────────────────
  int _paginaActual = 1;
  int _registrosPorPagina = 6;

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
        title: const Text('Eliminar producto',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('¿Seguro que quieres eliminar "${producto.nombre}"? Esta acción no se puede deshacer.',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828), foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    try {
      await ApiService.eliminarProducto(producto.id);
      setState(() {
        _productos.removeWhere((p) => p.id == producto.id);
        _seleccionados.remove(producto.id);
      });
      _aplicarFiltros();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  Future<void> _confirmarEliminarSeleccionados() async {
    final cantidad = _seleccionados.length;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar productos',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('¿Seguro que quieres eliminar $cantidad producto(s)? Esta acción no se puede deshacer.',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828), foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    final idsAEliminar = List<String>.from(_seleccionados);
    for (final id in idsAEliminar) {
      try {
        await ApiService.eliminarProducto(id);
      } catch (_) {
        // Sigue con el resto aunque uno falle; se refleja al final quién quedó.
      }
    }
    setState(() {
      _productos.removeWhere((p) => idsAEliminar.contains(p.id));
      _seleccionados.clear();
      _todosSeleccionados = false;
    });
    _aplicarFiltros();
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
        const SnackBar(content: Text('Inventario exportado correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar: ${e.toString().replaceAll('Exception: ', '')}')),
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
            'No se pudo cargar el inventario: $_error',
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
            Row(
              children: [
                Text(
                  'Mi inventario',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: esModoOscuro
                        ? Colors.white
                        : const Color(0xFF2C1810),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '✦',
                  style: TextStyle(fontSize: 20, color: Color(0xFF821515)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Gestiona y organiza todos tus productos en un solo lugar.',
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
          label: const Text(
            'Exportar inventario',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
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
          label: const Text(
            'Agregar producto',
            style: TextStyle(
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
          etiqueta: 'Productos totales',
        ),
        const SizedBox(width: 16),
        TarjetaEstadistica(
          icono: Icons.check_circle_outline,
          colorIcono: const Color(0xFF2E7D32),
          valor: '$_productosActivos',
          etiqueta: 'Activos',
        ),
        const SizedBox(width: 16),
        TarjetaEstadistica(
          icono: Icons.label_off_outlined,
          colorIcono: const Color(0xFFE65100),
          valor: '$_productosAgotados',
          etiqueta: 'Agotados',
        ),
        const SizedBox(width: 16),
        TarjetaEstadistica(
          icono: Icons.visibility_outlined,
          colorIcono: const Color(0xFF1565C0),
          valor: '${(_visitasMes / 1000).toStringAsFixed(1)}K',
          etiqueta: 'Visitas este mes',
        ),
        const SizedBox(width: 16),
        TarjetaEstadistica(
          icono: Icons.attach_money,
          colorIcono: const Color(0xFF821515),
          valor: '\$${_ventasTotales.toStringAsFixed(2)}',
          etiqueta: 'Ventas totales',
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
                hintText: 'Buscar producto...',
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
            label: const Text(
              'Limpiar filtros',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
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
            label: const Text(
              'Filtros avanzados',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
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
          // ── Barra de selección múltiple ──────────────────────────────
          Row(
            children: [
              Checkbox(
                value: _todosSeleccionados,
                onChanged: (v) {
                  setState(() {
                    _todosSeleccionados = v ?? false;
                    if (_todosSeleccionados) {
                      _seleccionados.addAll(_paginaProductos.map((p) => p.id));
                    } else {
                      _seleccionados.clear();
                    }
                  });
                },
                activeColor: const Color(0xFF821515),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              Text(
                _seleccionados.isEmpty
                    ? 'Seleccionar todos'
                    : '${_seleccionados.length} seleccionado(s)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: esModoOscuro ? Colors.white60 : const Color(0xFF6B5A52),
                ),
              ),
              const Spacer(),
              if (_seleccionados.isNotEmpty)
                TextButton.icon(
                  onPressed: _confirmarEliminarSeleccionados,
                  icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFC62828)),
                  label: const Text('Eliminar seleccionados',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: Color(0xFFC62828))),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Productos ─────────────────────────────────────────────────
          if (_paginaProductos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'No se encontraron productos con los filtros aplicados.',
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
                  seleccionado: _seleccionados.contains(producto.id),
                  alCambiarSeleccion: (v) {
                    setState(() {
                      if (v == true) {
                        _seleccionados.add(producto.id);
                      } else {
                        _seleccionados.remove(producto.id);
                      }
                    });
                  },
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
  late String _categoria;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrlNombre = TextEditingController(text: widget.producto.nombre);
    _ctrlPrecio = TextEditingController(text: widget.producto.precio.toStringAsFixed(2));
    _ctrlStock = TextEditingController(text: widget.producto.stock.toString());
    _ctrlImagen = TextEditingController(text: widget.producto.rutaImagen);
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
    super.dispose();
  }

  Future<void> _guardar() async {
    final precio = double.tryParse(_ctrlPrecio.text.trim().replaceAll(',', '.'));
    final stock = int.tryParse(_ctrlStock.text.trim());
    if (_ctrlNombre.text.trim().isEmpty || precio == null || stock == null) {
      setState(() => _error = 'Revisa que nombre, precio y stock sean válidos.');
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar producto',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                    fontWeight: FontWeight.w700, color: colorTexto),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrlNombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrlPrecio,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _ctrlStock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v ?? _categoria),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctrlImagen,
                decoration: const InputDecoration(labelText: 'URL de la imagen'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFFC62828))),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF821515),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Guardar'),
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
  String _categoria = _categorias.first;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _ctrlNombre.dispose();
    _ctrlPrecio.dispose();
    _ctrlStock.dispose();
    _ctrlImagen.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final precio = double.tryParse(_ctrlPrecio.text.trim().replaceAll(',', '.'));
    final stock = int.tryParse(_ctrlStock.text.trim());
    if (_ctrlNombre.text.trim().isEmpty || precio == null || stock == null) {
      setState(() => _error = 'Revisa que nombre, precio y stock sean válidos.');
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nuevo producto',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                    fontWeight: FontWeight.w700, color: colorTexto),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrlNombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrlPrecio,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _ctrlStock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v ?? _categoria),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctrlImagen,
                decoration: const InputDecoration(labelText: 'URL de la imagen (opcional)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFFC62828))),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF821515),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Crear producto'),
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

