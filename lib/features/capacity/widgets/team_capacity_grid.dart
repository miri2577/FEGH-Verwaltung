import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../providers/capacity_provider.dart';
import '../../../models/capacity_analytics.dart';

class TeamCapacityGrid extends ConsumerWidget {
  const TeamCapacityGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamCapacitiesAsync = ref.watch(teamCapacitiesProvider);

    return teamCapacitiesAsync.when(
      data: (teamCapacities) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Team-Kapazitäten',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildFilterChips(context, ref),
            ],
          ),
          const SizedBox(height: 16),
          if (teamCapacities.isEmpty)
            _buildEmptyState(context)
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: teamCapacities.length,
                itemBuilder: (context, index) {
                  return TeamCapacityCard(capacity: teamCapacities[index]);
                },
              ),
            ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.error,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Fehler beim Laden der Team-Daten'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.invalidate(teamCapacitiesProvider),
              child: const Text('Erneut laden'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('Alle'),
          selected: true,
          onSelected: (selected) {
            // TODO: Implement filtering
          },
        ),
        FilterChip(
          label: const Text('Kritisch'),
          selected: false,
          onSelected: (selected) {
            // TODO: Filter by critical status
          },
        ),
        FilterChip(
          label: const Text('Unterbesetzt'),
          selected: false,
          onSelected: (selected) {
            // TODO: Filter by understaffed status
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.corporate_fare,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Teams gefunden',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Erstellen Sie Teams, um Kapazitätsanalysen zu sehen.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class TeamCapacityCard extends StatelessWidget {
  final TeamCapacity capacity;

  const TeamCapacityCard({super.key, required this.capacity});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.corporate_fare,
                  size: 20,
                  color: _getStatusColor(capacity.status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    capacity.teamName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCapacityIndicator(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Verfügbar',
                    '${capacity.availableStaff}',
                    Symbols.person,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Benötigt',
                    '${capacity.requiredStaff}',
                    Symbols.group,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Aktiv',
                    '${capacity.activeStaff}',
                    Symbols.person_check,
                  ),
                ),
              ],
            ),
            if (capacity.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildWarnings(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final color = _getStatusColor(capacity.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        capacity.statusLabel,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCapacityIndicator(BuildContext context) {
    final percentage = capacity.capacityPercentage.clamp(0, 150);
    final color = _getStatusColor(capacity.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kapazität',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (percentage / 100).clamp(0, 1),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
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

  Widget _buildWarnings(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.warning,
            size: 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              capacity.warnings.first,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange[800],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (capacity.warnings.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${capacity.warnings.length - 1}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(CapacityStatus status) {
    switch (status) {
      case CapacityStatus.optimal:
        return Colors.green;
      case CapacityStatus.understaffed:
        return Colors.orange;
      case CapacityStatus.overstaffed:
        return Colors.blue;
      case CapacityStatus.critical:
        return Colors.red;
    }
  }
}