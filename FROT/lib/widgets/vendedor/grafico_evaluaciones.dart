import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';

class GraficoEvaluaciones extends StatefulWidget {
  final Map<int, int> distribucion; // estrella -> cantidad
  final double promedio;
  final int total;
  final bool esOscuro;

  const GraficoEvaluaciones({
    super.key,
    required this.distribucion,
    required this.promedio,
    required this.total,
    this.esOscuro = false,
  });

  @override
  State<GraficoEvaluaciones> createState() => _GraficoEvaluacionesState();
}

class _GraficoEvaluacionesState extends State<GraficoEvaluaciones> {
  int? _seccionTocada;

  @override
  Widget build(BuildContext context) {
    final totalComentarios =
        widget.distribucion.values.fold(0, (a, b) => a + b);
    final colorTexto = CraftHubColors.textoPrincipal(widget.esOscuro);
    final colorSec = CraftHubColors.textoSecundario(widget.esOscuro);
    final colorBorde = CraftHubColors.borde(widget.esOscuro);

    return Row(
      children: [
        // Promedio + estrellas
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.promedio.toStringAsFixed(1),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: colorTexto,
              ),
            ),
            Row(
              children: List.generate(5, (i) {
                final llena = i < widget.promedio.floor();
                final media = !llena &&
                    i < widget.promedio &&
                    widget.promedio - widget.promedio.floor() >= 0.5;
                return Icon(
                  llena
                      ? Icons.star_rounded
                      : (media
                          ? Icons.star_half_rounded
                          : Icons.star_outline_rounded),
                  size: 18,
                  color: const Color(0xFFD4A843),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              'Excelente',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorTexto,
              ),
            ),
            Text(
              'Basado en ${widget.total} opiniones',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: colorSec,
              ),
            ),
          ],
        ),

        const SizedBox(width: 20),

        // Donut
        SizedBox(
          width: 90,
          height: 90,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 28,
              pieTouchData: PieTouchData(
                touchCallback: (_, response) {
                  setState(() {
                    _seccionTocada =
                        response?.touchedSection?.touchedSectionIndex;
                  });
                },
              ),
              sections: [5, 4, 3, 2, 1].asMap().entries.map((e) {
                final estrellas = e.value;
                final cantidad =
                    widget.distribucion[estrellas] ?? 0;
                final porcentaje = totalComentarios > 0
                    ? cantidad / totalComentarios
                    : 0.0;
                final tocado = _seccionTocada == e.key;

                final colores = [
                  CraftHubColors.vinoTinto,
                  CraftHubColors.vinoTintoClaro,
                  const Color(0xFFD4A843),
                  const Color(0xFFE0C87A),
                  colorBorde,
                ];

                return PieChartSectionData(
                  value: porcentaje * 100,
                  color: colores[e.key],
                  radius: tocado ? 22 : 18,
                  showTitle: false,
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(width: 20),

        // Barras de distribución
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [5, 4, 3, 2, 1].map((estrellas) {
              final cantidad =
                  widget.distribucion[estrellas] ?? 0;
              final porcentaje = totalComentarios > 0
                  ? cantidad / totalComentarios
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        '$estrellas estrellas',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: colorSec,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: porcentaje,
                          minHeight: 6,
                          backgroundColor: colorBorde,
                          valueColor: AlwaysStoppedAnimation(
                            estrellas >= 4
                                ? CraftHubColors.vinoTinto
                                : estrellas == 3
                                    ? const Color(0xFFD4A843)
                                    : colorBorde,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${(porcentaje * 100).toInt()}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colorTexto,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}