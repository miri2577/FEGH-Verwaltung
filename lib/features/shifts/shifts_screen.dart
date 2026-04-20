import 'dart:convert';
import 'dart:typed_data';

import 'package:fegh_core/fegh_core.dart' show ShiftIcsExporter;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../models/shift.dart';
import '../../models/employee.dart';
import '../../providers/shift_provider.dart';
import '../../providers/employee_provider.dart';
import 'shift_swap_create_dialog.dart';
import 'shift_swap_screen.dart';
import 'widgets/shift_card.dart';
import 'widgets/shift_form_dialog.dart';

class ShiftsScreen extends ConsumerStatefulWidget {
  const ShiftsScreen({super.key});

  @override
  ConsumerState<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends ConsumerState<ShiftsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isTableView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shiftsAsyncValue = ref.watch(shiftsProvider);
    final shiftCount = ref.watch(shiftCountProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.schedule,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  'Schichtplanung',
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
                    '$shiftCount Schichten',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, icon: Icon(Symbols.grid_view, size: 18)),
                    ButtonSegment(value: true, icon: Icon(Symbols.table_rows, size: 18)),
                  ],
                  selected: {_isTableView},
                  onSelectionChanged: (value) {
                    setState(() {
                      _isTableView = value.first;
                    });
                  },
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Aktualisieren',
                  onPressed: () => _refreshShifts(ref),
                  icon: const Icon(Symbols.refresh),
                ),
                IconButton(
                  tooltip: 'iCal-Export',
                  onPressed: () => _exportIcs(),
                  icon: const Icon(Symbols.calendar_month),
                ),
                IconButton(
                  tooltip: 'Tausch-Anfragen',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ShiftSwapScreen()),
                  ),
                  icon: const Icon(Symbols.swap_horiz),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _showAddShiftDialog(),
                  icon: const Icon(Symbols.add, size: 18),
                  label: const Text('Neue Schicht'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Heute'),
                Tab(text: 'Kommend'),
                Tab(text: 'Aktiv'),
                Tab(text: 'Alle'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTodaysShifts(),
                  _buildUpcomingShifts(),
                  _buildActiveShifts(),
                  _buildAllShifts(shiftsAsyncValue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysShifts() {
    return Consumer(
      builder: (context, ref, child) {
        final todaysShifts = ref.watch(todaysShiftsProvider);
        return todaysShifts.when(
          data: (shifts) => shifts.isEmpty
              ? _buildEmptyState('Keine Schichten heute', 'Alle Schichten für heute sind abgeschlossen oder es sind keine geplant.')
              : _buildShiftsList(shifts),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error),
        );
      },
    );
  }

  Widget _buildUpcomingShifts() {
    return Consumer(
      builder: (context, ref, child) {
        final upcomingShifts = ref.watch(upcomingShiftsProvider);
        return upcomingShifts.when(
          data: (shifts) => shifts.isEmpty
              ? _buildEmptyState('Keine kommenden Schichten', 'Es sind keine zukünftigen Schichten geplant.')
              : _buildShiftsList(shifts),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error),
        );
      },
    );
  }

  Widget _buildActiveShifts() {
    return Consumer(
      builder: (context, ref, child) {
        final activeShifts = ref.watch(activeShiftsProvider);
        return activeShifts.when(
          data: (shifts) => shifts.isEmpty
              ? _buildEmptyState('Keine aktiven Schichten', 'Derzeit sind keine Schichten aktiv.')
              : _buildShiftsList(shifts),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error),
        );
      },
    );
  }

  Widget _buildAllShifts(AsyncValue<List<Shift>> shiftsAsyncValue) {
    return shiftsAsyncValue.when(
      data: (shifts) => shifts.isEmpty
          ? _buildEmptyState('Keine Schichten vorhanden', 'Erstellen Sie die erste Schicht, um zu beginnen.')
          : _buildShiftsList(shifts),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildShiftsList(List<Shift> shifts) {
    if (_isTableView) {
      return _buildShiftsTable(shifts);
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: shifts.length,
      itemBuilder: (context, index) {
        final shift = shifts[index];
        return ShiftCard(
          shift: shift,
          onTap: () => _showShiftDetails(shift),
          onEdit: () => _showEditShiftDialog(shift),
          onDelete: () => _showDeleteConfirmation(shift),
          onStart: () => _startShift(shift.id),
          onEnd: () => _endShift(shift.id),
          onCancel: () => _cancelShift(shift.id),
        );
      },
    );
  }

  String _getShiftStatusLabel(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.scheduled:
        return 'Geplant';
      case ShiftStatus.inProgress:
        return 'Aktiv';
      case ShiftStatus.completed:
        return 'Abgeschlossen';
      case ShiftStatus.cancelled:
        return 'Abgesagt';
      case ShiftStatus.noShow:
        return 'Nicht erschienen';
    }
  }

  String _getShiftTypeLabel(ShiftType type) {
    switch (type) {
      case ShiftType.regular:
        return 'Normal';
      case ShiftType.overtime:
        return 'Überstunden';
      case ShiftType.holiday:
        return 'Feiertag';
      case ShiftType.night:
        return 'Nacht';
      case ShiftType.weekend:
        return 'Wochenende';
    }
  }

  Widget _buildShiftsTable(List<Shift> shifts) {
    final employees = ref.watch(employeesProvider).valueOrNull ?? [];
    final dataSource = _ShiftDataSource(
      shifts: shifts,
      employees: employees,
      getStatusLabel: _getShiftStatusLabel,
      getTypeLabel: _getShiftTypeLabel,
      onEdit: _showEditShiftDialog,
      onDelete: _showDeleteConfirmation,
      onStart: (s) => _startShift(s.id),
      onEnd: (s) => _endShift(s.id),
    );
    return SfDataGrid(
      source: dataSource,
      columnWidthMode: ColumnWidthMode.fill,
      gridLinesVisibility: GridLinesVisibility.horizontal,
      headerGridLinesVisibility: GridLinesVisibility.horizontal,
      allowSorting: true,
      allowMultiColumnSorting: true,
      rowHeight: 48,
      headerRowHeight: 40,
      columns: [
        GridColumn(columnName: 'mitarbeiter', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Mitarbeiter', style: TextStyle(fontWeight: FontWeight.bold)))),
        GridColumn(columnName: 'datum', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Datum', style: TextStyle(fontWeight: FontWeight.bold))), minimumWidth: 90, maximumWidth: 120),
        GridColumn(columnName: 'zeit', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Zeit', style: TextStyle(fontWeight: FontWeight.bold))), minimumWidth: 100, maximumWidth: 140),
        GridColumn(columnName: 'typ', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Typ', style: TextStyle(fontWeight: FontWeight.bold))), minimumWidth: 80, maximumWidth: 120),
        GridColumn(columnName: 'status', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold))), minimumWidth: 80, maximumWidth: 130),
        GridColumn(columnName: 'geplant', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerRight, child: const Text('Geplant (h)', style: TextStyle(fontWeight: FontWeight.bold))), minimumWidth: 80, maximumWidth: 100),
        GridColumn(columnName: 'ist', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerRight, child: const Text('Ist (h)', style: TextStyle(fontWeight: FontWeight.bold))), minimumWidth: 70, maximumWidth: 90),
        GridColumn(columnName: 'aktionen', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Aktionen', style: TextStyle(fontWeight: FontWeight.bold))), minimumWidth: 130, maximumWidth: 170),
      ],
      onCellTap: (details) {
        if (details.rowColumnIndex.rowIndex > 0) {
          final index = details.rowColumnIndex.rowIndex - 1;
          if (index < shifts.length) _showShiftDetails(shifts[index]);
        }
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
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
            'Fehler beim Laden der Schichten',
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
            onPressed: () => _refreshShifts(ref),
            icon: const Icon(Symbols.refresh, size: 18),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  void _refreshShifts(WidgetRef ref) {
    ref.read(shiftsProvider.notifier).refresh();
  }

  Future<void> _exportIcs() async {
    final shifts = ref.read(shiftsProvider).valueOrNull ?? const <Shift>[];
    if (shifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Schichten zum Exportieren.')),
      );
      return;
    }
    final employees = ref.read(employeesProvider).valueOrNull ?? const <Employee>[];
    final nameById = {for (final e in employees) e.id: e.fullName};
    final ics = ShiftIcsExporter.export(
      shifts,
      calName: 'FEGH Dienstplan',
      employeeNameResolver: (id) => nameById[id] ?? id,
    );
    final bytes = Uint8List.fromList(utf8.encode(ics));
    try {
      await FileSaver.instance.saveFile(
        name: 'fegh-dienstplan',
        bytes: bytes,
        ext: 'ics',
        mimeType: MimeType.other,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('iCal mit ${shifts.length} Schichten exportiert.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export fehlgeschlagen: $e')),
      );
    }
  }

  void _showAddShiftDialog() {
    showDialog(
      context: context,
      builder: (context) => ShiftFormDialog(
        onSave: (shift) async {
          await ref.read(shiftsProvider.notifier).addShift(shift);
        },
      ),
    );
  }

  void _showEditShiftDialog(Shift shift) {
    showDialog(
      context: context,
      builder: (context) => ShiftFormDialog(
        shift: shift,
        onSave: (updatedShift) async {
          await ref.read(shiftsProvider.notifier).updateShift(updatedShift);
        },
      ),
    );
  }

  void _showShiftDetails(Shift shift) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schichtdetails'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mitarbeiter ID: ${shift.employeeId}'),
              Text('Beginn: ${shift.startTime}'),
              Text('Ende: ${shift.endTime}'),
              Text('Status: ${shift.status.toString().split('.').last}'),
              Text('Typ: ${shift.type.toString().split('.').last}'),
              if (shift.location != null) Text('Standort: ${shift.location}'),
              if (shift.description != null) Text('Beschreibung: ${shift.description}'),
              Text('Stundenlohn: €${shift.hourlyRate.toStringAsFixed(2)}'),
              Text('Geplante Stunden: ${shift.scheduledHours.toStringAsFixed(1)}h'),
              if (shift.actualHours != null)
                Text('Tatsächliche Stunden: ${shift.actualHours!.toStringAsFixed(1)}h'),
              if (shift.notes != null) Text('Notizen: ${shift.notes}'),
            ],
          ),
        ),
        actions: [
          if (shift.status == ShiftStatus.scheduled)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (_) => ShiftSwapCreateDialog(shift: shift),
                );
              },
              icon: const Icon(Symbols.swap_horiz, size: 18),
              label: const Text('Tausch anbieten'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Shift shift) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schicht löschen'),
        content: Text('Möchten Sie diese Schicht wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.'),
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
              await ref.read(shiftsProvider.notifier).deleteShift(shift.id);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _startShift(String shiftId) async {
    await ref.read(shiftsProvider.notifier).startShift(shiftId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schicht gestartet'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _endShift(String shiftId) async {
    await ref.read(shiftsProvider.notifier).endShift(shiftId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schicht beendet'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _cancelShift(String shiftId) async {
    await ref.read(shiftsProvider.notifier).cancelShift(shiftId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schicht abgesagt'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

class _ShiftDataSource extends DataGridSource {
  final List<Shift> shifts;
  final List<Employee> employees;
  final String Function(ShiftStatus) getStatusLabel;
  final String Function(ShiftType) getTypeLabel;
  final void Function(Shift) onEdit;
  final void Function(Shift) onDelete;
  final void Function(Shift) onStart;
  final void Function(Shift) onEnd;

  _ShiftDataSource({
    required this.shifts,
    required this.employees,
    required this.getStatusLabel,
    required this.getTypeLabel,
    required this.onEdit,
    required this.onDelete,
    required this.onStart,
    required this.onEnd,
  });

  String _employeeName(String id) {
    final emp = employees.where((e) => e.id == id).firstOrNull;
    return emp?.fullName ?? 'Unbekannt';
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  String _formatTime(DateTime start, DateTime end) =>
      '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} – ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

  @override
  List<DataGridRow> get rows => shifts.map((s) => DataGridRow(cells: [
    DataGridCell<String>(columnName: 'mitarbeiter', value: _employeeName(s.employeeId)),
    DataGridCell<String>(columnName: 'datum', value: _formatDate(s.startTime)),
    DataGridCell<String>(columnName: 'zeit', value: _formatTime(s.startTime, s.endTime)),
    DataGridCell<String>(columnName: 'typ', value: getTypeLabel(s.type)),
    DataGridCell<String>(columnName: 'status', value: getStatusLabel(s.status)),
    DataGridCell<double>(columnName: 'geplant', value: s.scheduledHours),
    DataGridCell<double?>(columnName: 'ist', value: s.actualHours),
    DataGridCell<Shift>(columnName: 'aktionen', value: s),
  ])).toList();

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(cells: row.getCells().map((cell) {
      if (cell.columnName == 'aktionen') {
        final shift = cell.value as Shift;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.centerLeft,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (shift.status == ShiftStatus.scheduled)
              IconButton(icon: const Icon(Symbols.play_arrow, size: 18), onPressed: () => onStart(shift), tooltip: 'Starten', visualDensity: VisualDensity.compact),
            if (shift.status == ShiftStatus.inProgress)
              IconButton(icon: const Icon(Symbols.stop, size: 18), onPressed: () => onEnd(shift), tooltip: 'Beenden', visualDensity: VisualDensity.compact),
            IconButton(icon: const Icon(Symbols.edit, size: 18), onPressed: () => onEdit(shift), tooltip: 'Bearbeiten', visualDensity: VisualDensity.compact),
            IconButton(icon: const Icon(Symbols.delete, size: 18), onPressed: () => onDelete(shift), tooltip: 'Löschen', visualDensity: VisualDensity.compact),
          ]),
        );
      }
      if (cell.columnName == 'geplant') {
        return Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerRight, child: Text('${(cell.value as double).toStringAsFixed(1)}'));
      }
      if (cell.columnName == 'ist') {
        final v = cell.value as double?;
        return Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerRight, child: Text(v != null ? v.toStringAsFixed(1) : '-'));
      }
      return Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: Text(cell.value?.toString() ?? '-', overflow: TextOverflow.ellipsis));
    }).toList());
  }
}