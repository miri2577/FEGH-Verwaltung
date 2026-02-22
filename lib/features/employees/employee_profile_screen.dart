import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/employee.dart';
import '../../providers/employee_provider.dart';
import '../../providers/timesheet_provider.dart';
import 'widgets/employee_info_card.dart';
import 'widgets/employee_stats_card.dart';
import 'widgets/employee_documents_card.dart';
import 'widgets/employee_timesheet_history.dart';
import '../timesheets/widgets/timesheet_card.dart';

class EmployeeProfileScreen extends ConsumerStatefulWidget {
  final String employeeId;

  const EmployeeProfileScreen({
    super.key,
    required this.employeeId,
  });

  @override
  ConsumerState<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends ConsumerState<EmployeeProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);
    final timesheetsAsync = ref.watch(timesheetsByEmployeeProvider(widget.employeeId));

    return employeesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Fehler')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Symbols.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Fehler beim Laden: $error'),
            ],
          ),
        ),
      ),
      data: (employees) {
        final employee = employees.where((e) => e.id == widget.employeeId).firstOrNull;

        if (employee == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mitarbeiter nicht gefunden')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.person_off, size: 64),
                  SizedBox(height: 16),
                  Text('Mitarbeiter wurde nicht gefunden.'),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(employee.fullName),
            actions: [
              IconButton(
                onPressed: () => _showEditDialog(employee),
                icon: const Icon(Symbols.edit),
                tooltip: 'Bearbeiten',
              ),
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Symbols.download),
                        SizedBox(width: 8),
                        Text('Profil exportieren'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'print',
                    child: Row(
                      children: [
                        Icon(Symbols.print),
                        SizedBox(width: 8),
                        Text('Profil drucken'),
                      ],
                    ),
                  ),
                  if (employee.status == EmployeeStatus.active)
                    const PopupMenuItem(
                      value: 'deactivate',
                      child: Row(
                        children: [
                          Icon(Symbols.person_off, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Deaktivieren'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'activate',
                      child: Row(
                        children: [
                          Icon(Symbols.person_check, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Aktivieren'),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) => _handleMenuAction(value, employee),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Symbols.person), text: 'Profil'),
                Tab(icon: Icon(Symbols.analytics), text: 'Statistiken'),
                Tab(icon: Icon(Symbols.schedule), text: 'Zeiten'),
                Tab(icon: Icon(Symbols.folder), text: 'Dokumente'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(employee),
              _buildStatsTab(employee),
              _buildTimesheetsTab(employee, timesheetsAsync),
              _buildDocumentsTab(employee),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          EmployeeInfoCard(employee: employee),
          const SizedBox(height: 24),
          _buildPersonalInfoCard(employee),
          const SizedBox(height: 24),
          _buildContractInfoCard(employee),
        ],
      ),
    );
  }

  Widget _buildStatsTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          EmployeeStatsCard(employee: employee),
          const SizedBox(height: 24),
          _buildPerformanceCard(employee),
          const SizedBox(height: 24),
          _buildAttendanceCard(employee),
        ],
      ),
    );
  }

  Widget _buildTimesheetsTab(Employee employee, AsyncValue timesheetsAsync) {
    return timesheetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Fehler beim Laden der Zeitnachweise: $error'),
          ],
        ),
      ),
      data: (timesheets) => EmployeeTimesheetHistory(
        employee: employee,
        timesheets: timesheets,
      ),
    );
  }

  Widget _buildDocumentsTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          EmployeeDocumentsCard(employee: employee),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(Employee employee) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.badge, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Persönliche Informationen',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Mitarbeiter-ID', employee.id),
            _buildInfoRow('Telefon', employee.phone ?? 'Nicht angegeben'),
            _buildInfoRow('E-Mail', employee.email),
            _buildInfoRow('Geburtsdatum', employee.dateOfBirth != null
                ? '${employee.dateOfBirth!.day}.${employee.dateOfBirth!.month}.${employee.dateOfBirth!.year}'
                : 'Nicht angegeben'),
            _buildInfoRow('Adresse', employee.address.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildContractInfoCard(Employee employee) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.work, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Vertragsinformationen',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Position', employee.position),
            _buildInfoRow('Abteilung', employee.department),
            _buildInfoRow('Stundenlohn', '${employee.hourlyRate.toStringAsFixed(2)} €'),
            _buildInfoRow('Einstellungsdatum',
                '${employee.hireDate.day}.${employee.hireDate.month}.${employee.hireDate.year}'),
            _buildInfoRow('Status', employee.statusLabel),
            _buildInfoRow('Wochenarbeitszeit', '${employee.contractualHours} Stunden'),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(Employee employee) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.trending_up, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Leistungsübersicht',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Durchschnittliche Arbeitszeit',
                    '38.5h',
                    'pro Woche',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    'Überstunden',
                    '12.5h',
                    'diesen Monat',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Pünktlichkeit',
                    '96%',
                    'letzte 30 Tage',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    'Anwesenheit',
                    '22/23',
                    'Arbeitstage',
                    Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(Employee employee) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.calendar_month, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Anwesenheitskalender',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Symbols.calendar_view_month,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Anwesenheitskalender wird hier angezeigt',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Employee employee) {
    // TODO: Implement employee edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bearbeitung wird implementiert')),
    );
  }

  void _handleMenuAction(String action, Employee employee) {
    switch (action) {
      case 'export':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export-Funktion wird implementiert')),
        );
        break;
      case 'print':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Druck-Funktion wird implementiert')),
        );
        break;
      case 'activate':
      case 'deactivate':
        _toggleEmployeeStatus(employee);
        break;
    }
  }

  void _toggleEmployeeStatus(Employee employee) {
    final newStatus = employee.status == EmployeeStatus.active
        ? EmployeeStatus.inactive
        : EmployeeStatus.active;

    final updatedEmployee = employee.copyWith(status: newStatus);
    ref.read(employeesProvider.notifier).updateEmployee(updatedEmployee);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == EmployeeStatus.active
              ? 'Mitarbeiter wurde aktiviert'
              : 'Mitarbeiter wurde deaktiviert'
        ),
      ),
    );
  }
}