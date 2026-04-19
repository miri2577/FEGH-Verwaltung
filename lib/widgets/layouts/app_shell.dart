import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../features/notifications/widgets/notification_bell.dart';
import '../../navigation/nav_registry.dart';
import '../../providers/policy_provider.dart';
import '../../services/policy_service.dart';

/// Neue Haupt-Shell: NavigationRail links, AppBar oben, Content rechts.
///
/// Ersetzt die fruehere TabBar-basierte `MainLayout`. Sichtbarkeit der
/// Eintraege richtet sich nach der aktuellen Rolle aus [PolicyService].
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final policy = ref.watch(policyProvider);
    final role = policy.role;
    final grouped = visibleEntriesGrouped(role);
    final flat = grouped.values.expand((e) => e).toList();

    // Default-Auswahl bei erstem Build
    _selectedId ??= defaultEntryFor(role)?.id;
    // Wenn die Rolle die aktuelle Auswahl nicht mehr zulaesst, zurueck zum Default.
    final current = flat.firstWhere(
      (e) => e.id == _selectedId,
      orElse: () => flat.first,
    );
    _selectedId = current.id;

    final theme = Theme.of(context);
    final narrow = MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Symbols.business, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 12),
            Text(
              'FEGH-Verwaltung',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              current.label,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onPrimary.withOpacity(0.7),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'Suche (folgt)',
            icon: const Icon(Symbols.search),
          ),
          NotificationBell(iconColor: theme.colorScheme.onPrimary),
          const SizedBox(width: 4),
          _roleBadge(theme, role),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NavigationRailColumn(
            grouped: grouped,
            selectedId: _selectedId!,
            onSelect: (id) => setState(() => _selectedId = id),
            extended: !narrow,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: current.builder(context),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(ThemeData theme, UserRole role) {
    final label = _roleLabel(role);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Chip(
        visualDensity: VisualDensity.compact,
        label: Text(label, style: const TextStyle(fontSize: 11)),
        backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.1),
        labelStyle: TextStyle(color: theme.colorScheme.onPrimary),
        side: BorderSide(
          color: theme.colorScheme.onPrimary.withOpacity(0.3),
        ),
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.orgAdmin:
        return 'Org-Admin';
      case UserRole.pvAdmin:
        return 'PV-Admin';
      case UserRole.teamLead:
        return 'Team-Leitung';
      case UserRole.teamMember:
        return 'Mitarbeiter';
      case UserRole.orgAuditor:
        return 'Auditor';
    }
  }
}

/// Die eigentliche Rail. Gruppen als kleine Caps-Header, darunter die
/// Icon+Label-Eintraege der jeweiligen Sektion.
class _NavigationRailColumn extends StatelessWidget {
  final Map<NavSection, List<NavEntry>> grouped;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final bool extended;

  const _NavigationRailColumn({
    required this.grouped,
    required this.selectedId,
    required this.onSelect,
    required this.extended,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = extended ? 220.0 : 72.0;

    return Container(
      width: width,
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final section in NavSection.values)
                if (grouped.containsKey(section)) ...[
                  if (extended)
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 20, 6),
                      child: Text(
                        section.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                  ...grouped[section]!.map(
                    (e) => _RailItem(
                      entry: e,
                      selected: e.id == selectedId,
                      extended: extended,
                      onTap: () => onSelect(e.id),
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final NavEntry entry;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  const _RailItem({
    required this.entry,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = selected ? theme.colorScheme.primaryContainer : Colors.transparent;
    final fg = selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    final child = extended
        ? Row(
            children: [
              const SizedBox(width: 20),
              Icon(entry.icon, size: 20, color: fg),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  entry.label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(entry.icon, size: 22, color: fg),
              const SizedBox(height: 4),
              Text(
                entry.label.split(' ').first,
                style: TextStyle(color: fg, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

    return InkWell(
      onTap: onTap,
      child: Container(
        height: extended ? 40 : 56,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
    );
  }
}
