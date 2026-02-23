import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../models/report_config.dart';
import '../../../models/employee.dart';
import '../../../models/shift.dart';
import '../../../providers/employee_provider.dart';
import '../../../providers/shift_provider.dart';
import '../../../providers/client_provider.dart';

class ReportBuilder extends ConsumerStatefulWidget {
  final ReportConfig? initialConfig;
  final Function(ReportConfig) onReportGenerated;

  const ReportBuilder({
    super.key,
    this.initialConfig,
    required this.onReportGenerated,
  });

  @override
  ConsumerState<ReportBuilder> createState() => _ReportBuilderState();
}

class _ReportBuilderState extends ConsumerState<ReportBuilder> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  ReportType _selectedType = ReportType.timesheet;
  ReportFormat _selectedFormat = ReportFormat.pdf;
  ReportPeriod _selectedPeriod = ReportPeriod.monthly;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<String> _selectedEmployeeIds = [];
  List<String> _selectedColumns = [];
  Map<String, dynamic> _filters = {};
  bool _includeCharts = true;
  bool _includeSummary = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialConfig != null) {
      _loadConfig(widget.initialConfig!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadConfig(ReportConfig config) {
    _nameController.text = config.name;
    _descriptionController.text = config.description;
    _selectedType = config.type;
    _selectedFormat = config.format;
    _selectedPeriod = config.period;
    _startDate = config.startDate;
    _endDate = config.endDate;
    _selectedEmployeeIds = config.employeeIds;
    _selectedColumns = config.columns;
    _filters = config.filters;
    _includeCharts = config.includeCharts;
    _includeSummary = config.includeSummary;
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.build,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Report Builder',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _previewReport,
                icon: const Icon(Symbols.visibility, size: 18),
                label: const Text('Vorschau'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isFormValid() ? _generateReport : null,
                icon: const Icon(Symbols.play_arrow, size: 18),
                label: const Text('Generieren'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Erstellen Sie benutzerdefinierte Berichte mit den gewünschten Daten und Filtern',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel - Configuration
                Expanded(
                  flex: 2,
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBasicInfoSection(context),
                          const SizedBox(height: 24),
                          _buildTypeAndFormatSection(context),
                          const SizedBox(height: 24),
                          _buildDateRangeSection(context),
                          const SizedBox(height: 24),
                          employeesAsync.when(
                            loading: () => const CircularProgressIndicator(),
                            error: (error, stack) => Text('Fehler: $error'),
                            data: (employees) => _buildEmployeeFilterSection(context, employees),
                          ),
                          const SizedBox(height: 24),
                          _buildDataColumnsSection(context),
                          const SizedBox(height: 24),
                          _buildFilterSection(context),
                          const SizedBox(height: 24),
                          _buildOptionsSection(context),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // Right Panel - Preview
                Expanded(
                  child: _buildPreviewPanel(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grundinformationen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Report Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Symbols.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Name ist erforderlich';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Symbols.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeAndFormatSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Typ & Format',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ReportType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Report Typ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Symbols.category),
                    ),
                    items: ReportType.values.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                          _selectedColumns = _getDefaultColumnsForType(value);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<ReportFormat>(
                    value: _selectedFormat,
                    decoration: const InputDecoration(
                      labelText: 'Format',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Symbols.file_present),
                    ),
                    items: ReportFormat.values.map((format) => DropdownMenuItem(
                      value: format,
                      child: Row(
                        children: [
                          Icon(_getFormatIcon(format), size: 18),
                          const SizedBox(width: 8),
                          Text(format.label),
                        ],
                      ),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedFormat = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReportPeriod>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Berichtszeitraum',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Symbols.schedule),
              ),
              items: ReportPeriod.values.map((period) => DropdownMenuItem(
                value: period,
                child: Text(period.label),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPeriod = value;
                    _updateDateRangeForPeriod(value);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datumsbereich',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Startdatum',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Symbols.calendar_today),
                      ),
                      child: Text(
                        '${_startDate.day}.${_startDate.month}.${_startDate.year}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Enddatum',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Symbols.calendar_today),
                      ),
                      child: Text(
                        '${_endDate.day}.${_endDate.month}.${_endDate.year}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeFilterSection(BuildContext context, List employees) {
    final activeEmployees = employees.where((e) => e.status == EmployeeStatus.active).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Mitarbeiter Filter',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedEmployeeIds.length == activeEmployees.length) {
                        _selectedEmployeeIds.clear();
                      } else {
                        _selectedEmployeeIds = activeEmployees.map((e) => e.id).cast<String>().toList();
                      }
                    });
                  },
                  child: Text(
                    _selectedEmployeeIds.length == activeEmployees.length ? 'Alle abwählen' : 'Alle auswählen',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedEmployeeIds.length}/${activeEmployees.length} ausgewählt',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: activeEmployees.length,
                itemBuilder: (context, index) {
                  final employee = activeEmployees[index];
                  final isSelected = _selectedEmployeeIds.contains(employee.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedEmployeeIds.add(employee.id);
                        } else {
                          _selectedEmployeeIds.remove(employee.id);
                        }
                      });
                    },
                    title: Text(employee.fullName),
                    subtitle: Text(employee.position),
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataColumnsSection(BuildContext context) {
    final availableColumns = _getAvailableColumnsForType(_selectedType);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Datenspalten',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedColumns = _getDefaultColumnsForType(_selectedType);
                    });
                  },
                  child: const Text('Standard zurücksetzen'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableColumns.map((column) {
                final isSelected = _selectedColumns.contains(column);
                return FilterChip(
                  label: Text(column),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedColumns.add(column);
                      } else {
                        _selectedColumns.remove(column);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Erweiterte Filter',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Nur aktive Mitarbeiter'),
                  selected: true,
                  onSelected: (value) {},
                ),
                FilterChip(
                  label: const Text('Überstunden > 0'),
                  selected: false,
                  onSelected: (value) {},
                ),
                FilterChip(
                  label: const Text('Mit Urlaubstagen'),
                  selected: false,
                  onSelected: (value) {},
                ),
                FilterChip(
                  label: const Text('Offene Zeitnachweise'),
                  selected: false,
                  onSelected: (value) {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Optionen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _includeCharts,
              onChanged: (value) {
                setState(() {
                  _includeCharts = value ?? false;
                });
              },
              title: const Text('Diagramme einschließen'),
              subtitle: const Text('Fügt visuelle Darstellungen hinzu'),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _includeSummary,
              onChanged: (value) {
                setState(() {
                  _includeSummary = value ?? false;
                });
              },
              title: const Text('Zusammenfassung einschließen'),
              subtitle: const Text('Fügt eine Executive Summary hinzu'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _getPreviewData() {
    final employees = ref.read(employeesProvider).valueOrNull ?? [];
    final shifts = ref.read(shiftsProvider).valueOrNull ?? [];
    final clients = ref.read(clientProvider);

    switch (_selectedType) {
      case ReportType.timesheet:
      case ReportType.shifts:
        return shifts.take(10).map((s) {
          final emp = employees.where((e) => e.id == s.employeeId).firstOrNull;
          return {
            'Mitarbeiter': emp?.fullName ?? s.employeeId,
            'Datum': '${s.startTime.day.toString().padLeft(2, '0')}.${s.startTime.month.toString().padLeft(2, '0')}.${s.startTime.year}',
            'Startzeit': '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}',
            'Endzeit': '${s.endTime.hour.toString().padLeft(2, '0')}:${s.endTime.minute.toString().padLeft(2, '0')}',
            'Stunden': s.scheduledHours.toStringAsFixed(1),
            'Überstunden': s.type == ShiftType.overtime ? 'Ja' : 'Nein',
            'Pausenzeit': '${s.breakDurationMinutes?.toStringAsFixed(0) ?? '0'} min',
            'Kommentar': s.notes ?? '',
            'Schichttyp': s.type.name,
            'Status': s.status.name,
            'Vertretung': '',
          };
        }).toList();
      case ReportType.employee:
        return employees.take(10).map((e) => {
          'Name': e.fullName,
          'Position': e.position,
          'Abteilung': e.department,
          'Einstellungsdatum': '${e.hireDate.day.toString().padLeft(2, '0')}.${e.hireDate.month.toString().padLeft(2, '0')}.${e.hireDate.year}',
          'Status': e.statusLabel,
          'Stundenlohn': '${e.hourlyRate.toStringAsFixed(2)} €',
          'Vertragsstunden': '${e.hoursPerWeek}',
        }).toList();
      case ReportType.attendance:
        return employees.take(10).map((e) => {
          'Mitarbeiter': e.fullName,
          'Anwesenheitstage': '${20 + (e.id.hashCode % 5)}',
          'Fehltage': '${e.id.hashCode.abs() % 4}',
          'Urlaubstage': '${e.id.hashCode.abs() % 6}',
          'Krankheitstage': '${e.id.hashCode.abs() % 3}',
          'Quote': '${90 + (e.id.hashCode.abs() % 10)}%',
        }).toList();
      case ReportType.payroll:
        return employees.take(10).map((e) {
          final base = e.hourlyRate * e.hoursPerWeek * 4;
          return {
            'Mitarbeiter': e.fullName,
            'Grundlohn': '${base.toStringAsFixed(2)} €',
            'Überstunden': '${(base * 0.05).toStringAsFixed(2)} €',
            'Zulagen': '${(base * 0.03).toStringAsFixed(2)} €',
            'Abzüge': '${(base * 0.2).toStringAsFixed(2)} €',
            'Nettolohn': '${(base * 0.88).toStringAsFixed(2)} €',
          };
        }).toList();
      case ReportType.vacation:
        return employees.take(10).map((e) => {
          'Mitarbeiter': e.fullName,
          'Urlaubsanspruch': '30',
          'Genommen': '${10 + e.id.hashCode.abs() % 15}',
          'Verbleibend': '${15 + e.id.hashCode.abs() % 10}',
          'Geplant': '${e.id.hashCode.abs() % 5}',
          'Status': e.isActive ? 'Aktiv' : 'Inaktiv',
        }).toList();
      default:
        return employees.take(10).map((e) => {
          'Kategorie': e.department,
          'Wert': '${e.hoursPerWeek}h',
          'Trend': 'stabil',
          'Vergleich': '+0%',
          'Status': e.statusLabel,
          'Kommentar': '',
        }).toList();
    }
  }

  int _getTotalDataCount() {
    switch (_selectedType) {
      case ReportType.timesheet:
      case ReportType.shifts:
        return ref.read(shiftsProvider).valueOrNull?.length ?? 0;
      case ReportType.employee:
      case ReportType.attendance:
      case ReportType.payroll:
      case ReportType.vacation:
      case ReportType.performance:
        return ref.read(employeesProvider).valueOrNull?.length ?? 0;
      default:
        return ref.read(employeesProvider).valueOrNull?.length ?? 0;
    }
  }

  Widget _buildPreviewPanel(BuildContext context) {
    final previewData = _getPreviewData();
    final totalCount = _getTotalDataCount();
    final visibleColumns = _selectedColumns.isNotEmpty ? _selectedColumns : ['Keine Spalten ausgewählt'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Symbols.preview, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Report Vorschau',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: _previewReport,
                  icon: const Icon(Symbols.fullscreen, size: 20),
                  tooltip: 'Vollbild',
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Report meta info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameController.text.isNotEmpty ? _nameController.text : 'Unbenannter Report',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedType.label} • ${_selectedFormat.label} • ${_selectedPeriod.label}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${_startDate.day}.${_startDate.month}.${_startDate.year} - ${_endDate.day}.${_endDate.month}.${_endDate.year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Data table
            Expanded(
              child: _selectedColumns.isEmpty
                  ? Center(
                      child: Text(
                        'Wählen Sie Spalten aus, um die Vorschau zu sehen.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : previewData.isEmpty
                      ? Center(
                          child: Text(
                            'Keine Daten verfügbar.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : SfDataGrid(
                          source: _ReportPreviewDataSource(data: previewData, columns: visibleColumns),
                          columnWidthMode: ColumnWidthMode.fill,
                          gridLinesVisibility: GridLinesVisibility.horizontal,
                          headerGridLinesVisibility: GridLinesVisibility.horizontal,
                          rowHeight: 36,
                          headerRowHeight: 36,
                          columns: visibleColumns.map((col) => GridColumn(
                            columnName: col,
                            label: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              alignment: Alignment.centerLeft,
                              child: Text(col, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          )).toList(),
                        ),
            ),
            // Footer
            if (totalCount > 10 && previewData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... und ${totalCount - 10} weitere Datensätze',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$totalCount Datensätze • ${_selectedColumns.length} Spalten • ${_selectedEmployeeIds.length} Mitarbeiter',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFormatIcon(ReportFormat format) {
    switch (format) {
      case ReportFormat.pdf:
        return Symbols.picture_as_pdf;
      case ReportFormat.excel:
        return Symbols.table_chart;
      case ReportFormat.csv:
        return Symbols.table_rows;
      case ReportFormat.json:
        return Symbols.data_object;
    }
  }

  List<String> _getAvailableColumnsForType(ReportType type) {
    switch (type) {
      case ReportType.timesheet:
        return ['Mitarbeiter', 'Datum', 'Startzeit', 'Endzeit', 'Stunden', 'Überstunden', 'Pausenzeit', 'Kommentar'];
      case ReportType.employee:
        return ['Name', 'Position', 'Abteilung', 'Einstellungsdatum', 'Status', 'Stundenlohn', 'Vertragsstunden'];
      case ReportType.shifts:
        return ['Mitarbeiter', 'Datum', 'Schichttyp', 'Startzeit', 'Endzeit', 'Status', 'Vertretung'];
      case ReportType.capacity:
        return ['Abteilung', 'Verfügbar', 'Geplant', 'Auslastung', 'Überstunden', 'Empfehlung'];
      case ReportType.performance:
        return ['Mitarbeiter', 'Pünktlichkeit', 'Anwesenheit', 'Produktivität', 'Bewertung', 'Ziele'];
      case ReportType.attendance:
        return ['Mitarbeiter', 'Anwesenheitstage', 'Fehltage', 'Urlaubstage', 'Krankheitstage', 'Quote'];
      case ReportType.payroll:
        return ['Mitarbeiter', 'Grundlohn', 'Überstunden', 'Zulagen', 'Abzüge', 'Nettolohn'];
      case ReportType.vacation:
        return ['Mitarbeiter', 'Urlaubsanspruch', 'Genommen', 'Verbleibend', 'Geplant', 'Status'];
      case ReportType.overview:
        return ['Kategorie', 'Wert', 'Trend', 'Vergleich', 'Status', 'Kommentar'];
      case ReportType.custom:
        return ['Spalte 1', 'Spalte 2', 'Spalte 3', 'Spalte 4', 'Spalte 5'];
    }
  }

  List<String> _getDefaultColumnsForType(ReportType type) {
    final available = _getAvailableColumnsForType(type);
    return available.take(4).toList(); // Take first 4 as default
  }

  void _updateDateRangeForPeriod(ReportPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.daily:
        _startDate = now;
        _endDate = now;
        break;
      case ReportPeriod.weekly:
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = _startDate.add(const Duration(days: 6));
        break;
      case ReportPeriod.monthly:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case ReportPeriod.quarterly:
        final quarter = ((now.month - 1) ~/ 3) + 1;
        _startDate = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
        _endDate = DateTime(now.year, quarter * 3 + 1, 0);
        break;
      case ReportPeriod.yearly:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
      case ReportPeriod.custom:
        // Keep current dates for custom period
        break;
    }
  }

  bool _isFormValid() {
    return _nameController.text.isNotEmpty && _selectedColumns.isNotEmpty;
  }

  void _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: _endDate,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _previewReport() {
    final previewData = _getPreviewData();
    final totalCount = _getTotalDataCount();
    final visibleColumns = _selectedColumns.isNotEmpty ? _selectedColumns : <String>[];

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(_nameController.text.isNotEmpty ? _nameController.text : 'Report Vorschau'),
            leading: IconButton(
              icon: const Icon(Symbols.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_selectedType.label} • ${_selectedFormat.label} • $totalCount Datensätze',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          body: visibleColumns.isEmpty || previewData.isEmpty
              ? Center(
                  child: Text(
                    visibleColumns.isEmpty
                        ? 'Keine Spalten ausgewählt.'
                        : 'Keine Daten verfügbar.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: SfDataGrid(
                    source: _ReportPreviewDataSource(data: previewData, columns: visibleColumns),
                    columnWidthMode: ColumnWidthMode.fill,
                    gridLinesVisibility: GridLinesVisibility.horizontal,
                    headerGridLinesVisibility: GridLinesVisibility.horizontal,
                    rowHeight: 44,
                    headerRowHeight: 44,
                    columns: visibleColumns.map((col) => GridColumn(
                      columnName: col,
                      label: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.centerLeft,
                        child: Text(col, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )).toList(),
                  ),
                ),
        ),
      ),
    );
  }

  void _generateReport() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final config = ReportConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      description: _descriptionController.text,
      type: _selectedType,
      format: _selectedFormat,
      period: _selectedPeriod,
      startDate: _startDate,
      endDate: _endDate,
      employeeIds: _selectedEmployeeIds,
      columns: _selectedColumns,
      filters: _filters,
      includeCharts: _includeCharts,
      includeSummary: _includeSummary,
      createdAt: DateTime.now(),
    );

    widget.onReportGenerated(config);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report wird generiert...')),
    );
  }
}

class _ReportPreviewDataSource extends DataGridSource {
  final List<Map<String, String>> data;
  final List<String> columns;

  _ReportPreviewDataSource({required this.data, required this.columns});

  @override
  List<DataGridRow> get rows => data.map((row) => DataGridRow(
    cells: columns.map((col) => DataGridCell<String>(columnName: col, value: row[col] ?? '-')).toList(),
  )).toList();

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(cells: row.getCells().map((cell) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        child: Text(cell.value?.toString() ?? '-', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
      );
    }).toList());
  }
}