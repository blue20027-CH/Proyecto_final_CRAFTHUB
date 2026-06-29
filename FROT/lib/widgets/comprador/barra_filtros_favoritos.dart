import 'package:flutter/material.dart';


/// Estado de los filtros de la pantalla de favoritos.
class EstadoFiltrosFavoritos {
  final String tipoSeleccionado;
  final String categoriaSeleccionada;
  final String ordenSeleccionado;

  const EstadoFiltrosFavoritos({
    this.tipoSeleccionado = 'Todos los tipos',
    this.categoriaSeleccionada = 'Todas las categorías',
    this.ordenSeleccionado = 'Más recientes',
  });

  EstadoFiltrosFavoritos copiarCon({
    String? tipo,
    String? categoria,
    String? orden,
  }) {
    return EstadoFiltrosFavoritos(
      tipoSeleccionado: tipo ?? tipoSeleccionado,
      categoriaSeleccionada: categoria ?? categoriaSeleccionada,
      ordenSeleccionado: orden ?? ordenSeleccionado,
    );
  }
}

/// Barra de filtros horizontal para la pantalla de Mis Favoritos.
/// 🔗 API: GET /api/v1/favoritos/{usuarioId}?tipo=X&categoria=Y&orden=Z
class BarraFiltrosFavoritos extends StatefulWidget {
  final Function(EstadoFiltrosFavoritos) alCambiarFiltros;

  const BarraFiltrosFavoritos({
    super.key,
    required this.alCambiarFiltros,
  });

  @override
  State<BarraFiltrosFavoritos> createState() => _BarraFiltrosFavoritosState();
}

class _BarraFiltrosFavoritosState extends State<BarraFiltrosFavoritos> {
  EstadoFiltrosFavoritos _filtros = const EstadoFiltrosFavoritos();

  static const _tiposProducto = [
    'Todos los tipos',
    'Textiles',
    'Cerámica',
    'Joyería',
    'Madera tallada',
    'Cestería',
    'Molas',
    'Sombreros',
  ];

  static const _categorias = [
    'Todas las categorías',
    'Artesanía indígena',
    'Arte folclórico',
    'Joyería tradicional',
    'Textiles bordados',
    'Cerámica pintada',
    'Productos naturales',
  ];

  static const _ordenamientos = [
    'Más recientes',
    'Mayor precio',
    'Menor precio',
    'Más populares',
    'A - Z',
  ];

  void _actualizarFiltros(EstadoFiltrosFavoritos nuevos) {
    setState(() => _filtros = nuevos);
    widget.alCambiarFiltros(nuevos);
    // 🔗 API: aplicar filtros al endpoint de favoritos con query params
  }

  @override
  Widget build(BuildContext context) {
    final esTemaOscuro = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        _DropdownFiltro(
          valor: _filtros.tipoSeleccionado,
          opciones: _tiposProducto,
          alCambiar: (v) => _actualizarFiltros(
              _filtros.copiarCon(tipo: v)),
          esTemaOscuro: esTemaOscuro,
        ),
        const SizedBox(width: 10),
        _DropdownFiltro(
          valor: _filtros.categoriaSeleccionada,
          opciones: _categorias,
          alCambiar: (v) => _actualizarFiltros(
              _filtros.copiarCon(categoria: v)),
          esTemaOscuro: esTemaOscuro,
        ),
        const Spacer(),
        _DropdownFiltro(
          valor: _filtros.ordenSeleccionado,
          opciones: _ordenamientos,
          alCambiar: (v) => _actualizarFiltros(
              _filtros.copiarCon(orden: v)),
          esTemaOscuro: esTemaOscuro,
          prefijoIcono: Icons.sort, // HugeIcons.strokeRoundedSort01,
        ),
      ],
    );
  }
}

class _DropdownFiltro extends StatelessWidget {
  final String valor;
  final List<String> opciones;
  final ValueChanged<String> alCambiar;
  final bool esTemaOscuro;
  final IconData? prefijoIcono;

  const _DropdownFiltro({
    required this.valor,
    required this.opciones,
    required this.alCambiar,
    required this.esTemaOscuro,
    this.prefijoIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: esTemaOscuro ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: esTemaOscuro
              ? Colors.white12
              : const Color(0xFFE0D8D0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esTemaOscuro ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valor,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: esTemaOscuro ? Colors.white : Colors.black87,
          ),
          dropdownColor:
              esTemaOscuro ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: opciones
              .map((op) => DropdownMenuItem(
                    value: op,
                    child: Row(
                      children: [
                        if (prefijoIcono != null && op == valor) ...[
                          Icon(prefijoIcono,
                              size: 14,
                              color: const Color(0xFF821515)),
                          const SizedBox(width: 6),
                        ],
                        Text(op),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) alCambiar(v);
          },
        ),
      ),
    );
  }
}