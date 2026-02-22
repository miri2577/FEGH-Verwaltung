import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/timesheet.dart';
import '../../../models/employee.dart';
import '../../../providers/timesheet_provider.dart';

class EmployeeStatsCard extends ConsumerWidget {
  final Employee employee;

  const EmployeeStatsCard({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesheetsAsync = ref.watch(timesheetsByEmployeeProvider(employee.id));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.analytics,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Arbeitszeit-Statistiken',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            timesheetsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Symbols.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Fehler beim Laden der Statistiken: $error'),
                    ],
                  ),
                ),
              ),
              data: (timesheets) => _buildStatistics(context, timesheets),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, List timesheets) {
    final totalHours = timesheets.fold(0.0, (sum, timesheet) => sum + timesheet.calculatedTotalHours);
    final totalPay = timesheets.fold(0.0, (sum, timesheet) => sum + timesheet.calculatedTotalPay);
    final overtimeHours = timesheets.fold(0.0, (sum, timesheet) => sum + timesheet.calculatedOvertimeHours);
    final averageHoursPerWeek = timesheets.isNotEmpty ? totalHours / timesheets.length : 0.0;

    return Column(
      children: [
        // Main Statistics Grid
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                context,
                'Gesamtstunden',
                '${totalHours.toStringAsFixed(1)}h',
                'Alle Zeitnachweise',
                Symbols.schedule,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatTile(
                context,
                'Gesamtvergütung',
                '${totalPay.toStringAsFixed(0)} €',
                'Brutto-Verdienst',
                Symbols.euro,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                context,
                'Überstunden',
                '${overtimeHours.toStringAsFixed(1)}h',
                'Zusätzliche Arbeitszeit',
                Symbols.trending_up,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatTile(
                context,
                'Ø Wochenstunden',
                '${averageHoursPerWeek.toStringAsFixed(1)}h',
                'Durchschnitt pro Woche',
                Symbols.analytics,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Performance Indicators
        _buildPerformanceSection(context, timesheets),

        const SizedBox(height: 24),

        // Recent Activity
        _buildRecentActivitySection(context, timesheets),
      ],
    );
  }

  Widget _buildStatTile(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
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
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(BuildContext context, List timesheets) {
    final approvedCount = timesheets.where((t) => t.status == TimesheetStatus.approved).length;
    final rejectedCount = timesheets.where((t) => t.status == TimesheetStatus.rejected).length;
    final pendingCount = timesheets.where((t) => t.status == TimesheetStatus.submitted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status-Übersicht',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusIndicator(
                context,
                'Genehmigt',
                approvedCount,
                Colors.green,
                Symbols.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusIndicator(
                context,
                'Ausstehend',
                pendingCount,
                Colors.orange,
                Symbols.pending,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusIndicator(
                context,
                'Abgelehnt',
                rejectedCount,
                Colors.red,
                Symbols.cancel,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, List timesheets) {
    final recentTimesheets = timesheets.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Letzte Aktivitäten',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (recentTimesheets.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Symbols.schedule,
                  size: 40,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Noch keine Zeitnachweise vorhanden',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ...recentTimesheets.map((timesheet) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildActivityItem(context, timesheet),
          )),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, dynamic timesheet) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getTimesheetStatusIcon(timesheet.status.toString().split('.').last),
            size: 20,
            color: _getTimesheetStatusColor(context, timesheet.status.toString().split('.').last),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zeitnachweis ${_formatDateRange(timesheet.startDate, timesheet.endDate)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${timesheet.calculatedTotalHours.toStringAsFixed(1)}h • ${timesheet.statusLabel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTimesheetStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return Symbols.edit_note;
      case 'submitted':
        return Symbols.send;
      case 'approved':
        return Symbols.check_circle;
      case 'rejected':
        return Symbols.cancel;
      case 'finalized':
        return Symbols.lock;
      default:
        return Symbols.schedule;
    }
  }

  Color _getTimesheetStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'draft':
        return Theme.of(context).colorScheme.outline;
      case 'submitted':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Theme.of(context).colorScheme.error;
      case 'finalized':
        return Colors.blue;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    return '${start.day}.${start.month} - ${end.day}.${end.month}.${end.year}';
  }
}