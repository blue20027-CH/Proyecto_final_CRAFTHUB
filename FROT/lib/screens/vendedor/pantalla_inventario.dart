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

class PantallaInventario extends StatefulWidget {
  const PantallaInventario({super.key});

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
    setState(() => _cargando = true);

    // 🔌 API: Reemplaza el bloque siguiente con:
    //
    // final respuesta = await http.get(
    //   Uri.parse('https://tu-api.com/api/vendedor/$vendedorId/productos'),
    //   headers: {'Authorization': 'Bearer $token'},
    // );
    // final datos = jsonDecode(respuesta.body);
    // _productos = (datos['productos'] as List)
    //     .map((j) => ProductoInventario.fromJson(j))
    //     .toList();
    // _totalProductos  = datos['estadisticas']['total'];
    // _productosActivos = datos['estadisticas']['activos'];
    // _productosAgotados = datos['estadisticas']['agotados'];
    // _visitasMes      = datos['estadisticas']['visitas_mes'];
    // _ventasTotales   = (datos['estadisticas']['ventas_totales'] as num).toDouble();

    await Future.delayed(const Duration(milliseconds: 400));
    _productos = productosMock;
    _totalProductos = 125;
    _productosActivos = 98;
    _productosAgotados = 18;
    _visitasMes = 12400;
    _ventasTotales = 3478.90;

    _aplicarFiltros();
    setState(() => _cargando = false);
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

  // 🔌 API: DELETE /api/vendedor/{vendedorId}/productos
  // Body: { "ids": [..._seleccionados] }
  // ignore: unused_element
  void _eliminarSeleccionados() {
    setState(() {
      _productos.removeWhere((p) => _seleccionados.contains(p.id));
      _seleccionados.clear();
      _todosSeleccionados = false;
    });
    _aplicarFiltros();
  }

  // 🔌 API: POST /api/vendedor/{vendedorId}/productos/exportar
  // Respuesta: URL de descarga del CSV/Excel
  void _exportarInventario() {
    // TODO: Llamar al endpoint de exportación y abrir la URL con url_launcher
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

                  // ── Tabla ───────────────────────────────────────────────
                  _construirTabla(
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
          onPressed: () {
            // 🔌 API: Navegar al formulario de creación de producto
            // POST /api/vendedor/{vendedorId}/productos
          },
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

  // ── Tabla ─────────────────────────────────────────────────────────────────────
  Widget _construirTabla(bool esModoOscuro) {
    final colorTarjeta = esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white;
    final colorCabecera = const Color(0xFF821515);

    return Container(
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
            color: Colors.black.withOpacity(esModoOscuro ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Cabecera de tabla ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: colorCabecera,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Checkbox global
                SizedBox(
                  width: 52,
                  child: Checkbox(
                    value: _todosSeleccionados,
                    onChanged: (v) {
                      setState(() {
                        _todosSeleccionados = v ?? false;
                        if (_todosSeleccionados) {
                          _seleccionados.addAll(
                            _paginaProductos.map((p) => p.id),
                          );
                        } else {
                          _seleccionados.clear();
                        }
                      });
                    },
                    activeColor: Colors.white,
                    checkColor: colorCabecera,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                _CeldaCabecera(
                  texto: 'Producto',
                  flex: 3,
                  columna: 'nombre',
                  columnaActual: _columnaOrden,
                  ascendente: _ordenAscendente,
                  alOrdenar: _ordenarPor,
                ),
                _CeldaCabecera(texto: 'Colección', flex: 2),
                _CeldaCabecera(texto: 'Categoría', flex: 2),
                _CeldaCabecera(
                  texto: 'Precio',
                  flex: 1,
                  columna: 'precio',
                  columnaActual: _columnaOrden,
                  ascendente: _ordenAscendente,
                  alOrdenar: _ordenarPor,
                ),
                _CeldaCabecera(
                  texto: 'Stock',
                  flex: 1,
                  columna: 'stock',
                  columnaActual: _columnaOrden,
                  ascendente: _ordenAscendente,
                  alOrdenar: _ordenarPor,
                ),
                _CeldaCabecera(
                  texto: 'Ventas',
                  flex: 1,
                  columna: 'ventas',
                  columnaActual: _columnaOrden,
                  ascendente: _ordenAscendente,
                  alOrdenar: _ordenarPor,
                ),
                _CeldaCabecera(texto: 'Estado', flex: 1),
                const SizedBox(
                  width: 80,
                  child: Center(
                    child: Text(
                      'Acciones',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Filas ─────────────────────────────────────────────────────
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
            ...List.generate(_paginaProductos.length, (i) {
              final producto = _paginaProductos[i];
              final esPar = i % 2 == 0;
              return Column(
                children: [
                  Container(
                    color: esPar
                        ? Colors.transparent
                        : (esModoOscuro
                              ? Colors.white.withOpacity(0.02)
                              : const Color(0xFFFAF8F5)),
                    child: FilaProducto(
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
                      alEditar: () {
                        // 🔌 API: GET /api/vendedor/{vendedorId}/productos/{productoId}
                        // Navegar al formulario de edición con los datos del producto
                      },
                      alVerOpciones: () {
                        _mostrarMenuOpciones(context, producto);
                      },
                    ),
                  ),
                  if (i < _paginaProductos.length - 1)
                    Divider(
                      height: 1,
                      color: esModoOscuro
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF0EBE5),
                    ),
                ],
              );
            }),

          // ── Paginador ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: esModoOscuro
                      ? const Color(0xFF2E2E2E)
                      : const Color(0xFFEDE8E2),
                ),
              ),
            ),
            child: PaginadorTabla(
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
          ),
        ],
      ),
    );
  }

  // ── Menú contextual de opciones ───────────────────────────────────────────
  void _mostrarMenuOpciones(BuildContext context, ProductoInventario producto) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => AlertDialog(
        backgroundColor: esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OpcionMenu(
              icono: Icons.visibility_outlined,
              texto: 'Ver producto',
              alPresionar: () {
                Navigator.pop(context);
                // 🔌 API: Navegar a pantalla de detalle del producto
              },
            ),
            _OpcionMenu(
              icono: Icons.edit_outlined,
              texto: 'Editar',
              alPresionar: () {
                Navigator.pop(context);
                // 🔌 API: PUT /api/vendedor/{vendedorId}/productos/{productoId}
              },
            ),
            _OpcionMenu(
              icono: Icons.copy_outlined,
              texto: 'Duplicar',
              alPresionar: () {
                Navigator.pop(context);
                // 🔌 API: POST /api/vendedor/{vendedorId}/productos/{productoId}/duplicar
              },
            ),
            const Divider(height: 1),
            _OpcionMenu(
              icono: Icons.delete_outline,
              texto: 'Eliminar',
              esDestructivo: true,
              alPresionar: () {
                Navigator.pop(context);
                // 🔌 API: DELETE /api/vendedor/{vendedorId}/productos/{productoId}
                setState(() {
                  _productos.removeWhere((p) => p.id == producto.id);
                });
                _aplicarFiltros();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares privados
// ─────────────────────────────────────────────────────────────────────────────

class _CeldaCabecera extends StatelessWidget {
  final String texto;
  final int flex;
  final String? columna;
  final String? columnaActual;
  final bool ascendente;
  final void Function(String)? alOrdenar;

  const _CeldaCabecera({
    required this.texto,
    required this.flex,
    this.columna,
    this.columnaActual,
    this.ascendente = true,
    this.alOrdenar,
  });

  @override
  Widget build(BuildContext context) {
    final esActiva = columna != null && columna == columnaActual;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: columna != null && alOrdenar != null
            ? () => alOrdenar!(columna!)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                texto,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: esActiva ? Colors.white : Colors.white70,
                ),
              ),
              if (columna != null) ...[
                const SizedBox(width: 4),
                Icon(
                  esActiva
                      ? (ascendente ? Icons.arrow_upward : Icons.arrow_downward)
                      : Icons.unfold_more,
                  size: 13,
                  color: esActiva ? Colors.white : Colors.white38,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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

class _OpcionMenu extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback alPresionar;
  final bool esDestructivo;

  const _OpcionMenu({
    required this.icono,
    required this.texto,
    required this.alPresionar,
    this.esDestructivo = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = esDestructivo
        ? const Color(0xFFC62828)
        : (Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : const Color(0xFF4A4A4A));

    return ListTile(
      dense: true,
      leading: Icon(icono, size: 18, color: color),
      title: Text(
        texto,
        style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: color),
      ),
      onTap: alPresionar,
    );
  }
}
