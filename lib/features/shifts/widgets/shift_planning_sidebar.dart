import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/employee.dart';
import '../../../providers/employee_provider.dart';
import '../../../providers/shift_provider.dart';

class ShiftPlanningSidebar extends ConsumerWidget {
  final DateTime selectedDate;
  final String selectedView;
  final List<String> selectedEmployeeIds;
  final String selectedShiftType;
  final Function(DateTime) onDateChanged;
  final Function(String) onViewChanged;
  final Function(List<String>) onEmployeeSelectionChanged;
  final Function(String) onShiftTypeChanged;

  const ShiftPlanningSidebar({
    super.key,
    required this.selectedDate,
    required this.selectedView,
    required this.selectedEmployeeIds,
    required this.selectedShiftType,
    required this.onDateChanged,
    required this.onViewChanged,
    required this.onEmployeeSelectionChanged,
    required this.onShiftTypeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);
    final shiftsAsync = ref.watch(shiftsProvider);

    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.tune,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Planungsoptionen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  _buildQuickActions(context),
                  const SizedBox(height: 24),

                  // Date Selection
                  _buildDateSelection(context),
                  const SizedBox(height: 24),

                  // Shift Type Filter
                  _buildShiftTypeFilter(context),
                  const SizedBox(height: 24),

                  // Employee Filter
                  employeesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text('Fehler: $error'),
                    data: (employees) => _buildEmployeeFilter(context, employees),
                  ),
                  const SizedBox(height: 24),

                  // Statistics
                  shiftsAsync.when(
                    loading: () => const SizedBox(),
                    error: (error, stack) => const SizedBox(),
                    data: (shifts) => _buildStatistics(context, shifts),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schnellaktionen',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showTemplateDialog(context),
                icon: const Icon(Symbols.content_copy, size: 18),
                label: const Text('Vorlage anwenden'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showBulkEditDialog(context),
                icon: const Icon(Symbols.edit_calendar, size: 18),
                label: const Text('Massenbearbeitung'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _clearAllFilters(),
                icon: const Icon(Symbols.filter_alt_off, size: 18),
                label: const Text('Filter zurücksetzen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datumsauswahl',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Symbols.calendar_today,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Icon(
                      Symbols.expand_more,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onDateChanged(DateTime.now()),
                    child: const Text('Heute'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onDateChanged(DateTime.now().add(const Duration(days: 1))),
                    child: const Text('Morgen'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftTypeFilter(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schichttyp',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedShiftType,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Alle Schichten')),
                DropdownMenuItem(value: 'morning', child: Text('Frühschicht')),
                DropdownMenuItem(value: 'afternoon', child: Text('Spätschicht')),
                DropdownMenuItem(value: 'evening', child: Text('Abendschicht')),
                DropdownMenuItem(value: 'night', child: Text('Nachtschicht')),
                DropdownMenuItem(value: 'weekend', child: Text('Wochenendschicht')),
                DropdownMenuItem(value: 'holiday', child: Text('Feiertagsschicht')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onShiftTypeChanged(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeFilter(BuildContext context, List<Employee> employees) {
    final activeEmployees = employees.where((e) => e.status == EmployeeStatus.active).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Mitarbeiter',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    if (selectedEmployeeIds.length == activeEmployees.length) {
                      onEmployeeSelectionChanged([]);
                    } else {
                      onEmployeeSelectionChanged(activeEmployees.map((e) => e.id).toList());
                    }
                  },
                  child: Text(
                    selectedEmployeeIds.length == activeEmployees.length ? 'Alle abwählen' : 'Alle auswählen',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${selectedEmployeeIds.length}/${activeEmployees.length} ausgewählt',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  children: activeEmployees.map((employee) {
                    final isSelected = selectedEmployeeIds.contains(employee.id);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        final newSelection = List<String>.from(selectedEmployeeIds);
                        if (value == true) {
                          newSelection.add(employee.id);
                        } else {
                          newSelection.remove(employee.id);
                        }
                        onEmployeeSelectionChanged(newSelection);
                      },
                      title: Text(
                        employee.fullName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        employee.position,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, List shifts) {
    // Filter shifts based on current view and date
    final DateTime startDate;
    final DateTime endDate;

    switch (selectedView) {
      case 'day':
        startDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'week':
        final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        endDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
        break;
      default:
        return const SizedBox();
    }

    final filteredShifts = shifts.where((shift) {
      return shift.startTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
             shift.startTime.isBefore(endDate);
    }).toList();

    final totalShifts = filteredShifts.length;
    final totalHours = filteredShifts.fold(0.0, (sum, shift) {
      final duration = shift.endTime.difference(shift.startTime);
      return sum + (duration.inMinutes / 60.0);
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiken',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              context,
              'Schichten gesamt',
              totalShifts.toString(),
              Symbols.schedule,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildStatItem(
              context,
              'Stunden gesamt',
              '${totalHours.toStringAsFixed(1)}h',
              Symbols.timer,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildStatItem(
              context,
              'Durchschnitt/Schicht',
              totalShifts > 0 ? '${(totalHours / totalShifts).toStringAsFixed(1)}h' : '0h',
              Symbols.analytics,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      onDateChanged(picked);
    }
  }

  void _showTemplateDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vorlagen-Dialog wird implementiert')),
    );
  }

  void _showBulkEditDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Massenbearbeitung wird implementiert')),
    );
  }

  void _clearAllFilters() {
    onEmployeeSelectionChanged([]);
    onShiftTypeChanged('all');
  }
}