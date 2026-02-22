import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../providers/capacity_provider.dart';
import '../../../models/capacity_analytics.dart';

class CapacityForecastChart extends ConsumerWidget {
  const CapacityForecastChart({super.key});

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

  Widget _buildForecastChart(BuildContext context, List<CapacityForecast> forecasts) {
    final maxCapacity = forecasts.map((f) => f.predictedCapacity).reduce((a, b) => a > b ? a : b);
    final minCapacity = forecasts.map((f) => f.predictedCapacity).reduce((a, b) => a < b ? a : b);
    final range = maxCapacity - minCapacity;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: CustomPaint(
            painter: ForecastChartPainter(
              forecasts: forecasts,
              minCapacity: minCapacity,
              maxCapacity: maxCapacity,
              theme: Theme.of(context),
            ),
            size: const Size(double.infinity, 200),
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

class ForecastChartPainter extends CustomPainter {
  final List<CapacityForecast> forecasts;
  final double minCapacity;
  final double maxCapacity;
  final ThemeData theme;

  ForecastChartPainter({
    required this.forecasts,
    required this.minCapacity,
    required this.maxCapacity,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = <Offset>[];

    // Calculate points
    for (int i = 0; i < forecasts.length; i++) {
      final x = (i / (forecasts.length - 1)) * size.width;
      final normalizedY = (forecasts[i].predictedCapacity - minCapacity) / (maxCapacity - minCapacity);
      final y = size.height - (normalizedY * size.height);
      points.add(Offset(x, y));
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = theme.colorScheme.outline.withOpacity(0.2)
      ..strokeWidth = 1;

    // Horizontal grid lines (capacity levels)
    for (int i = 0; i <= 5; i++) {
      final y = (i / 5) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical grid lines (days)
    for (int i = 0; i < forecasts.length; i++) {
      final x = (i / (forecasts.length - 1)) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw capacity zones
    _drawCapacityZones(canvas, size);

    // Draw forecast line
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      paint.color = theme.colorScheme.primary;
      canvas.drawPath(path, paint);

      // Draw points
      for (final point in points) {
        canvas.drawCircle(point, 4, Paint()..color = theme.colorScheme.primary);
      }
    }
  }

  void _drawCapacityZones(Canvas canvas, Size size) {
    final zonePaint = Paint()..style = PaintingStyle.fill;

    // Critical zone (< 60%)
    final criticalHeight = _getYForCapacity(60, size);
    zonePaint.color = Colors.red.withOpacity(0.1);
    canvas.drawRect(
      Rect.fromLTWH(0, criticalHeight, size.width, size.height - criticalHeight),
      zonePaint,
    );

    // Warning zone (60-80%)
    final warningHeight = _getYForCapacity(80, size);
    zonePaint.color = Colors.orange.withOpacity(0.1);
    canvas.drawRect(
      Rect.fromLTWH(0, warningHeight, size.width, criticalHeight - warningHeight),
      zonePaint,
    );

    // Optimal zone (80-100%)
    final optimalHeight = _getYForCapacity(100, size);
    zonePaint.color = Colors.green.withOpacity(0.1);
    canvas.drawRect(
      Rect.fromLTWH(0, optimalHeight, size.width, warningHeight - optimalHeight),
      zonePaint,
    );
  }

  double _getYForCapacity(double capacity, Size size) {
    final normalizedY = (capacity - minCapacity) / (maxCapacity - minCapacity);
    return size.height - (normalizedY * size.height);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}