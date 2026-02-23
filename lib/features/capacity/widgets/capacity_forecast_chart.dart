import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../providers/capacity_provider.dart';
import '../../../models/capacity_analytics.dart';

class CapacityForecastChart extends ConsumerWidget {
  const CapacityForecastChart({super.key});

  static const _dayNames = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastsAsync = ref.watch(capacityForecastsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kapazitäts-Prognose (7 Tage)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showForecastDetails(context, ref),
                  icon: const Icon(Symbols.info),
                  tooltip: 'Prognose-Details',
                ),
              ],
            ),
            const SizedBox(height: 16),
            forecastsAsync.when(
              data: (forecasts) => forecasts.isEmpty
                  ? _buildEmptyState(context)
                  : _buildForecastChart(context, forecasts),
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => _buildErrorState(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.timeline,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'Keine Prognosedaten verfügbar',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.error,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              'Fehler beim Laden der Prognose',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _getDayLabel(DateTime date) {
    // DateTime.weekday: 1 = Monday, 7 = Sunday
    return _dayNames[date.weekday - 1];
  }

  Widget _buildForecastChart(BuildContext context, List<CapacityForecast> forecasts) {
    final tooltipBehavior = TooltipBehavior(
      enable: true,
      format: 'point.x: point.y%',
    );

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: SfCartesianChart(
            tooltipBehavior: tooltipBehavior,
            primaryXAxis: CategoryAxis(
              majorGridLines: const MajorGridLines(width: 0.5, dashArray: [3, 3]),
            ),
            primaryYAxis: NumericAxis(
              minimum: 0,
              maximum: 150,
              interval: 30,
              axisLine: const AxisLine(width: 0),
              majorGridLines: const MajorGridLines(width: 0.5, dashArray: [3, 3]),
              plotBands: <PlotBand>[
                PlotBand(
                  start: 0,
                  end: 60,
                  color: Colors.red.withOpacity(0.1),
                ),
                PlotBand(
                  start: 60,
                  end: 80,
                  color: Colors.orange.withOpacity(0.1),
                ),
                PlotBand(
                  start: 80,
                  end: 100,
                  color: Colors.green.withOpacity(0.1),
                ),
                PlotBand(
                  start: 100,
                  end: 150,
                  color: Colors.blue.withOpacity(0.1),
                ),
              ],
            ),
            series: <CartesianSeries<CapacityForecast, String>>[
              SplineAreaSeries<CapacityForecast, String>(
                dataSource: forecasts,
                xValueMapper: (CapacityForecast f, _) => _getDayLabel(f.date),
                yValueMapper: (CapacityForecast f, _) => f.predictedCapacity,
                color: Theme.of(context).colorScheme.primary,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ],
                ),
                borderColor: Theme.of(context).colorScheme.primary,
                borderWidth: 2,
                markerSettings: const MarkerSettings(
                  isVisible: true,
                  height: 6,
                  width: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildForecastLegend(context, forecasts),
        const SizedBox(height: 16),
        _buildForecastSummary(context, forecasts),
      ],
    );
  }

  Widget _buildForecastLegend(BuildContext context, List<CapacityForecast> forecasts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(context, 'Optimal (80-100%)', Colors.green),
        _buildLegendItem(context, 'Warnung (60-80%)', Colors.orange),
        _buildLegendItem(context, 'Kritisch (<60%)', Colors.red),
        _buildLegendItem(context, 'Überbesetzt (>100%)', Colors.blue),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildForecastSummary(BuildContext context, List<CapacityForecast> forecasts) {
    final avgCapacity = forecasts.map((f) => f.predictedCapacity).reduce((a, b) => a + b) / forecasts.length;
    final trend = _calculateTrend(forecasts);
    final riskyDays = forecasts.where((f) => f.predictedCapacity < 80).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              context,
              'Durchschnitt',
              '${avgCapacity.toStringAsFixed(1)}%',
              Symbols.analytics,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              context,
              'Trend',
              trend,
              _getTrendIcon(trend),
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              context,
              'Risiko-Tage',
              '$riskyDays/7',
              Symbols.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _calculateTrend(List<CapacityForecast> forecasts) {
    if (forecasts.length < 2) return 'Stabil';
    final first = forecasts.first.predictedCapacity;
    final last = forecasts.last.predictedCapacity;
    final diff = last - first;

    if (diff > 5) return 'Steigend';
    if (diff < -5) return 'Fallend';
    return 'Stabil';
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'Steigend':
        return Symbols.trending_up;
      case 'Fallend':
        return Symbols.trending_down;
      default:
        return Symbols.trending_flat;
    }
  }

  void _showForecastDetails(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prognose-Details'),
        content: const Text(
          'Diese Prognose basiert auf historischen Daten, aktuellen Trends und '
          'geplanten Veränderungen. Sie wird täglich aktualisiert und berücksichtigt '
          'saisonale Schwankungen sowie bekannte Ereignisse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}
