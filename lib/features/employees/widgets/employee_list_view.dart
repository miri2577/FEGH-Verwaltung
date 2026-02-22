import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/employee.dart';
import '../../../providers/employee_provider.dart';
import 'employee_card.dart';
import 'employee_form_dialog.dart';

class EmployeeListView extends ConsumerStatefulWidget {
  final List<Employee> employees;

  const EmployeeListView({super.key, required this.employees});

  @override
  ConsumerState<EmployeeListView> createState() => _EmployeeListViewState();
}

class _EmployeeListViewState extends ConsumerState<EmployeeListView> {
  String _searchQuery = '';
  EmployeeStatus? _statusFilter;
  String? _departmentFilter;

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = _filterEmployees(widget.employees);

    return Column(
      children: [
        _buildFilters(),
        const SizedBox(height: 16),
        Expanded(
          child: filteredEmployees.isEmpty
              ? _buildNoResultsState()
              : _buildEmployeeGrid(filteredEmployees),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final departments = widget.employees.map((e) => e.department).toSet().toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Mitarbeiter suchen...',
                  prefixIcon: const Icon(Symbols.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<EmployeeStatus?>(
              value: _statusFilter,
              hint: const Text('Status'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Alle Status')),
                ...EmployeeStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(_getStatusLabel(status)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _statusFilter = value;
                });
              },
            ),
            const SizedBox(width: 16),
            DropdownButton<String?>(
              value: _departmentFilter,
              hint: const Text('Abteilung'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Alle Abteilungen')),
                ...departments.map(
                  (dept) => DropdownMenuItem(
                    value: dept,
                    child: Text(dept),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _departmentFilter = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeGrid(List<Employee> employees) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return EmployeeCard(
          employee: employee,
          onTap: () => _showEmployeeDetails(employee),
          onEdit: () => _showEditEmployeeDialog(employee),
          onDelete: () => _showDeleteConfirmation(employee),
        );
      },
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.person_search,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Mitarbeiter gefunden',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Versuchen Sie andere Suchkriterien.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<Employee> _filterEmployees(List<Employee> employees) {
    return employees.where((employee) {
      final matchesSearch = _searchQuery.isEmpty ||
          employee.fullName.toLowerCase().contains(_searchQuery) ||
          employee.email.toLowerCase().contains(_searchQuery) ||
          employee.employeeNumber.toLowerCase().contains(_searchQuery);

      final matchesStatus = _statusFilter == null || employee.status == _statusFilter;

      final matchesDepartment = _departmentFilter == null || employee.department == _departmentFilter;

      return matchesSearch && matchesStatus && matchesDepartment;
    }).toList();
  }

  String _getStatusLabel(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.active:
        return 'Aktiv';
      case EmployeeStatus.inactive:
        return 'Inaktiv';
      case EmployeeStatus.onLeave:
        return 'Beurlaubt';
      case EmployeeStatus.terminated:
        return 'Gekündigt';
    }
  }

  void _showEmployeeDetails(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(employee.fullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mitarbeiternummer: ${employee.employeeNumber}'),
            Text('E-Mail: ${employee.email}'),
            Text('Abteilung: ${employee.department}'),
            Text('Position: ${employee.position}'),
            Text('Status: ${_getStatusLabel(employee.status)}'),
            Text('Stunden/Woche: ${employee.hoursPerWeek}'),
            Text('Stundenlohn: €${employee.hourlyRate.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditEmployeeDialog(employee);
            },
            child: const Text('Bearbeiten'),
          ),
        ],
      ),
    );
  }

  void _showEditEmployeeDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => EmployeeFormDialog(
        employee: employee,
        onSave: (updatedEmployee) async {
          await ref.read(employeesProvider.notifier).updateEmployee(updatedEmployee);
        },
      ),
    );
  }

  void _showDeleteConfirmation(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mitarbeiter löschen'),
        content: Text(
          'Möchten Sie den Mitarbeiter "${employee.fullName}" wirklich löschen? '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
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
              await ref.read(employeesProvider.notifier).deleteEmployee(employee.id);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}