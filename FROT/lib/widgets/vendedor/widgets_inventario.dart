// lib/widgets/inventario/widgets_inventario.dart
// Widgets reutilizables para PantallaInventario

import 'package:flutter/material.dart';
import '../../models/modelo_producto_inventario.dart';
import '../../core/i18n/i18n.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 0. Tarjeta de producto (grilla visual del inventario)
// ─────────────────────────────────────────────────────────────────────────────

class TarjetaProductoInventario extends StatefulWidget {
  final ProductoInventario producto;
  final VoidCallback alVer;
  final VoidCallback alEditar;
  final VoidCallback alEliminar;

  const TarjetaProductoInventario({
    super.key,
    required this.producto,
    required this.alVer,
    required this.alEditar,
    required this.alEliminar,
  });

  @override
  State<TarjetaProductoInventario> createState() => _TarjetaProductoInventarioState();
}

class _TarjetaProductoInventarioState extends State<TarjetaProductoInventario> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTarjeta = esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white;
    const colorPrimario = Color(0xFF821515);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorTarjeta,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hover
                ? colorPrimario.withValues(alpha: 0.35)
                : (esModoOscuro ? const Color(0xFF2E2E2E) : const Color(0xFFEDE8E2)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hover ? (esModoOscuro ? 0.28 : 0.08) : (esModoOscuro ? 0.2 : 0.04)),
              blurRadius: _hover ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.alVer,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AspectRatio(
                  aspectRatio: 16 / 11,
                  child: Image.network(
                    widget.producto.rutaImagen,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: colorPrimario.withValues(alpha: 0.08),
                      alignment: Alignment.center,
                      child: const Icon(Icons.inventory_2_outlined, color: colorPrimario, size: 32),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: esModoOscuro ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${widget.producto.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorPrimario,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Stock: ${widget.producto.stock}   ${tr(context, 'vendedor_inventario.ventas_prefijo')}${widget.producto.ventas}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: esModoOscuro ? Colors.white54 : const Color(0xFF6B5A52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  BadgeEstado(estado: widget.producto.estado),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.alEditar,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: esModoOscuro ? Colors.white70 : const Color(0xFF4A4A4A),
                            side: BorderSide(
                              color: esModoOscuro ? const Color(0xFF3A3A3A) : const Color(0xFFDDD5CC),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          ),
                          child: Text(tr(context, 'vendedor_inventario.editar'),
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.alEliminar,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC62828),
                            side: const BorderSide(color: Color(0xFFF0C6C6)),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          ),
                          child: Text(tr(context, 'vendedor_inventario.eliminar'),
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Tarjeta de estadística superior
// ─────────────────────────────────────────────────────────────────────────────

class TarjetaEstadistica extends StatelessWidget {
  final IconData icono;
  final Color colorIcono;
  final String valor;
  final String etiqueta;

  const TarjetaEstadistica({
    super.key,
    required this.icono,
    required this.colorIcono,
    required this.valor,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTarjeta = esModoOscuro ? const Color(0xFF1E1E1E) : Colors.white;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: colorTarjeta,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: esModoOscuro
                ? const Color(0xFF2E2E2E)
                : const Color(0xFFEDE8E2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: esModoOscuro ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorIcono.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: colorIcono, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: esModoOscuro
                        ? Colors.white
                        : const Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  etiqueta,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: esModoOscuro
                        ? Colors.white54
                        : const Color(0xFF9E8E85),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Badge de estado del producto
// ─────────────────────────────────────────────────────────────────────────────

class BadgeEstado extends StatelessWidget {
  final EstadoProducto estado;

  const BadgeEstado({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String texto;

    switch (estado) {
      case EstadoProducto.activo:
        color = const Color(0xFF2E7D32);
        texto = tr(context, 'vendedor_inventario.estado_activo');
        break;
      case EstadoProducto.agotado:
        color = const Color(0xFFC62828);
        texto = tr(context, 'vendedor_inventario.estado_agotado');
        break;
      case EstadoProducto.borrador:
        color = const Color(0xFFE65100);
        texto = tr(context, 'vendedor_inventario.estado_borrador');
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Chip de colección (badge naranja/vinotinto en la tabla)
// ─────────────────────────────────────────────────────────────────────────────

class ChipColeccion extends StatelessWidget {
  final String nombre;

  const ChipColeccion({super.key, required this.nombre});

  @override
  Widget build(BuildContext context) {
    const colorPrimario = Color(0xFF821515);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorPrimario.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorPrimario.withValues(alpha: 0.2)),
      ),
      child: Text(
        nombre,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colorPrimario,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Fila de producto en la tabla
// ─────────────────────────────────────────────────────────────────────────────

class FilaProducto extends StatefulWidget {
  final ProductoInventario producto;
  final bool seleccionado;
  final ValueChanged<bool?> alCambiarSeleccion;
  final VoidCallback alEditar;
  final VoidCallback alVerOpciones;

  const FilaProducto({
    super.key,
    required this.producto,
    required this.seleccionado,
    required this.alCambiarSeleccion,
    required this.alEditar,
    required this.alVerOpciones,
  });

  @override
  State<FilaProducto> createState() => _FilaProductoState();
}

class _FilaProductoState extends State<FilaProducto> {
  bool _enHover = false;

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFila = _enHover || widget.seleccionado
        ? (esModoOscuro
              ? const Color(0xFF821515).withValues(alpha: 0.06)
              : const Color(0xFF821515).withValues(alpha: 0.03))
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _enHover = true),
      onExit: (_) => setState(() => _enHover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: colorFila,
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 52,
              child: Checkbox(
                value: widget.seleccionado,
                onChanged: widget.alCambiarSeleccion,
                activeColor: const Color(0xFF821515),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Imagen + nombre + SKU
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.producto.rutaImagen,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF821515).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF821515),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.producto.nombre,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: esModoOscuro
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'SKU: ${widget.producto.sku}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: esModoOscuro
                                  ? Colors.white38
                                  : const Color(0xFF9E8E85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Colección
            Expanded(
              flex: 2,
              child: ChipColeccion(nombre: widget.producto.coleccion),
            ),

            // Categoría
            Expanded(
              flex: 2,
              child: Text(
                widget.producto.categoria,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: esModoOscuro
                      ? Colors.white70
                      : const Color(0xFF4A4A4A),
                ),
              ),
            ),

            // Precio
            Expanded(
              flex: 1,
              child: Text(
                '\$${widget.producto.precio.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: esModoOscuro ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ),

            // Stock
            Expanded(
              flex: 1,
              child: Text(
                '${widget.producto.stock} ${tr(context, 'vendedor_inventario.unidades_sufijo')}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: widget.producto.stock == 0
                      ? const Color(0xFFC62828)
                      : (esModoOscuro
                            ? Colors.white70
                            : const Color(0xFF4A4A4A)),
                  fontWeight: widget.producto.stock == 0
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),

            // Ventas
            Expanded(
              flex: 1,
              child: Text(
                '${widget.producto.ventas}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: esModoOscuro
                      ? Colors.white70
                      : const Color(0xFF4A4A4A),
                ),
              ),
            ),

            // Estado
            Expanded(
              flex: 1,
              child: BadgeEstado(estado: widget.producto.estado),
            ),

            // Acciones
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BotonAccion(
                    icono: Icons.edit_outlined,
                    tooltip: tr(context, 'vendedor_inventario.editar_producto_titulo'),
                    alPresionar: widget.alEditar,
                  ),
                  const SizedBox(width: 4),
                  _BotonAccion(
                    icono: Icons.more_horiz,
                    tooltip: tr(context, 'vendedor_inventario.mas_opciones_tooltip'),
                    alPresionar: widget.alVerOpciones,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonAccion extends StatefulWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback alPresionar;

  const _BotonAccion({
    required this.icono,
    required this.tooltip,
    required this.alPresionar,
  });

  @override
  State<_BotonAccion> createState() => _BotonAccionState();
}

class _BotonAccionState extends State<_BotonAccion> {
  bool _enHover = false;

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _enHover = true),
      onExit: (_) => setState(() => _enHover = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.alPresionar,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _enHover
                  ? (esModoOscuro ? Colors.white12 : const Color(0xFFF0EAE5))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icono,
              size: 17,
              color: esModoOscuro ? Colors.white60 : const Color(0xFF6B5A52),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Paginador inferior
// ─────────────────────────────────────────────────────────────────────────────

class PaginadorTabla extends StatelessWidget {
  final int paginaActual;
  final int totalPaginas;
  final int totalRegistros;
  final int registrosPorPagina;
  final ValueChanged<int> alCambiarPagina;
  final ValueChanged<int> alCambiarRegistrosPorPagina;

  const PaginadorTabla({
    super.key,
    required this.paginaActual,
    required this.totalPaginas,
    required this.totalRegistros,
    required this.registrosPorPagina,
    required this.alCambiarPagina,
    required this.alCambiarRegistrosPorPagina,
  });

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = esModoOscuro ? Colors.white60 : const Color(0xFF6B5A52);

    return Row(
      children: [
        // Info de registros
        Text(
          _textoRango(context),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: colorTexto,
          ),
        ),
        const Spacer(),

        // Botones de paginación
        _BtnPagina(
          icono: Icons.chevron_left,
          habilitado: paginaActual > 1,
          alPresionar: () => alCambiarPagina(paginaActual - 1),
          esModoOscuro: esModoOscuro,
        ),
        const SizedBox(width: 4),

        // Páginas
        ..._construirBotonesPagina(esModoOscuro),

        const SizedBox(width: 4),
        _BtnPagina(
          icono: Icons.chevron_right,
          habilitado: paginaActual < totalPaginas,
          alPresionar: () => alCambiarPagina(paginaActual + 1),
          esModoOscuro: esModoOscuro,
        ),

        const SizedBox(width: 24),

        // Registros por página
        Text(
          tr(context, 'vendedor_inventario.productos_por_pagina'),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: colorTexto,
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: registrosPorPagina,
          underline: const SizedBox(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: esModoOscuro ? Colors.white : const Color(0xFF1A1A1A),
          ),
          items: [25, 50, 100].map((n) {
            return DropdownMenuItem(value: n, child: Text('$n'));
          }).toList(),
          onChanged: (v) {
            if (v != null) alCambiarRegistrosPorPagina(v);
          },
        ),
      ],
    );
  }

  String _textoRango(BuildContext context) {
    if (totalRegistros == 0) return tr(context, 'vendedor_inventario.no_hay_productos');
    final inicio = (paginaActual - 1) * registrosPorPagina + 1;
    final fin = (inicio + registrosPorPagina - 1).clamp(0, totalRegistros);
    return '${tr(context, 'vendedor_inventario.mostrando_prefijo')}$inicio'
        '${tr(context, 'vendedor_inventario.mostrando_a_infijo')}$fin'
        '${tr(context, 'vendedor_inventario.mostrando_de_infijo')}$totalRegistros'
        '${tr(context, 'vendedor_inventario.mostrando_productos_sufijo')}';
  }

  List<Widget> _construirBotonesPagina(bool esModoOscuro) {
    final paginas = <Widget>[];
    final mostrar = <dynamic>[];

    mostrar.add(1);
    if (paginaActual > 3) mostrar.add('...');
    for (int i = paginaActual - 1; i <= paginaActual + 1; i++) {
      if (i > 1 && i < totalPaginas) mostrar.add(i);
    }
    if (paginaActual < totalPaginas - 2) mostrar.add('...');
    if (totalPaginas > 1) mostrar.add(totalPaginas);

    for (final item in mostrar) {
      if (item == '...') {
        paginas.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '...',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: esModoOscuro ? Colors.white38 : const Color(0xFF9E8E85),
              ),
            ),
          ),
        );
      } else {
        final num = item as int;
        final esActual = num == paginaActual;
        paginas.add(
          GestureDetector(
            onTap: () => alCambiarPagina(num),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 32,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: esActual ? const Color(0xFF821515) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: esActual
                      ? const Color(0xFF821515)
                      : (esModoOscuro
                            ? const Color(0xFF3A3A3A)
                            : const Color(0xFFE0D8D0)),
                ),
              ),
              child: Center(
                child: Text(
                  '$num',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: esActual
                        ? Colors.white
                        : (esModoOscuro
                              ? Colors.white60
                              : const Color(0xFF4A4A4A)),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return paginas;
  }
}

class _BtnPagina extends StatelessWidget {
  final IconData icono;
  final bool habilitado;
  final VoidCallback alPresionar;
  final bool esModoOscuro;

  const _BtnPagina({
    required this.icono,
    required this.habilitado,
    required this.alPresionar,
    required this.esModoOscuro,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: habilitado ? alPresionar : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: esModoOscuro
                ? const Color(0xFF3A3A3A)
                : const Color(0xFFE0D8D0),
          ),
        ),
        child: Icon(
          icono,
          size: 18,
          color: habilitado
              ? (esModoOscuro ? Colors.white70 : const Color(0xFF4A4A4A))
              : (esModoOscuro ? Colors.white24 : const Color(0xFFCCC5BE)),
        ),
      ),
    );
  }
}
