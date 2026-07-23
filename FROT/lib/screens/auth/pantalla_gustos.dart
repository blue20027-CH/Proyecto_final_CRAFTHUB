// lib/screens/comprador/pantalla_intereses.dart
// Panel de selección de intereses del comprador.
// Se inserta directamente en el switch de _obtenerPantallaActual() de HomeComprador.
// No contiene Scaffold, Sidebar ni TopBar propios.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../core/i18n/i18n.dart';
import '../comprador/inicio_comprador.dart';

class _Provincia {
  final String id;
  final String nombre;
  final String bandera;

  const _Provincia({
    required this.id,
    required this.nombre,
    required this.bandera,
  });
}

class _Comarca {
  final String id;
  final String nombre;
  final String bandera;

  const _Comarca({
    required this.id,
    required this.nombre,
    required this.bandera,
  });
}

class _Categoria {
  final String id;
  final String nombre;
  final String rutaImagen;

  const _Categoria({
    required this.id,
    required this.nombre,
    required this.rutaImagen,
  });
}

// Datos mock: reemplazar con llamadas a GET /api/regiones y GET /api/categorias.
const List<_Provincia> _provincias = [
  _Provincia(
    id: 'colon',
    nombre: 'Colón',
    bandera: 'assets/images/banderas/Colon.png',
  ),
  _Provincia(
    id: 'chiriqui',
    nombre: 'Chiriquí',
    bandera: 'assets/images/banderas/Chiriqui.png',
  ),
  _Provincia(
    id: 'bocas',
    nombre: 'Bocas del Toro',
    bandera: 'assets/images/banderas/Bocas_del_Toro.png',
  ),
  _Provincia(
    id: 'veraguas',
    nombre: 'Veraguas',
    bandera: 'assets/images/banderas/Veraguas.png',
  ),
  _Provincia(
    id: 'cocle',
    nombre: 'Coclé',
    bandera: 'assets/images/banderas/Cocle.png',
  ),
  _Provincia(
    id: 'panama',
    nombre: 'Panamá',
    bandera: 'assets/images/banderas/Panama.png',
  ),
  _Provincia(
    id: 'panama_oeste',
    nombre: 'Panamá Oeste',
    bandera: 'assets/images/banderas/Panama_Oeste.png',
  ),
  _Provincia(
    id: 'los_santos',
    nombre: 'Los Santos',
    bandera: 'assets/images/banderas/Los_Santos.png',
  ),
  _Provincia(
    id: 'darien',
    nombre: 'Darién',
    bandera: 'assets/images/banderas/Darien.png',
  ),
  _Provincia(
    id: 'herrera',
    nombre: 'Herrera',
    bandera: 'assets/images/banderas/Herrera.png',
  ),
];

const List<_Comarca> _comarcas = [
  _Comarca(
    id: 'guna_yala',
    nombre: 'Comarca Guna-Yala',
    bandera: 'assets/images/banderas/Guna_Yala.png',
  ),
  _Comarca(
    id: 'ngabe_bugle',
    nombre: 'Comarca Ngäbe-Buglé',
    bandera: 'assets/images/banderas/Ngabe_Buglé.png',
  ),
  _Comarca(
    id: 'embera_wounaan',
    nombre: 'Comarca Emberá-Wounaan',
    bandera: 'assets/images/banderas/Emberá_Wounaan.png',
  ),
  _Comarca(
    id: 'madugandi',
    nombre: 'Comarca Madugandí',
    bandera: 'assets/images/banderas/Madugandí.png',
  ),
  _Comarca(
    id: 'wargandi',
    nombre: 'Comarca Wargandí',
    bandera: 'assets/images/banderas/Wargandí.png',
  ),
];

// Mismas 7 categorías reales que filtran el catálogo (ver la constante
// `categorias` en inicio_comprador.dart, la que de verdad se envía al
// backend vía ApiService.getProductos). Antes esta pantalla mostraba
// nombres inventados que no coincidían con ninguna categoría real, así
// que guardar una preferencia nunca hacía match con ningún producto.
const List<_Categoria> _categorias = [
  _Categoria(
    id: 'vestir',
    nombre: 'Vestir',
    rutaImagen: 'assets/images/Categoria/vestir.png',
  ),
  _Categoria(
    id: 'artesania',
    nombre: 'Artesanía',
    rutaImagen: 'assets/images/Categoria/artesania.png',
  ),
  _Categoria(
    id: 'muebles',
    nombre: 'Muebles',
    rutaImagen: 'assets/images/Categoria/muebles.png',
  ),
  _Categoria(
    id: 'joyeria',
    nombre: 'Joyería',
    rutaImagen: 'assets/images/Categoria/joyeria.png',
  ),
  _Categoria(
    id: 'alimentos',
    nombre: 'Alimentos',
    rutaImagen: 'assets/images/Categoria/alimentos.png',
  ),
  _Categoria(
    id: 'accesorios',
    nombre: 'Accesorios',
    rutaImagen: 'assets/images/Categoria/accesorios.png',
  ),
  _Categoria(
    id: 'calzado',
    nombre: 'Calzado',
    rutaImagen: 'assets/images/Categoria/calzado.png',
  ),
];

class PantallaIntereses extends StatefulWidget {
  final String userId;
  // Hooks opcionales para casos que quieran un efecto extra al continuar
  // (por defecto esta pantalla ya navega sola a HomeComprador usando su
  // propio context, así no depende de un context externo que puede haber
  // quedado obsoleto si quien la empujó usó pushReplacement).
  final VoidCallback? alGuardar;
  final VoidCallback? alOmitir;

  const PantallaIntereses({
    super.key,
    this.userId = '',
    this.alGuardar,
    this.alOmitir,
  });

  @override
  State<PantallaIntereses> createState() => _PantallaInteresesState();
}

class _PantallaInteresesState extends State<PantallaIntereses> {
  final Set<String> _provinciasSeleccionadas = {};
  final Set<String> _comarcasSeleccionadas = {};
  final Set<String> _categoriasSeleccionadas = {};

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    if (widget.userId.isNotEmpty) {
      _cargarPreferenciasExistentes();
    }
  }

  Future<void> _cargarPreferenciasExistentes() async {
    try {
      final data = await ApiService.getPreferencias(widget.userId);
      if (!mounted) return;
      setState(() {
        _provinciasSeleccionadas.addAll(
          (data['provincias'] as List<dynamic>? ?? []).map((e) => e.toString()),
        );
        _comarcasSeleccionadas.addAll(
          (data['comarcas'] as List<dynamic>? ?? []).map((e) => e.toString()),
        );
        _categoriasSeleccionadas.addAll(
          (data['categorias'] as List<dynamic>? ?? []).map((e) => e.toString()),
        );
      });
    } catch (_) {
      // Sin preferencias previas o backend no disponible: se queda en blanco.
    }
  }

  Future<void> _guardarIntereses() async {
    setState(() => _guardando = true);

    try {
      if (widget.userId.isNotEmpty) {
        await ApiService.guardarPreferencias(
          userId: widget.userId,
          provincias: _provinciasSeleccionadas.toList(),
          comarcas: _comarcasSeleccionadas.toList(),
          categorias: _categoriasSeleccionadas.toList(),
        );
      }
    } catch (_) {
      // Si falla el guardado no bloqueamos el flujo: el usuario igual continúa.
    }

    if (!mounted) return;
    setState(() => _guardando = false);
    widget.alGuardar?.call();
    _continuar();
  }

  void _omitir() {
    widget.alOmitir?.call();
    _continuar();
  }

  // Navega a HomeComprador usando el context de esta propia pantalla
  // (siempre vivo en este punto), en vez de depender de un callback externo
  // que puede haber capturado un context ya destruido por un pushReplacement
  // previo (login/registro reemplazan su propia pantalla al llegar aquí).
  void _continuar() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeComprador(userId: widget.userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondoPantalla = esModoOscuro
        ? const Color(0xFF121212)
        : const Color(0xFFF9F6F0);

    // Scaffold propio: permite empujar esta pantalla directamente con
    // Navigator.push (como hacen role.dart y pantalla_login.dart) sin
    // perder la posibilidad de embeberla dentro de otro Scaffold (p. ej.
    // el switch de HomeComprador), ya que un Scaffold anidado es válido.
    return Scaffold(
      backgroundColor: colorFondoPantalla,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              !_guardando) {
            _guardarIntereses();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: DefaultTextStyle.merge(
        style: const TextStyle(decoration: TextDecoration.none),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Encabezado()
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.1, end: 0),
                    const SizedBox(height: 24),
                    _ResumenSeleccion(
                      totalRegiones:
                          _provinciasSeleccionadas.length +
                          _comarcasSeleccionadas.length,
                      totalCategorias: _categoriasSeleccionadas.length,
                    ),
                    const SizedBox(height: 32),
                    _SeccionRegiones(
                          provinciasSeleccionadas: _provinciasSeleccionadas,
                          comarcasSeleccionadas: _comarcasSeleccionadas,
                          alToggleProvincia: (id) => setState(() {
                            _provinciasSeleccionadas.contains(id)
                                ? _provinciasSeleccionadas.remove(id)
                                : _provinciasSeleccionadas.add(id);
                          }),
                          alToggleComarca: (id) => setState(() {
                            _comarcasSeleccionadas.contains(id)
                                ? _comarcasSeleccionadas.remove(id)
                                : _comarcasSeleccionadas.add(id);
                          }),
                        )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 100.ms)
                        .slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 32),
                    _SeccionCategorias(
                          categoriasSeleccionadas: _categoriasSeleccionadas,
                          alToggleCategoria: (id) => setState(() {
                            _categoriasSeleccionadas.contains(id)
                                ? _categoriasSeleccionadas.remove(id)
                                : _categoriasSeleccionadas.add(id);
                          }),
                        )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 200.ms)
                        .slideY(begin: 0.05, end: 0),
                  ],
                ),
              ),
            ),
            _BarraAcciones(
              guardando: _guardando,
              alOmitir: _omitir,
              alGuardar: _guardarIntereses,
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        children: [
          Text(
            tr(context, 'auth.cuentanos_intereses'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: esModoOscuro
                  ? Colors.white
                  : const Color(0xFF2C1810),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr(context, 'auth.selecciona_provincias_comarcas_tipos'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              height: 1.6,
              color: esModoOscuro ? Colors.white60 : const Color(0xFF6B5A52),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenSeleccion extends StatelessWidget {
  final int totalRegiones;
  final int totalCategorias;

  const _ResumenSeleccion({
    required this.totalRegiones,
    required this.totalCategorias,
  });

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esModoOscuro
              ? const Color(0xFF2E2E2E)
              : const Color(0xFFE8E1DA),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.location_on_outlined,
              titulo: tr(context, 'auth.regiones'),
              valor: totalRegiones.toString(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.category_outlined,
              titulo: tr(context, 'auth.categorias'),
              valor: totalCategorias.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionRegiones extends StatelessWidget {
  final Set<String> provinciasSeleccionadas;
  final Set<String> comarcasSeleccionadas;
  final ValueChanged<String> alToggleProvincia;
  final ValueChanged<String> alToggleComarca;

  const _SeccionRegiones({
    required this.provinciasSeleccionadas,
    required this.comarcasSeleccionadas,
    required this.alToggleProvincia,
    required this.alToggleComarca,
  });

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return _SeccionTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TituloSeccion(
            icono: Icons.location_on_outlined,
            texto: tr(context, 'auth.titulo_seccion_regiones'),
          ),
          const SizedBox(height: 20),
          _SubLabel(texto: tr(context, 'auth.provincias_label'), esModoOscuro: esModoOscuro),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _provincias.map((provincia) {
              return _ChipRegionInline(
                nombre: provincia.nombre,
                bandera: provincia.bandera,
                seleccionado: provinciasSeleccionadas.contains(provincia.nombre),
                alSeleccionar: () => alToggleProvincia(provincia.nombre),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _SubLabel(texto: tr(context, 'auth.comarcas_label'), esModoOscuro: esModoOscuro),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _comarcas.map((comarca) {
              return _ChipRegionInline(
                nombre: comarca.nombre,
                bandera: comarca.bandera,
                seleccionado: comarcasSeleccionadas.contains(comarca.nombre),
                alSeleccionar: () => alToggleComarca(comarca.nombre),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _Nota(
            icono: Icons.people_outline,
            texto: tr(context, 'auth.nota_provincias_comarcas'),
          ),
        ],
      ),
    );
  }
}

class _SeccionCategorias extends StatelessWidget {
  final Set<String> categoriasSeleccionadas;
  final ValueChanged<String> alToggleCategoria;

  const _SeccionCategorias({
    required this.categoriasSeleccionadas,
    required this.alToggleCategoria,
  });

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return _SeccionTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TituloSeccion(
            icono: Icons.shopping_bag_outlined,
            texto: tr(context, 'auth.titulo_seccion_categorias'),
          ),
          const SizedBox(height: 6),
          Text(
            tr(context, 'auth.selecciona_categorias_gustan'),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: esModoOscuro ? Colors.white54 : const Color(0xFF9E8E85),
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnas = constraints.maxWidth < 700 ? 2 : 4;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categorias.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnas,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (_, index) {
                  final categoria = _categorias[index];

                  return _ChipCategoriaInline(
                    nombre: categoria.nombre,
                    rutaImagen: categoria.rutaImagen,
                    seleccionado: categoriasSeleccionadas.contains(
                      categoria.nombre,
                    ),
                    alSeleccionar: () => alToggleCategoria(categoria.nombre),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _Nota(
            icono: Icons.favorite_border,
            texto: tr(context, 'auth.nota_categorias'),
          ),
        ],
      ),
    );
  }
}

class _SeccionTarjeta extends StatelessWidget {
  final Widget child;

  const _SeccionTarjeta({required this.child});

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: esModoOscuro
              ? const Color(0xFF2E2E2E)
              : const Color(0xFFEDE8E2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esModoOscuro ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _TituloSeccion({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icono, color: const Color(0xFF821515), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: esModoOscuro ? Colors.white : const Color(0xFF2C1810),
            ),
          ),
        ),
      ],
    );
  }
}

class _BarraAcciones extends StatelessWidget {
  final bool guardando;
  final VoidCallback? alOmitir;
  final VoidCallback alGuardar;

  const _BarraAcciones({
    required this.guardando,
    required this.alOmitir,
    required this.alGuardar,
  });

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
      decoration: BoxDecoration(
        color: esModoOscuro ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: esModoOscuro
                ? const Color(0xFF2E2E2E)
                : const Color(0xFFEDE8E2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: guardando ? null : alOmitir,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: esModoOscuro
                      ? const Color(0xFF3A3A3A)
                      : const Color(0xFFDDD5CC),
                ),
              ),
            ),
            child: Text(
              tr(context, 'auth.omitir_por_ahora'),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: esModoOscuro ? Colors.white60 : const Color(0xFF6B5A52),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: guardando ? null : alGuardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF821515),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tr(context, 'auth.guardar_continuar'),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String valor;

  const _StatCard({
    required this.icon,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: esModoOscuro ? const Color(0xFF262019) : const Color(0xFFF9F6F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esModoOscuro ? const Color(0xFF3A2E26) : const Color(0xFFEDE1D6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF821515).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF821515), size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF821515),
                ),
              ),
              Text(
                titulo,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: esModoOscuro ? Colors.white54 : const Color(0xFF6B5A52),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  final String texto;
  final bool esModoOscuro;

  const _SubLabel({required this.texto, required this.esModoOscuro});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: esModoOscuro ? Colors.white54 : const Color(0xFF6B5A52),
      ),
    );
  }
}

class _Nota extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Nota({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icono, size: 15, color: const Color(0xFF821515).withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: esModoOscuro ? Colors.white38 : const Color(0xFF9E8E85),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipRegionInline extends StatefulWidget {
  final String nombre;
  final String bandera;
  final bool seleccionado;
  final VoidCallback alSeleccionar;

  const _ChipRegionInline({
    required this.nombre,
    required this.bandera,
    required this.seleccionado,
    required this.alSeleccionar,
  });

  @override
  State<_ChipRegionInline> createState() => _ChipRegionInlineState();
}

class _ChipRegionInlineState extends State<_ChipRegionInline> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    const colorPrimario = Color(0xFF821515);
    final esAsset = widget.bandera.startsWith('assets/');

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alSeleccionar,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          scale: hover ? 1.03 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 180,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.seleccionado
                    ? colorPrimario
                    : Colors.grey.shade300,
                width: widget.seleccionado ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (esAsset)
                    Image.asset(
                      widget.bandera,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFF4EDE5),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.map_outlined,
                          color: Color(0xFF9E8E85),
                          size: 34,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFFF4EDE5),
                      alignment: Alignment.center,
                      child: Text(
                        widget.bandera,
                        style: const TextStyle(fontSize: 42),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Text(
                      widget.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (widget.seleccionado)
                    const Positioned(
                      right: 10,
                      top: 10,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: colorPrimario,
                        child: Icon(Icons.check, size: 15, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipCategoriaInline extends StatefulWidget {
  final String nombre;
  final String rutaImagen;
  final bool seleccionado;
  final VoidCallback alSeleccionar;

  const _ChipCategoriaInline({
    required this.nombre,
    required this.rutaImagen,
    required this.seleccionado,
    required this.alSeleccionar,
  });

  @override
  State<_ChipCategoriaInline> createState() => _ChipCategoriaInlineState();
}

class _ChipCategoriaInlineState extends State<_ChipCategoriaInline> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    const colorPrimario = Color(0xFF821515);
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alSeleccionar,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          scale: hover ? 1.03 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.seleccionado
                    ? colorPrimario
                    : (esModoOscuro ? const Color(0xFF2E2E2E) : const Color(0xFFE0D8D0)),
                width: widget.seleccionado ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: esModoOscuro ? 0.3 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: Image.asset(
                          widget.rutaImagen,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: double.infinity,
                            color: const Color(0xFFF4EDE5),
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Color(0xFF9E8E85),
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          widget.nombre,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: widget.seleccionado
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: widget.seleccionado
                                ? colorPrimario
                                : (esModoOscuro ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.seleccionado)
                    const Positioned(
                      right: 10,
                      top: 10,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: colorPrimario,
                        child: Icon(Icons.check, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
