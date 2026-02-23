import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/report_config.dart';
import '../../../models/employee.dart';
import '../../../providers/employee_provider.dart';
import '../../../providers/timesheet_provider.dart';
import '../../../providers/shift_provider.dart';

class ReportDashboard extends ConsumerWidget {
  final String selectedCategory;
  final DateTimeRange dateRange;
  final Function(ReportConfig) onReportSelected;

  const ReportDashboard({
    super.key,
    required this.selectedCategory,
    required this.dateRange,
    required this.onReportSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);
    final timesheetsAsync = ref.watch(timesheetsProvider);
    final shiftsAsync = ref.watch(shiftsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with KPIs
          Row(
            children: [
              Icon(
                Symbols.dashboard,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Analytics Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Chip(
                label: Text(
                  '${dateRange.start.day}.${dateRange.start.month}.${dateRange.start.year} - ${dateRange.end.day}.${dateRange.end.month}.${dateRange.end.year}',
                ),
                avatar: const Icon(Symbols.date_range, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // KPI Cards
          _buildKPISection(context, employeesAsync, timesheetsAsync, shiftsAsync),
          const SizedBox(height: 32),

          // Quick Reports
          _buildQuickReportsSection(context),
          const SizedBox(height: 32),

          // Chart Analytics
          _buildChartSection(context, timesheetsAsync),
          const SizedBox(height: 32),

          // Recent Activity
          _buildRecentActivitySection(context),
        ],
      ),
    );
  }

  Widget _buildKPISection(
    BuildContext context,
    AsyncValue employeesAsync,
    AsyncValue timesheetsAsync,
    AsyncValue shiftsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kennzahlen',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: employeesAsync.when(
                loading: () => _buildKPICard(context, 'Mitarbeiter', '...', Symbols.people, Colors.blue, isLoading: true),
                error: (_, __) => _buildKPICard(context, 'Mitarbeiter', 'Fehler', Symbols.people, Colors.blue),
                data: (employees) {
                  final activeEmployees = employees.where((e) => e.status == EmployeeStatus.active).length;
                  return _buildKPICard(context, 'Mitarbeiter', '$activeEmployees', Symbols.people, Colors.blue);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: timesheetsAsync.when(
                loading: () => _buildKPICard(context, 'Zeitnachweise', '...', Symbols.schedule, Colors.green, isLoading: true),
                error: (_, __) => _buildKPICard(context, 'Zeitnachweise', 'Fehler', Symbols.schedule, Colors.green),
                data: (timesheets) {
                  final filteredTimesheets = timesheets.where((t) =>
                    t.startDate.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
                    t.startDate.isBefore(dateRange.end.add(const Duration(days: 1)))
                  ).length;
                  return _buildKPICard(context, 'Zeitnachweise', '$filteredTimesheets', Symbols.schedule, Colors.green);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: shiftsAsync.when(
                loading: () => _buildKPICard(context, 'Schichten', '...', Symbols.work, Colors.orange, isLoading: true),
                error: (_, __) => _buildKPICard(context, 'Schichten', 'Fehler', Symbols.work, Colors.orange),
                data: (shifts) {
                  final filteredShifts = shifts.where((s) =>
                    s.startTime.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
                    s.startTime.isBefore(dateRange.end.add(const Duration(days: 1)))
                  ).length;
                  return _buildKPICard(context, 'Schichten', '$filteredShifts', Symbols.work, Colors.orange);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: timesheetsAsync.when(
                loading: () => _buildKPICard(context, 'Gesamtstunden', '...', Symbols.timer, Colors.purple, isLoading: true),
                error: (_, __) => _buildKPICard(context, 'Gesamtstunden', 'Fehler', Symbols.timer, Colors.purple),
                data: (timesheets) {
                  final filteredTimesheets = timesheets.where((t) =>
                    t.startDate.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
                    t.startDate.isBefore(dateRange.end.add(const Duration(days: 1)))
                  );
                  final totalHours = filteredTimesheets.fold(0.0, (sum, t) => sum + t.calculatedTotalHours);
                  return _buildKPICard(context, 'Gesamtstunden', '${totalHours.toStringAsFixed(0)}h', Symbols.timer, Colors.purple);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isLoading = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReportsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Schnellberichte',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text('Alle anzeigen'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildQuickReportCard(
              context,
              'Zeiterfassung Übersicht',
              'Monatlicher Zeitnachweis',
              Symbols.schedule,
              Colors.blue,
              () => _generateQuickReport('timesheet'),
            ),
            _buildQuickReportCard(
              context,
              'Mitarbeiter Analytics',
              'Leistungsanalyse',
              Symbols.people,
              Colors.green,
              () => _generateQuickReport('employee'),
            ),
            _buildQuickReportCard(
              context,
              'Schichtplanung',
              'Wöchentlicher Report',
              Symbols.calendar_view_week,
              Colors.orange,
              () => _generateQuickReport('shifts'),
            ),
            _buildQuickReportCard(
              context,
              'Kapazitätsanalyse',
              'Team-Auslastung',
              Symbols.analytics,
              Colors.purple,
              () => _generateQuickReport('capacity'),
            ),
            _buildQuickReportCard(
              context,
              'Anwesenheit',
              'Präsenzstatistik',
              Symbols.fact_check,
              Colors.teal,
              () => _generateQuickReport('attendance'),
            ),
            _buildQuickReportCard(
              context,
              'Überstunden',
              'Mehrarbeitsanalyse',
              Symbols.trending_up,
              Colors.red,
              () => _generateQuickReport('overtime'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickReportCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  Icon(
                    Symbols.arrow_outward,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, AsyncValue timesheetsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trends & Analytics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTimelineChart(context, timesheetsAsync),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatusDistribution(context, timesheetsAsync),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineChart(BuildContext context, AsyncValue timesheetsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.trending_up,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Arbeitsstunden Trend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Symbols.insert_chart,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Zeitlinien-Chart - Daten werden im Hauptdiagramm oben angezeigt',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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

  Widget _buildStatusDistribution(BuildContext context, AsyncValue timesheetsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.pie_chart,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status Verteilung',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              error: (error, stack) => const Center(
                child: Text('Fehler beim Laden'),
              ),
              data: (timesheets) {
                final filteredTimesheets = timesheets.where((t) =>
                  t.startDate.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
                  t.startDate.isBefore(dateRange.end.add(const Duration(days: 1)))
                ).toList();

                final statusCounts = <String, int>{};
                for (final timesheet in filteredTimesheets) {
                  final status = timesheet.status.toString().split('.').last;
                  statusCounts[status] = (statusCounts[status] ?? 0) + 1;
                }

                return Column(
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Symbols.donut_small,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...statusCounts.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(entry.key),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getStatusLabel(entry.key),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Text(
                            '${entry.value}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kürzlich generierte Berichte',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _buildActivityItem(
                context,
                'Zeiterfassung Januar',
                'vor 2 Stunden',
                Symbols.schedule,
                Colors.blue,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                context,
                'Kapazitätsanalyse Q4',
                'gestern',
                Symbols.analytics,
                Colors.purple,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                context,
                'Mitarbeiter Report',
                'vor 3 Tagen',
                Symbols.people,
                Colors.green,
              ),
              const Divider(height: 1),
              TextButton(
                onPressed: () {},
                child: const Text('Alle anzeigen'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(time),
      trailing: const Icon(Symbols.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'submitted':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'finalized':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Entwurf';
      case 'submitted':
        return 'Eingereicht';
      case 'approved':
        return 'Genehmigt';
      case 'rejected':
        return 'Abgelehnt';
      case 'finalized':
        return 'Abgeschlossen';
      default:
        return status;
    }
  }

  void _generateQuickReport(String type) {
    final typeMap = {
      'overtime': ReportType.timesheet,
      'attendance': ReportType.attendance,
      'vacation': ReportType.vacation,
      'cost': ReportType.payroll,
    };
    final labels = {
      'overtime': 'Überstunden-Report',
      'attendance': 'Anwesenheits-Report',
      'vacation': 'Urlaubs-Report',
      'cost': 'Kosten-Report',
    };
    final config = ReportConfig(
      id: 'quick_${type}_${DateTime.now().millisecondsSinceEpoch}',
      name: labels[type] ?? type,
      description: 'Schnellbericht: ${labels[type] ?? type}',
      type: typeMap[type] ?? ReportType.overview,
      format: ReportFormat.pdf,
      period: ReportPeriod.monthly,
      startDate: dateRange.start,
      endDate: dateRange.end,
      createdAt: DateTime.now(),
    );
    onReportSelected(config);
  }
}