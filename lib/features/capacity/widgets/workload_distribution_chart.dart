import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../providers/capacity_provider.dart';
import '../../../models/capacity_analytics.dart';

class WorkloadDistributionChart extends ConsumerWidget {
  const WorkloadDistributionChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributionAsync = ref.watch(workloadDistributionProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.donut_small,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Arbeitsbelastung-Verteilung',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showDistributionDetails(context),
                  icon: const Icon(Symbols.info),
                  tooltip: 'Verteilungs-Details',
                ),
              ],
            ),
            const SizedBox(height: 16),
            distributionAsync.when(
              data: (distribution) => _buildDistributionChart(context, distribution),
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

  Widget _buildDistributionChart(BuildContext context, Map<WorkloadType, double> distribution) {
    final totalPercentage = distribution.values.fold(0.0, (sum, value) => sum + value);

    if (totalPercentage == 0) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: SfCircularChart(
            legend: const Legend(
              isVisible: true,
              position: LegendPosition.bottom,
              overflowMode: LegendItemOverflowMode.wrap,
            ),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <CircularSeries>[
              DoughnutSeries<MapEntry<WorkloadType, double>, String>(
                dataSource: distribution.entries.toList(),
                xValueMapper: (entry, _) => _getWorkloadTypeLabel(entry.key),
                yValueMapper: (entry, _) => entry.value,
                pointColorMapper: (entry, _) => _getWorkloadTypeColor(entry.key),
                innerRadius: '50%',
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                  labelPosition: ChartDataLabelPosition.outside,
                ),
                dataLabelMapper: (entry, _) => '${entry.value.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildDistributionStats(context, distribution),
      ],
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
              Symbols.donut_small,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'Keine Arbeitsbelastungsdaten',
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
              'Fehler beim Laden der Verteilung',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionStats(BuildContext context, Map<WorkloadType, double> distribution) {
    final regularWork = distribution[WorkloadType.regular] ?? 0.0;
    final overtime = distribution[WorkloadType.overtime] ?? 0.0;
    final healthIndex = _calculateHealthIndex(distribution);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              'Reguläre Arbeit',
              '${regularWork.toStringAsFixed(1)}%',
              Symbols.schedule,
              regularWork >= 70 ? Colors.green : Colors.orange,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              'Überstunden',
              '${overtime.toStringAsFixed(1)}%',
              Symbols.timer,
              overtime <= 15 ? Colors.green : Colors.red,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              'Gesundheitsindex',
              _getHealthLabel(healthIndex),
              Symbols.health_and_safety,
              _getHealthColor(healthIndex),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  double _calculateHealthIndex(Map<WorkloadType, double> distribution) {
    final regular = distribution[WorkloadType.regular] ?? 0.0;
    final overtime = distribution[WorkloadType.overtime] ?? 0.0;
    final sick = distribution[WorkloadType.sick] ?? 0.0;
    final vacation = distribution[WorkloadType.vacation] ?? 0.0;

    // Ideal: 80% regular, 10% overtime, 5% vacation, 5% sick/training
    double score = 100.0;
    score -= (overtime > 15 ? (overtime - 15) * 2 : 0); // Penalty for high overtime
    score -= (sick > 10 ? (sick - 10) * 3 : 0); // Penalty for high sick leave
    score += (vacation >= 5 && vacation <= 15 ? 10 : 0); // Bonus for healthy vacation rate

    return score.clamp(0, 100);
  }

  String _getHealthLabel(double healthIndex) {
    if (healthIndex >= 80) return 'Gut';
    if (healthIndex >= 60) return 'Mittel';
    return 'Schlecht';
  }

  Color _getHealthColor(double healthIndex) {
    if (healthIndex >= 80) return Colors.green;
    if (healthIndex >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getWorkloadTypeColor(WorkloadType type) {
    switch (type) {
      case WorkloadType.regular:
        return Colors.blue;
      case WorkloadType.overtime:
        return Colors.red;
      case WorkloadType.vacation:
        return Colors.green;
      case WorkloadType.sick:
        return Colors.orange;
      case WorkloadType.training:
        return Colors.purple;
    }
  }

  String _getWorkloadTypeLabel(WorkloadType type) {
    switch (type) {
      case WorkloadType.regular:
        return 'Regulär';
      case WorkloadType.overtime:
        return 'Überstunden';
      case WorkloadType.vacation:
        return 'Urlaub';
      case WorkloadType.sick:
        return 'Krankheit';
      case WorkloadType.training:
        return 'Schulung';
    }
  }

  void _showDistributionDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arbeitsbelastung-Details'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diese Verteilung zeigt die prozentuale Aufteilung der verschiedenen '
              'Arbeitstypen basierend auf den aktuellen Schichten und Zeitmeldungen.',
            ),
            SizedBox(height: 16),
            Text(
              'Optimale Werte:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Reguläre Arbeit: 70-85%'),
            Text('• Überstunden: <15%'),
            Text('• Urlaub: 5-15%'),
            Text('• Krankheit: <10%'),
            Text('• Schulungen: 5-10%'),
          ],
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
