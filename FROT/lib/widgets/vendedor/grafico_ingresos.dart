import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';

class GraficoIngresos extends StatefulWidget {
  final List<double> valores;
  final List<String> etiquetas;
  final bool esOscuro;

  const GraficoIngresos({
    super.key,
    required this.valores,
    required this.etiquetas,
    this.esOscuro = false,
  });

  @override
  State<GraficoIngresos> createState() => _GraficoIngresosState();
}

class _GraficoIngresosState extends State<GraficoIngresos> {
  int? _puntoTocado;

  @override
  Widget build(BuildContext context) {
    // Un vendedor nuevo sin ventas todavía tiene todos los valores en 0.
    // fl_chart necesita un intervalo > 0 para dibujar la cuadrícula — con
    // maxVal = 0 el intervalo también sería 0, lo que cuelga el gráfico
    // (y con él toda la pantalla) en vez de simplemente mostrarlo vacío.
    final valorMasAlto = widget.valores.isEmpty
        ? 0.0
        : widget.valores.reduce((a, b) => a > b ? a : b);
    final maxVal = valorMasAlto > 0 ? valorMasAlto : 100.0;
    final colorTexto = CraftHubColors.textoSecundario(widget.esOscuro);
    final colorGrid = CraftHubColors.borde(widget.esOscuro);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxVal * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colorGrid,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: maxVal / 4,
              getTitlesWidget: (v, _) => Text(
                v >= 1000 ? '\$${(v / 1000).toStringAsFixed(1)}k' : '\$${v.toInt()}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: colorTexto,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= widget.etiquetas.length) {
                  return const SizedBox();
                }
                final esActivo = i == widget.etiquetas.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: esActivo
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: CraftHubColors.vinoTinto,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.etiquetas[i],
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          widget.etiquetas[i],
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: colorTexto,
                          ),
                        ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchCallback: (_, response) {
            setState(() {
              _puntoTocado =
                  response?.lineBarSpots?.first.spotIndex;
            });
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => CraftHubColors.vinoTinto,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '\$${s.y.toStringAsFixed(0)}',
                      const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: widget.valores
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: CraftHubColors.vinoTinto,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, _, i) => FlDotCirclePainter(
                radius: _puntoTocado == i ? 6 : 4,
                color: CraftHubColors.vinoTinto,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CraftHubColors.vinoTinto.withValues(alpha: 0.20),
                  CraftHubColors.vinoTinto.withValues(alpha: 0.01),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}