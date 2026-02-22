import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/timesheet.dart';
import '../../../models/employee.dart';
import '../../../providers/employee_provider.dart';
import '../../../services/timesheet_service.dart';

class TimesheetFormDialog extends ConsumerStatefulWidget {
  final Timesheet? timesheet;
  final Function(Timesheet) onSave;

  const TimesheetFormDialog({
    super.key,
    this.timesheet,
    required this.onSave,
  });

  @override
  ConsumerState<TimesheetFormDialog> createState() => _TimesheetFormDialogState();
}

class _TimesheetFormDialogState extends ConsumerState<TimesheetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedEmployeeId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.timesheet != null) {
      _populateFields();
    } else {
      // Set default to current week
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      _startDate = startOfWeek;
      _endDate = startOfWeek.add(const Duration(days: 6));
    }
  }

  void _populateFields() {
    final timesheet = widget.timesheet!;
    _selectedEmployeeId = timesheet.employeeId;
    _startDate = timesheet.startDate;
    _endDate = timesheet.endDate;
    _notesController.text = timesheet.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.assignment,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.timesheet == null ? 'Neuen Zeitnachweis erstellen' : 'Zeitnachweis bearbeiten',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Symbols.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      employeesAsync.when(
                        data: (employees) => _buildEmployeeSelection(employees),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Text(
                          'Fehler beim Laden der Mitarbeiter: $error',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectStartDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Startdatum',
                                  prefixIcon: Icon(Symbols.calendar_today),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  '${_startDate.day}.${_startDate.month}.${_startDate.year}',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _selectEndDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Enddatum',
                                  prefixIcon: Icon(Symbols.calendar_today),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  '${_endDate.day}.${_endDate.month}.${_endDate.year}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notizen (optional)',
                          hintText: 'Zusätzliche Informationen zum Zeitnachweis',
                          prefixIcon: Icon(Symbols.note),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isLoading ? null : _saveTimesheet,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.timesheet == null ? 'Erstellen' : 'Speichern'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeSelection(List<Employee> employees) {
    final activeEmployees = employees.where((e) => e.status == EmployeeStatus.active).toList();

    return DropdownButtonFormField<String>(
      value: _selectedEmployeeId,
      decoration: const InputDecoration(
        labelText: 'Mitarbeiter',
        prefixIcon: Icon(Symbols.person),
        border: OutlineInputBorder(),
      ),
      hint: const Text('Mitarbeiter auswählen'),
      items: activeEmployees.map((employee) {
        return DropdownMenuItem(
          value: employee.id,
          child: Text(employee.fullName),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bitte wählen Sie einen Mitarbeiter aus';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {
          _selectedEmployeeId = value;
        });
      },
    );
  }

  Widget _buildInfoCard() {
    final duration = _endDate.difference(_startDate).inDays + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zeitraum-Informationen',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
                'Zeitraum: $duration Tage',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Symbols.info,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nach dem Erstellen können Sie Arbeitszeit-Einträge hinzufügen.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Adjust end date if it's before start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 6));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _saveTimesheet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final timesheetService = TimesheetService();
      final timesheetId = widget.timesheet?.id ?? timesheetService.generateTimesheetId();

      final timesheet = Timesheet(
        id: timesheetId,
        employeeId: _selectedEmployeeId!,
        startDate: _startDate,
        endDate: _endDate,
        status: widget.timesheet?.status ?? TimesheetStatus.draft,
        entries: widget.timesheet?.entries ?? [],
        submittedBy: widget.timesheet?.submittedBy,
        submittedAt: widget.timesheet?.submittedAt,
        approvedBy: widget.timesheet?.approvedBy,
        approvedAt: widget.timesheet?.approvedAt,
        rejectionReason: widget.timesheet?.rejectionReason,
        totalHours: widget.timesheet?.totalHours,
        regularHours: widget.timesheet?.regularHours,
        overtimeHours: widget.timesheet?.overtimeHours,
        totalPay: widget.timesheet?.totalPay,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        metadata: widget.timesheet?.metadata,
        createdAt: widget.timesheet?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.onSave(timesheet);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.timesheet == null
                  ? 'Zeitnachweis erfolgreich erstellt'
                  : 'Zeitnachweis erfolgreich aktualisiert',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}