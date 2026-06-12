// lib/screens/comprador/pantalla_intereses.dart
// Panel de selección de intereses del comprador
// Se inserta directamente en el switch de _obtenerPantallaActual() de HomeComprador
// NO contiene Scaffold, Sidebar ni TopBar propios

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// 🔌 API: Importar tu servicio HTTP cuando conectes el backend
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// ---------------------------------------------------------------------------
// Modelos de datos locales (reemplazar por respuesta de API)
// ---------------------------------------------------------------------------

class _Provincia {
  final String id;
  final String nombre;
  final String bandera; // Emoji o ruta asset

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
  final String rutaImagen; // Image.asset path

  const _Categoria({
    required this.id,
    required this.nombre,
    required this.rutaImagen,
  });
}

// ---------------------------------------------------------------------------
// Datos mock — reemplazar con llamadas al endpoint GET /api/regiones y GET /api/categorias
// ---------------------------------------------------------------------------

const List<_Provincia> _provincias = [
  _Provincia(id: 'colon', nombre: 'Colón', bandera: '🟡'),
  _Provincia(id: 'chiriqui', nombre: 'Chiriquí', bandera: '🔴'),
  _Provincia(id: 'bocas', nombre: 'Bocas del Toro', bandera: '🟢'),
  _Provincia(id: 'veraguas', nombre: 'Veraguas', bandera: '🔵'),
  _Provincia(id: 'cocle', nombre: 'Coclé', bandera: '💠'),
  _Provincia(id: 'panama', nombre: 'Panamá', bandera: '🔴'),
  _Provincia(id: 'panama_oeste', nombre: 'Panamá Oeste', bandera: '🟠'),
  _Provincia(id: 'los_santos', nombre: 'Los Santos', bandera: '🟧'),
  _Provincia(id: 'darien', nombre: 'Darién', bandera: '🟤'),
  _Provincia(id: 'herrera', nombre: 'Herrera', bandera: '🟡'),
];

const List<_Comarca> _comarcas = [
  _Comarca(id: 'guna_yala', nombre: 'Comarca Guna-Yala', bandera: '🏳'),
  _Comarca(id: 'ngabe_bugle', nombre: 'Comarca Ngäbe-Buglé', bandera: '🏳'),
  _Comarca(
    id: 'embera_wounaan',
    nombre: 'Comarca Emberá-Wounaan',
    bandera: '🏳',
  ),
  _Comarca(id: 'madugandi', nombre: 'Comarca Madugandí', bandera: '🏳'),
  _Comarca(id: 'wargandi', nombre: 'Comarca Wargandí', bandera: '🏳'),
  _Comarca(
    id: 'guna_madugandi',
    nombre: 'Comarca Guna de Madugandí',
    bandera: '🏳',
  ),
  _Comarca(
    id: 'guna_wargandi',
    nombre: 'Comarca Guna de Wargandí',
    bandera: '🏳',
  ),
];

const List<_Categoria> _categorias = [
  _Categoria(
    id: 'tejidos',
    nombre: 'Tejidos y textiles',
    rutaImagen: 'assets/categorias/tejidos.png',
  ),
  _Categoria(
    id: 'ceramica',
    nombre: 'Cerámica',
    rutaImagen: 'assets/categorias/ceramica.png',
  ),
  _Categoria(
    id: 'joyeria',
    nombre: 'Joyería artesanal',
    rutaImagen: 'assets/categorias/joyeria.png',
  ),
  _Categoria(
    id: 'madera',
    nombre: 'Madera tallada',
    rutaImagen: 'assets/categorias/madera.png',
  ),
  _Categoria(
    id: 'cesteria',
    nombre: 'Cestería',
    rutaImagen: 'assets/categorias/cesteria.png',
  ),
  _Categoria(
    id: 'decoracion',
    nombre: 'Decoración',
    rutaImagen: 'assets/categorias/decoracion.png',
  ),
  _Categoria(
    id: 'cuero',
    nombre: 'Cuero',
    rutaImagen: 'assets/categorias/cuero.png',
  ),
  _Categoria(
    id: 'pintura',
    nombre: 'Pintura artesanal',
    rutaImagen: 'assets/categorias/pintura.png',
  ),
  _Categoria(
    id: 'instrumentos',
    nombre: 'Instrumentos',
    rutaImagen: 'assets/categorias/instrumentos.png',
  ),
  _Categoria(
    id: 'naturales',
    nombre: 'Productos naturales',
    rutaImagen: 'assets/categorias/naturales.png',
  ),
  _Categoria(
    id: 'souvenirs',
    nombre: 'Regalos y souvenirs',
    rutaImagen: 'assets/categorias/souvenirs.png',
  ),
];

// ---------------------------------------------------------------------------
// Pantalla principal
// ---------------------------------------------------------------------------

class PantallaIntereses extends StatefulWidget {
  /// Callback llamado al guardar intereses — HomeComprador decide la navegación
  final VoidCallback? alGuardar;

  /// Callback llamado al omitir
  final VoidCallback? alOmitir;

  const PantallaIntereses({super.key, this.alGuardar, this.alOmitir});

  @override
  State<PantallaIntereses> createState() => _PantallaInteresesState();
}

class _PantallaInteresesState extends State<PantallaIntereses> {
  // Sets de IDs seleccionados
  final Set<String> _provinciasSeleccionadas = {};
  final Set<String> _comarcasSeleccionadas = {};
  final Set<String> _categoriasSeleccionadas = {};

  bool _guardando = false;

  // ---------------------------------------------------------------------------
  // Lógica de guardado
  // 🔌 API: POST /api/compradores/{userId}/intereses
  // Body: { "provincias": [...], "comarcas": [...], "categorias": [...] }
  // ---------------------------------------------------------------------------
  Future<void> _guardarIntereses() async {
    setState(() => _guardando = true);

    // 🔌 API: Reemplaza el bloque de await Future.delayed con:
    //
    // final respuesta = await http.post(
    //   Uri.parse('https://tu-api.com/api/compradores/$userId/intereses'),
    //   headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    //   body: jsonEncode({
    //     'provincias': _provinciasSeleccionadas.toList(),
    //     'comarcas':   _comarcasSeleccionadas.toList(),
    //     'categorias': _categoriasSeleccionadas.toList(),
    //   }),
    // );
    //
    // if (respuesta.statusCode == 200) { widget.alGuardar?.call(); }
    // else { /* mostrar error con toastification */ }

    await Future.delayed(const Duration(milliseconds: 600));

    setState(() => _guardando = false);
    widget.alGuardar?.call();
  }

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondoPantalla = esModoOscuro
        ? const Color(0xFF121212)
        : const Color(0xFFF9F6F0);

    return Container(
      color: colorFondoPantalla,
      child: Column(
        children: [
          // Área scrolleable
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Encabezado ──────────────────────────────────────
                      _Encabezado()
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: -0.1, end: 0),

                      const SizedBox(height: 40),

                      // ── Sección 1: Regiones ──────────────────────────────
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

                      // ── Sección 2: Categorías ────────────────────────────
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

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Barra inferior de acciones ───────────────────────────────────
          _BarraAcciones(
            guardando: _guardando,
            alOmitir: widget.alOmitir,
            alGuardar: _guardarIntereses,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets internos
// ---------------------------------------------------------------------------

class _Encabezado extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuéntanos tus intereses',
              style: TextStyle(
                fontFamily: 'RocaTwo',
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: esModoOscuro ? Colors.white : const Color(0xFF2C1810),
              ),
            ),
            const SizedBox(width: 6),
            // Estrella decorativa
            Text(
              '✦',
              style: TextStyle(
                fontSize: 24,
                color: const Color(0xFF821515).withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Selecciona tus provincias, comarcas y los tipos de productos\nque más te interesan para personalizar tu experiencia.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            height: 1.6,
            color: esModoOscuro ? Colors.white60 : const Color(0xFF6B5A52),
          ),
        ),
      ],
    );
  }
}

// ── Sección 1 ────────────────────────────────────────────────────────────────

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
    final colorTarjeta = esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorTarjeta,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: esModoOscuro
              ? const Color(0xFF2E2E2E)
              : const Color(0xFFEDE8E2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(esModoOscuro ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de sección
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: const Color(0xFF821515),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '1. Selecciona las provincias y comarcas de Panamá que te interesan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: esModoOscuro
                        ? Colors.white
                        : const Color(0xFF2C1810),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Sub-label Provincias
          _SubLabel(texto: 'Provincias', esModoOscuro: esModoOscuro),
          const SizedBox(height: 12),

          // Grid de provincias
          // 🔌 API: GET /api/provincias → reemplaza la lista _provincias
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _provincias.map((p) {
              final seleccionado = provinciasSeleccionadas.contains(p.id);
              return _ChipRegionInline(
                nombre: p.nombre,
                bandera: p.bandera,
                seleccionado: seleccionado,
                alSeleccionar: () => alToggleProvincia(p.id),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Sub-label Comarcas
          _SubLabel(texto: 'Comarcas', esModoOscuro: esModoOscuro),
          const SizedBox(height: 12),

          // Grid de comarcas
          // 🔌 API: GET /api/comarcas → reemplaza la lista _comarcas
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _comarcas.map((c) {
              final seleccionado = comarcasSeleccionadas.contains(c.id);
              return _ChipRegionInline(
                nombre: c.nombre,
                bandera: c.bandera,
                seleccionado: seleccionado,
                alSeleccionar: () => alToggleComarca(c.id),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Nota informativa
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 15,
                color: const Color(0xFF821515).withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Puedes seleccionar una o varias provincias y comarcas según tus intereses.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: esModoOscuro
                      ? Colors.white38
                      : const Color(0xFF9E8E85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sección 2 ────────────────────────────────────────────────────────────────

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
    final colorTarjeta = esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorTarjeta,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: esModoOscuro
              ? const Color(0xFF2E2E2E)
              : const Color(0xFFEDE8E2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(esModoOscuro ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: const Color(0xFF821515),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                '2. ¿Qué tipos de productos te interesan?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: esModoOscuro ? Colors.white : const Color(0xFF2C1810),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Selecciona las categorías que más te gustan.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: esModoOscuro ? Colors.white54 : const Color(0xFF9E8E85),
            ),
          ),

          const SizedBox(height: 20),

          // Grid de categorías
          // 🔌 API: GET /api/categorias → reemplaza la lista _categorias
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _categorias.map((cat) {
              final seleccionado = categoriasSeleccionadas.contains(cat.id);
              return _ChipCategoriaInline(
                nombre: cat.nombre,
                rutaImagen: cat.rutaImagen,
                seleccionado: seleccionado,
                alSeleccionar: () => alToggleCategoria(cat.id),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Nota
          Row(
            children: [
              Icon(
                Icons.favorite_border,
                size: 15,
                color: const Color(0xFF821515).withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Cuantas más categorías selecciones, mejores recomendaciones te daremos.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: esModoOscuro
                      ? Colors.white38
                      : const Color(0xFF9E8E85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Barra de acciones inferior ────────────────────────────────────────────────

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
          // Botón omitir
          TextButton(
            onPressed: alOmitir,
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
              'Omitir por ahora',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: esModoOscuro ? Colors.white60 : const Color(0xFF6B5A52),
              ),
            ),
          ),

          // Botón guardar
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
                    children: const [
                      Text(
                        'Guardar y continuar',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chips inline (versión compacta para usar dentro de esta pantalla)
// Importa chip_region.dart y chip_categoria.dart si los prefieres externos
// ---------------------------------------------------------------------------

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
  bool _enHover = false;

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    const colorPrimario = Color(0xFF821515);
    final colorFondo = esModoOscuro ? const Color(0xFF262626) : Colors.white;
    final colorBorde = widget.seleccionado
        ? colorPrimario
        : (esModoOscuro ? const Color(0xFF3A3A3A) : const Color(0xFFE0D8D0));

    return MouseRegion(
      onEnter: (_) => setState(() => _enHover = true),
      onExit: (_) => setState(() => _enHover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alSeleccionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(minWidth: 120),
          decoration: BoxDecoration(
            color: widget.seleccionado
                ? colorPrimario.withOpacity(0.09)
                : (_enHover ? colorPrimario.withOpacity(0.04) : colorFondo),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorBorde,
              width: widget.seleccionado ? 2.0 : 1.5,
            ),
            boxShadow: _enHover || widget.seleccionado
                ? [
                    BoxShadow(
                      color: colorPrimario.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.bandera, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                widget.nombre,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: widget.seleccionado
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: widget.seleccionado
                      ? colorPrimario
                      : (esModoOscuro ? Colors.white : const Color(0xFF2C2C2C)),
                ),
              ),
              if (widget.seleccionado) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: colorPrimario,
                ),
              ],
            ],
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
  bool _enHover = false;

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    const colorPrimario = Color(0xFF821515);
    final colorFondo = esModoOscuro ? const Color(0xFF262626) : Colors.white;
    final colorBorde = widget.seleccionado
        ? colorPrimario
        : (esModoOscuro ? const Color(0xFF3A3A3A) : const Color(0xFFE0D8D0));

    return MouseRegion(
      onEnter: (_) => setState(() => _enHover = true),
      onExit: (_) => setState(() => _enHover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alSeleccionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 115,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: widget.seleccionado
                ? colorPrimario.withOpacity(0.09)
                : (_enHover ? colorPrimario.withOpacity(0.04) : colorFondo),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorBorde,
              width: widget.seleccionado ? 2.0 : 1.5,
            ),
            boxShadow: _enHover || widget.seleccionado
                ? [
                    BoxShadow(
                      color: colorPrimario.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      widget.rutaImagen,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      // 🔌 API: Cambiar por Image.network si las imágenes vienen del backend
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: colorPrimario.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.category_outlined,
                          color: colorPrimario,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.nombre,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: widget.seleccionado
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: widget.seleccionado
                          ? colorPrimario
                          : (esModoOscuro
                                ? Colors.white70
                                : const Color(0xFF2C2C2C)),
                    ),
                  ),
                ],
              ),
              if (widget.seleccionado)
                Positioned(
                  top: 0,
                  right: 0,
                  child:
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: colorPrimario,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ).animate().scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 200.ms,
                        curve: Curves.elasticOut,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
