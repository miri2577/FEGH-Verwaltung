import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../../../models/report_config.dart';

class ReportsSidebar extends StatelessWidget {
  final String selectedCategory;
  final DateTimeRange dateRange;
  final Function(String) onCategoryChanged;
  final Function(DateTimeRange) onDateRangeChanged;
  final Function(ReportConfig) onReportSelected;

  const ReportsSidebar({
    super.key,
    required this.selectedCategory,
    required this.dateRange,
    required this.onCategoryChanged,
    required this.onDateRangeChanged,
    required this.onReportSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.filter_list,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filter & Optionen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  _buildQuickActions(context),
                  const SizedBox(height: 24),

                  // Date Range Selector
                  _buildDateRangeSection(context),
                  const SizedBox(height: 24),

                  // Category Filter
                  _buildCategoryFilter(context),
                  const SizedBox(height: 24),

                  // Saved Reports
                  _buildSavedReports(context),
                  const SizedBox(height: 24),

                  // Export Options
                  _buildExportOptions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schnellaktionen',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _generateMonthlyReport(context),
                icon: const Icon(Symbols.calendar_month, size: 18),
                label: const Text('Monatsbericht'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _generateWeeklyReport(context),
                icon: const Icon(Symbols.view_week, size: 18),
                label: const Text('Wochenbericht'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _generateCustomReport(context),
                icon: const Icon(Symbols.tune, size: 18),
                label: const Text('Benutzerdefiniert'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zeitraum',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Quick Date Filters
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDateChip(context, 'Heute', () => _setDateRange(DateTime.now(), DateTime.now())),
                _buildDateChip(context, 'Diese Woche', () {
                  final now = DateTime.now();
                  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                  final endOfWeek = startOfWeek.add(const Duration(days: 6));
                  _setDateRange(startOfWeek, endOfWeek);
                }),
                _buildDateChip(context, 'Dieser Monat', () {
                  final now = DateTime.now();
                  final startOfMonth = DateTime(now.year, now.month, 1);
                  final endOfMonth = DateTime(now.year, now.month + 1, 0);
                  _setDateRange(startOfMonth, endOfMonth);
                }),
                _buildDateChip(context, 'Letzten 30 Tage', () {
                  final end = DateTime.now();
                  final start = end.subtract(const Duration(days: 30));
                  _setDateRange(start, end);
                }),
              ],
            ),
            const SizedBox(height: 12),

            // Inline SfDateRangePicker
            SizedBox(
              height: 280,
              child: SfDateRangePicker(
                selectionMode: DateRangePickerSelectionMode.range,
                initialSelectedRange: PickerDateRange(dateRange.start, dateRange.end),
                showNavigationArrow: true,
                headerStyle: DateRangePickerHeaderStyle(
                  textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                monthViewSettings: const DateRangePickerMonthViewSettings(
                  firstDayOfWeek: 1,
                  viewHeaderStyle: DateRangePickerViewHeaderStyle(
                    textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
                onSelectionChanged: (args) {
                  if (args.value is PickerDateRange) {
                    final range = args.value as PickerDateRange;
                    if (range.startDate != null && range.endDate != null) {
                      onDateRangeChanged(DateTimeRange(start: range.startDate!, end: range.endDate!));
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    final categories = [
      {'value': 'all', 'label': 'Alle Berichte', 'icon': Symbols.dashboard},
      {'value': 'timesheet', 'label': 'Zeiterfassung', 'icon': Symbols.schedule},
      {'value': 'employee', 'label': 'Mitarbeiter', 'icon': Symbols.people},
      {'value': 'shifts', 'label': 'Schichten', 'icon': Symbols.work},
      {'value': 'capacity', 'label': 'Kapazität', 'icon': Symbols.analytics},
      {'value': 'performance', 'label': 'Leistung', 'icon': Symbols.trending_up},
      {'value': 'attendance', 'label': 'Anwesenheit', 'icon': Symbols.fact_check},
      {'value': 'payroll', 'label': 'Lohnabrechnung', 'icon': Symbols.euro},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategorien',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...categories.map((category) => _buildCategoryItem(
              context,
              category['value'] as String,
              category['label'] as String,
              category['icon'] as IconData,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String value, String label, IconData icon) {
    final isSelected = selectedCategory == value;

    return InkWell(
      onTap: () => onCategoryChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  fontWeight: isSelected ? FontWeight.w500 : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Symbols.check,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedReports(BuildContext context) {
    final savedReports = [
      {'name': 'Monatlicher Zeitnachweis', 'type': 'timesheet'},
      {'name': 'Wöchentliche Kapazität', 'type': 'capacity'},
      {'name': 'Mitarbeiter Performance', 'type': 'performance'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Gespeicherte Berichte',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showSavedReportsDialog(context),
                  icon: const Icon(Symbols.more_horiz, size: 16),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (savedReports.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Symbols.bookmark_border,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Keine gespeicherten Berichte',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...savedReports.map((report) => _buildSavedReportItem(
                context,
                report['name'] as String,
                report['type'] as String,
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedReportItem(BuildContext context, String name, String type) {
    return InkWell(
      onTap: () => _loadSavedReport(context, name, type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              Symbols.bookmark,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    type,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Symbols.arrow_forward_ios,
              size: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export-Optionen',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildExportOptionItem(context, 'PDF', Symbols.picture_as_pdf, Colors.red),
            _buildExportOptionItem(context, 'Excel', Symbols.table_chart, Colors.green),
            _buildExportOptionItem(context, 'CSV', Symbols.table_rows, Colors.blue),
            _buildExportOptionItem(context, 'JSON', Symbols.data_object, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptionItem(BuildContext context, String format, IconData icon, Color color) {
    return InkWell(
      onTap: () => _setExportFormat(format),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                format,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: dateRange,
    );
    if (picked != null) {
      onDateRangeChanged(picked);
    }
  }

  void _setDateRange(DateTime start, DateTime end) {
    onDateRangeChanged(DateTimeRange(start: start, end: end));
  }

  void _generateMonthlyReport(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    onDateRangeChanged(DateTimeRange(start: start, end: end));
    onCategoryChanged('overview');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Monatsbericht für ${start.month}/${start.year} geladen'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _generateWeeklyReport(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    onDateRangeChanged(DateTimeRange(start: startOfWeek, end: endOfWeek));
    onCategoryChanged('overview');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Wochenbericht KW${_getWeekNumber(now)} geladen'),
        backgroundColor: Colors.green,
      ),
    );
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(firstDayOfYear).inDays;
    return ((days + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  void _generateCustomReport(BuildContext context) {
    onCategoryChanged('custom');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom Report Builder geöffnet - nutzen Sie die Filter oben'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showSavedReportsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Symbols.bookmark),
            SizedBox(width: 12),
            Text('Gespeicherte Berichte'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Symbols.folder_open, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Noch keine gespeicherten Berichte vorhanden.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Berichte werden automatisch gespeichert, wenn Sie einen Report generieren.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _loadSavedReport(BuildContext context, String name, String type) {
    final reportType = _mapStringToReportType(type);
    final config = ReportConfig(
      id: 'saved-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: 'Gespeicherter Bericht: $name',
      type: reportType,
      format: ReportFormat.pdf,
      period: ReportPeriod.monthly,
      startDate: dateRange.start,
      endDate: dateRange.end,
      createdAt: DateTime.now(),
    );
    onReportSelected(config);
  }

  void _setExportFormat(String format) {
    final formatEnum = ReportFormat.values.firstWhere(
      (f) => f.name.toLowerCase() == format.toLowerCase(),
      orElse: () => ReportFormat.pdf,
    );
    final config = ReportConfig(
      id: 'quick-export-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Schnell-Export $format',
      description: 'Export im Format $format',
      type: _mapStringToReportType(selectedCategory == 'all' ? 'overview' : selectedCategory),
      format: formatEnum,
      period: ReportPeriod.monthly,
      startDate: dateRange.start,
      endDate: dateRange.end,
      createdAt: DateTime.now(),
    );
    onReportSelected(config);
  }

  ReportType _mapStringToReportType(String type) {
    switch (type) {
      case 'timesheet':
        return ReportType.timesheet;
      case 'employee':
        return ReportType.employee;
      case 'shifts':
        return ReportType.shifts;
      case 'capacity':
        return ReportType.capacity;
      case 'performance':
        return ReportType.performance;
      case 'attendance':
        return ReportType.attendance;
      case 'payroll':
        return ReportType.payroll;
      case 'vacation':
        return ReportType.vacation;
      case 'overview':
        return ReportType.overview;
      default:
        return ReportType.overview;
    }
  }
}