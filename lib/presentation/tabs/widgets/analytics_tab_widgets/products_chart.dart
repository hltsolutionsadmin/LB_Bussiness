import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProductsChart extends StatelessWidget {
  final List<Map<String, dynamic>> reportItems;
  final int maxItems;

  const ProductsChart({
    super.key,
    required this.reportItems,
    this.maxItems = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (reportItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Items by Sales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                maxY: _getMaxY(),
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getHorizontalInterval(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < reportItems.length) {
                          final name =
                              reportItems[idx]['productName']?.toString() ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              name.length > 8
                                  ? '${name.substring(0, 8)}...'
                                  : name,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                barGroups: _buildBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (reportItems.isEmpty) return 1000;
    final maxValue = reportItems
        .map((e) => (e['total'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a > b ? a : b);
    return maxValue * 1.2;
  }

  double _getHorizontalInterval() {
    if (reportItems.isEmpty) return 100;
    final maxValue = reportItems
        .map((e) => (e['total'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a > b ? a : b);
    return maxValue / 5;
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(reportItems.take(maxItems).length, (i) {
      final item = reportItems[i];
      final v = (item['total'] as num?)?.toDouble() ?? 0.0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            fromY: 0,
            toY: v,
            color: const Color(0xFFF97316),
            width: 24,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }
}
