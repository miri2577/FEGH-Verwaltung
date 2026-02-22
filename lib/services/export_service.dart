import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/employee.dart';
import '../models/timesheet.dart';
import '../models/shift.dart';

class ExportService {
  static Future<Uint8List> exportEmployeesToPDF(List<Employee> employees) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            'Mitarbeiter-Report',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Seite ${context.pageNumber} von ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Generiert am: ${DateTime.now().toString().substring(0, 19)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Name',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'E-Mail',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Position',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Stundenlohn',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Status',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ...employees.map((employee) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${employee.firstName} ${employee.lastName}'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(employee.email),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(employee.position),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('€${employee.hourlyRate.toStringAsFixed(2)}'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(employee.status.toString().split('.').last),
                  ),
                ],
              )),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> exportTimesheetsToPDF(List<dynamic> timesheets) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            'Zeitnachweise-Report',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Seite ${context.pageNumber} von ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Generiert am: ${DateTime.now().toString().substring(0, 19)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Mitarbeiter ID',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Zeitraum',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Stunden',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Überstunden',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Vergütung',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Status',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ...timesheets.map((timesheet) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(timesheet.employeeId),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${timesheet.startDate.day}.${timesheet.startDate.month} - ${timesheet.endDate.day}.${timesheet.endDate.month}'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${timesheet.calculatedTotalHours.toStringAsFixed(1)}h'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${timesheet.calculatedOvertimeHours.toStringAsFixed(1)}h'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('€${timesheet.calculatedTotalPay.toStringAsFixed(2)}'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(timesheet.status.toString().split('.').last),
                  ),
                ],
              )),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> exportEmployeesToExcel(List<Employee> employees) async {
    final excel = Excel.createExcel();
    final sheet = excel['Mitarbeiter'];

    final headers = ['Name', 'Vorname', 'E-Mail', 'Position', 'Stundenlohn', 'Status', 'Einstellungsdatum'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }

    for (int i = 0; i < employees.length; i++) {
      final employee = employees[i];
      final row = i + 1;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(employee.lastName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(employee.firstName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(employee.email);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(employee.position);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(employee.hourlyRate);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = TextCellValue(employee.status.toString().split('.').last);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = TextCellValue(employee.hireDate.toString().substring(0, 10));
    }

    return Uint8List.fromList(excel.encode()!);
  }

  static Future<Uint8List> exportTimesheetsToExcel(List<dynamic> timesheets) async {
    final excel = Excel.createExcel();
    final sheet = excel['Zeitnachweise'];

    final headers = ['Mitarbeiter ID', 'Startdatum', 'Enddatum', 'Gesamtstunden', 'Überstunden', 'Vergütung', 'Status'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }

    for (int i = 0; i < timesheets.length; i++) {
      final timesheet = timesheets[i];
      final row = i + 1;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(timesheet.employeeId);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(timesheet.startDate.toString().substring(0, 10));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(timesheet.endDate.toString().substring(0, 10));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = DoubleCellValue(timesheet.calculatedTotalHours);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(timesheet.calculatedOvertimeHours);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(timesheet.calculatedTotalPay);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = TextCellValue(timesheet.status.toString().split('.').last);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  static String exportEmployeesToCSV(List<Employee> employees) {
    final List<List<String>> rows = [];

    rows.add(['Name', 'Vorname', 'E-Mail', 'Position', 'Stundenlohn', 'Status', 'Einstellungsdatum']);

    for (final employee in employees) {
      rows.add([
        employee.lastName,
        employee.firstName,
        employee.email,
        employee.position,
        employee.hourlyRate.toString(),
        employee.status.toString().split('.').last,
        employee.hireDate.toString().substring(0, 10),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  static String exportTimesheetsToCSV(List<dynamic> timesheets) {
    final List<List<String>> rows = [];

    rows.add(['Mitarbeiter ID', 'Startdatum', 'Enddatum', 'Gesamtstunden', 'Überstunden', 'Vergütung', 'Status']);

    for (final timesheet in timesheets) {
      rows.add([
        timesheet.employeeId,
        timesheet.startDate.toString().substring(0, 10),
        timesheet.endDate.toString().substring(0, 10),
        timesheet.calculatedTotalHours.toString(),
        timesheet.calculatedOvertimeHours.toString(),
        timesheet.calculatedTotalPay.toString(),
        timesheet.status.toString().split('.').last,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  static String exportEmployeesToJSON(List<Employee> employees) {
    final List<Map<String, dynamic>> data = employees.map((employee) => {
      'id': employee.id,
      'firstName': employee.firstName,
      'lastName': employee.lastName,
      'email': employee.email,
      'position': employee.position,
      'hourlyRate': employee.hourlyRate,
      'status': employee.status.toString().split('.').last,
      'hireDate': employee.hireDate.toIso8601String(),
      'phone': employee.phone,
      'address': employee.address,
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'employees': data,
      'exportDate': DateTime.now().toIso8601String(),
      'totalCount': employees.length,
    });
  }

  static String exportTimesheetsToJSON(List<dynamic> timesheets) {
    final List<Map<String, dynamic>> data = timesheets.map((timesheet) => {
      'id': timesheet.id,
      'employeeId': timesheet.employeeId,
      'startDate': timesheet.startDate.toIso8601String(),
      'endDate': timesheet.endDate.toIso8601String(),
      'totalHours': timesheet.calculatedTotalHours,
      'overtimeHours': timesheet.calculatedOvertimeHours,
      'totalPay': timesheet.calculatedTotalPay,
      'status': timesheet.status.toString().split('.').last,
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'timesheets': data,
      'exportDate': DateTime.now().toIso8601String(),
      'totalCount': timesheets.length,
    });
  }

  static Future<void> saveFile(Uint8List data, String fileName) async {
    final file = File(fileName);
    await file.writeAsBytes(data);
  }

  static Future<void> saveTextFile(String content, String fileName) async {
    final file = File(fileName);
    await file.writeAsString(content);
  }
}