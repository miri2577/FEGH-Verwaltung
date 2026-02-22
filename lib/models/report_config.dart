enum ReportType {
  timesheet('Zeiterfassung'),
  employee('Mitarbeiter'),
  shifts('Schichten'),
  capacity('Kapazität'),
  performance('Leistung'),
  attendance('Anwesenheit'),
  payroll('Lohnabrechnung'),
  vacation('Urlaub'),
  overview('Übersicht'),
  custom('Benutzerdefiniert');

  const ReportType(this.label);
  final String label;
}

enum ReportFormat {
  pdf('PDF'),
  excel('Excel'),
  csv('CSV'),
  json('JSON');

  const ReportFormat(this.label);
  final String label;
}

enum ReportPeriod {
  daily('Täglich'),
  weekly('Wöchentlich'),
  monthly('Monatlich'),
  quarterly('Quartalsweise'),
  yearly('Jährlich'),
  custom('Benutzerdefiniert');

  const ReportPeriod(this.label);
  final String label;
}

class ReportConfig {
  final String id;
  final String name;
  final String description;
  final ReportType type;
  final ReportFormat format;
  final ReportPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> employeeIds;
  final List<String> departmentIds;
  final Map<String, dynamic> parameters;
  final List<String> columns;
  final Map<String, dynamic> filters;
  final bool includeCharts;
  final bool includeSummary;
  final DateTime createdAt;
  final DateTime? lastGenerated;

  const ReportConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.format,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.employeeIds = const [],
    this.departmentIds = const [],
    this.parameters = const {},
    this.columns = const [],
    this.filters = const {},
    this.includeCharts = true,
    this.includeSummary = true,
    required this.createdAt,
    this.lastGenerated,
  });

  ReportConfig copyWith({
    String? id,
    String? name,
    String? description,
    ReportType? type,
    ReportFormat? format,
    ReportPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? employeeIds,
    List<String>? departmentIds,
    Map<String, dynamic>? parameters,
    List<String>? columns,
    Map<String, dynamic>? filters,
    bool? includeCharts,
    bool? includeSummary,
    DateTime? createdAt,
    DateTime? lastGenerated,
  }) {
    return ReportConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      format: format ?? this.format,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      employeeIds: employeeIds ?? this.employeeIds,
      departmentIds: departmentIds ?? this.departmentIds,
      parameters: parameters ?? this.parameters,
      columns: columns ?? this.columns,
      filters: filters ?? this.filters,
      includeCharts: includeCharts ?? this.includeCharts,
      includeSummary: includeSummary ?? this.includeSummary,
      createdAt: createdAt ?? this.createdAt,
      lastGenerated: lastGenerated ?? this.lastGenerated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'format': format.name,
      'period': period.name,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'employeeIds': employeeIds,
      'departmentIds': departmentIds,
      'parameters': parameters,
      'columns': columns,
      'filters': filters,
      'includeCharts': includeCharts,
      'includeSummary': includeSummary,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastGenerated': lastGenerated?.millisecondsSinceEpoch,
    };
  }

  factory ReportConfig.fromMap(Map<String, dynamic> map) {
    return ReportConfig(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: ReportType.values.firstWhere((e) => e.name == map['type']),
      format: ReportFormat.values.firstWhere((e) => e.name == map['format']),
      period: ReportPeriod.values.firstWhere((e) => e.name == map['period']),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      employeeIds: List<String>.from(map['employeeIds'] ?? []),
      departmentIds: List<String>.from(map['departmentIds'] ?? []),
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
      columns: List<String>.from(map['columns'] ?? []),
      filters: Map<String, dynamic>.from(map['filters'] ?? {}),
      includeCharts: map['includeCharts'] ?? true,
      includeSummary: map['includeSummary'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastGenerated: map['lastGenerated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastGenerated'])
          : null,
    );
  }
}

class ReportData {
  final String reportId;
  final String title;
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> data;
  final Map<String, dynamic> charts;
  final DateTime generatedAt;
  final String filePath;

  const ReportData({
    required this.reportId,
    required this.title,
    required this.summary,
    required this.data,
    required this.charts,
    required this.generatedAt,
    required this.filePath,
  });
}