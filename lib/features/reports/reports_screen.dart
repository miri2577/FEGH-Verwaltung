import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../providers/reports_provider.dart';
import 'widgets/report_dashboard.dart';
import 'widgets/report_templates.dart' hide ReportTemplate;
import 'widgets/report_builder.dart';
import 'widgets/reports_sidebar.dart';
import 'widgets/export_dialog.dart';
import '../../models/report_config.dart';
import '../../providers/policy_provider.dart';
import '../../services/audit_logger.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
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
    final reportsAsync = ref.watch(reportsProvider);
    final templatesAsync = ref.watch(reportTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Symbols.assessment,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Berichte & Analytics',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Quick Export Buttons
          PopupMenuButton<String>(
            icon: const Icon(Symbols.download),
            tooltip: 'Schnell-Export',
            onSelected: (value) {
              final policy = ref.read(policyProvider);
              if (!policy.canExportData()) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keine Berechtigung für Export')));
                return;
              }
              _quickExport(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: ListTile(
                  leading: Icon(Symbols.picture_as_pdf, color: Colors.red),
                  title: Text('Als PDF exportieren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: ListTile(
                  leading: Icon(Symbols.table_chart, color: Colors.green),
                  title: Text('Als Excel exportieren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: ListTile(
                  leading: Icon(Symbols.text_snippet, color: Colors.blue),
                  title: Text('Als CSV exportieren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: ref.read(policyProvider).canManageReportTemplates() ? () => _showReportBuilder() : null,
            icon: const Icon(Symbols.add, size: 18),
            label: const Text('Neuer Report'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Symbols.dashboard, size: 20), text: 'Dashboard'),
            Tab(icon: Icon(Symbols.library_books, size: 20), text: 'Vorlagen'),
            Tab(icon: Icon(Symbols.build, size: 20), text: 'Report Builder'),
            Tab(icon: Icon(Symbols.history, size: 20), text: 'Verlauf'),
          ],
        ),
      ),
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 250,
            child: ReportsSidebar(
            selectedCategory: 'all',
            dateRange: DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
            onCategoryChanged: (category) {},
            onDateRangeChanged: (range) {},
            onReportSelected: (reportId) {},
            ),
          ),
          const VerticalDivider(width: 1),

          // Main Content
          Expanded(
            flex: 4,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Dashboard Tab
                ReportDashboard(
                  selectedCategory: 'all',
                  dateRange: DateTimeRange(
                    start: DateTime.now().subtract(const Duration(days: 30)),
                    end: DateTime.now(),
                  ),
                  onReportSelected: (reportId) {},
                ),

                // Templates Tab
                ReportTemplates(
                  selectedCategory: 'all',
                  onTemplateSelected: (template) => _createReportFromTemplate(template),
                ),

                // Report Builder Tab
                ReportBuilder(
                  onReportGenerated: (config) => _handleReportCreated(config),
                ),

                // History Tab
                _buildHistoryTab(reportsAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(AsyncValue<List<ReportConfig>> reportsAsync) {
    return reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Fehler beim Laden der Berichte: $error'),
          ],
        ),
      ),
      data: (reports) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Report-Verlauf',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _refreshReports(),
                  icon: const Icon(Symbols.refresh, size: 18),
                  label: const Text('Aktualisieren'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: reports.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getReportTypeIcon(report.type),
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        report.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(report.description),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Symbols.schedule, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Erstellt: ${_formatDate(report.createdAt)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              if (report.lastGenerated != null) ...[
                                const SizedBox(width: 16),
                                Icon(Symbols.download, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Zuletzt generiert: ${_formatDate(report.lastGenerated!)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Quick Export Buttons
                          IconButton(
                            icon: const Icon(Symbols.picture_as_pdf, color: Colors.red),
                            tooltip: 'Als PDF exportieren',
                            onPressed: ref.read(policyProvider).canExportData() ? () => _exportReport(report, ReportFormat.pdf) : null,
                          ),
                          IconButton(
                            icon: const Icon(Symbols.table_chart, color: Colors.green),
                            tooltip: 'Als Excel exportieren',
                            onPressed: ref.read(policyProvider).canExportData() ? () => _exportReport(report, ReportFormat.excel) : null,
                          ),
                          PopupMenuButton<String>(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Symbols.edit),
                                  title: Text('Bearbeiten'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'duplicate',
                                child: ListTile(
                                  leading: Icon(Symbols.content_copy),
                                  title: Text('Duplizieren'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'export_all',
                                child: ListTile(
                                  leading: Icon(Symbols.download),
                                  title: Text('Erweiterte Export-Optionen'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Symbols.delete, color: Colors.red),
                                  title: Text('Löschen'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                            onSelected: (value) => _handleReportAction(value, report),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getReportTypeIcon(ReportType type) {
    switch (type) {
      case ReportType.timesheet:
        return Symbols.schedule;
      case ReportType.employee:
        return Symbols.group;
      case ReportType.shifts:
        return Symbols.schedule;
      case ReportType.capacity:
        return Symbols.analytics;
      case ReportType.performance:
        return Symbols.trending_up;
      case ReportType.attendance:
        return Symbols.how_to_reg;
      case ReportType.payroll:
        return Symbols.payments;
      case ReportType.vacation:
        return Symbols.beach_access;
      case ReportType.overview:
        return Symbols.dashboard;
      case ReportType.custom:
        return Symbols.build;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _quickExport(String format) {
    // Create a sample report config for quick export
    final sampleReport = ReportConfig(
      id: 'quick-export-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Schnell-Export ${format.toUpperCase()}',
      description: 'Aktueller Übersichtsbericht',
      type: ReportType.overview,
      format: ReportFormat.values.firstWhere((f) => f.name == format),
      period: ReportPeriod.monthly,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    _exportReport(sampleReport, ReportFormat.values.firstWhere((f) => f.name == format));
    AuditLogger.log('export.quick', context: {'format': format});
  }

  void _showReportBuilder() {
    _tabController.animateTo(2); // Switch to Report Builder tab
  }

  void _createReportFromTemplate(dynamic template) {
    // Switch to Report Builder and pre-fill with template
    _tabController.animateTo(2);
  }

  void _exportTemplate(ReportTemplate template) {
    final reportConfig = ReportConfig(
      id: 'template-${template.id}-${DateTime.now().millisecondsSinceEpoch}',
      name: template.name,
      description: template.description,
      type: template.type,
      format: template.format,
      period: ReportPeriod.monthly,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
      columns: template.defaultColumns,
      filters: template.defaultFilters,
      createdAt: DateTime.now(),
    );

    showDialog(
      context: context,
      builder: (context) => ExportDialog(reportConfig: reportConfig),
    );
  }

  void _handleReportCreated(ReportConfig config) {
    ref.read(reportsProvider.notifier).createReport(config);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report erfolgreich erstellt'),
        backgroundColor: Colors.green,
      ),
    );
    _tabController.animateTo(3); // Switch to History tab
  }

  void _exportReport(ReportConfig report, ReportFormat format) {
    final policy = ref.read(policyProvider);
    if (!policy.canExportData()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keine Berechtigung für Export')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => ExportDialog(reportConfig: report),
    );
  }

  void _handleReportAction(String action, ReportConfig report) {
    switch (action) {
      case 'edit':
        // TODO: Edit report
        break;
      case 'duplicate':
        final duplicated = report.copyWith(
          id: 'dup-${DateTime.now().millisecondsSinceEpoch}',
          name: '${report.name} (Kopie)',
          createdAt: DateTime.now(),
          lastGenerated: null,
        );
        ref.read(reportsProvider.notifier).createReport(duplicated);
        break;
      case 'export_all':
        showDialog(
          context: context,
          builder: (context) => ExportDialog(reportConfig: report),
        );
        break;
      case 'delete':
        _confirmDeleteReport(report);
        break;
    }
  }

  void _confirmDeleteReport(ReportConfig report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report löschen'),
        content: Text('Möchten Sie den Report "${report.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(reportsProvider.notifier).deleteReport(report.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report gelöscht'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _refreshReports() {
    ref.read(reportsProvider.notifier).loadReports();
  }
}
