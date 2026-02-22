import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../models/team.dart';
import '../../../providers/policy_provider.dart';
import '../../../providers/team_provider.dart';
import '../../../providers/employee_provider.dart';
import 'team_card.dart';
import 'team_form_dialog.dart';

class TeamListView extends ConsumerStatefulWidget {
  final List<Team> teams;
  final bool isTableView;

  const TeamListView({super.key, required this.teams, this.isTableView = false});

  @override
  ConsumerState<TeamListView> createState() => _TeamListViewState();
}

class _TeamListViewState extends ConsumerState<TeamListView> {
  String _searchQuery = '';
  TeamStatus? _statusFilter;
  String? _departmentFilter;

  @override
  Widget build(BuildContext context) {
    final filteredTeams = _filterTeams(widget.teams);

    return Column(
      children: [
        _buildFilters(),
        const SizedBox(height: 16),
        Expanded(
          child: filteredTeams.isEmpty
              ? _buildNoResultsState()
              : widget.isTableView
                  ? _buildTeamTable(filteredTeams)
                  : _buildTeamGrid(filteredTeams),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final departments = widget.teams
        .where((t) => t.department != null)
        .map((t) => t.department!)
        .toSet()
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Teams suchen...',
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
            DropdownButton<TeamStatus?>(
              value: _statusFilter,
              hint: const Text('Status'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Alle Status')),
                ...TeamStatus.values.map(
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
            if (departments.isNotEmpty) ...[
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
          ],
        ),
      ),
    );
  }

  Widget _buildTeamGrid(List<Team> teams) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        final canManage = ref.read(policyProvider).canManageTeams();
        return TeamCard(
          team: team,
          onTap: () => _showTeamDetails(team),
          onEdit: canManage ? () => _showEditTeamDialog(team) : null,
          onDelete: canManage ? () => _showDeleteConfirmation(team) : null,
        );
      },
    );
  }

  Widget _buildTeamTable(List<Team> teams) {
    final canManage = ref.read(policyProvider).canManageTeams();
    final dataSource = _TeamDataSource(
      teams: teams,
      canManage: canManage,
      getStatusLabel: _getStatusLabel,
      onEdit: _showEditTeamDialog,
      onDelete: _showDeleteConfirmation,
    );
    return SfDataGrid(
      source: dataSource,
      columnWidthMode: ColumnWidthMode.fill,
      gridLinesVisibility: GridLinesVisibility.horizontal,
      headerGridLinesVisibility: GridLinesVisibility.horizontal,
      rowHeight: 48,
      headerRowHeight: 40,
      columns: [
        GridColumn(columnName: 'team', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Team', style: TextStyle(fontWeight: FontWeight.bold)))),
        GridColumn(columnName: 'abteilung', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Abteilung', style: TextStyle(fontWeight: FontWeight.bold)))),
        GridColumn(columnName: 'status', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold))), minimumWidth: 80, maximumWidth: 120),
        GridColumn(columnName: 'mitglieder', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerRight, child: const Text('Mitglieder', style: TextStyle(fontWeight: FontWeight.bold))), minimumWidth: 80, maximumWidth: 110),
        GridColumn(columnName: 'standort', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Standort', style: TextStyle(fontWeight: FontWeight.bold)))),
        GridColumn(columnName: 'aktionen', label: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: const Text('Aktionen', style: TextStyle(fontWeight: FontWeight.bold))), minimumWidth: 100, maximumWidth: 120),
      ],
      onCellTap: (details) {
        if (details.rowColumnIndex.rowIndex > 0) {
          final index = details.rowColumnIndex.rowIndex - 1;
          if (index < teams.length) _showTeamDetails(teams[index]);
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
            Symbols.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Teams gefunden',
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

  List<Team> _filterTeams(List<Team> teams) {
    return teams.where((team) {
      final matchesSearch = _searchQuery.isEmpty ||
          team.name.toLowerCase().contains(_searchQuery) ||
          team.description.toLowerCase().contains(_searchQuery);

      final matchesStatus = _statusFilter == null || team.status == _statusFilter;

      final matchesDepartment = _departmentFilter == null || team.department == _departmentFilter;

      return matchesSearch && matchesStatus && matchesDepartment;
    }).toList();
  }

  String _getStatusLabel(TeamStatus status) {
    switch (status) {
      case TeamStatus.active:
        return 'Aktiv';
      case TeamStatus.inactive:
        return 'Inaktiv';
      case TeamStatus.onHold:
        return 'Pausiert';
    }
  }

  void _showTeamDetails(Team team) {
    final employeesAsync = ref.read(employeesProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(team.name),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Beschreibung: ${team.description}'),
              if (team.department != null) Text('Abteilung: ${team.department}'),
              Text('Status: ${_getStatusLabel(team.status)}'),
              Text('Mitglieder: ${team.memberCount}'),
              if (team.location != null) Text('Standort: ${team.location}'),
              if (team.budget != null)
                Text('Budget: €${team.budget!.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              if (team.memberIds.isNotEmpty) ...[
                Text('Team-Mitglieder:',
                  style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ...employeesAsync.when(
                  data: (employees) => team.memberIds.map((memberId) {
                    final employee = employees.where((e) => e.id == memberId).firstOrNull;
                    return employee != null
                        ? Text('• ${employee.fullName}')
                        : Text('• Mitarbeiter ID: $memberId');
                  }).toList(),
                  loading: () => [const Text('Lade Mitglieder...')],
                  error: (_, __) => [const Text('Fehler beim Laden der Mitglieder')],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditTeamDialog(team);
            },
            child: const Text('Bearbeiten'),
          ),
        ],
      ),
    );
  }

  void _showEditTeamDialog(Team team) {
    showDialog(
      context: context,
      builder: (context) => TeamFormDialog(
        team: team,
        onSave: (updatedTeam) async {
          await ref.read(teamsProvider.notifier).updateTeam(updatedTeam);
        },
      ),
    );
  }

  void _showDeleteConfirmation(Team team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Team löschen'),
        content: Text(
          'Möchten Sie das Team "${team.name}" wirklich löschen? '
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
              await ref.read(teamsProvider.notifier).deleteTeam(team.id);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

class _TeamDataSource extends DataGridSource {
  final List<Team> teams;
  final bool canManage;
  final String Function(TeamStatus) getStatusLabel;
  final void Function(Team) onEdit;
  final void Function(Team) onDelete;

  _TeamDataSource({required this.teams, required this.canManage, required this.getStatusLabel, required this.onEdit, required this.onDelete});

  @override
  List<DataGridRow> get rows => teams.map((team) => DataGridRow(cells: [
    DataGridCell<String>(columnName: 'team', value: team.name),
    DataGridCell<String>(columnName: 'abteilung', value: team.department ?? '-'),
    DataGridCell<String>(columnName: 'status', value: getStatusLabel(team.status)),
    DataGridCell<int>(columnName: 'mitglieder', value: team.memberCount),
    DataGridCell<String>(columnName: 'standort', value: team.location ?? '-'),
    DataGridCell<Team>(columnName: 'aktionen', value: team),
  ])).toList();

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(cells: row.getCells().map((cell) {
      if (cell.columnName == 'aktionen') {
        final team = cell.value as Team;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.centerLeft,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (canManage) IconButton(icon: const Icon(Symbols.edit, size: 18), onPressed: () => onEdit(team), tooltip: 'Bearbeiten', visualDensity: VisualDensity.compact),
            if (canManage) IconButton(icon: const Icon(Symbols.delete, size: 18), onPressed: () => onDelete(team), tooltip: 'Löschen', visualDensity: VisualDensity.compact),
          ]),
        );
      }
      if (cell.columnName == 'mitglieder') {
        return Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerRight, child: Text('${cell.value}'));
      }
      return Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: Text(cell.value?.toString() ?? '-', overflow: TextOverflow.ellipsis));
    }).toList());
  }
}
