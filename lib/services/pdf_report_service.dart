import 'dart:io';
import 'dart:typed_data';

import 'package:fegh_pdf_kit/fegh_pdf_kit.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/capacity_analytics.dart';
import '../models/employee.dart';
import '../models/kassenbuch_eintrag.dart';
import '../models/shift.dart';
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

  // ── Kassenbuch-Monatsauszug ───────────────────────────────────────

  /// Monatsauszug pro Klient: Kopf mit Klient, Zeitraum und Saldo-Kennzahlen,
  /// Tabelle mit Einzelbuchungen und fortlaufendem Saldo, Unterschriften.
  Future<String> generateKassenbuchMonthlyStatement({
    required String clientId,
    required String clientName,
    required DateTime month,
    required double saldoVorMonat,
    required List<KassenbuchEintrag> eintraege,
  }) async {
    final bytes = await _buildKassenbuchPdf(
        clientId, clientName, month, saldoVorMonat, eintraege);
    final ymd =
        '${month.year}_${month.month.toString().padLeft(2, '0')}';
    return _writeBytes(bytes, 'kassenbuch_${_slug(clientName)}_$ymd.pdf');
  }

  // ── Dienstplan-Aushang ────────────────────────────────────────────

  /// Aushang-PDF fuer einen Wochendienstplan: Mitarbeiter × 7 Tage,
  /// Zellen mit Zeiten und Schichttyp. A4 quer.
  Future<String> generateShiftScheduleAushang({
    required String teamName,
    required DateTime weekStart, // Montag
    required List<Shift> shifts,
    required Map<String, Employee> employees,
  }) async {
    final bytes = await _buildAushangPdf(teamName, weekStart, shifts, employees);
    final ymd =
        '${weekStart.year}_${weekStart.month.toString().padLeft(2, '0')}_${weekStart.day.toString().padLeft(2, '0')}';
    return _writeBytes(bytes, 'dienstplan_${_slug(teamName)}_$ymd.pdf');
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

  Future<Uint8List> _buildKassenbuchPdf(
    String clientId,
    String clientName,
    DateTime month,
    double saldoVorMonat,
    List<KassenbuchEintrag> eintraege,
  ) async {
    final theme = await PdfFontCache.theme();
    final pdf = pw.Document(theme: theme);
    final euro = NumberFormat.currency(locale: 'de_DE', symbol: '\u20AC');
    final df = DateFormat('dd.MM.yyyy');
    final monthLabel = DateFormat('MMMM yyyy', 'de_DE').format(month);

    // Monats-Eintraege aufsteigend (fuer fortlaufenden Saldo)
    final monatsEintraege = eintraege
        .where((e) =>
            e.datum.year == month.year && e.datum.month == month.month)
        .toList()
      ..sort((a, b) => a.datum.compareTo(b.datum));

    double einzahlungen = 0;
    double auszahlungen = 0;
    for (final e in monatsEintraege) {
      if (e.betrag >= 0) {
        einzahlungen += e.betrag;
      } else {
        auszahlungen += e.betrag.abs();
      }
    }
    final saldoEnde = saldoVorMonat + einzahlungen - auszahlungen;

    // Fortlaufender Saldo fuer die Tabelle
    double laufend = saldoVorMonat;
    final rows = <List<String>>[];
    for (final e in monatsEintraege) {
      laufend += e.betrag;
      rows.add([
        df.format(e.datum),
        e.kategorie.label,
        e.beschreibung,
        '${e.betrag >= 0 ? '+' : ''}${euro.format(e.betrag)}',
        euro.format(laufend),
      ]);
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 50),
      header: (ctx) => buildHeader(
        title: 'Kassenbuch-Monatsauszug',
        appName: _appName,
        appTagline: _appTagline,
        aktenzeichen: clientId,
      ),
      footer: buildFooter(appName: _appName),
      build: (ctx) => [
        pw.SizedBox(height: 20),
        buildHero(
          label: 'KLIENT',
          title: clientName,
          subtitle: monthLabel,
        ),
        pw.SizedBox(height: 32),
        buildKpiRow([
          PdfKpi(
            label: 'Saldo Monatsanfang',
            value: euro.format(saldoVorMonat),
            color: PdfDesignTokens.text,
          ),
          PdfKpi(
            label: 'Einzahlungen',
            value: euro.format(einzahlungen),
            color: PdfDesignTokens.accent,
          ),
          PdfKpi(
            label: 'Auszahlungen',
            value: euro.format(auszahlungen),
            color: PdfDesignTokens.warn,
          ),
          PdfKpi(
            label: 'Saldo Monatsende',
            value: euro.format(saldoEnde),
            color: saldoEnde < 0
                ? PdfDesignTokens.warn
                : PdfDesignTokens.primaer,
            hero: true,
          ),
        ]),
        pw.SizedBox(height: 28),
        buildSectionHeading('I', 'Einzelbuchungen'),
        pw.SizedBox(height: 12),
        if (monatsEintraege.isEmpty)
          buildEmptyState('Keine Buchungen in diesem Monat.')
        else
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1.1),
              1: pw.FlexColumnWidth(1.3),
              2: pw.FlexColumnWidth(2.5),
              3: pw.FlexColumnWidth(1),
              4: pw.FlexColumnWidth(1.1),
            },
            children: [
              buildTableHeader(
                ['Datum', 'Kategorie', 'Beschreibung', 'Betrag', 'Saldo'],
                alignRight: const [false, false, false, true, true],
              ),
              ...rows.map(
                (r) => buildTableRow(
                  r,
                  alignRight: const [false, false, false, true, true],
                ),
              ),
            ],
          ),
        pw.SizedBox(height: 24),
        pw.Text(
          'Dieser Auszug ist ein Monatsabschluss. Nicht-freigegebene '
          'Eintraege sind bis zur Freigabe aenderbar; nach Freigabe '
          'verbleibt als Aenderung nur die Stornobuchung.',
          style: pw.TextStyle(fontSize: 9, color: PdfDesignTokens.muted),
        ),
        pw.SizedBox(height: 36),
        buildSignatureRow(),
      ],
    ));
    return pdf.save();
  }

  Future<Uint8List> _buildAushangPdf(
    String teamName,
    DateTime weekStart,
    List<Shift> shifts,
    Map<String, Employee> employees,
  ) async {
    final theme = await PdfFontCache.theme();
    final pdf = pw.Document(theme: theme);
    final df = DateFormat('dd.MM.');

    final weekDays = List<DateTime>.generate(
      7,
      (i) => DateTime(weekStart.year, weekStart.month, weekStart.day + i),
    );
    final weekEnd = weekDays.last;

    // Gruppiere Schichten pro Mitarbeiter (nur Mitarbeiter mit Schichten)
    final byEmployee = <String, List<Shift>>{};
    for (final s in shifts) {
      if (s.status == ShiftStatus.cancelled) continue;
      if (!s.startTime.isAfter(weekEnd.add(const Duration(days: 1))) &&
          !s.endTime.isBefore(weekStart)) {
        byEmployee.putIfAbsent(s.employeeId, () => []).add(s);
      }
    }
    final sortedEmployees = byEmployee.keys.toList()
      ..sort((a, b) => (employees[a]?.fullName ?? a)
          .compareTo(employees[b]?.fullName ?? b));

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.fromLTRB(30, 30, 30, 30),
      header: (ctx) => buildHeader(
        title: 'Dienstplan Aushang',
        appName: _appName,
        appTagline: _appTagline,
      ),
      footer: buildFooter(appName: _appName),
      build: (ctx) => [
        pw.SizedBox(height: 12),
        buildHero(
          label: 'TEAM',
          title: teamName,
          subtitle:
              'Woche ${df.format(weekStart)} bis ${df.format(weekEnd)}.${weekEnd.year}',
        ),
        pw.SizedBox(height: 20),
        if (sortedEmployees.isEmpty)
          buildEmptyState('Keine Schichten in dieser Woche.')
        else
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              for (var i = 0; i < 7; i++) (i + 1): const pw.FlexColumnWidth(1.3),
            },
            children: [
              buildTableHeader([
                'Mitarbeiter',
                ..._weekdayLabels(weekDays),
              ]),
              ...sortedEmployees.map((empId) {
                final name = employees[empId]?.fullName ?? empId;
                final row = <String>[name];
                for (final d in weekDays) {
                  row.add(_cellText(byEmployee[empId]!, d));
                }
                return buildTableRow(row);
              }),
            ],
          ),
        pw.SizedBox(height: 18),
        pw.Text(
          'Legende: F = Frueh, S = Spaet, N = Nacht, U = Urlaub, ! = gekuerzte Ruhezeit',
          style: pw.TextStyle(fontSize: 8, color: PdfDesignTokens.muted),
        ),
      ],
    ));
    return pdf.save();
  }

  List<String> _weekdayLabels(List<DateTime> days) {
    const names = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return [
      for (var i = 0; i < days.length; i++)
        '${names[i]} ${days[i].day.toString().padLeft(2, '0')}.${days[i].month.toString().padLeft(2, '0')}.',
    ];
  }

  String _cellText(List<Shift> shifts, DateTime day) {
    final matching = shifts.where((s) =>
        s.startTime.year == day.year &&
        s.startTime.month == day.month &&
        s.startTime.day == day.day).toList();
    if (matching.isEmpty) return '';
    matching.sort((a, b) => a.startTime.compareTo(b.startTime));
    return matching
        .map((s) =>
            '${_tt(s.startTime)}-${_tt(s.endTime)} ${_shortType(s.type)}')
        .join('\n');
  }

  String _tt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _shortType(ShiftType t) {
    switch (t) {
      case ShiftType.regular:
        return '';
      case ShiftType.overtime:
        return 'ÜS';
      case ShiftType.holiday:
        return 'FT';
      case ShiftType.night:
        return 'N';
      case ShiftType.weekend:
        return 'WE';
    }
  }

  String _slug(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
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
