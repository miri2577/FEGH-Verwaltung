import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/reports_provider.dart';

class ReportAnalyticsSummary extends ConsumerStatefulWidget {
  const ReportAnalyticsSummary({super.key});

  @override
  ConsumerState<ReportAnalyticsSummary> createState() => _ReportAnalyticsSummaryState();
}

class _ReportAnalyticsSummaryState extends ConsumerState<ReportAnalyticsSummary>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: _buildContent(),
        );
      },
    );
  }

  Widget _buildContent() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Symbols.analytics,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Analytics',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Detaillierte Einblicke in Ihre Berichtserstellung',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Symbols.refresh),
                  onPressed: _refreshAnalytics,
                  tooltip: 'Analytics aktualisieren',
                ),
              ],
            ),
            const SizedBox(height: 32),
            FutureBuilder<Map<String, dynamic>>(
              future: ref.read(reportsServiceProvider).getReportAnalytics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                } else if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                } else if (snapshot.hasData) {
                  return _buildAnalyticsContent(snapshot.data!);
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Symbols.error,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden der Analytics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(Map<String, dynamic> analytics) {
    return Column(
      children: [
        // Summary Statistics Row
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Reports', analytics['totalReports'].toString(), Symbols.assessment, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Diesen Monat', analytics['reportsThisMonth'].toString(), Symbols.calendar_month, Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Beliebteste Vorlage', analytics['mostUsedTemplate'], Symbols.star, Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Ø Generierungszeit', analytics['averageGenerationTime'], Symbols.speed, Colors.purple)),
          ],
        ),
        const SizedBox(height: 32),

        // Charts Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format Distribution Pie Chart
            Expanded(
              flex: 1,
              child: _buildFormatDistributionChart(analytics['popularFormats']),
            ),
            const SizedBox(width: 24),

            // Monthly Trend Line Chart
            Expanded(
              flex: 2,
              child: _buildMonthlyTrendChart(analytics['monthlyTrend']),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Symbols.trending_up, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatDistributionChart(Map<String, dynamic> formatData) {
    final List<PieChartSectionData> sections = formatData.entries.map((entry) {
      final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
      final colorIndex = formatData.keys.toList().indexOf(entry.key) % colors.length;

      return PieChartSectionData(
        color: colors[colorIndex],
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: 100,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Format-Verteilung',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendChart(List<dynamic> trendData) {
    final spots = trendData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['count'].toDouble());
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monatlicher Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < trendData.length) {
                            return Text(
                              trendData[value.toInt()]['month'],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshAnalytics() {
    setState(() {
      _animationController.reset();
      _animationController.forward();
    });
  }
}