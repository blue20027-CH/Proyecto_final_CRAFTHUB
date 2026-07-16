// lib/widgets/eventos/calendario_mensual.dart
//
// Calendario mensual interactivo: navegación entre meses, botón "Hoy",
// selección de día y puntos indicadores en los días con actividades.

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';

class CalendarioMensual extends StatelessWidget {
  final DateTime mesMostrado;
  final DateTime? diaSeleccionado;
  final Set<DateTime> diasConEventos;
  final Set<DateTime> diasConDescuento;
  final ValueChanged<DateTime> alSeleccionarDia;
  final VoidCallback alMesAnterior;
  final VoidCallback alMesSiguiente;
  final VoidCallback alIrHoy;

  const CalendarioMensual({
    super.key,
    required this.mesMostrado,
    required this.diaSeleccionado,
    required this.diasConEventos,
    this.diasConDescuento = const {},
    required this.alSeleccionarDia,
    required this.alMesAnterior,
    required this.alMesSiguiente,
    required this.alIrHoy,
  });

  static const _clavesMes = [
    'compartido.mes_enero', 'compartido.mes_febrero', 'compartido.mes_marzo',
    'compartido.mes_abril', 'compartido.mes_mayo', 'compartido.mes_junio',
    'compartido.mes_julio', 'compartido.mes_agosto', 'compartido.mes_septiembre',
    'compartido.mes_octubre', 'compartido.mes_noviembre', 'compartido.mes_diciembre',
  ];
  static const _clavesDiaSemana = [
    'compartido.dia_dom', 'compartido.dia_lun', 'compartido.dia_mar',
    'compartido.dia_mie', 'compartido.dia_jue', 'compartido.dia_vie', 'compartido.dia_sab',
  ];

  static DateTime _normalizar(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final hoy = _normalizar(DateTime.now());
    final primerDiaMes = DateTime(mesMostrado.year, mesMostrado.month, 1);
    final diasEnMes = DateTime(mesMostrado.year, mesMostrado.month + 1, 0).day;
    final offsetInicio = primerDiaMes.weekday % 7; // Dom=0 … Sáb=6
    final totalCeldas = ((offsetInicio + diasEnMes) / 7).ceil() * 7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CraftHubColors.panel(oscuro),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CraftHubColors.borde(oscuro)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Encabezado: mes/año + navegación + botón Hoy ──────────────
          Row(
            children: [
              _BotonFlecha(icono: Icons.chevron_left_rounded, onTap: alMesAnterior),
              Expanded(
                child: Center(
                  child: Text(
                    '${tr(context, _clavesMes[mesMostrado.month - 1])} ${mesMostrado.year}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: CraftHubColors.textoPrincipal(oscuro),
                    ),
                  ),
                ),
              ),
              _BotonFlecha(icono: Icons.chevron_right_rounded, onTap: alMesSiguiente),
              const SizedBox(width: 10),
              _BotonHoy(onTap: alIrHoy, oscuro: oscuro),
            ],
          ),
          const SizedBox(height: 18),

          // ── Fila de días de la semana ──────────────────────────────────
          Row(
            children: _clavesDiaSemana
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          tr(context, d),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: CraftHubColors.textoSecundario(oscuro),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // ── Grilla de días ──────────────────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCeldas,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, i) {
              final numeroDia = i - offsetInicio + 1;
              final fechaCelda = DateTime(mesMostrado.year, mesMostrado.month, numeroDia);
              final normalizada = _normalizar(fechaCelda);
              final delMesActual = fechaCelda.month == mesMostrado.month;
              final esHoy = normalizada == hoy;
              final esSeleccionado =
                  diaSeleccionado != null && normalizada == _normalizar(diaSeleccionado!);
              final tieneEvento = diasConEventos.contains(normalizada);
              final tieneDescuento = diasConDescuento.contains(normalizada);

              return _CeldaDia(
                numero: fechaCelda.day,
                delMesActual: delMesActual,
                esHoy: esHoy,
                esSeleccionado: esSeleccionado,
                tieneEvento: tieneEvento,
                tieneDescuento: tieneDescuento,
                onTap: () => alSeleccionarDia(normalizada),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BotonFlecha extends StatefulWidget {
  final IconData icono;
  final VoidCallback onTap;
  const _BotonFlecha({required this.icono, required this.onTap});

  @override
  State<_BotonFlecha> createState() => _BotonFlechaState();
}

class _BotonFlechaState extends State<_BotonFlecha> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hover
                ? CraftHubColors.vinoTinto.withValues(alpha: 0.12)
                : CraftHubColors.fondo(oscuro),
            border: Border.all(color: CraftHubColors.borde(oscuro)),
          ),
          child: Icon(widget.icono, size: 20, color: CraftHubColors.vinoTinto),
        ),
      ),
    );
  }
}

class _BotonHoy extends StatefulWidget {
  final VoidCallback onTap;
  final bool oscuro;
  const _BotonHoy({required this.onTap, required this.oscuro});

  @override
  State<_BotonHoy> createState() => _BotonHoyState();
}

class _BotonHoyState extends State<_BotonHoy> {
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
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hover
                ? CraftHubColors.vinoTinto
                : CraftHubColors.vinoTinto.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: CraftHubColors.vinoTinto, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.today_rounded,
                  size: 14, color: _hover ? Colors.white : CraftHubColors.vinoTinto),
              const SizedBox(width: 6),
              Text(
                tr(context, 'compartido.hoy_boton'),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _hover ? Colors.white : CraftHubColors.vinoTinto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CeldaDia extends StatefulWidget {
  final int numero;
  final bool delMesActual;
  final bool esHoy;
  final bool esSeleccionado;
  final bool tieneEvento;
  final bool tieneDescuento;
  final VoidCallback onTap;

  const _CeldaDia({
    required this.numero,
    required this.delMesActual,
    required this.esHoy,
    required this.esSeleccionado,
    required this.tieneEvento,
    this.tieneDescuento = false,
    required this.onTap,
  });

  @override
  State<_CeldaDia> createState() => _CeldaDiaState();
}

class _CeldaDiaState extends State<_CeldaDia> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    Color colorTexto;
    Color colorFondo = Colors.transparent;
    Border? borde;

    if (widget.esHoy) {
      colorFondo = CraftHubColors.vinoTinto;
      colorTexto = Colors.white;
    } else if (widget.esSeleccionado) {
      colorFondo = CraftHubColors.vinoTintoSuave.withValues(alpha: oscuro ? 0.25 : 1);
      colorTexto = CraftHubColors.vinoTinto;
      borde = Border.all(color: CraftHubColors.vinoTinto, width: 1.2);
    } else if (!widget.delMesActual) {
      colorTexto = CraftHubColors.textoSecundario(oscuro).withValues(alpha: 0.5);
    } else {
      colorTexto = CraftHubColors.textoPrincipal(oscuro);
    }

    if (_hover && !widget.esHoy && !widget.esSeleccionado) {
      colorFondo = CraftHubColors.vinoTinto.withValues(alpha: 0.06);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: colorFondo,
            borderRadius: BorderRadius.circular(10),
            border: borde,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.numero}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: widget.esHoy || widget.esSeleccionado
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: colorTexto,
                ),
              ),
              if (widget.tieneEvento) ...[
                const SizedBox(height: 3),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.tieneDescuento
                        ? const Color(0xFFD4A843)
                        : (widget.esHoy ? Colors.white : CraftHubColors.vinoTinto),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
