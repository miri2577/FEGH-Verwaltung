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

/// IDs fuer Sichtbarkeits-Persistenz — nicht umbenennen.
const _chartServicesId = 'chart_services';
const _chartFlsId = 'chart_fls_top';
const _auditId = 'audit_activity';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 16),
            _kpiRow(context),
            const SizedBox(height: 16),
            _chartsRow(context),
            const SizedBox(height: 16),
            _auditRow(context),
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
            size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text('Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        if (_editMode) ...[
          const SizedBox(width: 12),
          Chip(
            avatar: const Icon(Symbols.edit, size: 16),
            label: const Text('Bearbeitungsmodus'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        ],
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

  // ── KPI-Zeile: kompakte uniforme Cards, responsive via Wrap ──

  Widget _kpiRow(BuildContext context) {
    final layout = ref.watch(dashboardLayoutProvider);
    final kpis = _kpiTiles();
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final columns = constraints.maxWidth >= 1400
            ? 6
            : constraints.maxWidth >= 1050
                ? 4
                : constraints.maxWidth >= 700
                    ? 3
                    : 2;
        const spacing = 12.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final k in kpis)
              if (_editMode || layout.isVisible(k.id))
                SizedBox(
                  width: tileWidth,
                  height: 110,
                  child: _hideableCard(
                    id: k.id,
                    hidden: !layout.isVisible(k.id),
                    child: k.card,
                  ),
                ),
          ],
        );
      },
    );
  }

  // ── Charts-Zeile (2:3) ────────────────────────────────────────

  Widget _chartsRow(BuildContext context) {
    final layout = ref.watch(dashboardLayoutProvider);
    final flsVisible = _editMode || layout.isVisible(_chartFlsId);
    final servicesVisible = _editMode || layout.isVisible(_chartServicesId);
    if (!flsVisible && !servicesVisible) return const SizedBox.shrink();

    return SizedBox(
      height: 340,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (servicesVisible)
            Expanded(
              flex: 3,
              child: _hideableCard(
                id: _chartServicesId,
                hidden: !layout.isVisible(_chartServicesId),
                child: _servicesCard(context),
              ),
            ),
          if (servicesVisible && flsVisible) const SizedBox(width: 16),
          if (flsVisible)
            Expanded(
              flex: 2,
              child: _hideableCard(
                id: _chartFlsId,
                hidden: !layout.isVisible(_chartFlsId),
                child: _flsTopCard(context),
              ),
            ),
        ],
      ),
    );
  }

  // ── Audit-Zeile (full width) ──────────────────────────────────

  Widget _auditRow(BuildContext context) {
    final layout = ref.watch(dashboardLayoutProvider);
    if (!_editMode && !layout.isVisible(_auditId)) return const SizedBox.shrink();
    return SizedBox(
      height: 340,
      child: _hideableCard(
        id: _auditId,
        hidden: !layout.isVisible(_auditId),
        child: _AuditActivityCard(),
      ),
    );
  }

  // ── Kachel-Wrapper mit Visibility-Overlay im Edit-Mode ───────

  Widget _hideableCard({
    required String id,
    required bool hidden,
    required Widget child,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(opacity: hidden ? 0.4 : 1.0, child: child),
        if (_editMode)
          Positioned(
            right: 4,
            top: 4,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              child: IconButton(
                tooltip:
                    hidden ? 'Kachel einblenden' : 'Kachel ausblenden',
                icon: Icon(
                    hidden ? Symbols.visibility : Symbols.visibility_off,
                    size: 18),
                onPressed: () => ref
                    .read(dashboardLayoutProvider.notifier)
                    .toggleVisibility(id),
              ),
            ),
          ),
      ],
    );
  }

  Future<bool?> _confirmReset(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dashboard zuruecksetzen?'),
        content: const Text(
            'Sichtbarkeit und Reihenfolge werden auf den Auslieferungs-Default zurueckgesetzt.'),
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

  // ── KPI-Definitionen ─────────────────────────────────────────

  List<_KpiDef> _kpiTiles() {
    final nEmp = ref.watch(activeEmployeeCountProvider);
    final teamsActive = ref.watch(activeTeamCountProvider);
    final teamsTotal = ref.watch(teamCountProvider);
    final vacPending = ref.watch(pendingApprovalCountProvider);
    final clients = ref.watch(clientProvider);
    final ts = ref.watch(timesheetDashboardProvider);

    final withFls = clients
        .where((c) =>
            c.fachleistungsstunden != null && c.fachleistungsstunden! > 0)
        .toList();
    final flsAvg = withFls.isEmpty
        ? 0.0
        : withFls.fold<double>(0, (s, c) => s + c.stundenverbrauchProzent) /
            withFls.length;
    final flsColor = flsAvg > 90
        ? Colors.red
        : flsAvg > 70
            ? Colors.orange
            : Colors.green;
    final activeClients =
        clients.where((c) => c.status == ClientStatus.active).length;
    final totalHours =
        (ts['totalHours'] as double?)?.toStringAsFixed(0) ?? '0';

    return [
      _KpiDef('kpi_employees', _buildKpiCard('Mitarbeiter', '$nEmp',
          Symbols.group, Colors.blue, 'aktiv')),
      _KpiDef('kpi_teams', _buildKpiCard('Aktive Teams', '$teamsActive',
          Symbols.corporate_fare, Colors.green, '$teamsTotal gesamt')),
      _KpiDef('kpi_vacations', _buildKpiCard('Urlaubsantraege',
          '$vacPending', Symbols.beach_access, Colors.orange, 'offen')),
      _KpiDef('kpi_fls', _buildKpiCard('FLS-Auslastung',
          '${flsAvg.toStringAsFixed(0)}%', Symbols.trending_up, flsColor,
          '${withFls.length} mit FLS')),
      _KpiDef('kpi_clients', _buildKpiCard('Klienten',
          '${clients.length}', Symbols.people, Colors.purple,
          '$activeClients aktiv')),
      _KpiDef('kpi_hours', _buildKpiCard('Arbeitsstunden', totalHours,
          Symbols.schedule, Colors.teal, 'erfasst')),
    ];
  }

  // Kompakte KPI-Karte (110 px Hoehe). Einheitliche Typografie.
  Widget _buildKpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.0,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Charts ───────────────────────────────────────────────────

  Widget _servicesCard(BuildContext context) {
    final stats = ref.watch(serviceStatisticsProvider);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leistungsverteilung',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            Expanded(
              child: stats.isEmpty
                  ? Center(
                      child: Text('Keine Daten',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)))
                  : _buildServiceChart(stats),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flsTopCard(BuildContext context) {
    final clients = ref
        .watch(clientProvider)
        .where((c) =>
            c.fachleistungsstunden != null && c.fachleistungsstunden! > 0)
        .toList()
      ..sort((a, b) =>
          b.stundenverbrauchProzent.compareTo(a.stundenverbrauchProzent));
    final top = clients.take(5).toList();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FLS Top-Klienten',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            Expanded(
              child: top.isEmpty
                  ? Center(
                      child: Text('Keine FLS-Daten',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)))
                  : ListView(
                      children: top
                          .map((c) => _buildFlsBar(context, c))
                          .toList(),
                    ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                '${c.verbrauchteStunden.toStringAsFixed(0)}/${c.fachleistungsstunden} (${c.stundenverbrauchProzent.toStringAsFixed(0)}%)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prozent / 100.0,
              minHeight: 6,
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

class _KpiDef {
  final String id;
  final Widget card;
  const _KpiDef(this.id, this.card);
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.history,
                    color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Letzte Aktivitaeten',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
              ],
            ),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(info.icon, color: info.color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
                if (info.subtitle.isNotEmpty)
                  Text(info.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      overflow: TextOverflow.ellipsis),
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
