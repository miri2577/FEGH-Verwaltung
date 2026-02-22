import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../providers/capacity_provider.dart';
import '../../../models/capacity_analytics.dart';

class CapacityOverviewCard extends ConsumerWidget {
  const CapacityOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(capacityDashboardProvider);

    return dashboardAsync.when(
      data: (dashboard) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Symbols.analytics,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Kapazitäts-Übersicht',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusIndicator(context, dashboard),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Gesamtkapazität',
                      '${dashboard['overallCapacity'].toStringAsFixed(1)}%',
                      Symbols.speed,
                      _getCapacityColor(dashboard['overallCapacity']),
                      subtitle: 'Durchschnittliche Auslastung',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Aktive Mitarbeiter',
                      '${dashboard['activeEmployees']}',
                      Symbols.group,
                      Theme.of(context).colorScheme.primary,
                      subtitle: 'von ${dashboard['totalEmployees']} Gesamt',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Teams Status',
                      '${dashboard['optimalTeams']}/${dashboard['totalTeams']}',
                      Symbols.corporate_fare,
                      dashboard['criticalTeams'] == 0 ? Colors.green : Colors.red,
                      subtitle: 'optimal besetzt',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusBreakdown(context, dashboard),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildTrendIndicator(context, dashboard),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Symbols.error,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                'Fehler beim Laden der Übersicht',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, Map<String, dynamic> dashboard) {
    final warningLevel = dashboard['warningLevel'] as String;
    final color = _getWarningLevelColor(warningLevel);
    final icon = _getWarningLevelIcon(warningLevel);
    final label = _getWarningLevelLabel(warningLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown(BuildContext context, Map<String, dynamic> dashboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team-Status Verteilung',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatusItem(
          context,
          'Optimal',
          dashboard['optimalTeams'],
          Colors.green,
          Symbols.check_circle,
        ),
        const SizedBox(height: 8),
        _buildStatusItem(
          context,
          'Unterbesetzt',
          dashboard['understaffedTeams'],
          Colors.orange,
          Symbols.warning,
        ),
        const SizedBox(height: 8),
        _buildStatusItem(
          context,
          'Kritisch',
          dashboard['criticalTeams'],
          Colors.red,
          Symbols.error,
        ),
        const SizedBox(height: 8),
        _buildStatusItem(
          context,
          'Überbesetzt',
          dashboard['overstaffedTeams'],
          Colors.blue,
          Symbols.trending_up,
        ),
      ],
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendIndicator(BuildContext context, Map<String, dynamic> dashboard) {
    final forecastTrend = dashboard['forecastTrend'] as String;
    final nextWeekCapacity = dashboard['nextWeekCapacity'] as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prognose-Trend',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getTrendIcon(forecastTrend),
                    size: 16,
                    color: _getTrendColor(forecastTrend),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getTrendLabel(forecastTrend),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _getTrendColor(forecastTrend),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Nächste Woche: ${nextWeekCapacity.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getCapacityColor(double capacity) {
    if (capacity < 60) return Colors.red;
    if (capacity < 80) return Colors.orange;
    if (capacity > 110) return Colors.blue;
    return Colors.green;
  }

  Color _getWarningLevelColor(String level) {
    switch (level) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData _getWarningLevelIcon(String level) {
    switch (level) {
      case 'critical':
        return Symbols.error;
      case 'warning':
        return Symbols.warning;
      default:
        return Symbols.check_circle;
    }
  }

  String _getWarningLevelLabel(String level) {
    switch (level) {
      case 'critical':
        return 'Kritisch';
      case 'warning':
        return 'Warnung';
      default:
        return 'Normal';
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'improving':
        return Symbols.trending_up;
      case 'declining':
        return Symbols.trending_down;
      default:
        return Symbols.trending_flat;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'improving':
        return Colors.green;
      case 'declining':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTrendLabel(String trend) {
    switch (trend) {
      case 'improving':
        return 'Verbesserung';
      case 'declining':
        return 'Verschlechterung';
      default:
        return 'Stabil';
    }
  }
}