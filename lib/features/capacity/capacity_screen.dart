import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../providers/capacity_provider.dart';
import 'widgets/capacity_overview_card.dart';
import 'widgets/team_capacity_grid.dart';
import 'widgets/capacity_alerts_panel.dart';
import 'widgets/capacity_forecast_chart.dart';
import 'widgets/workload_distribution_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CapacityScreen extends ConsumerStatefulWidget {
  const CapacityScreen({super.key});

  @override
  ConsumerState<CapacityScreen> createState() => _CapacityScreenState();
}

class _CapacityScreenState extends ConsumerState<CapacityScreen>
    with TickerProviderStateMixin {
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
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.analytics,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Kapazitätsanalyse',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(refreshCapacityAnalyticsProvider)();
                  },
                  icon: const Icon(Symbols.refresh),
                  label: const Text('Aktualisieren'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _exportCapacityReport,
                  icon: const Icon(Symbols.download),
                  label: const Text('Bericht exportieren'),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Symbols.dashboard),
                text: 'Übersicht',
              ),
              Tab(
                icon: Icon(Symbols.groups),
                text: 'Teams',
              ),
              Tab(
                icon: Icon(Symbols.trending_up),
                text: 'Prognose',
              ),
              Tab(
                icon: Icon(Symbols.bar_chart),
                text: 'Analysen',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTeamsTab(),
                _buildForecastTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final dashboardAsync = ref.watch(capacityDashboardProvider);

    return dashboardAsync.when(
      data: (dashboard) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CapacityOverviewCard(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const CapacityAlertsPanel(),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Schnellübersicht',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildQuickStats(dashboard),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      const WorkloadDistributionChart(),
                      const SizedBox(height: 16),
                      _buildDepartmentDistribution(dashboard),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
            Text(
              'Fehler beim Laden der Kapazitätsdaten',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref.read(refreshCapacityAnalyticsProvider)();
              },
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsTab() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: TeamCapacityGrid(),
    );
  }

  Widget _buildForecastTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          CapacityForecastChart(),
          SizedBox(height: 16),
          // Additional forecast widgets would go here
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const WorkloadDistributionChart(),
          const SizedBox(height: 16),
          // Historical trends, advanced analytics widgets would go here
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Erweiterte Analysen',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Detaillierte Analysen und historische Trends werden hier angezeigt.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> dashboard) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                'Verfügbarkeit',
                '${dashboard['availabilityRate'].toStringAsFixed(1)}%',
                Symbols.person_check,
                dashboard['availabilityRate'] >= 80 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                'Auslastung',
                '${dashboard['capacityUtilization'].toStringAsFixed(1)}%',
                Symbols.trending_up,
                dashboard['capacityUtilization'] >= 80 && dashboard['capacityUtilization'] <= 100
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                'Überstunden',
                '${dashboard['overtimePercentage'].toStringAsFixed(1)}%',
                Symbols.schedule,
                dashboard['overtimePercentage'] <= 10 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                'Aktive Teams',
                '${dashboard['totalTeams'] - dashboard['criticalTeams']}/${dashboard['totalTeams']}',
                Symbols.groups,
                dashboard['criticalTeams'] == 0 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentDistribution(Map<String, dynamic> dashboard) {
    final distribution = dashboard['departmentDistribution'] as Map<String, int>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Abteilungsverteilung',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...distribution.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _exportCapacityReport() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Kapazitätsbericht',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Erstellt am: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}'),
          pw.SizedBox(height: 16),
          pw.Text('Dieser Bericht enthält eine Übersicht der aktuellen Teamkapazitäten.',
            style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 16),
          pw.Text('Details finden Sie in der Anwendung unter Kapazitätsplanung.',
            style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Kapazitaetsbericht_${DateTime.now().month}_${DateTime.now().year}.pdf',
    );
  }
}