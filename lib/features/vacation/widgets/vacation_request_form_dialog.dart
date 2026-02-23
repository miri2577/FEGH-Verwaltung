import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/vacation_request.dart';
import '../../../models/employee.dart';
import '../../../providers/employee_provider.dart';
import '../../../providers/vacation_provider.dart';

class VacationRequestFormDialog extends ConsumerStatefulWidget {
  final VacationRequest? request;

  const VacationRequestFormDialog({
    super.key,
    this.request,
  });

  @override
  ConsumerState<VacationRequestFormDialog> createState() => _VacationRequestFormDialogState();
}

class _VacationRequestFormDialogState extends ConsumerState<VacationRequestFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedEmployeeId;
  VacationType _selectedType = VacationType.annual;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 5));
  int _workingDays = 0;

  bool get _isEditing => widget.request != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final r = widget.request!;
      _selectedEmployeeId = r.employeeId;
      _selectedType = r.type;
      _startDate = r.startDate;
      _endDate = r.endDate;
      _reasonController.text = r.reason;
      _notesController.text = r.notes ?? '';
    }
    _calculateWorkingDays();
  }

  void _calculateWorkingDays() {
    _workingDays = VacationRequest.calculateWorkingDays(_startDate, _endDate);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);

    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isEditing ? Symbols.edit : Symbols.beach_access,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  _isEditing ? 'Urlaubsantrag bearbeiten' : 'Neuer Urlaubsantrag',
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
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee Selection
                      employeesAsync.when(
                        data: (employees) {
                          final activeEmployees = employees
                              .where((e) => e.status == EmployeeStatus.active)
                              .toList();
                          return DropdownButtonFormField<String>(
                            value: _selectedEmployeeId,
                            decoration: const InputDecoration(
                              labelText: 'Mitarbeiter *',
                              border: OutlineInputBorder(),
                            ),
                            items: activeEmployees.map((e) {
                              return DropdownMenuItem(
                                value: e.id,
                                child: Text(e.fullName),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedEmployeeId = value),
                            validator: (value) =>
                                value == null ? 'Bitte Mitarbeiter auswählen' : null,
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text('Fehler beim Laden der Mitarbeiter'),
                      ),
                      const SizedBox(height: 16),

                      // Vacation Type
                      DropdownButtonFormField<VacationType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Urlaubsart *',
                          border: OutlineInputBorder(),
                        ),
                        items: VacationType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getTypeLabel(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedType = value);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date Selection Row
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(true),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Von *',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Symbols.calendar_today),
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
                              onTap: () => _selectDate(false),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Bis *',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Symbols.calendar_today),
                                ),
                                child: Text(
                                  '${_endDate.day}.${_endDate.month}.${_endDate.year}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Working Days Summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Symbols.date_range, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '$_workingDays Arbeitstage (${_endDate.difference(_startDate).inDays + 1} Kalendertage)',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reason
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Begründung *',
                          border: OutlineInputBorder(),
                          hintText: 'Grund für den Urlaubsantrag...',
                        ),
                        maxLines: 2,
                        validator: (value) =>
                            (value?.isEmpty ?? true) ? 'Begründung ist erforderlich' : null,
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notizen',
                          border: OutlineInputBorder(),
                          hintText: 'Zusätzliche Informationen...',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _saveRequest,
                  child: Text(_isEditing ? 'Speichern' : 'Antrag stellen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = date;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
        _calculateWorkingDays();
      });
    }
  }

  void _saveRequest() {
    if (!_formKey.currentState!.validate()) return;

    if (_isEditing) {
      final updated = widget.request!.copyWith(
        employeeId: _selectedEmployeeId,
        type: _selectedType,
        startDate: _startDate,
        endDate: _endDate,
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        workingDays: _workingDays,
        updatedAt: DateTime.now().toIso8601String(),
      );
      ref.read(vacationRequestsProvider.notifier).updateVacationRequest(updated);
    } else {
      final request = VacationRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        employeeId: _selectedEmployeeId!,
        startDate: _startDate,
        endDate: _endDate,
        type: _selectedType,
        status: VacationRequestStatus.pending,
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        workingDays: _workingDays,
        requestDate: DateTime.now(),
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      ref.read(vacationRequestsProvider.notifier).addVacationRequest(request);
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? 'Urlaubsantrag aktualisiert'
            : 'Urlaubsantrag wurde eingereicht'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getTypeLabel(VacationType type) {
    switch (type) {
      case VacationType.annual:
        return 'Jahresurlaub';
      case VacationType.sick:
        return 'Krankenstand';
      case VacationType.personal:
        return 'Persönlicher Urlaub';
      case VacationType.maternity:
        return 'Mutterschaftsurlaub';
      case VacationType.paternity:
        return 'Vaterschaftsurlaub';
      case VacationType.emergency:
        return 'Notfall';
      case VacationType.unpaid:
        return 'Unbezahlter Urlaub';
      case VacationType.sabbatical:
        return 'Sabbatical';
    }
  }
}
