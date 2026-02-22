import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/employee.dart';
import '../../providers/employee_provider.dart';
import 'widgets/employee_list_view.dart';
import 'widgets/employee_form_dialog.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsyncValue = ref.watch(employeesProvider);
    final activeEmployeeCount = ref.watch(activeEmployeeCountProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.person,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  'Mitarbeiterverwaltung',
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
                    '$activeEmployeeCount aktiv',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _refreshEmployees(ref),
                  icon: const Icon(Symbols.refresh, size: 18),
                  label: const Text('Aktualisieren'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _showAddEmployeeDialog(context, ref),
                  icon: const Icon(Symbols.person_add, size: 18),
                  label: const Text('Neuer Mitarbeiter'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: employeesAsyncValue.when(
                data: (employees) => employees.isEmpty
                    ? _buildEmptyState(context)
                    : EmployeeListView(employees: employees),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => _buildErrorState(context, error, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.person_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Mitarbeiter vorhanden',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Fügen Sie den ersten Mitarbeiter hinzu, um zu beginnen.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
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
            'Fehler beim Laden der Mitarbeiter',
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
            onPressed: () => _refreshEmployees(ref),
            icon: const Icon(Symbols.refresh, size: 18),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  void _refreshEmployees(WidgetRef ref) {
    ref.read(employeesProvider.notifier).refresh();
  }

  void _showAddEmployeeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => EmployeeFormDialog(
        onSave: (employee) async {
          await ref.read(employeesProvider.notifier).addEmployee(employee);
        },
      ),
    );
  }
}