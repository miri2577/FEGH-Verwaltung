import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/team.dart';
import '../../providers/policy_provider.dart';
import '../../providers/team_provider.dart';
import 'widgets/team_list_view.dart';
import 'widgets/team_form_dialog.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  bool _isTableView = false;

  @override
  Widget build(BuildContext context) {
    final teamsAsyncValue = ref.watch(teamsProvider);
    final teamCount = ref.watch(teamCountProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.corporate_fare,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  'Teams & Abteilungen',
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
                    '$teamCount Teams',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, icon: Icon(Symbols.grid_view, size: 18)),
                    ButtonSegment(value: true, icon: Icon(Symbols.table_rows, size: 18)),
                  ],
                  selected: {_isTableView},
                  onSelectionChanged: (value) {
                    setState(() {
                      _isTableView = value.first;
                    });
                  },
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _refreshTeams(),
                  icon: const Icon(Symbols.refresh, size: 18),
                  label: const Text('Aktualisieren'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: ref.read(policyProvider).canManageTeams()
                      ? () => _showAddTeamDialog()
                      : null,
                  icon: const Icon(Symbols.add, size: 18),
                  label: const Text('Neues Team'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: teamsAsyncValue.when(
                data: (teams) => teams.isEmpty
                    ? _buildEmptyState()
                    : TeamListView(teams: teams, isTableView: _isTableView),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => _buildErrorState(error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.group_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Teams vorhanden',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Erstellen Sie das erste Team, um zu beginnen.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
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
            'Fehler beim Laden der Teams',
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
            onPressed: () => _refreshTeams(),
            icon: const Icon(Symbols.refresh, size: 18),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  void _refreshTeams() {
    ref.read(teamsProvider.notifier).refresh();
  }

  void _showAddTeamDialog() {
    showDialog(
      context: context,
      builder: (context) => TeamFormDialog(
        onSave: (team) async {
          await ref.read(teamsProvider.notifier).addTeam(team);
        },
      ),
    );
  }
}
