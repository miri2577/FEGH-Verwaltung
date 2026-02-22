import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/shift.dart';
import '../../../models/employee.dart';
import '../../../providers/employee_provider.dart';
import '../../../providers/shift_provider.dart';

class BulkShiftDialog extends ConsumerStatefulWidget {
  const BulkShiftDialog({super.key});

  @override
  ConsumerState<BulkShiftDialog> createState() => _BulkShiftDialogState();
}

class _BulkShiftDialogState extends ConsumerState<BulkShiftDialog> {
  final _formKey = GlobalKey<FormState>();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  ShiftType _shiftType = ShiftType.morning;
  List<String> _selectedEmployeeIds = [];
  List<int> _selectedWeekdays = [1, 2, 3, 4, 5]; // Monday to Friday
  bool _includeWeekends = false;
  bool _includeHolidays = false;
  String _creationMode = 'daily'; // 'daily', 'weekly', 'custom'

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);

    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Symbols.add_box, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Schichten in Masse erstellen',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Symbols.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Creation Mode
                      _buildCreationModeSection(),
                      const SizedBox(height: 24),

                      // Date Range
                      _buildDateRangeSection(context),
                      const SizedBox(height: 24),

                      // Time Settings
                      _buildTimeSettingsSection(context),
                      const SizedBox(height: 24),

                      // Weekday Selection
                      if (_creationMode != 'daily') _buildWeekdaySection(),
                      if (_creationMode != 'daily') const SizedBox(height: 24),

                      // Employee Selection
                      employeesAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Text('Fehler: $error'),
                        data: (employees) => _buildEmployeeSection(employees),
                      ),
                      const SizedBox(height: 24),

                      // Additional Options
                      _buildAdditionalOptionsSection(),
                      const SizedBox(height: 24),

                      // Preview
                      _buildPreviewSection(),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _selectedEmployeeIds.isNotEmpty ? _createBulkShifts : null,
                  icon: const Icon(Symbols.add, size: 18),
                  label: const Text('Schichten erstellen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreationModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Erstellungsmodus',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'daily',
              label: Text('Täglich'),
              icon: Icon(Symbols.today, size: 18),
            ),
            ButtonSegment(
              value: 'weekly',
              label: Text('Wöchentlich'),
              icon: Icon(Symbols.view_week, size: 18),
            ),
            ButtonSegment(
              value: 'custom',
              label: Text('Benutzerdefiniert'),
              icon: Icon(Symbols.tune, size: 18),
            ),
          ],
          selected: {_creationMode},
          onSelectionChanged: (selection) {
            setState(() {
              _creationMode = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zeitraum',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectStartDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Startdatum',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Symbols.calendar_today),
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
                onTap: () => _selectEndDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Enddatum',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Symbols.calendar_today),
                  ),
                  child: Text(
                    '${_endDate.day}.${_endDate.month}.${_endDate.year}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Arbeitszeiten',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectStartTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Startzeit',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Symbols.schedule),
                  ),
                  child: Text(
                    '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectEndTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Endzeit',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Symbols.schedule),
                  ),
                  child: Text(
                    '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ShiftType>(
          value: _shiftType,
          decoration: const InputDecoration(
            labelText: 'Schichttyp',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Symbols.work),
          ),
          items: ShiftType.values.map((type) => DropdownMenuItem(
            value: type,
            child: Text(type.label),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _shiftType = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildWeekdaySection() {
    const weekdays = [
      {'value': 1, 'label': 'Montag'},
      {'value': 2, 'label': 'Dienstag'},
      {'value': 3, 'label': 'Mittwoch'},
      {'value': 4, 'label': 'Donnerstag'},
      {'value': 5, 'label': 'Freitag'},
      {'value': 6, 'label': 'Samstag'},
      {'value': 7, 'label': 'Sonntag'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Wochentage',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedWeekdays.length == 7) {
                    _selectedWeekdays.clear();
                  } else {
                    _selectedWeekdays = [1, 2, 3, 4, 5, 6, 7];
                  }
                });
              },
              child: Text(_selectedWeekdays.length == 7 ? 'Alle abwählen' : 'Alle auswählen'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: weekdays.map((day) {
            final isSelected = _selectedWeekdays.contains(day['value']);
            return FilterChip(
              label: Text(day['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedWeekdays.add(day['value'] as int);
                  } else {
                    _selectedWeekdays.remove(day['value']);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmployeeSection(List<Employee> employees) {
    final activeEmployees = employees.where((e) => e.status == EmployeeStatus.active).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Mitarbeiter',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedEmployeeIds.length == activeEmployees.length) {
                    _selectedEmployeeIds.clear();
                  } else {
                    _selectedEmployeeIds = activeEmployees.map((e) => e.id).toList();
                  }
                });
              },
              child: Text(
                _selectedEmployeeIds.length == activeEmployees.length ? 'Alle abwählen' : 'Alle auswählen',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_selectedEmployeeIds.length} von ${activeEmployees.length} ausgewählt',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: activeEmployees.length,
            itemBuilder: (context, index) {
              final employee = activeEmployees[index];
              final isSelected = _selectedEmployeeIds.contains(employee.id);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedEmployeeIds.add(employee.id);
                    } else {
                      _selectedEmployeeIds.remove(employee.id);
                    }
                  });
                },
                title: Text(employee.fullName),
                subtitle: Text(employee.position),
                dense: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zusätzliche Optionen',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _includeWeekends,
          onChanged: (value) {
            setState(() {
              _includeWeekends = value ?? false;
              if (_includeWeekends) {
                if (!_selectedWeekdays.contains(6)) _selectedWeekdays.add(6);
                if (!_selectedWeekdays.contains(7)) _selectedWeekdays.add(7);
              } else {
                _selectedWeekdays.removeWhere((day) => day == 6 || day == 7);
              }
            });
          },
          title: const Text('Wochenenden einschließen'),
          subtitle: const Text('Samstag und Sonntag automatisch hinzufügen'),
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          value: _includeHolidays,
          onChanged: (value) {
            setState(() {
              _includeHolidays = value ?? false;
            });
          },
          title: const Text('Feiertage einschließen'),
          subtitle: const Text('Schichten auch an Feiertagen erstellen'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    final totalDays = _calculateTotalDays();
    final totalShifts = totalDays * _selectedEmployeeIds.length;

    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.preview, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Vorschau',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPreviewStat('Tage', totalDays.toString()),
                ),
                Expanded(
                  child: _buildPreviewStat('Mitarbeiter', _selectedEmployeeIds.length.toString()),
                ),
                Expanded(
                  child: _buildPreviewStat('Schichten', totalShifts.toString()),
                ),
              ],
            ),
            if (totalShifts > 100) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.warningContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Symbols.warning,
                      size: 16,
                      color: Theme.of(context).colorScheme.onWarningContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Es werden viele Schichten erstellt. Dies kann einige Zeit dauern.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onWarningContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  int _calculateTotalDays() {
    if (_creationMode == 'daily') {
      return _endDate.difference(_startDate).inDays + 1;
    }

    int totalDays = 0;
    DateTime currentDate = _startDate;

    while (currentDate.isBefore(_endDate) || currentDate.isAtSameMomentAs(_endDate)) {
      if (_selectedWeekdays.contains(currentDate.weekday)) {
        totalDays++;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return totalDays;
  }

  void _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 7));
        }
      });
    }
  }

  void _selectEndDate(BuildContext context) async {
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

  void _selectStartTime(BuildContext context) async {
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

  void _selectEndTime(BuildContext context) async {
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

  void _createBulkShifts() async {
    if (!_formKey.currentState!.validate() || _selectedEmployeeIds.isEmpty) {
      return;
    }

    final shifts = <Shift>[];
    DateTime currentDate = _startDate;

    while (currentDate.isBefore(_endDate) || currentDate.isAtSameMomentAs(_endDate)) {
      bool shouldCreateShift = false;

      if (_creationMode == 'daily') {
        shouldCreateShift = true;
      } else {
        shouldCreateShift = _selectedWeekdays.contains(currentDate.weekday);
      }

      if (shouldCreateShift) {
        for (final employeeId in _selectedEmployeeIds) {
          final startDateTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            _startTime.hour,
            _startTime.minute,
          );

          final endDateTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            _endTime.hour,
            _endTime.minute,
          );

          final shift = Shift(
            id: DateTime.now().millisecondsSinceEpoch.toString() + employeeId + currentDate.day.toString(),
            employeeId: employeeId,
            startTime: startDateTime,
            endTime: endDateTime,
            shiftType: _shiftType,
          );

          shifts.add(shift);
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Add shifts to provider
    for (final shift in shifts) {
      await ref.read(shiftsProvider.notifier).addShift(shift);
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${shifts.length} Schichten wurden erfolgreich erstellt')),
    );
  }
}