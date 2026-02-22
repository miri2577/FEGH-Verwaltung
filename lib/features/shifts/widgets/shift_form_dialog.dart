import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/shift.dart';
import '../../../models/employee.dart';
import '../../../providers/employee_provider.dart';

class ShiftFormDialog extends ConsumerStatefulWidget {
  final Shift? shift;
  final Function(Shift) onSave;

  const ShiftFormDialog({
    super.key,
    this.shift,
    required this.onSave,
  });

  @override
  ConsumerState<ShiftFormDialog> createState() => _ShiftFormDialogState();
}

class _ShiftFormDialogState extends ConsumerState<ShiftFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedEmployeeId;
  ShiftType _selectedType = ShiftType.regular;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(hour: (TimeOfDay.now().hour + 8) % 24, minute: TimeOfDay.now().minute);
  TimeOfDay? _breakDuration;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.shift != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final shift = widget.shift!;
    _selectedEmployeeId = shift.employeeId;
    _selectedType = shift.type;
    _selectedDate = shift.startTime;
    _startTime = TimeOfDay.fromDateTime(shift.startTime);
    _endTime = TimeOfDay.fromDateTime(shift.endTime);
    _breakDuration = shift.breakDurationMinutes != null
        ? TimeOfDay(
            hour: (shift.breakDurationMinutes! / 60).floor().clamp(0, 23),
            minute: (shift.breakDurationMinutes! % 60).round().clamp(0, 59),
          )
        : null;
    _notesController.text = shift.notes ?? '';
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
                  Symbols.schedule,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.shift == null ? 'Neue Schicht erstellen' : 'Schicht bearbeiten',
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
                            child: DropdownButtonFormField<ShiftType>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Schichttyp',
                                prefixIcon: Icon(Symbols.work),
                                border: OutlineInputBorder(),
                              ),
                              items: ShiftType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(_getTypeLabel(type)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedType = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Datum',
                                  prefixIcon: Icon(Symbols.calendar_today),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectStartTime,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Startzeit',
                                  prefixIcon: Icon(Symbols.schedule),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(_formatTimeOfDay(_startTime)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _selectEndTime,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Endzeit',
                                  prefixIcon: Icon(Symbols.schedule),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(_formatTimeOfDay(_endTime)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectBreakDuration,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Pausenzeit (optional)',
                            prefixIcon: Icon(Symbols.coffee),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _breakDuration != null
                                ? _formatTimeOfDay(_breakDuration!)
                                : 'Keine Pause',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notizen (optional)',
                          hintText: 'Zusätzliche Informationen zur Schicht',
                          prefixIcon: Icon(Symbols.note),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildCalculatedFields(),
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
                  onPressed: _isLoading ? null : _saveShift,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.shift == null ? 'Erstellen' : 'Speichern'),
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

  Widget _buildCalculatedFields() {
    final totalDuration = _calculateTotalDuration();
    final workingHours = _calculateWorkingHours();

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
            'Berechnete Werte',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gesamtdauer',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${totalDuration.inHours}h ${totalDuration.inMinutes % 60}min',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arbeitszeit',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${workingHours.inHours}h ${workingHours.inMinutes % 60}min',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Duration _calculateTotalDuration() {
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    var endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    // Handle overnight shifts
    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    return endDateTime.difference(startDateTime);
  }

  Duration _calculateWorkingHours() {
    final totalDuration = _calculateTotalDuration();
    final breakDuration = _breakDuration != null
        ? Duration(hours: _breakDuration!.hour, minutes: _breakDuration!.minute)
        : Duration.zero;

    return totalDuration - breakDuration;
  }

  String _getTypeLabel(ShiftType type) {
    switch (type) {
      case ShiftType.regular:
        return 'Reguläre Schicht';
      case ShiftType.overtime:
        return 'Überstunden';
      case ShiftType.night:
        return 'Nachtschicht';
      case ShiftType.weekend:
        return 'Wochenendschicht';
      case ShiftType.holiday:
        return 'Feiertagsschicht';
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _selectBreakDuration() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _breakDuration ?? const TimeOfDay(hour: 0, minute: 30),
      helpText: 'Pausenzeit auswählen',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked.hour >= 0 && picked.hour < 24) {
      setState(() {
        _breakDuration = picked;
      });
    }
  }

  Future<void> _saveShift() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      var endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Handle overnight shifts
      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }

      final breakDurationMinutes = _breakDuration != null
          ? (_breakDuration!.hour.clamp(0, 23) * 60 + _breakDuration!.minute.clamp(0, 59)).toDouble()
          : null;

      final shift = Shift(
        id: widget.shift?.id ?? '',
        employeeId: _selectedEmployeeId!,
        startTime: startDateTime,
        endTime: endDateTime,
        type: _selectedType,
        status: widget.shift?.status ?? ShiftStatus.scheduled,
        breakDurationMinutes: breakDurationMinutes,
        hourlyRate: 15.0, // Default hourly rate
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.shift?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.onSave(shift);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.shift == null
                  ? 'Schicht erfolgreich erstellt'
                  : 'Schicht erfolgreich aktualisiert',
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