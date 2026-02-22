import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/timesheet.dart';
import '../../providers/timesheet_provider.dart';
import '../../providers/employee_provider.dart';
import 'widgets/timesheet_card.dart';
import 'widgets/timesheet_form_dialog.dart';
import 'widgets/timesheet_stats_card.dart';

class TimesheetsScreen extends ConsumerStatefulWidget {
  const TimesheetsScreen({super.key});

  @override
  ConsumerState<TimesheetsScreen> createState() => _TimesheetsScreenState();
}

class _TimesheetsScreenState extends ConsumerState<TimesheetsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timesheetsAsyncValue = ref.watch(timesheetsProvider);
    final timesheetCount = ref.watch(timesheetCountProvider);
    final pendingCount = ref.watch(pendingTimesheetsCountProvider);
    final draftCount = ref.watch(draftTimesheetsCountProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.assignment,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  'Arbeitszeitnachweise',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$timesheetCount Zeitnachweise',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$pendingCount Ausstehend',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _refreshTimesheets(ref),
                  icon: const Icon(Symbols.refresh, size: 18),
                  label: const Text('Aktualisieren'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _showAddTimesheetDialog(),
                  icon: const Icon(Symbols.add, size: 18),
                  label: const Text('Neuer Zeitnachweis'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Stats Row
            Row(
              children: [
                Expanded(child: TimesheetStatsCard()),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Symbols.pending_actions,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ausstehende Genehmigungen',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$pendingCount',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Zeitnachweise warten auf Genehmigung',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Alle'),
                Tab(text: 'Entwürfe'),
                Tab(text: 'Eingereicht'),
                Tab(text: 'Genehmigt'),
                Tab(text: 'Diese Woche'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllTimesheets(timesheetsAsyncValue),
                  _buildTimesheetsByStatus(TimesheetStatus.draft),
                  _buildTimesheetsByStatus(TimesheetStatus.submitted),
                  _buildTimesheetsByStatus(TimesheetStatus.approved),
                  _buildCurrentWeekTimesheets(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTimesheets(AsyncValue<List<Timesheet>> timesheetsAsyncValue) {
    return timesheetsAsyncValue.when(
      data: (timesheets) => timesheets.isEmpty
          ? _buildEmptyState('Keine Zeitnachweise vorhanden', 'Erstellen Sie den ersten Zeitnachweis, um zu beginnen.')
          : _buildTimesheetsList(timesheets),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildTimesheetsByStatus(TimesheetStatus status) {
    return Consumer(
      builder: (context, ref, child) {
        final timesheetsAsync = ref.watch(timesheetsByStatusProvider(status));
        return timesheetsAsync.when(
          data: (timesheets) => timesheets.isEmpty
              ? _buildEmptyState(
                  'Keine ${_getStatusLabel(status).toLowerCase()} Zeitnachweise',
                  'Es sind keine Zeitnachweise mit dem Status "${_getStatusLabel(status)}" vorhanden.'
                )
              : _buildTimesheetsList(timesheets),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error),
        );
      },
    );
  }

  Widget _buildCurrentWeekTimesheets() {
    return Consumer(
      builder: (context, ref, child) {
        final currentWeekAsync = ref.watch(currentWeekTimesheetsProvider);
        return currentWeekAsync.when(
          data: (timesheets) => timesheets.isEmpty
              ? _buildEmptyState('Keine Zeitnachweise diese Woche', 'Für diese Woche sind noch keine Zeitnachweise erstellt.')
              : _buildTimesheetsList(timesheets),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error),
        );
      },
    );
  }

  Widget _buildTimesheetsList(List<Timesheet> timesheets) {
    // Sort timesheets by creation date (newest first)
    final sortedTimesheets = List<Timesheet>.from(timesheets)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: sortedTimesheets.length,
      itemBuilder: (context, index) {
        final timesheet = sortedTimesheets[index];
        return TimesheetCard(
          timesheet: timesheet,
          onTap: () => _showTimesheetDetails(timesheet),
          onEdit: () => _showEditTimesheetDialog(timesheet),
          onDelete: () => _showDeleteConfirmation(timesheet),
          onSubmit: () => _submitTimesheet(timesheet.id),
          onApprove: () => _approveTimesheet(timesheet.id),
          onReject: () => _showRejectDialog(timesheet),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.assignment,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.error,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Fehler beim Laden der Zeitnachweise',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _refreshTimesheets(ref),
            icon: const Icon(Symbols.refresh, size: 18),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  void _refreshTimesheets(WidgetRef ref) {
    ref.read(timesheetsProvider.notifier).refresh();
  }

  void _showAddTimesheetDialog() {
    showDialog(
      context: context,
      builder: (context) => TimesheetFormDialog(
        onSave: (timesheet) async {
          await ref.read(timesheetsProvider.notifier).addTimesheet(timesheet);
        },
      ),
    );
  }

  void _showEditTimesheetDialog(Timesheet timesheet) {
    showDialog(
      context: context,
      builder: (context) => TimesheetFormDialog(
        timesheet: timesheet,
        onSave: (updatedTimesheet) async {
          await ref.read(timesheetsProvider.notifier).updateTimesheet(updatedTimesheet);
        },
      ),
    );
  }

  void _showTimesheetDetails(Timesheet timesheet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Zeitnachweis Details'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mitarbeiter ID: ${timesheet.employeeId}'),
              Text('Zeitraum: ${timesheet.startDate.toLocal().toString().split(' ')[0]} - ${timesheet.endDate.toLocal().toString().split(' ')[0]}'),
              Text('Status: ${timesheet.statusLabel}'),
              Text('Gesamt Stunden: ${timesheet.calculatedTotalHours.toStringAsFixed(1)}h'),
              Text('Reguläre Stunden: ${timesheet.calculatedRegularHours.toStringAsFixed(1)}h'),
              Text('Überstunden: ${timesheet.calculatedOvertimeHours.toStringAsFixed(1)}h'),
              Text('Gesamt Vergütung: €${timesheet.calculatedTotalPay.toStringAsFixed(2)}'),
              Text('Einträge: ${timesheet.entries.length}'),
              if (timesheet.submittedAt != null)
                Text('Eingereicht am: ${timesheet.submittedAt!.toLocal()}'),
              if (timesheet.approvedAt != null)
                Text('Genehmigt am: ${timesheet.approvedAt!.toLocal()}'),
              if (timesheet.rejectionReason != null)
                Text('Ablehnungsgrund: ${timesheet.rejectionReason}'),
              if (timesheet.notes != null)
                Text('Notizen: ${timesheet.notes}'),
            ],
          ),
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

  void _showDeleteConfirmation(Timesheet timesheet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zeitnachweis löschen'),
        content: Text('Möchten Sie diesen Zeitnachweis wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(timesheetsProvider.notifier).deleteTimesheet(timesheet.id);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _submitTimesheet(String timesheetId) async {
    await ref.read(timesheetsProvider.notifier).submitTimesheet(timesheetId, 'system');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zeitnachweis eingereicht'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _approveTimesheet(String timesheetId) async {
    await ref.read(timesheetsProvider.notifier).approveTimesheet(timesheetId, 'system');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zeitnachweis genehmigt'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showRejectDialog(Timesheet timesheet) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zeitnachweis ablehnen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Geben Sie einen Grund für die Ablehnung an:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Ablehnungsgrund',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(timesheetsProvider.notifier).rejectTimesheet(
                timesheet.id,
                reasonController.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Zeitnachweis abgelehnt'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Ablehnen'),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(TimesheetStatus status) {
    switch (status) {
      case TimesheetStatus.draft:
        return 'Entwürfe';
      case TimesheetStatus.submitted:
        return 'Eingereichte';
      case TimesheetStatus.approved:
        return 'Genehmigte';
      case TimesheetStatus.rejected:
        return 'Abgelehnte';
      case TimesheetStatus.finalized:
        return 'Abgeschlossene';
    }
  }
}