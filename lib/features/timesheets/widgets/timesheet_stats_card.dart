import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../providers/timesheet_provider.dart';

class TimesheetStatsCard extends ConsumerWidget {
  const TimesheetStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(timesheetDashboardProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Zeitnachweis-Übersicht',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Summary
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Gesamt Stunden',
                    '${(dashboardData['totalHours'] ?? 0.0).toStringAsFixed(1)}h',
                    Symbols.schedule,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Gesamt Vergütung',
                    '€${(dashboardData['totalPay'] ?? 0.0).toStringAsFixed(0)}',
                    Symbols.euro,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status Breakdown
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Entwürfe',
                    '${dashboardData['draft'] ?? 0}',
                    Symbols.edit_note,
                    Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Eingereicht',
                    '${dashboardData['submitted'] ?? 0}',
                    Symbols.send,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Genehmigt',
                    '${dashboardData['approved'] ?? 0}',
                    Symbols.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}