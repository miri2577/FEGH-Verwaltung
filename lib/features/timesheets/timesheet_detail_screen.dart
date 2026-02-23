import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/timesheet.dart';
import '../../models/employee.dart';
import '../../providers/timesheet_provider.dart';
import '../../providers/employee_provider.dart';
import 'widgets/timesheet_entry_form_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TimesheetDetailScreen extends ConsumerStatefulWidget {
  final String timesheetId;

  const TimesheetDetailScreen({
    super.key,
    required this.timesheetId,
  });

  @override
  ConsumerState<TimesheetDetailScreen> createState() => _TimesheetDetailScreenState();
}

class _TimesheetDetailScreenState extends ConsumerState<TimesheetDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timesheetAsync = ref.watch(timesheetByIdProvider(widget.timesheetId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zeitnachweis Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          timesheetAsync.when(
            data: (timesheet) => timesheet != null && timesheet.canBeEdited
                ? IconButton(
                    onPressed: () => _addTimesheetEntry(context, timesheet),
                    icon: const Icon(Symbols.add),
                    tooltip: 'Zeiteintrag hinzufügen',
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            onPressed: () => _exportTimesheet(context),
            icon: const Icon(Symbols.download),
            tooltip: 'Exportieren',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Symbols.schedule),
              text: 'Einträge',
            ),
            Tab(
              icon: Icon(Symbols.analytics),
              text: 'Übersicht',
            ),
            Tab(
              icon: Icon(Symbols.history),
              text: 'Verlauf',
            ),
          ],
        ),
      ),
      body: timesheetAsync.when(
        data: (timesheet) => timesheet != null
            ? TabBarView(
                controller: _tabController,
                children: [
                  _buildEntriesTab(timesheet),
                  _buildOverviewTab(timesheet),
                  _buildHistoryTab(timesheet),
                ],
              )
            : _buildNotFoundState(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildEntriesTab(Timesheet timesheet) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Arbeitszeit-Einträge',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (timesheet.canBeEdited)
                FilledButton.icon(
                  onPressed: () => _addTimesheetEntry(context, timesheet),
                  icon: const Icon(Symbols.add),
                  label: const Text('Eintrag hinzufügen'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (timesheet.entries.isEmpty)
            _buildEmptyEntriesState(timesheet)
          else
            Expanded(
              child: ListView.builder(
                itemCount: timesheet.entries.length,
                itemBuilder: (context, index) {
                  final entry = timesheet.entries[index];
                  return TimesheetEntryCard(
                    entry: entry,
                    timesheet: timesheet,
                    onEdit: timesheet.canBeEdited ? (entry) => _editTimesheetEntry(context, timesheet, entry) : null,
                    onDelete: timesheet.canBeEdited ? (entry) => _deleteTimesheetEntry(context, timesheet, entry) : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Timesheet timesheet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimesheetHeader(timesheet),
          const SizedBox(height: 16),
          _buildTimesheetSummary(timesheet),
          const SizedBox(height: 16),
          _buildTimesheetActions(timesheet),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(Timesheet timesheet) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statusverlauf',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusTimeline(timesheet),
        ],
      ),
    );
  }

  Widget _buildTimesheetHeader(Timesheet timesheet) {
    final employeesAsync = ref.watch(employeesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.assignment,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Zeitnachweis ${timesheet.id}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(timesheet.status),
              ],
            ),
            const SizedBox(height: 16),
            employeesAsync.when(
              data: (employees) {
                final employee = employees.firstWhere(
                  (e) => e.id == timesheet.employeeId,
                  orElse: () => Employee(
                    id: timesheet.employeeId,
                    employeeNumber: 'UNKNOWN',
                    firstName: 'Unbekannt',
                    lastName: '',
                    email: '',
                    dateOfBirth: DateTime.now(),
                    hireDate: DateTime.now(),
                    status: EmployeeStatus.active,
                    contractType: ContractType.fullTime,
                    hoursPerWeek: 40,
                    hourlyRate: 15.0,
                    position: '',
                    department: '',
                    address: Address(
                      street: '',
                      city: '',
                      postalCode: '',
                      country: 'Deutschland',
                    ),
                    qualifications: [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
                return Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Symbols.person,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text('Mitarbeiter: ${employee.fullName}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Symbols.date_range,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Zeitraum: ${timesheet.startDate.day}.${timesheet.startDate.month}.${timesheet.startDate.year} - ${timesheet.endDate.day}.${timesheet.endDate.month}.${timesheet.endDate.year}',
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Fehler beim Laden der Mitarbeiterdaten'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimesheetSummary(Timesheet timesheet) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zusammenfassung',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Gesamtstunden',
                    '${timesheet.calculatedTotalHours.toStringAsFixed(1)}h',
                    Symbols.schedule,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Reguläre Stunden',
                    '${timesheet.calculatedRegularHours.toStringAsFixed(1)}h',
                    Symbols.work,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Überstunden',
                    '${timesheet.calculatedOvertimeHours.toStringAsFixed(1)}h',
                    Symbols.trending_up,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Vergütung',
                    '€${timesheet.calculatedTotalPay.toStringAsFixed(2)}',
                    Symbols.euro,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildTimesheetActions(Timesheet timesheet) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktionen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (timesheet.canBeSubmitted)
                  FilledButton.icon(
                    onPressed: () => _submitTimesheet(timesheet),
                    icon: const Icon(Symbols.send),
                    label: const Text('Einreichen'),
                  ),
                if (timesheet.canBeApproved)
                  FilledButton.icon(
                    onPressed: () => _approveTimesheet(timesheet),
                    icon: const Icon(Symbols.check_circle),
                    label: const Text('Genehmigen'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  ),
                if (timesheet.canBeApproved)
                  OutlinedButton.icon(
                    onPressed: () => _rejectTimesheet(timesheet),
                    icon: const Icon(Symbols.cancel),
                    label: const Text('Ablehnen'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _exportTimesheet(context),
                  icon: const Icon(Symbols.download),
                  label: const Text('PDF Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(Timesheet timesheet) {
    final events = <Map<String, dynamic>>[];

    events.add({
      'title': 'Erstellt',
      'date': timesheet.createdAt,
      'icon': Symbols.add_circle,
      'color': Colors.blue,
    });

    if (timesheet.submittedAt != null) {
      events.add({
        'title': 'Eingereicht',
        'date': timesheet.submittedAt,
        'icon': Symbols.send,
        'color': Colors.orange,
        'by': timesheet.submittedBy,
      });
    }

    if (timesheet.approvedAt != null) {
      events.add({
        'title': 'Genehmigt',
        'date': timesheet.approvedAt,
        'icon': Symbols.check_circle,
        'color': Colors.green,
        'by': timesheet.approvedBy,
      });
    }

    if (timesheet.status == TimesheetStatus.rejected) {
      events.add({
        'title': 'Abgelehnt',
        'date': timesheet.updatedAt,
        'icon': Symbols.cancel,
        'color': Colors.red,
        'reason': timesheet.rejectionReason,
      });
    }

    return Column(
      children: events.map((event) => _buildTimelineItem(event)).toList(),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: event['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: event['color'], width: 2),
            ),
            child: Icon(
              event['icon'],
              color: event['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${event['date'].day}.${event['date'].month}.${event['date'].year} ${event['date'].hour}:${event['date'].minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (event['by'] != null)
                  Text(
                    'von ${event['by']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (event['reason'] != null)
                  Text(
                    'Grund: ${event['reason']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TimesheetStatus status) {
    Color color;
    switch (status) {
      case TimesheetStatus.draft:
        color = Colors.grey;
        break;
      case TimesheetStatus.submitted:
        color = Colors.orange;
        break;
      case TimesheetStatus.approved:
        color = Colors.green;
        break;
      case TimesheetStatus.rejected:
        color = Colors.red;
        break;
      case TimesheetStatus.finalized:
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getStatusLabel(TimesheetStatus status) {
    switch (status) {
      case TimesheetStatus.draft:
        return 'Entwurf';
      case TimesheetStatus.submitted:
        return 'Eingereicht';
      case TimesheetStatus.approved:
        return 'Genehmigt';
      case TimesheetStatus.rejected:
        return 'Abgelehnt';
      case TimesheetStatus.finalized:
        return 'Abgeschlossen';
    }
  }

  Widget _buildEmptyEntriesState(Timesheet timesheet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.schedule,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Zeiteinträge vorhanden',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Fügen Sie Ihren ersten Zeiteintrag hinzu',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (timesheet.canBeEdited) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _addTimesheetEntry(context, timesheet),
              icon: const Icon(Symbols.add),
              label: const Text('Ersten Eintrag hinzufügen'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
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
            'Zeitnachweis nicht gefunden',
            style: Theme.of(context).textTheme.titleMedium,
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
            'Fehler beim Laden',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _addTimesheetEntry(BuildContext context, Timesheet timesheet) {
    showDialog(
      context: context,
      builder: (context) => TimesheetEntryFormDialog(
        timesheetId: timesheet.id,
        onSave: (entry) async {
          await ref.read(timesheetEntriesProvider.notifier).addEntry(entry);
          if (this.context.mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(content: Text('Zeiteintrag hinzugefügt')),
            );
          }
        },
      ),
    );
  }

  void _editTimesheetEntry(BuildContext context, Timesheet timesheet, TimesheetEntry entry) {
    showDialog(
      context: context,
      builder: (context) => TimesheetEntryFormDialog(
        entry: entry,
        timesheetId: timesheet.id,
        onSave: (updatedEntry) async {
          await ref.read(timesheetEntriesProvider.notifier).updateEntry(updatedEntry);
          if (this.context.mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(content: Text('Zeiteintrag aktualisiert')),
            );
          }
        },
      ),
    );
  }

  void _deleteTimesheetEntry(BuildContext context, Timesheet timesheet, TimesheetEntry entry) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eintrag löschen'),
        content: const Text('Möchten Sie diesen Zeiteintrag wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(timesheetEntriesProvider.notifier).deleteEntry(entry.id);
              if (this.context.mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Zeiteintrag gelöscht')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _submitTimesheet(Timesheet timesheet) async {
    await ref.read(timesheetsProvider.notifier).submitTimesheet(timesheet.id, 'current_user');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zeitnachweis eingereicht'), backgroundColor: Colors.green),
      );
    }
  }

  void _approveTimesheet(Timesheet timesheet) async {
    await ref.read(timesheetsProvider.notifier).approveTimesheet(timesheet.id, 'current_user');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zeitnachweis genehmigt'), backgroundColor: Colors.green),
      );
    }
  }

  void _rejectTimesheet(Timesheet timesheet) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Zeitnachweis ablehnen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Grund für die Ablehnung:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Begründung eingeben...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop();
                await ref.read(timesheetsProvider.notifier).rejectTimesheet(
                  timesheet.id,
                  reasonController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zeitnachweis abgelehnt'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Ablehnen'),
          ),
        ],
      ),
    );
  }

  void _exportTimesheet(BuildContext context) async {
    final timesheet = ref.read(timesheetByIdProvider(widget.timesheetId)).valueOrNull;
    if (timesheet == null) return;

    final employees = ref.read(employeesProvider).valueOrNull ?? [];
    final employee = employees.where((e) => e.id == timesheet.employeeId).firstOrNull;
    final employeeName = employee?.fullName ?? 'Unbekannt';

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Zeitnachweis', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Mitarbeiter: $employeeName'),
              pw.Text('Status: ${timesheet.statusLabel}'),
            ],
          ),
          pw.Text('Zeitraum: ${timesheet.startDate.day}.${timesheet.startDate.month}.${timesheet.startDate.year} - ${timesheet.endDate.day}.${timesheet.endDate.month}.${timesheet.endDate.year}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Datum', 'Typ', 'Von', 'Bis', 'Stunden', 'Beschreibung'],
            data: timesheet.entries.map((e) => [
              '${e.startTime.day}.${e.startTime.month}.${e.startTime.year}',
              _getEntryTypeLabel(e.type),
              '${e.startTime.hour}:${e.startTime.minute.toString().padLeft(2, '0')}',
              '${e.endTime.hour}:${e.endTime.minute.toString().padLeft(2, '0')}',
              '${e.totalHours.toStringAsFixed(1)}h',
              e.description ?? '',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Gesamtstunden: ${timesheet.calculatedTotalHours.toStringAsFixed(1)}h',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Überstunden: ${timesheet.calculatedOvertimeHours.toStringAsFixed(1)}h'),
              pw.Text('Vergütung: ${timesheet.calculatedTotalPay.toStringAsFixed(2)} EUR',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Zeitnachweis_${employeeName}_${timesheet.startDate.month}_${timesheet.startDate.year}.pdf',
    );
  }

  String _getEntryTypeLabel(TimesheetEntryType type) {
    switch (type) {
      case TimesheetEntryType.regular:
        return 'Regulär';
      case TimesheetEntryType.overtime:
        return 'Überstunden';
      case TimesheetEntryType.travel:
        return 'Fahrt';
      case TimesheetEntryType.break_:
        return 'Pause';
      case TimesheetEntryType.training:
        return 'Schulung';
      case TimesheetEntryType.administrative:
        return 'Verwaltung';
    }
  }
}

class TimesheetEntryCard extends StatelessWidget {
  final TimesheetEntry entry;
  final Timesheet timesheet;
  final Function(TimesheetEntry)? onEdit;
  final Function(TimesheetEntry)? onDelete;

  const TimesheetEntryCard({
    super.key,
    required this.entry,
    required this.timesheet,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTypeIcon(entry.type),
                  color: _getTypeColor(entry.type),
                ),
                const SizedBox(width: 8),
                Text(
                  _getTypeLabel(entry.type),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call(entry);
                          break;
                        case 'delete':
                          onDelete?.call(entry);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Symbols.edit),
                            title: Text('Bearbeiten'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Symbols.delete, color: Colors.red),
                            title: Text('Löschen', style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Symbols.schedule,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.startTime.day}.${entry.startTime.month}.${entry.startTime.year} ${entry.startTime.hour}:${entry.startTime.minute.toString().padLeft(2, '0')} - ${entry.endTime.hour}:${entry.endTime.minute.toString().padLeft(2, '0')}',
                ),
                const SizedBox(width: 16),
                Icon(
                  Symbols.timer,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text('${entry.totalHours.toStringAsFixed(1)}h'),
                const SizedBox(width: 16),
                Icon(
                  Symbols.euro,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text('€${entry.calculatedPay.toStringAsFixed(2)}'),
              ],
            ),
            if (entry.description != null) ...[
              const SizedBox(height: 8),
              Text(
                entry.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (entry.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Symbols.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(entry.location!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(TimesheetEntryType type) {
    switch (type) {
      case TimesheetEntryType.regular:
        return Symbols.work;
      case TimesheetEntryType.overtime:
        return Symbols.trending_up;
      case TimesheetEntryType.travel:
        return Symbols.directions_car;
      case TimesheetEntryType.break_:
        return Symbols.coffee;
      case TimesheetEntryType.training:
        return Symbols.school;
      case TimesheetEntryType.administrative:
        return Symbols.admin_panel_settings;
    }
  }

  Color _getTypeColor(TimesheetEntryType type) {
    switch (type) {
      case TimesheetEntryType.regular:
        return Colors.blue;
      case TimesheetEntryType.overtime:
        return Colors.orange;
      case TimesheetEntryType.travel:
        return Colors.green;
      case TimesheetEntryType.break_:
        return Colors.grey;
      case TimesheetEntryType.training:
        return Colors.purple;
      case TimesheetEntryType.administrative:
        return Colors.brown;
    }
  }

  String _getTypeLabel(TimesheetEntryType type) {
    switch (type) {
      case TimesheetEntryType.regular:
        return 'Reguläre Arbeitszeit';
      case TimesheetEntryType.overtime:
        return 'Überstunden';
      case TimesheetEntryType.travel:
        return 'Fahrtzeit';
      case TimesheetEntryType.break_:
        return 'Pause';
      case TimesheetEntryType.training:
        return 'Schulung';
      case TimesheetEntryType.administrative:
        return 'Verwaltung';
    }
  }
}