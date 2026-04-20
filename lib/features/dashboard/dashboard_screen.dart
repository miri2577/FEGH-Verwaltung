import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../models/client.dart';
import '../../providers/client_provider.dart';
import '../../providers/dashboard_layout_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/timesheet_provider.dart';
import '../../providers/vacation_provider.dart';
import '../../services/audit_logger.dart';

/// Beschreibt eine Dashboard-Kachel. [id] ist persistenz-stabil — nicht
/// aendern, sobald Layout-Preferences gespeichert wurden.
class _Tile {
  final String id;
  final String title;
  final double height;
  final Widget Function(BuildContext, WidgetRef) build;

  const _Tile({
    required this.id,
    required this.title,
    required this.height,
    required this.build,
  });
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    final layout = ref.watch(dashboardLayoutProvider);
    final tiles = _allTiles();
    final knownIds = tiles.map((t) => t.id).toList();
    final visibleIds =
        _editMode ? layout.allIds(knownIds) : layout.visibleIds(knownIds);
    final tileById = {for (final t in tiles) t.id: t};

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 16),
            Expanded(
              child: visibleIds.isEmpty
                  ? _emptyHint(context)
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: visibleIds.length,
                      onReorder: (oldIdx, newIdx) {
                        ref
                            .read(dashboardLayoutProvider.notifier)
                            .reorder(oldIdx, newIdx, knownIds);
                      },
                      itemBuilder: (ctx, i) {
                        final id = visibleIds[i];
                        final tile = tileById[id]!;
                        final hidden = !layout.isVisible(id);
                        return _tileWrapper(
                          key: ValueKey(id),
                          index: i,
                          tile: tile,
                          hidden: hidden,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Icon(Symbols.dashboard,
            size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Text('Dashboard',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(width: 16),
        if (_editMode)
          Chip(
            avatar: const Icon(Symbols.edit, size: 16),
            label: const Text('Bearbeitungsmodus'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        const Spacer(),
        if (!_editMode)
          OutlinedButton.icon(
            onPressed: () async {
              final actions = ref.read(notificationActionsProvider);
              await actions.showSuccess(
                'Daten aktualisiert',
                'Dashboard-Daten wurden erfolgreich aktualisiert.',
              );
            },
            icon: const Icon(Symbols.refresh, size: 18),
            label: const Text('Aktualisieren'),
          ),
        if (_editMode) ...[
          TextButton.icon(
            onPressed: () async {
              final ok = await _confirmReset(context);
              if (ok == true) {
                await ref.read(dashboardLayoutProvider.notifier).reset();
              }
            },
            icon: const Icon(Symbols.restart_alt, size: 18),
            label: const Text('Zuruecksetzen'),
          ),
          const SizedBox(width: 8),
        ],
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => setState(() => _editMode = !_editMode),
          icon: Icon(_editMode ? Symbols.check : Symbols.edit, size: 18),
          label: Text(_editMode ? 'Fertig' : 'Anpassen'),
        ),
      ],
    );
  }

  Widget _tileWrapper({
    required Key key,
    required int index,
    required _Tile tile,
    required bool hidden,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Opacity(
        opacity: hidden ? 0.45 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_editMode)
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Symbols.drag_indicator,
                      color: Theme.of(context).colorScheme.outline),
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  SizedBox(height: tile.height, child: tile.build(context, ref)),
                  if (_editMode)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Material(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        child: IconButton(
                          tooltip: hidden
                              ? 'Kachel einblenden'
                              : 'Kachel ausblenden',
                          icon: Icon(hidden
                              ? Symbols.visibility
                              : Symbols.visibility_off),
                          onPressed: () => ref
                              .read(dashboardLayoutProvider.notifier)
                              .toggleVisibility(tile.id),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyHint(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.dashboard_customize,
              size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          const Text('Alle Kacheln ausgeblendet.'),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _editMode = true),
            icon: const Icon(Symbols.edit),
            label: const Text('Dashboard anpassen'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmReset(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dashboard zuruecksetzen?'),
        content: const Text(
            'Reihenfolge und Sichtbarkeit werden auf den Auslieferungs-Default zurueckgesetzt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Zuruecksetzen'),
          ),
        ],
      ),
    );
  }

  // ── Tiles ─────────────────────────────────────────────────────

  List<_Tile> _allTiles() {
    return [
      _Tile(
        id: 'kpi_employees',
        title: 'Mitarbeiter',
        height: 140,
        build: (ctx, ref) {
          final n = ref.watch(activeEmployeeCountProvider);
          return _buildKPICard(ctx, 'Mitarbeiter', '$n', Symbols.group,
              Colors.blue, 'Aktive Mitarbeiter');
        },
      ),
      _Tile(
        id: 'kpi_teams',
        title: 'Aktive Teams',
        height: 140,
        build: (ctx, ref) {
          final active = ref.watch(activeTeamCountProvider);
          final total = ref.watch(teamCountProvider);
          return _buildKPICard(ctx, 'Aktive Teams', '$active',
              Symbols.corporate_fare, Colors.green, '$total insgesamt');
        },
      ),
      _Tile(
        id: 'kpi_vacations',
        title: 'Offene Urlaube',
        height: 140,
        build: (ctx, ref) {
          final n = ref.watch(pendingApprovalCountProvider);
          return _buildKPICard(ctx, 'Offene Urlaube', '$n',
              Symbols.beach_access, Colors.orange, '$n zu genehmigen');
        },
      ),
      _Tile(
        id: 'kpi_fls',
        title: 'FLS-Auslastung',
        height: 140,
        build: (ctx, ref) {
          final clients = ref.watch(clientProvider);
          final withFls = clients
              .where((c) =>
                  c.fachleistungsstunden != null &&
                  c.fachleistungsstunden! > 0)
              .toList();
          final avg = withFls.isEmpty
              ? 0.0
              : withFls.fold<double>(
                      0, (s, c) => s + c.stundenverbrauchProzent) /
                  withFls.length;
          final color = avg > 90
              ? Colors.red
              : avg > 70
                  ? Colors.orange
                  : Colors.green;
          return _buildKPICard(ctx, 'FLS-Auslastung',
              '${avg.toStringAsFixed(0)}%', Symbols.trending_up, color,
              '${withFls.length} Klienten mit FLS');
        },
      ),
      _Tile(
        id: 'kpi_clients',
        title: 'Klienten',
        height: 140,
        build: (ctx, ref) {
          final clients = ref.watch(clientProvider);
          final active =
              clients.where((c) => c.status == ClientStatus.active).length;
          return _buildKPICard(ctx, 'Klienten', '${clients.length}',
              Symbols.people, Colors.purple, '$active aktiv');
        },
      ),
      _Tile(
        id: 'kpi_hours',
        title: 'Arbeitsstunden',
        height: 140,
        build: (ctx, ref) {
          final ts = ref.watch(timesheetDashboardProvider);
          final total =
              (ts['totalHours'] as double?)?.toStringAsFixed(0) ?? '0';
          return _buildKPICard(ctx, 'Arbeitsstunden', total,
              Symbols.schedule, Colors.teal, 'Erfasste Stunden');
        },
      ),
      _Tile(
        id: 'chart_services',
        title: 'Leistungsverteilung',
        height: 340,
        build: (ctx, ref) {
          final stats = ref.watch(serviceStatisticsProvider);
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Leistungsverteilung',
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Expanded(
                    child: stats.isEmpty
                        ? Center(
                            child: Text('Keine Daten',
                                style: TextStyle(
                                    color: Theme.of(ctx)
                                        .colorScheme
                                        .onSurfaceVariant)))
                        : _buildServiceChart(stats),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      _Tile(
        id: 'chart_fls_top',
        title: 'FLS-Verbrauch Top-Klienten',
        height: 340,
        build: (ctx, ref) {
          final clients = ref
              .watch(clientProvider)
              .where((c) =>
                  c.fachleistungsstunden != null &&
                  c.fachleistungsstunden! > 0)
              .toList()
            ..sort((a, b) => b.stundenverbrauchProzent
                .compareTo(a.stundenverbrauchProzent));
          final top = clients.take(5).toList();
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FLS-Verbrauch Top-Klienten',
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Expanded(
                    child: top.isEmpty
                        ? Center(
                            child: Text('Keine FLS-Daten',
                                style: TextStyle(
                                    color: Theme.of(ctx)
                                        .colorScheme
                                        .onSurfaceVariant)))
                        : ListView(
                            children: top
                                .map((c) => _buildFlsBar(ctx, c))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      _Tile(
        id: 'audit_activity',
        title: 'Letzte Aktivitaeten',
        height: 380,
        build: (ctx, ref) => _AuditActivityCard(),
      ),
    ];
  }

  // ── Uebernommene Helper-Methoden (unveraendert) ──────────────

  Widget _buildKPICard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceChart(Map<ServiceType, int> serviceStats) {
    final colors = {
      ServiceType.ambulant: Colors.blue,
      ServiceType.stationaer: Colors.green,
      ServiceType.beratung: Colors.orange,
      ServiceType.begleitung: Colors.purple,
      ServiceType.wohnen: Colors.teal,
      ServiceType.arbeit: Colors.red,
      ServiceType.freizeit: Colors.amber,
    };
    final labels = {
      ServiceType.ambulant: 'AMB',
      ServiceType.stationaer: 'STA',
      ServiceType.beratung: 'BER',
      ServiceType.begleitung: 'BEG',
      ServiceType.wohnen: 'WOH',
      ServiceType.arbeit: 'ARB',
      ServiceType.freizeit: 'FRZ',
    };
    final dataSource = serviceStats.entries
        .map((e) => _ServiceChartData(
              labels[e.key] ?? e.key.name,
              e.value,
              colors[e.key] ?? Colors.grey,
            ))
        .toList();

    return SfCircularChart(
      legend: const Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <DoughnutSeries<_ServiceChartData, String>>[
        DoughnutSeries<_ServiceChartData, String>(
          dataSource: dataSource,
          xValueMapper: (d, _) => d.label,
          yValueMapper: (d, _) => d.value,
          pointColorMapper: (d, _) => d.color,
          dataLabelMapper: (d, _) => '${d.label} (${d.value})',
          innerRadius: '40',
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle:
                TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildFlsBar(BuildContext context, Client c) {
    final prozent = c.stundenverbrauchProzent.clamp(0.0, 100.0);
    final color = prozent >= 90
        ? Colors.red
        : (prozent >= 70 ? Colors.orange : Colors.green);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  c.fullName,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${c.verbrauchteStunden.toStringAsFixed(0)}/${c.fachleistungsstunden} Std.  '
                '(${c.stundenverbrauchProzent.toStringAsFixed(0)} %)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prozent / 100.0,
              minHeight: 8,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceChartData {
  final String label;
  final int value;
  final Color color;
  _ServiceChartData(this.label, this.value, this.color);
}

/// Activity-Feed der letzten Audit-Log-Eintraege.
class _AuditActivityCard extends StatefulWidget {
  @override
  State<_AuditActivityCard> createState() => _AuditActivityCardState();
}

class _AuditActivityCardState extends State<_AuditActivityCard> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAuditEntries();
  }

  Future<void> _loadAuditEntries() async {
    try {
      final lines = await AuditLogger.tail(lines: 20);
      final parsed = <Map<String, dynamic>>[];
      for (final line in lines.reversed) {
        try {
          parsed.add(jsonDecode(line) as Map<String, dynamic>);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _entries = parsed.take(10).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.history,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text('Letzte Aktivitaeten',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? Center(
                          child: Text(
                            'Noch keine Aktivitaeten',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            final action = entry['action'] as String? ?? '';
                            final ctx =
                                entry['ctx'] as Map<String, dynamic>? ?? {};
                            final ts = entry['ts'] as String?;
                            return _buildAuditItem(context, action, ctx, ts);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditItem(BuildContext context, String action,
      Map<String, dynamic> ctx, String? ts) {
    final info = _auditActionInfo(action, ctx);
    final timeAgo = ts != null ? _formatTimeAgo(DateTime.tryParse(ts)) : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(info.icon, color: info.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
                if (info.subtitle.isNotEmpty)
                  Text(info.subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(timeAgo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }

  _AuditInfo _auditActionInfo(String action, Map<String, dynamic> ctx) {
    final name = ctx['name'] as String? ?? '';
    switch (action) {
      case 'client.add':
        return _AuditInfo(
            'Klient angelegt', name, Symbols.person_add, Colors.green);
      case 'client.update':
        return _AuditInfo('Klient bearbeitet', name, Symbols.edit, Colors.blue);
      case 'client.delete':
        return _AuditInfo('Klient geloescht', name, Symbols.delete, Colors.red);
      case 'employee.add':
        return _AuditInfo('Mitarbeiter angelegt', name, Symbols.person_add,
            Colors.green);
      case 'employee.update':
        return _AuditInfo(
            'Mitarbeiter bearbeitet', name, Symbols.edit, Colors.blue);
      case 'employee.delete':
        return _AuditInfo(
            'Mitarbeiter geloescht', name, Symbols.delete, Colors.red);
      case 'team.add':
        return _AuditInfo(
            'Team erstellt', name, Symbols.group_add, Colors.teal);
      case 'team.update':
        return _AuditInfo('Team bearbeitet', name, Symbols.edit, Colors.blue);
      case 'team.delete':
        return _AuditInfo('Team geloescht', name, Symbols.delete, Colors.red);
      case 'vacation.approve':
        return _AuditInfo(
            'Urlaub genehmigt', name, Symbols.check_circle, Colors.green);
      case 'vacation.reject':
        return _AuditInfo(
            'Urlaub abgelehnt', name, Symbols.cancel, Colors.red);
      case 'vacation.request':
        return _AuditInfo(
            'Urlaubsantrag', name, Symbols.beach_access, Colors.orange);
      default:
        return _AuditInfo(action, name, Symbols.info, Colors.grey);
    }
  }

  String _formatTimeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'gerade';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tag${diff.inDays > 1 ? 'en' : ''}';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}

class _AuditInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  _AuditInfo(this.title, this.subtitle, this.icon, this.color);
}
