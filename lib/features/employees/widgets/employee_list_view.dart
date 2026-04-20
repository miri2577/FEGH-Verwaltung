import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../models/employee.dart';
import '../../../providers/employee_provider.dart';
import 'employee_card.dart';
import 'employee_form_dialog.dart';
import '../employee_profile_screen.dart';

class EmployeeListView extends ConsumerStatefulWidget {
  final List<Employee> employees;
  final bool isTableView;

  const EmployeeListView({super.key, required this.employees, this.isTableView = false});

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
              : widget.isTableView
                  ? _buildEmployeeTable(filteredEmployees)
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
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        mainAxisExtent: 240,
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

  Widget _buildEmployeeTable(List<Employee> employees) {
    final dataSource = _EmployeeDataSource(
      employees: employees,
      getStatusLabel: _getStatusLabel,
      onEdit: _showEditEmployeeDialog,
      onDelete: _showDeleteConfirmation,
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
        GridColumn(columnName: 'name', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)))),
        GridColumn(columnName: 'nr', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Nr.', style: TextStyle(fontWeight: FontWeight.bold))), minimumWidth: 70, maximumWidth: 100),
        GridColumn(columnName: 'position', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Position', style: TextStyle(fontWeight: FontWeight.bold)))),
        GridColumn(columnName: 'abteilung', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Abteilung', style: TextStyle(fontWeight: FontWeight.bold)))),
        GridColumn(columnName: 'status', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold))), minimumWidth: 80, maximumWidth: 110),
        GridColumn(columnName: 'stunden', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerRight, child: const Text('Std/Woche', style: TextStyle(fontWeight: FontWeight.bold))), minimumWidth: 80, maximumWidth: 110),
        GridColumn(columnName: 'lohn', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerRight, child: const Text('Stundenlohn', style: TextStyle(fontWeight: FontWeight.bold))), minimumWidth: 90, maximumWidth: 120),
        GridColumn(columnName: 'aktionen', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Aktionen', style: TextStyle(fontWeight: FontWeight.bold))), minimumWidth: 100, maximumWidth: 120),
      ],
      onCellTap: (details) {
        if (details.rowColumnIndex.rowIndex > 0) {
          final index = details.rowColumnIndex.rowIndex - 1;
          if (index < employees.length) _showEmployeeDetails(employees[index]);
        }
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
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditEmployeeDialog(employee);
            },
            child: const Text('Bearbeiten'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EmployeeProfileScreen(employeeId: employee.id),
                ),
              );
            },
            child: const Text('Profil öffnen'),
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

class _EmployeeDataSource extends DataGridSource {
  final List<Employee> employees;
  final String Function(EmployeeStatus) getStatusLabel;
  final void Function(Employee) onEdit;
  final void Function(Employee) onDelete;

  _EmployeeDataSource({required this.employees, required this.getStatusLabel, required this.onEdit, required this.onDelete});

  @override
  List<DataGridRow> get rows => employees.map((e) => DataGridRow(cells: [
    DataGridCell<String>(columnName: 'name', value: e.fullName),
    DataGridCell<String>(columnName: 'nr', value: e.employeeNumber),
    DataGridCell<String>(columnName: 'position', value: e.position),
    DataGridCell<String>(columnName: 'abteilung', value: e.department),
    DataGridCell<String>(columnName: 'status', value: getStatusLabel(e.status)),
    DataGridCell<double>(columnName: 'stunden', value: e.hoursPerWeek),
    DataGridCell<double>(columnName: 'lohn', value: e.hourlyRate),
    DataGridCell<Employee>(columnName: 'aktionen', value: e),
  ])).toList();

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(cells: row.getCells().map((cell) {
      if (cell.columnName == 'aktionen') {
        final emp = cell.value as Employee;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.centerLeft,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Symbols.edit, size: 18), onPressed: () => onEdit(emp), tooltip: 'Bearbeiten', visualDensity: VisualDensity.compact),
            IconButton(icon: const Icon(Symbols.delete, size: 18), onPressed: () => onDelete(emp), tooltip: 'Löschen', visualDensity: VisualDensity.compact),
          ]),
        );
      }
      if (cell.columnName == 'stunden') {
        return Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerRight, child: Text('${cell.value}'));
      }
      if (cell.columnName == 'lohn') {
        return Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerRight, child: Text('${(cell.value as double).toStringAsFixed(2)} \u20AC'));
      }
      return Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: Text(cell.value?.toString() ?? '-', overflow: TextOverflow.ellipsis));
    }).toList());
  }
}