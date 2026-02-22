import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/notification_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/vacation_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/timesheet_provider.dart';
import '../../models/client.dart';
import '../../services/audit_logger.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeCount = ref.watch(activeEmployeeCountProvider);
    final teamCount = ref.watch(activeTeamCountProvider);
    final pendingVacations = ref.watch(pendingApprovalCountProvider);
    final clients = ref.watch(clientProvider);
    final timesheetDashboard = ref.watch(timesheetDashboardProvider);
    final serviceStats = ref.watch(serviceStatisticsProvider);

    // FLS-Auslastung berechnen
    final clientsWithFls = clients.where((c) => c.fachleistungsstunden != null && c.fachleistungsstunden! > 0).toList();
    final flsAuslastung = clientsWithFls.isNotEmpty
        ? clientsWithFls.fold<double>(0, (sum, c) => sum + c.stundenverbrauchProzent) / clientsWithFls.length
        : 0.0;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Symbols.dashboard,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const Spacer(),
                FilledButton.icon(
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
              ],
            ),
            const SizedBox(height: 32),

            // KPI Cards
            Expanded(
              child: Row(
                children: [
                  // Left Column - KPIs
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Top KPI Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildKPICard(
                                context,
                                'Mitarbeiter',
                                '$employeeCount',
                                Symbols.group,
                                Colors.blue,
                                'Aktive Mitarbeiter',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildKPICard(
                                context,
                                'Aktive Teams',
                                '$teamCount',
                                Symbols.corporate_fare,
                                Colors.green,
                                '${ref.watch(teamCountProvider)} insgesamt',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildKPICard(
                                context,
                                'Offene Urlaube',
                                '$pendingVacations',
                                Symbols.beach_access,
                                Colors.orange,
                                '$pendingVacations zu genehmigen',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Bottom KPI Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildKPICard(
                                context,
                                'FLS-Auslastung',
                                '${flsAuslastung.toStringAsFixed(0)}%',
                                Symbols.trending_up,
                                flsAuslastung > 90
                                    ? Colors.red
                                    : flsAuslastung > 70
                                        ? Colors.orange
                                        : Colors.green,
                                '${clientsWithFls.length} Klienten mit FLS',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildKPICard(
                                context,
                                'Klienten',
                                '${clients.length}',
                                Symbols.people,
                                Colors.purple,
                                '${clients.where((c) => c.status == ClientStatus.active).length} aktiv',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildKPICard(
                                context,
                                'Arbeitsstunden',
                                timesheetDashboard['totalHours'] != null
                                    ? (timesheetDashboard['totalHours'] as double).toStringAsFixed(0)
                                    : '0',
                                Symbols.schedule,
                                Colors.teal,
                                'Erfasste Stunden',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Recent Activities from Audit Log
                        Expanded(
                          child: _AuditActivityCard(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right Column - Charts
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        // Service Distribution Pie Chart (from real data)
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Leistungsverteilung',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: serviceStats.isEmpty
                                        ? Center(
                                            child: Text(
                                              'Keine Daten',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                            ),
                                          )
                                        : PieChart(
                                            PieChartData(
                                              sections: _buildPieSections(serviceStats),
                                              sectionsSpace: 2,
                                              centerSpaceRadius: 40,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // FLS Overview Chart
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FLS-Verbrauch Top-Klienten',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: clientsWithFls.isEmpty
                                        ? Center(
                                            child: Text(
                                              'Keine FLS-Daten',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                            ),
                                          )
                                        : ListView(
                                            children: clientsWithFls
                                                .take(5)
                                                .map((c) => _buildFlsBar(context, c))
                                                .toList(),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  List<PieChartSectionData> _buildPieSections(Map<ServiceType, int> stats) {
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

    return stats.entries.map((e) {
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${labels[e.key]} (${e.value})',
        color: colors[e.key] ?? Colors.grey,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildFlsBar(BuildContext context, Client c) {
    final prozent = c.stundenverbrauchProzent.clamp(0.0, 100.0);
    final color = prozent > 90
        ? Colors.red
        : prozent > 70
            ? Colors.orange
            : Colors.green;

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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${c.verbrauchteStunden.toStringAsFixed(0)}/${c.fachleistungsstunden} Std.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: prozent / 100,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

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
}

/// Widget das echte Audit-Log-Einträge als Activity Feed anzeigt
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
          final entry = jsonDecode(line) as Map<String, dynamic>;
          parsed.add(entry);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _entries = parsed.take(10).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
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
                Icon(
                  Symbols.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Letzte Aktivitäten',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? Center(
                          child: Text(
                            'Noch keine Aktivitäten',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            final action = entry['action'] as String? ?? '';
                            final ctx = entry['ctx'] as Map<String, dynamic>? ?? {};
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

  Widget _buildAuditItem(BuildContext context, String action, Map<String, dynamic> ctx, String? ts) {
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
              color: info.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(info.icon, color: info.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (info.subtitle.isNotEmpty)
                  Text(
                    info.subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Text(
            timeAgo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  _AuditInfo _auditActionInfo(String action, Map<String, dynamic> ctx) {
    final name = ctx['name'] as String? ?? '';
    switch (action) {
      case 'client.add':
        return _AuditInfo('Klient angelegt', name, Symbols.person_add, Colors.green);
      case 'client.update':
        return _AuditInfo('Klient bearbeitet', name, Symbols.edit, Colors.blue);
      case 'client.delete':
        return _AuditInfo('Klient gelöscht', name, Symbols.delete, Colors.red);
      case 'employee.add':
        return _AuditInfo('Mitarbeiter angelegt', name, Symbols.person_add, Colors.green);
      case 'employee.update':
        return _AuditInfo('Mitarbeiter bearbeitet', name, Symbols.edit, Colors.blue);
      case 'employee.delete':
        return _AuditInfo('Mitarbeiter gelöscht', name, Symbols.delete, Colors.red);
      case 'team.add':
        return _AuditInfo('Team erstellt', name, Symbols.group_add, Colors.teal);
      case 'team.update':
        return _AuditInfo('Team bearbeitet', name, Symbols.edit, Colors.blue);
      case 'team.delete':
        return _AuditInfo('Team gelöscht', name, Symbols.delete, Colors.red);
      case 'vacation.approve':
        return _AuditInfo('Urlaub genehmigt', name, Symbols.check_circle, Colors.green);
      case 'vacation.reject':
        return _AuditInfo('Urlaub abgelehnt', name, Symbols.cancel, Colors.red);
      case 'vacation.request':
        return _AuditInfo('Urlaubsantrag', name, Symbols.beach_access, Colors.orange);
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
