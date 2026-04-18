import 'dart:io';
import 'dart:typed_data';

import 'package:fegh_pdf_kit/fegh_pdf_kit.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/capacity_analytics.dart';
import '../models/employee.dart';
import '../models/timesheet.dart';

/// Erzeugt die Report-PDFs der FEGH-Verwaltung.
///
/// Das Design kommt aus dem gemeinsamen `fegh_pdf_kit`, die Inhalte
/// (Zeitnachweise, Kapazitaet, Team-Status, Monatsberichte) sind
/// verwaltungsspezifisch.
class PdfReportService {
  static const String _appName = 'FEGH-Verwaltung';
  static const String _appTagline = 'Personalverwaltung Eingliederungshilfe';

  // ── Zeitnachweis einzeln ─────────────────────────────────────────

  Future<String> generateTimesheetReport({
    required Timesheet timesheet,
    required Employee employee,
    List<TimesheetEntry>? entries,
  }) async {
    final bytes = await _buildTimesheetPdf(timesheet, employee, entries ?? []);
    return _writeBytes(bytes, 'zeitnachweis_${timesheet.id}.pdf');
  }

  // ── Kapazitaetsanalyse ───────────────────────────────────────────

  Future<String> generateCapacityReport({
    required WorkforceAnalytics analytics,
    DateTime? reportDate,
  }) async {
    final bytes = await _buildCapacityPdf(analytics, reportDate ?? DateTime.now());
    return _writeBytes(
      bytes,
      'kapazitaetsbericht_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // ── Teamkapazitaeten ─────────────────────────────────────────────

  Future<String> generateTeamCapacityReport({
    required List<TeamCapacity> teamCapacities,
    DateTime? reportDate,
  }) async {
    final bytes = await _buildTeamCapacityPdf(teamCapacities, reportDate ?? DateTime.now());
    return _writeBytes(
      bytes,
      'team_kapazitaet_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // ── Monatsbericht ────────────────────────────────────────────────

  Future<String> generateMonthlyTimesheetSummary({
    required List<Timesheet> timesheets,
    required DateTime month,
    Map<String, Employee>? employees,
  }) async {
    final bytes = await _buildMonthlyPdf(timesheets, month, employees ?? {});
    return _writeBytes(
      bytes,
      'monatsbericht_${month.year}_${month.month.toString().padLeft(2, '0')}.pdf',
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // PDF-Bauten
  // ═════════════════════════════════════════════════════════════════

  Future<Uint8List> _buildTimesheetPdf(
    Timesheet t,
    Employee e,
    List<TimesheetEntry> entries,
  ) async {
    final theme = await PdfFontCache.theme();
    final pdf = pw.Document(theme: theme);
    final df = DateFormat('dd.MM.yyyy');
    final euro = NumberFormat.currency(locale: 'de_DE', symbol: '\u20AC');

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 50),
      header: (ctx) => buildHeader(
        title: 'Zeitnachweis',
        appName: _appName,
        appTagline: _appTagline,
        aktenzeichen: t.id,
      ),
      footer: buildFooter(appName: _appName),
      build: (ctx) => [
        pw.SizedBox(height: 20),
        buildHero(
          label: 'MITARBEITER',
          title: e.fullName,
          subtitle:
              '${e.position} | ${e.department} | Pers.-Nr. ${e.employeeNumber}',
        ),
        pw.SizedBox(height: 32),
        buildKpiRow([
          PdfKpi(
            label: 'Gesamtstunden',
            value: '${t.calculatedTotalHours.toStringAsFixed(1)} h',
            color: PdfDesignTokens.primaer,
            hero: true,
          ),
          PdfKpi(
            label: 'Regulaer',
            value: '${t.calculatedRegularHours.toStringAsFixed(1)} h',
            color: PdfDesignTokens.text,
          ),
          PdfKpi(
            label: 'Ueberstunden',
            value: '${t.calculatedOvertimeHours.toStringAsFixed(1)} h',
            color: t.calculatedOvertimeHours > 0
                ? PdfDesignTokens.warnSoft
                : PdfDesignTokens.text,
          ),
          PdfKpi(
            label: 'Verguetung',
            value: euro.format(t.calculatedTotalPay),
            color: PdfDesignTokens.accent,
          ),
        ]),
        pw.SizedBox(height: 32),
        buildSectionHeading('I', 'Zeitraum und Status'),
        pw.SizedBox(height: 14),
        _keyValueTable([
          ['Zeitraum', '${df.format(t.startDate)} - ${df.format(t.endDate)}'],
          ['Status', t.statusLabel],
          ['Erstellt', df.format(t.createdAt)],
          if (t.submittedAt != null) ['Eingereicht', df.format(t.submittedAt!)],
          if (t.approvedAt != null) ['Genehmigt', df.format(t.approvedAt!)],
        ]),
        if (entries.isNotEmpty) ...[
          pw.SizedBox(height: 24),
          buildSectionHeading('II', 'Eintraege'),
          pw.SizedBox(height: 14),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1.1),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(2.2),
              3: pw.FlexColumnWidth(0.9),
              4: pw.FlexColumnWidth(0.9),
            },
            children: [
              buildTableHeader(
                ['Datum', 'Zeit', 'Typ', 'Stunden', 'Verguetung'],
                alignRight: const [false, false, false, true, true],
              ),
              ...entries.map((entry) => buildTableRow([
                    df.format(entry.startTime),
                    '${DateFormat('HH:mm').format(entry.startTime)} - ${DateFormat('HH:mm').format(entry.endTime)}',
                    _typeLabel(entry.type),
                    '${entry.totalHours.toStringAsFixed(2)} h',
                    euro.format(entry.calculatedPay),
                  ], alignRight: const [false, false, false, true, true])),
            ],
          ),
        ],
        if (t.notes != null && t.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 24),
          buildSectionHeading(entries.isNotEmpty ? 'III' : 'II', 'Notizen'),
          pw.SizedBox(height: 8),
          pw.Text(t.notes!,
              style: pw.TextStyle(fontSize: 10, color: PdfDesignTokens.text)),
        ],
        pw.SizedBox(height: 40),
        buildSignatureRow(authorName: e.fullName),
      ],
    ));
    return pdf.save();
  }

  Future<Uint8List> _buildCapacityPdf(
    WorkforceAnalytics a,
    DateTime reportDate,
  ) async {
    final theme = await PdfFontCache.theme();
    final pdf = pw.Document(theme: theme);
    final df = DateFormat('dd.MM.yyyy HH:mm');

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 50),
      header: (ctx) => buildHeader(
        title: 'Kapazitaetsanalyse',
        appName: _appName,
        appTagline: _appTagline,
      ),
      footer: buildFooter(appName: _appName),
      build: (ctx) => [
        pw.SizedBox(height: 20),
        buildHero(
          label: 'STICHTAG',
          title: 'Workforce Analytics',
          subtitle: df.format(reportDate),
        ),
        pw.SizedBox(height: 32),
        buildKpiRow([
          PdfKpi(
            label: 'Mitarbeiter',
            value: '${a.activeEmployees} / ${a.totalEmployees}',
            color: PdfDesignTokens.primaer,
            hero: true,
          ),
          PdfKpi(
            label: 'Verfuegbarkeit',
            value: '${a.availabilityRate.toStringAsFixed(1)} %',
            color: a.availabilityRate >= 85
                ? PdfDesignTokens.accent
                : PdfDesignTokens.warn,
          ),
          PdfKpi(
            label: 'Kapazitaet',
            value: '${a.overallCapacity.toStringAsFixed(1)} %',
            color: PdfDesignTokens.text,
          ),
          PdfKpi(
            label: 'Ueberstunden',
            value: '${a.overtimePercentage.toStringAsFixed(1)} %',
            color: a.overtimePercentage > 15
                ? PdfDesignTokens.warn
                : PdfDesignTokens.text,
          ),
        ]),
        pw.SizedBox(height: 32),
        buildSectionHeading('I', 'Team-Status'),
        pw.SizedBox(height: 14),
        if (a.teamCapacities.isEmpty)
          buildEmptyState('Keine Team-Daten vorhanden.')
        else
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(1.3),
              2: pw.FlexColumnWidth(1.2),
              3: pw.FlexColumnWidth(1.2),
            },
            children: [
              buildTableHeader(
                ['Team', 'Status', 'Kapazitaet', 'Personal'],
                alignRight: const [false, false, true, true],
              ),
              ...a.teamCapacities.map((team) => buildTableRow(
                    [
                      team.teamName,
                      team.statusLabel,
                      '${team.capacityPercentage.toStringAsFixed(0)} %',
                      '${team.availableStaff} / ${team.requiredStaff}',
                    ],
                    alignRight: const [false, false, true, true],
                    warnIdx: team.capacityPercentage < 75 ? 2 : null,
                  )),
            ],
          ),
        if (a.departmentDistribution.isNotEmpty) ...[
          pw.SizedBox(height: 24),
          buildSectionHeading('II', 'Abteilungsverteilung'),
          pw.SizedBox(height: 14),
          buildHorizontalBarList(
            a.departmentDistribution.map((k, v) => MapEntry(k, v.toDouble())),
            total: a.departmentDistribution.values.fold(0, (s, v) => s + v).toDouble(),
            unit: 'MA',
          ),
        ],
        if (a.criticalAlerts.isNotEmpty) ...[
          pw.SizedBox(height: 24),
          buildSectionHeading('III', 'Kritische Warnungen'),
          pw.SizedBox(height: 8),
          ...a.criticalAlerts.map((alert) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Text('\u2022 $alert',
                    style: pw.TextStyle(
                        fontSize: 10, color: PdfDesignTokens.warn)),
              )),
        ],
        pw.SizedBox(height: 40),
        buildSignatureRow(),
      ],
    ));
    return pdf.save();
  }

  Future<Uint8List> _buildTeamCapacityPdf(
    List<TeamCapacity> teams,
    DateTime reportDate,
  ) async {
    final theme = await PdfFontCache.theme();
    final pdf = pw.Document(theme: theme);
    final df = DateFormat('dd.MM.yyyy');

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 50),
      header: (ctx) => buildHeader(
        title: 'Team-Kapazitaeten',
        appName: _appName,
        appTagline: _appTagline,
      ),
      footer: buildFooter(appName: _appName),
      build: (ctx) => [
        pw.SizedBox(height: 20),
        buildHero(
          label: 'STICHTAG',
          title: 'Team-Kapazitaeten',
          subtitle: '${teams.length} Teams | ${df.format(reportDate)}',
        ),
        pw.SizedBox(height: 28),
        if (teams.isEmpty) buildEmptyState('Keine Teams vorhanden.'),
        ...teams.map((team) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildSectionHeading(
                    teams.indexOf(team).toString().padLeft(2, '0'),
                    team.teamName,
                  ),
                  pw.SizedBox(height: 10),
                  _keyValueTable([
                    ['Status', team.statusLabel],
                    ['Kapazitaet', '${team.capacityPercentage.toStringAsFixed(1)} %'],
                    ['Benoetigt', '${team.requiredStaff}'],
                    ['Verfuegbar', '${team.availableStaff}'],
                    ['Aktiv', '${team.activeStaff}'],
                  ]),
                  if (team.warnings.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    ...team.warnings.map((w) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Text('\u26A0 $w',
                              style: pw.TextStyle(
                                  fontSize: 9, color: PdfDesignTokens.warn)),
                        )),
                  ],
                ],
              ),
            )),
      ],
    ));
    return pdf.save();
  }

  Future<Uint8List> _buildMonthlyPdf(
    List<Timesheet> timesheets,
    DateTime month,
    Map<String, Employee> employees,
  ) async {
    final theme = await PdfFontCache.theme();
    final pdf = pw.Document(theme: theme);
    final euro = NumberFormat.currency(locale: 'de_DE', symbol: '\u20AC');

    final byStatus = <TimesheetStatus, int>{};
    double totalHours = 0;
    double totalPay = 0;
    for (final t in timesheets) {
      byStatus[t.status] = (byStatus[t.status] ?? 0) + 1;
      totalHours += t.calculatedTotalHours;
      totalPay += t.calculatedTotalPay;
    }

    final monthLabel = DateFormat('MMMM yyyy', 'de_DE').format(month);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 50),
      header: (ctx) => buildHeader(
        title: 'Monatsbericht Zeitnachweise',
        appName: _appName,
        appTagline: _appTagline,
      ),
      footer: buildFooter(appName: _appName),
      build: (ctx) => [
        pw.SizedBox(height: 20),
        buildHero(
          label: 'ZEITRAUM',
          title: monthLabel,
          subtitle: '${timesheets.length} Zeitnachweise',
        ),
        pw.SizedBox(height: 32),
        buildKpiRow([
          PdfKpi(
            label: 'Zeitnachweise',
            value: '${timesheets.length}',
            color: PdfDesignTokens.primaer,
            hero: true,
          ),
          PdfKpi(
            label: 'Gesamtstunden',
            value: '${totalHours.toStringAsFixed(0)} h',
            color: PdfDesignTokens.text,
          ),
          PdfKpi(
            label: 'Verguetung',
            value: euro.format(totalPay),
            color: PdfDesignTokens.accent,
          ),
        ]),
        pw.SizedBox(height: 32),
        buildSectionHeading('I', 'Verteilung nach Status'),
        pw.SizedBox(height: 14),
        _keyValueTable([
          for (final entry in byStatus.entries)
            [_statusLabel(entry.key), '${entry.value}'],
        ]),
        pw.SizedBox(height: 24),
        buildSectionHeading('II', 'Einzelnachweis'),
        pw.SizedBox(height: 14),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(1.4),
            1: pw.FlexColumnWidth(2.4),
            2: pw.FlexColumnWidth(1.4),
            3: pw.FlexColumnWidth(0.9),
            4: pw.FlexColumnWidth(1.1),
          },
          children: [
            buildTableHeader(
              ['ID', 'Mitarbeiter', 'Status', 'Stunden', 'Verguetung'],
              alignRight: const [false, false, false, true, true],
            ),
            ...timesheets.map((t) {
              final e = employees[t.employeeId];
              return buildTableRow(
                [
                  t.id,
                  e?.fullName ?? 'Unbekannt',
                  t.statusLabel,
                  '${t.calculatedTotalHours.toStringAsFixed(1)} h',
                  euro.format(t.calculatedTotalPay),
                ],
                alignRight: const [false, false, false, true, true],
              );
            }),
          ],
        ),
      ],
    ));
    return pdf.save();
  }

  // ─────────────────────────────────────────────────────────────────
  // Helfer
  // ─────────────────────────────────────────────────────────────────

  pw.Widget _keyValueTable(List<List<String>> rows) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(2),
      },
      children: [
        for (final r in rows)
          buildTableRow([r[0], r[1]], alignRight: const [false, false]),
      ],
    );
  }

  Future<String> _writeBytes(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  String _typeLabel(TimesheetEntryType t) {
    switch (t) {
      case TimesheetEntryType.regular:
        return 'Regulaere Arbeitszeit';
      case TimesheetEntryType.overtime:
        return 'Ueberstunden';
      case TimesheetEntryType.travel:
        return 'Fahrtzeit';
      case TimesheetEntryType.break_:
        return 'Pause';
      case TimesheetEntryType.training:
        return 'Schulung';
      case TimesheetEntryType.administrative:
        return 'Verwaltung';
    }
  }

  String _statusLabel(TimesheetStatus s) {
    switch (s) {
      case TimesheetStatus.draft:
        return 'Entwurf';
      case TimesheetStatus.submitted:
        return 'Eingereicht';
      case TimesheetStatus.approved:
        return 'Genehmigt';
      case TimesheetStatus.rejected:
        return 'Abgelehnt';
      case TimesheetStatus.finalized:
        return 'Abgeschlossen';
    }
  }
}
