import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_config.dart';
import '../models/employee.dart';
import '../models/timesheet.dart';
import '../providers/reports_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/timesheet_provider.dart';
import 'export_service.dart';

class ReportsService {
  final _uuid = const Uuid();
  final WidgetRef? _ref;

  ReportsService([this._ref]);

  Future<List<ReportConfig>> getAllReports() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

    return [
      ReportConfig(
        id: 'monthly-timesheet-2024',
        name: 'Monatsauswertung Zeiterfassung',
        description: 'Detaillierte Auswertung aller Arbeitszeiten für den aktuellen Monat',
        type: ReportType.timesheet,
        format: ReportFormat.pdf,
        period: ReportPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
        employeeIds: ['emp-1', 'emp-2'],
        columns: ['name', 'arbeitszeit', 'überstunden', 'urlaubstage'],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        lastGenerated: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ReportConfig(
        id: 'employee-overview-2024',
        name: 'Mitarbeiterübersicht',
        description: 'Vollständige Übersicht aller aktiven Mitarbeiter',
        type: ReportType.employee,
        format: ReportFormat.excel,
        period: ReportPeriod.yearly,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        columns: ['name', 'position', 'abteilung', 'status'],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  Future<List<ReportTemplate>> getReportTemplates() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      const ReportTemplate(
        id: 'template-timesheet-monthly',
        name: 'Monatsauswertung Zeiten',
        description: 'Standardvorlage für monatliche Zeiterfassung mit Überstunden und Urlaubsanspruch',
        type: ReportType.timesheet,
        format: ReportFormat.pdf,
        category: 'Zeiterfassung',
        defaultColumns: ['name', 'arbeitszeit', 'überstunden', 'urlaubstage'],
        icon: 'schedule',
        features: ['Überstunden', 'Urlaubsanspruch', 'Graphiken'],
      ),
      const ReportTemplate(
        id: 'template-employee-list',
        name: 'Mitarbeiterliste',
        description: 'Vollständige Liste aller Mitarbeiter mit Kontaktdaten und Positionen',
        type: ReportType.employee,
        format: ReportFormat.excel,
        category: 'Personal',
        defaultColumns: ['name', 'position', 'abteilung', 'telefon', 'email'],
        icon: 'group',
        features: ['Kontaktdaten', 'Export', 'Filter'],
      ),
      const ReportTemplate(
        id: 'template-shifts-weekly',
        name: 'Wochenschichten',
        description: 'Übersicht über alle Schichten einer Woche mit Besetzungsgrad',
        type: ReportType.shifts,
        format: ReportFormat.pdf,
        category: 'Schichtplanung',
        defaultColumns: ['datum', 'schicht', 'mitarbeiter', 'besetzung'],
        icon: 'schedule',
        features: ['Besetzungsgrad', 'Konflikte', 'Graphiken'],
      ),
      const ReportTemplate(
        id: 'template-capacity-analysis',
        name: 'Kapazitätsanalyse',
        description: 'Detaillierte Analyse der Personalkapazität und Auslastung',
        type: ReportType.capacity,
        format: ReportFormat.pdf,
        category: 'Analyse',
        defaultColumns: ['abteilung', 'kapazität', 'auslastung', 'verfügbarkeit'],
        icon: 'analytics',
        features: ['Trendanalyse', 'Prognose', 'Dashboards'],
      ),
      const ReportTemplate(
        id: 'template-vacation-overview',
        name: 'Urlaubsübersicht',
        description: 'Komplette Übersicht über Urlaubsanträge und verbrauchte Urlaubstage',
        type: ReportType.vacation,
        format: ReportFormat.excel,
        category: 'Urlaub',
        defaultColumns: ['mitarbeiter', 'urlaubstage_gesamt', 'genommen', 'geplant', 'verfügbar'],
        icon: 'beach_access',
        features: ['Jahresübersicht', 'Planungstools', 'Genehmigung'],
      ),
      const ReportTemplate(
        id: 'template-attendance',
        name: 'Anwesenheitsreport',
        description: 'Übersicht über Anwesenheit, Fehlzeiten und Krankmeldungen',
        type: ReportType.attendance,
        format: ReportFormat.pdf,
        category: 'Anwesenheit',
        defaultColumns: ['mitarbeiter', 'anwesenheit', 'fehlzeiten', 'krankheit'],
        icon: 'how_to_reg',
        features: ['Fehlzeitenanalyse', 'Trends', 'Benachrichtigung'],
      ),
    ];
  }

  Future<ReportData> generateReport(String reportId) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate report generation

    return ReportData(
      reportId: reportId,
      title: 'Generierter Bericht',
      summary: {
        'totalEmployees': 45,
        'totalHours': 1850.5,
        'overtimeHours': 125.75,
        'vacationDays': 320,
        'averageHours': 41.12,
        'departments': 5,
      },
      data: [
        {
          'name': 'Max Mustermann',
          'arbeitszeit': '168:30',
          'überstunden': '12:15',
          'urlaubstage': 5,
          'abteilung': 'Wohnbereich A',
        },
        {
          'name': 'Anna Schmidt',
          'arbeitszeit': '155:45',
          'überstunden': '3:20',
          'urlaubstage': 2,
          'abteilung': 'Wohnbereich B',
        },
        {
          'name': 'Thomas Weber',
          'arbeitszeit': '172:10',
          'überstunden': '15:50',
          'urlaubstage': 0,
          'abteilung': 'Verwaltung',
        },
      ],
      charts: {
        'hoursDistribution': [168.5, 155.75, 172.17],
        'departmentSummary': {
          'Wohnbereich A': 950.5,
          'Wohnbereich B': 832.25,
          'Verwaltung': 678.0,
        },
      },
      generatedAt: DateTime.now(),
      filePath: '/reports/generated_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> createReport(ReportConfig config) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Simulate saving to database/storage
  }

  Future<void> updateReport(ReportConfig config) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Simulate updating in database/storage
  }

  Future<void> deleteReport(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Simulate deletion from database/storage
  }

  Future<Map<String, dynamic>> getReportAnalytics() async {
    await Future.delayed(const Duration(milliseconds: 700));

    return {
      'totalReports': 127,
      'reportsThisMonth': 23,
      'mostUsedTemplate': 'Monatsauswertung Zeiten',
      'averageGenerationTime': '2.3s',
      'popularFormats': {
        'PDF': 65,
        'Excel': 35,
        'CSV': 18,
        'JSON': 9,
      },
      'monthlyTrend': [
        {'month': 'Jan', 'count': 15},
        {'month': 'Feb', 'count': 18},
        {'month': 'Mar', 'count': 22},
        {'month': 'Apr', 'count': 19},
        {'month': 'Mai', 'count': 25},
        {'month': 'Jun', 'count': 28},
      ],
    };
  }

  Future<bool> exportReport(String reportId, ReportFormat format, String filePath) async {
    try {
      // Get report configuration to determine type
      final reports = await getAllReports();
      final report = reports.firstWhere((r) => r.id == reportId);

      switch (report.type) {
        case ReportType.employee:
          return await _exportEmployeeReport(format, filePath);
        case ReportType.timesheet:
          return await _exportTimesheetReport(format, filePath);
        case ReportType.shifts:
          return await _exportShiftReport(format, filePath);
        default:
          return await _exportGenericReport(report, format, filePath);
      }
    } catch (e) {
      print('Export error: $e');
      return false;
    }
  }

  Future<bool> _exportEmployeeReport(ReportFormat format, String filePath) async {
    try {
      // Get mock employee data for now
      final employees = await _getMockEmployees();

      switch (format) {
        case ReportFormat.pdf:
          final pdfData = await ExportService.exportEmployeesToPDF(employees);
          await ExportService.saveFile(pdfData, filePath);
          break;
        case ReportFormat.excel:
          final excelData = await ExportService.exportEmployeesToExcel(employees);
          await ExportService.saveFile(excelData, filePath);
          break;
        case ReportFormat.csv:
          final csvData = ExportService.exportEmployeesToCSV(employees);
          await ExportService.saveTextFile(csvData, filePath);
          break;
        case ReportFormat.json:
          final jsonData = ExportService.exportEmployeesToJSON(employees);
          await ExportService.saveTextFile(jsonData, filePath);
          break;
      }
      return true;
    } catch (e) {
      print('Employee export error: $e');
      return false;
    }
  }

  Future<bool> _exportTimesheetReport(ReportFormat format, String filePath) async {
    try {
      // Get mock timesheet data for now
      final timesheets = await _getMockTimesheets();

      switch (format) {
        case ReportFormat.pdf:
          final pdfData = await ExportService.exportTimesheetsToPDF(timesheets);
          await ExportService.saveFile(pdfData, filePath);
          break;
        case ReportFormat.excel:
          final excelData = await ExportService.exportTimesheetsToExcel(timesheets);
          await ExportService.saveFile(excelData, filePath);
          break;
        case ReportFormat.csv:
          final csvData = ExportService.exportTimesheetsToCSV(timesheets);
          await ExportService.saveTextFile(csvData, filePath);
          break;
        case ReportFormat.json:
          final jsonData = ExportService.exportTimesheetsToJSON(timesheets);
          await ExportService.saveTextFile(jsonData, filePath);
          break;
      }
      return true;
    } catch (e) {
      print('Timesheet export error: $e');
      return false;
    }
  }

  Future<bool> _exportShiftReport(ReportFormat format, String filePath) async {
    try {
      // For now, export as a generic report
      return await _exportGenericReport(null, format, filePath);
    } catch (e) {
      print('Shift export error: $e');
      return false;
    }
  }

  Future<bool> _exportGenericReport(ReportConfig? report, ReportFormat format, String filePath) async {
    try {
      final reportData = {
        'reportId': report?.id ?? 'unknown',
        'name': report?.name ?? 'Generic Report',
        'generated': DateTime.now().toIso8601String(),
        'format': format.toString(),
        'data': 'This is a generic report export.',
      };

      switch (format) {
        case ReportFormat.json:
          final jsonData = const JsonEncoder.withIndent('  ').convert(reportData);
          await ExportService.saveTextFile(jsonData, filePath);
          break;
        case ReportFormat.csv:
          final csvData = 'Report,Value\nName,${reportData['name']}\nGenerated,${reportData['generated']}\nFormat,${reportData['format']}';
          await ExportService.saveTextFile(csvData, filePath);
          break;
        default:
          // For PDF and Excel, create a simple text file for now
          final textData = 'Report: ${reportData['name']}\nGenerated: ${reportData['generated']}\nFormat: ${reportData['format']}';
          await ExportService.saveTextFile(textData, filePath);
      }
      return true;
    } catch (e) {
      print('Generic export error: $e');
      return false;
    }
  }

  Future<List<Employee>> _getMockEmployees() async {
    // Return mock employee data for testing
    return [
      Employee(
        id: 'emp-1',
        employeeNumber: 'E001',
        firstName: 'Max',
        lastName: 'Mustermann',
        email: 'max.mustermann@example.com',
        dateOfBirth: DateTime(1985, 5, 15),
        position: 'Wohnbereichsleitung',
        department: 'Wohnbereich A',
        contractType: ContractType.fullTime,
        hoursPerWeek: 40.0,
        hourlyRate: 25.50,
        status: EmployeeStatus.active,
        hireDate: DateTime(2022, 1, 15),
        phone: '+49 123 456 7890',
        address: Address(
          street: 'Musterstraße 1',
          city: 'Musterstadt',
          postalCode: '12345',
          country: 'Deutschland',
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Employee(
        id: 'emp-2',
        employeeNumber: 'E002',
        firstName: 'Anna',
        lastName: 'Schmidt',
        email: 'anna.schmidt@example.com',
        dateOfBirth: DateTime(1990, 8, 22),
        position: 'Betreuungsassistentin',
        department: 'Wohnbereich B',
        contractType: ContractType.partTime,
        hoursPerWeek: 30.0,
        hourlyRate: 22.00,
        status: EmployeeStatus.active,
        hireDate: DateTime(2023, 3, 10),
        phone: '+49 123 456 7891',
        address: Address(
          street: 'Beispielweg 5',
          city: 'Musterstadt',
          postalCode: '12345',
          country: 'Deutschland',
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Employee(
        id: 'emp-3',
        employeeNumber: 'E003',
        firstName: 'Thomas',
        lastName: 'Weber',
        email: 'thomas.weber@example.com',
        dateOfBirth: DateTime(1982, 12, 3),
        position: 'Verwaltung',
        department: 'Administration',
        contractType: ContractType.fullTime,
        hoursPerWeek: 40.0,
        hourlyRate: 28.75,
        status: EmployeeStatus.active,
        hireDate: DateTime(2021, 8, 20),
        phone: '+49 123 456 7892',
        address: Address(
          street: 'Teststraße 10',
          city: 'Musterstadt',
          postalCode: '12345',
          country: 'Deutschland',
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  Future<List<dynamic>> _getMockTimesheets() async {
    // Return mock timesheet data for testing
    return [
      MockTimesheet(
        id: 'ts-1',
        employeeId: 'emp-1',
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
        calculatedTotalHours: 40.0,
        calculatedOvertimeHours: 2.5,
        calculatedTotalPay: 1020.0,
        status: 'approved',
      ),
      MockTimesheet(
        id: 'ts-2',
        employeeId: 'emp-2',
        startDate: DateTime.now().subtract(const Duration(days: 14)),
        endDate: DateTime.now().subtract(const Duration(days: 7)),
        calculatedTotalHours: 38.5,
        calculatedOvertimeHours: 0.0,
        calculatedTotalPay: 847.0,
        status: 'approved',
      ),
      MockTimesheet(
        id: 'ts-3',
        employeeId: 'emp-3',
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
        calculatedTotalHours: 42.0,
        calculatedOvertimeHours: 4.0,
        calculatedTotalPay: 1207.5,
        status: 'submitted',
      ),
    ];
  }

  Future<List<String>> getAvailableColumns(ReportType type) async {
    await Future.delayed(const Duration(milliseconds: 200));

    switch (type) {
      case ReportType.employee:
        return ['name', 'vorname', 'position', 'abteilung', 'eintrittsdatum', 'telefon', 'email', 'status'];
      case ReportType.timesheet:
        return ['mitarbeiter', 'datum', 'arbeitszeit', 'überstunden', 'pause', 'projekt', 'notizen'];
      case ReportType.shifts:
        return ['datum', 'schicht', 'mitarbeiter', 'position', 'vertretung', 'besetzung'];
      case ReportType.vacation:
        return ['mitarbeiter', 'urlaubstage_gesamt', 'genommen', 'geplant', 'verfügbar', 'genehmigt'];
      case ReportType.capacity:
        return ['abteilung', 'kapazität', 'auslastung', 'verfügbarkeit', 'trend'];
      case ReportType.attendance:
        return ['mitarbeiter', 'anwesenheit', 'fehlzeiten', 'krankheit', 'urlaub'];
      case ReportType.performance:
        return ['mitarbeiter', 'leistung', 'ziele', 'bewertung', 'feedback'];
      case ReportType.payroll:
        return ['mitarbeiter', 'grundgehalt', 'zulagen', 'überstunden', 'gesamt'];
      case ReportType.overview:
        return ['bereich', 'mitarbeiter', 'stunden', 'kosten', 'effizienz'];
      case ReportType.custom:
        return ['custom_field_1', 'custom_field_2', 'custom_field_3'];
    }
  }
}

class MockTimesheet {
  final String id;
  final String employeeId;
  final DateTime startDate;
  final DateTime endDate;
  final double calculatedTotalHours;
  final double calculatedOvertimeHours;
  final double calculatedTotalPay;
  final String status;

  MockTimesheet({
    required this.id,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.calculatedTotalHours,
    required this.calculatedOvertimeHours,
    required this.calculatedTotalPay,
    required this.status,
  });
}