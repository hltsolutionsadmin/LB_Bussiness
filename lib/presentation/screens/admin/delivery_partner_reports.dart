import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_basket_business/widgets/glass_card.dart';
import 'package:local_basket_business/theme/app_colors.dart';

class DeliveryPartnerReportsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const DeliveryPartnerReportsScreen({super.key, required this.onBack});

  @override
  State<DeliveryPartnerReportsScreen> createState() =>
      _DeliveryPartnerReportsScreenState();
}

class _DeliveryPartnerReportsScreenState
    extends State<DeliveryPartnerReportsScreen> {
  String _selectedPeriod = 'Week';
  final List<String> _periods = const ['Week', 'Month', 'Year'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: widget.onBack,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Delivery Analytics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          _buildPeriodSelector(),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: -0.2, end: 0, duration: 300.ms),
                const SizedBox(height: 24),
                _buildPerformanceMetrics(),
                const SizedBox(height: 24),
                _buildDeliveriesChart(),
                const SizedBox(height: 24),
                _buildTopPerformers(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: DropdownButton<String>(
        value: _selectedPeriod,
        underline: const SizedBox(),
        dropdownColor: AppColors.red900,
        isDense: true,
        items: _periods
            .map(
              (period) => DropdownMenuItem(
                value: period,
                child: Text(
                  period,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _selectedPeriod = value);
        },
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildMetricCard(
                  'Total Deliveries',
                  '1,234',
                  '+18%',
                  Icons.delivery_dining,
                  AppColors.info,
                ),
                _buildMetricCard(
                  'On-Time Rate',
                  '94%',
                  '+3%',
                  Icons.timer,
                  AppColors.success,
                ),
                _buildMetricCard(
                  'Avg Rating',
                  '4.7',
                  '+0.3',
                  Icons.star,
                  AppColors.warning,
                ),
                _buildMetricCard(
                  'Total Earnings',
                  '₹45K',
                  '+12%',
                  Icons.currency_rupee,
                  AppColors.orange600,
                ),
              ],
            ),
          ],
        )
        .animate()
        .fadeIn(delay: 100.ms, duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveriesChart() {
    return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deliveries Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: AppColors.glassBorder, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ];
                            if (value.toInt() >= 0 &&
                                value.toInt() < days.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  days[value.toInt()],
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: 250,
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 150),
                          FlSpot(1, 175),
                          FlSpot(2, 160),
                          FlSpot(3, 190),
                          FlSpot(4, 220),
                          FlSpot(5, 210),
                          FlSpot(6, 185),
                        ],
                        isCurved: true,
                        gradient: AppColors.buttonGradient,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.orange600.withOpacity(0.3),
                              AppColors.orange600.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }

  Widget _buildTopPerformers() {
    final topPerformers = [
      {'name': 'Vijay Kumar', 'deliveries': 245, 'rating': 4.8},
      {'name': 'Ravi Singh', 'deliveries': 198, 'rating': 4.7},
      {'name': 'Arjun Reddy', 'deliveries': 176, 'rating': 4.6},
      {'name': 'Rahul Sharma', 'deliveries': 165, 'rating': 4.5},
      {'name': 'Amit Patel', 'deliveries': 152, 'rating': 4.4},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Performers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
              child: Column(
                children: topPerformers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final performer = entry.value;
                  return Column(
                    children: [
                      if (index > 0)
                        Divider(color: AppColors.glassBorder, height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: index < 3
                                    ? AppColors.buttonGradient
                                    : null,
                                color: index >= 3 ? AppColors.glass : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
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
                                    performer['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${performer['deliveries']} deliveries',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  performer['rating'].toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            )
            .animate()
            .fadeIn(delay: 300.ms, duration: 300.ms)
            .slideY(begin: 0.1, end: 0, duration: 300.ms),
      ],
    );
  }
}
