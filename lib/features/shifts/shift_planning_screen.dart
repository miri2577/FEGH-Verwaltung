import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/shift.dart';
import '../../models/employee.dart';
import '../../providers/shift_provider.dart';
import '../../providers/employee_provider.dart';
import 'widgets/shift_calendar_widget.dart';
import 'widgets/shift_planning_sidebar.dart';
import 'widgets/bulk_shift_dialog.dart';
import 'widgets/shift_form_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ShiftPlanningScreen extends ConsumerStatefulWidget {
  const ShiftPlanningScreen({super.key});

  @override
  ConsumerState<ShiftPlanningScreen> createState() => _ShiftPlanningScreenState();
}

class _ShiftPlanningScreenState extends ConsumerState<ShiftPlanningScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedView = 'week'; // 'week', 'month', 'day'
  List<String> _selectedEmployeeIds = [];
  String _selectedShiftType = 'all';

  @override
  Widget build(BuildContext context) {
    final shiftsAsync = ref.watch(shiftsProvider);
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schichtplanung'),
        actions: [
          IconButton(
            onPressed: () => _showBulkShiftDialog(context),
            icon: const Icon(Symbols.add_box),
            tooltip: 'Massenerstellung',
          ),
          IconButton(
            onPressed: () => _exportSchedule(),
            icon: const Icon(Symbols.download),
            tooltip: 'Exportieren',
          ),
          IconButton(
            onPressed: () => _showPlanningSettings(),
            icon: const Icon(Symbols.settings),
            tooltip: 'Einstellungen',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 320,
            child: ShiftPlanningSidebar(
              selectedDate: _selectedDate,
              selectedView: _selectedView,
              selectedEmployeeIds: _selectedEmployeeIds,
              selectedShiftType: _selectedShiftType,
              onDateChanged: (date) => setState(() => _selectedDate = date),
              onViewChanged: (view) => setState(() => _selectedView = view),
              onEmployeeSelectionChanged: (employeeIds) => setState(() => _selectedEmployeeIds = employeeIds),
              onShiftTypeChanged: (shiftType) => setState(() => _selectedShiftType = shiftType),
            ),
          ),
          const VerticalDivider(width: 1),

          // Main Calendar Area
          Expanded(
            child: Column(
              children: [
                // Calendar Toolbar
                _buildCalendarToolbar(),
                const Divider(height: 1),

                // Calendar View
                Expanded(
                  child: shiftsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Symbols.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Fehler beim Laden der Schichten: $error'),
                        ],
                      ),
                    ),
                    data: (shifts) => employeesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text('Fehler beim Laden der Mitarbeiter: $error'),
                      ),
                      data: (employees) => ShiftCalendarWidget(
                        shifts: _getFilteredShifts(shifts),
                        employees: employees,
                        selectedDate: _selectedDate,
                        viewMode: _selectedView,
                        selectedEmployeeIds: _selectedEmployeeIds,
                        onShiftTap: _handleShiftTap,
                        onTimeSlotTap: _handleTimeSlotTap,
                        onShiftDrag: _handleShiftDrag,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewShift(),
        icon: const Icon(Symbols.add),
        label: const Text('Neue Schicht'),
      ),
    );
  }

  Widget _buildCalendarToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Row(
        children: [
          // Navigation Buttons
          IconButton(
            onPressed: _previousPeriod,
            icon: const Icon(Symbols.chevron_left),
            tooltip: 'Vorheriger Zeitraum',
          ),
          IconButton(
            onPressed: _nextPeriod,
            icon: const Icon(Symbols.chevron_right),
            tooltip: 'Nächster Zeitraum',
          ),
          TextButton(
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
            child: const Text('Heute'),
          ),
          const SizedBox(width: 16),

          // Current Period Display
          Expanded(
            child: Text(
              _getPeriodTitle(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // View Mode Buttons
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'day',
                icon: Icon(Symbols.today, size: 18),
                label: Text('Tag'),
              ),
              ButtonSegment(
                value: 'week',
                icon: Icon(Symbols.view_week, size: 18),
                label: Text('Woche'),
              ),
              ButtonSegment(
                value: 'month',
                icon: Icon(Symbols.calendar_month, size: 18),
                label: Text('Monat'),
              ),
            ],
            selected: {_selectedView},
            onSelectionChanged: (selection) {
              setState(() => _selectedView = selection.first);
            },
          ),
        ],
      ),
    );
  }

  List<Shift> _getFilteredShifts(List<Shift> shifts) {
    var filteredShifts = shifts;

    // Filter by selected employees
    if (_selectedEmployeeIds.isNotEmpty) {
      filteredShifts = filteredShifts.where((shift) {
        return _selectedEmployeeIds.contains(shift.employeeId);
      }).toList();
    }

    // Filter by shift type
    if (_selectedShiftType != 'all') {
      filteredShifts = filteredShifts.where((shift) {
        return shift.type.toString().split('.').last == _selectedShiftType;
      }).toList();
    }

    // Filter by date range based on view
    final DateTime startDate;
    final DateTime endDate;

    switch (_selectedView) {
      case 'day':
        startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'week':
        final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
        endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
        break;
      default:
        return filteredShifts;
    }

    filteredShifts = filteredShifts.where((shift) {
      return shift.startTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
             shift.startTime.isBefore(endDate);
    }).toList();

    return filteredShifts;
  }

  String _getPeriodTitle() {
    switch (_selectedView) {
      case 'day':
        return '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}';
      case 'week':
        final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${startOfWeek.day}.${startOfWeek.month} - ${endOfWeek.day}.${endOfWeek.month}.${endOfWeek.year}';
      case 'month':
        final months = [
          '', 'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
          'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
        ];
        return '${months[_selectedDate.month]} ${_selectedDate.year}';
      default:
        return '';
    }
  }

  void _previousPeriod() {
    setState(() {
      switch (_selectedView) {
        case 'day':
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
          break;
        case 'week':
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
          break;
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      switch (_selectedView) {
        case 'day':
          _selectedDate = _selectedDate.add(const Duration(days: 1));
          break;
        case 'week':
          _selectedDate = _selectedDate.add(const Duration(days: 7));
          break;
        case 'month':
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          break;
      }
    });
  }

  void _handleShiftTap(Shift shift) {
    showDialog(
      context: context,
      builder: (context) => ShiftFormDialog(
        shift: shift,
        onSave: (updatedShift) async {
          ref.read(shiftsProvider.notifier).updateShift(updatedShift);
        },
      ),
    );
  }

  void _handleTimeSlotTap(DateTime dateTime) {
    _createNewShift(dateTime: dateTime);
  }

  void _handleShiftDrag(Shift shift, DateTime newStartTime) {
    final duration = shift.endTime.difference(shift.startTime);
    final newEndTime = newStartTime.add(duration);

    final updatedShift = shift.copyWith(
      startTime: newStartTime,
      endTime: newEndTime,
    );

    ref.read(shiftsProvider.notifier).updateShift(updatedShift);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schicht verschoben')),
    );
  }

  void _createNewShift({DateTime? dateTime}) {
    showDialog(
      context: context,
      builder: (context) => ShiftFormDialog(
        onSave: (shift) async {
          ref.read(shiftsProvider.notifier).addShift(shift);
        },
      ),
    );
  }

  void _showBulkShiftDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BulkShiftDialog(),
    );
  }

  void _exportSchedule() async {
    final shifts = ref.read(shiftsProvider).valueOrNull ?? [];
    final employees = ref.read(employeesProvider).valueOrNull ?? [];
    final filteredShifts = _getFilteredShifts(shifts);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Schichtplan - ${_getPeriodTitle()}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Mitarbeiter', 'Datum', 'Von', 'Bis', 'Typ', 'Status'],
            data: filteredShifts.map((s) {
              final emp = employees.where((e) => e.id == s.employeeId).firstOrNull;
              return [
                emp?.fullName ?? s.employeeId,
                '${s.startTime.day}.${s.startTime.month}.${s.startTime.year}',
                '${s.startTime.hour}:${s.startTime.minute.toString().padLeft(2, '0')}',
                '${s.endTime.hour}:${s.endTime.minute.toString().padLeft(2, '0')}',
                s.type.name,
                s.status.name,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Schichtplan_${_getPeriodTitle().replaceAll(' ', '_')}.pdf',
    );
  }

  void _showPlanningSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Planungseinstellungen werden implementiert')),
    );
  }
}