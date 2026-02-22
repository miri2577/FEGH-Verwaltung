import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/timesheet.dart';
import '../../../models/employee.dart';
import '../../../providers/employee_provider.dart';
import '../../../services/timesheet_service.dart';

class TimesheetEntryFormDialog extends ConsumerStatefulWidget {
  final TimesheetEntry? entry;
  final String timesheetId;
  final Function(TimesheetEntry) onSave;

  const TimesheetEntryFormDialog({
    super.key,
    this.entry,
    required this.timesheetId,
    required this.onSave,
  });

  @override
  ConsumerState<TimesheetEntryFormDialog> createState() => _TimesheetEntryFormDialogState();
}

class _TimesheetEntryFormDialogState extends ConsumerState<TimesheetEntryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _travelDistanceController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  TimesheetEntryType _selectedType = TimesheetEntryType.regular;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  double _breakDurationMinutes = 0.0;
  double _overtimeMultiplier = 1.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _populateFields();
    } else {
      _hourlyRateController.text = '15.0';
    }
  }

  void _populateFields() {
    final entry = widget.entry!;
    _selectedType = entry.type;
    _startDate = DateTime(entry.startTime.year, entry.startTime.month, entry.startTime.day);
    _startTime = TimeOfDay.fromDateTime(entry.startTime);
    _endDate = DateTime(entry.endTime.year, entry.endTime.month, entry.endTime.day);
    _endTime = TimeOfDay.fromDateTime(entry.endTime);
    _breakDurationMinutes = entry.breakDurationMinutes ?? 0.0;
    _descriptionController.text = entry.description ?? '';
    _locationController.text = entry.location ?? '';
    _travelDistanceController.text = entry.travelDistance?.toString() ?? '';
    _hourlyRateController.text = entry.hourlyRate?.toString() ?? '15.0';
    _overtimeMultiplier = entry.overtimeMultiplier ?? 1.0;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _travelDistanceController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
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
                  widget.entry == null ? 'Neuen Zeiteintrag erstellen' : 'Zeiteintrag bearbeiten',
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
                      _buildTypeSelection(),
                      const SizedBox(height: 16),
                      _buildDateTimeSection(),
                      const SizedBox(height: 16),
                      _buildDescriptionAndLocation(),
                      const SizedBox(height: 16),
                      _buildRatesAndBreaks(),
                      const SizedBox(height: 16),
                      _buildSummaryCard(),
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
                  onPressed: _isLoading ? null : _saveEntry,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.entry == null ? 'Erstellen' : 'Speichern'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Arbeitszeit-Typ',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TimesheetEntryType.values.map((type) {
            return FilterChip(
              selected: _selectedType == type,
              label: Text(_getTypeLabel(type)),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedType = type;
                    if (type == TimesheetEntryType.overtime) {
                      _overtimeMultiplier = 1.5;
                    } else {
                      _overtimeMultiplier = 1.0;
                    }
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Arbeitszeit',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
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
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: _selectStartTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Startzeit',
                    prefixIcon: Icon(Symbols.access_time),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
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
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: _selectEndTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Endzeit',
                    prefixIcon: Icon(Symbols.access_time),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionAndLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Beschreibung',
            hintText: 'Was wurde gearbeitet?',
            prefixIcon: Icon(Symbols.description),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Arbeitsort',
                  hintText: 'Wo wurde gearbeitet?',
                  prefixIcon: Icon(Symbols.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _travelDistanceController,
                decoration: const InputDecoration(
                  labelText: 'Fahrstrecke (km)',
                  prefixIcon: Icon(Symbols.directions_car),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatesAndBreaks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vergütung & Pausen',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _hourlyRateController,
                decoration: const InputDecoration(
                  labelText: 'Stundenlohn (€)',
                  prefixIcon: Icon(Symbols.euro),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Stundenlohn ist erforderlich';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null || rate <= 0) {
                    return 'Ungültiger Stundenlohn';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: _breakDurationMinutes.toString(),
                decoration: const InputDecoration(
                  labelText: 'Pause (Minuten)',
                  prefixIcon: Icon(Symbols.coffee),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _breakDurationMinutes = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: _overtimeMultiplier.toString(),
                decoration: const InputDecoration(
                  labelText: 'Zuschlag-Faktor',
                  prefixIcon: Icon(Symbols.trending_up),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _overtimeMultiplier = double.tryParse(value) ?? 1.0;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final totalDuration = endDateTime.difference(startDateTime);
    final workingDuration = totalDuration - Duration(minutes: _breakDurationMinutes.round());
    final workingHours = workingDuration.inMinutes / 60.0;
    final hourlyRate = double.tryParse(_hourlyRateController.text) ?? 0.0;
    final totalPay = workingHours * hourlyRate * _overtimeMultiplier;

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
            'Zusammenfassung',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Gesamtdauer',
                  '${totalDuration.inHours}:${(totalDuration.inMinutes % 60).toString().padLeft(2, '0')}h',
                  Symbols.schedule,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Arbeitszeit',
                  '${workingDuration.inHours}:${(workingDuration.inMinutes % 60).toString().padLeft(2, '0')}h',
                  Symbols.work,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Vergütung',
                  '€${totalPay.toStringAsFixed(2)}',
                  Symbols.euro,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
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

  String _getTypeLabel(TimesheetEntryType type) {
    switch (type) {
      case TimesheetEntryType.regular:
        return 'Regulär';
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

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final timesheetService = TimesheetService();
      final entryId = widget.entry?.id ?? timesheetService.generateTimesheetId();

      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final entry = TimesheetEntry(
        id: entryId,
        timesheetId: widget.timesheetId,
        shiftId: widget.entry?.shiftId,
        type: _selectedType,
        startTime: startDateTime,
        endTime: endDateTime,
        breakDurationMinutes: _breakDurationMinutes > 0 ? _breakDurationMinutes : null,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        clientId: widget.entry?.clientId,
        travelDistance: _travelDistanceController.text.trim().isEmpty ? null : double.tryParse(_travelDistanceController.text),
        hourlyRate: double.tryParse(_hourlyRateController.text),
        overtimeMultiplier: _overtimeMultiplier != 1.0 ? _overtimeMultiplier : null,
        metadata: widget.entry?.metadata,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.onSave(entry);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.entry == null
                  ? 'Zeiteintrag erfolgreich erstellt'
                  : 'Zeiteintrag erfolgreich aktualisiert',
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