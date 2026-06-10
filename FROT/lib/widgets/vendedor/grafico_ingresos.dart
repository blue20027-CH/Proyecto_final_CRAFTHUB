import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';

class GraficoIngresos extends StatefulWidget {
  final List<double> valores;
  final List<String> etiquetas;

  const GraficoIngresos({
    super.key,
    required this.valores,
    required this.etiquetas,
  });

  @override
  State<GraficoIngresos> createState() => _GraficoIngresosState();
}

class _GraficoIngresosState extends State<GraficoIngresos> {
  int? _puntoTocado;

  @override
  Widget build(BuildContext context) {
    final maxVal = widget.valores.reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxVal * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: CraftHubColors.bordeClaro,
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
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: CraftHubColors.textoSecClaro,
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
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: CraftHubColors.textoSecClaro,
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
              getDotPainter: (spot, _, __, i) => FlDotCirclePainter(
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
                  CraftHubColors.vinoTinto.withOpacity(0.20),
                  CraftHubColors.vinoTinto.withOpacity(0.01),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}