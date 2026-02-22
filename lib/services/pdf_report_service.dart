import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/timesheet.dart';
import '../models/employee.dart';
import '../models/capacity_analytics.dart';

class PdfReportService {
  static const String _companyName = 'Eingliederungshilfe Enterprise';
  static const String _companyAddress = 'Musterstraße 123, 12345 Berlin';

  Future<String> generateTimesheetReport({
    required Timesheet timesheet,
    required Employee employee,
    List<TimesheetEntry>? entries,
  }) async {
    try {
      // For this implementation, we'll create a detailed text-based report
      // In a real implementation, you would use packages like pdf or printing

      final reportContent = _buildTimesheetReportContent(timesheet, employee, entries ?? []);

      // Save to documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/zeitnachweis_${timesheet.id}.txt');
      await file.writeAsString(reportContent);

      return file.path;
    } catch (e) {
      throw Exception('Fehler beim Erstellen des PDF-Berichts: $e');
    }
  }

  Future<String> generateCapacityReport({
    required WorkforceAnalytics analytics,
    DateTime? reportDate,
  }) async {
    try {
      final reportContent = _buildCapacityReportContent(analytics, reportDate ?? DateTime.now());

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'kapazitaetsbericht_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(reportContent);

      return file.path;
    } catch (e) {
      throw Exception('Fehler beim Erstellen des Kapazitätsberichts: $e');
    }
  }

  Future<String> generateTeamCapacityReport({
    required List<TeamCapacity> teamCapacities,
    DateTime? reportDate,
  }) async {
    try {
      final reportContent = _buildTeamCapacityReportContent(teamCapacities, reportDate ?? DateTime.now());

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'team_kapazitaet_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(reportContent);

      return file.path;
    } catch (e) {
      throw Exception('Fehler beim Erstellen des Team-Berichts: $e');
    }
  }

  Future<String> generateMonthlyTimesheetSummary({
    required List<Timesheet> timesheets,
    required DateTime month,
    Map<String, Employee>? employees,
  }) async {
    try {
      final reportContent = _buildMonthlyTimesheetSummary(timesheets, month, employees ?? {});

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'monatsbericht_${month.year}_${month.month.toString().padLeft(2, '0')}.txt';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(reportContent);

      return file.path;
    } catch (e) {
      throw Exception('Fehler beim Erstellen des Monatsberichts: $e');
    }
  }

  String _buildTimesheetReportContent(Timesheet timesheet, Employee employee, List<TimesheetEntry> entries) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('═══════════════════════════════════════════════════════════════');
    buffer.writeln('                    ZEITNACHWEIS BERICHT');
    buffer.writeln('═══════════════════════════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('Unternehmen: $_companyName');
    buffer.writeln('Adresse:     $_companyAddress');
    buffer.writeln('Erstellt am: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}');
    buffer.writeln();

    // Employee Information
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('MITARBEITER INFORMATIONEN');
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('Name:            ${employee.fullName}');
    buffer.writeln('Personalnummer:  ${employee.employeeNumber}');
    buffer.writeln('Abteilung:       ${employee.department}');
    buffer.writeln('Position:        ${employee.position}');
    buffer.writeln('E-Mail:          ${employee.email}');
    buffer.writeln();

    // Timesheet Information
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('ZEITNACHWEIS DETAILS');
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('Zeitnachweis-ID: ${timesheet.id}');
    buffer.writeln('Status:          ${timesheet.statusLabel}');
    buffer.writeln('Zeitraum:        ${timesheet.startDate.day}.${timesheet.startDate.month}.${timesheet.startDate.year} - ${timesheet.endDate.day}.${timesheet.endDate.month}.${timesheet.endDate.year}');
    buffer.writeln('Erstellt:        ${timesheet.createdAt.day}.${timesheet.createdAt.month}.${timesheet.createdAt.year}');

    if (timesheet.submittedAt != null) {
      buffer.writeln('Eingereicht:     ${timesheet.submittedAt!.day}.${timesheet.submittedAt!.month}.${timesheet.submittedAt!.year}');
    }
    if (timesheet.approvedAt != null) {
      buffer.writeln('Genehmigt:       ${timesheet.approvedAt!.day}.${timesheet.approvedAt!.month}.${timesheet.approvedAt!.year}');
    }
    buffer.writeln();

    // Summary
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('ZUSAMMENFASSUNG');
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('Gesamtstunden:    ${timesheet.calculatedTotalHours.toStringAsFixed(2)} h');
    buffer.writeln('Reguläre Stunden: ${timesheet.calculatedRegularHours.toStringAsFixed(2)} h');
    buffer.writeln('Überstunden:      ${timesheet.calculatedOvertimeHours.toStringAsFixed(2)} h');
    buffer.writeln('Gesamtvergütung:  €${timesheet.calculatedTotalPay.toStringAsFixed(2)}');
    buffer.writeln();

    // Entries
    if (entries.isNotEmpty) {
      buffer.writeln('───────────────────────────────────────────────────────────────');
      buffer.writeln('ARBEITSZEIT EINTRÄGE');
      buffer.writeln('───────────────────────────────────────────────────────────────');

      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        buffer.writeln('${i + 1}. ${_getTypeLabel(entry.type)}');
        buffer.writeln('   Datum:        ${entry.startTime.day}.${entry.startTime.month}.${entry.startTime.year}');
        buffer.writeln('   Zeit:         ${entry.startTime.hour}:${entry.startTime.minute.toString().padLeft(2, '0')} - ${entry.endTime.hour}:${entry.endTime.minute.toString().padLeft(2, '0')}');
        buffer.writeln('   Arbeitszeit:  ${entry.totalHours.toStringAsFixed(2)} h');
        buffer.writeln('   Vergütung:    €${entry.calculatedPay.toStringAsFixed(2)}');

        if (entry.description != null && entry.description!.isNotEmpty) {
          buffer.writeln('   Beschreibung: ${entry.description}');
        }
        if (entry.location != null && entry.location!.isNotEmpty) {
          buffer.writeln('   Ort:          ${entry.location}');
        }
        if (entry.breakDurationMinutes != null && entry.breakDurationMinutes! > 0) {
          buffer.writeln('   Pause:        ${entry.breakDurationMinutes!.toStringAsFixed(0)} min');
        }
        buffer.writeln();
      }
    }

    // Notes
    if (timesheet.notes != null && timesheet.notes!.isNotEmpty) {
      buffer.writeln('───────────────────────────────────────────────────────────────');
      buffer.writeln('NOTIZEN');
      buffer.writeln('───────────────────────────────────────────────────────────────');
      buffer.writeln(timesheet.notes);
      buffer.writeln();
    }

    // Footer
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('Dieser Bericht wurde automatisch generiert durch das');
    buffer.writeln('Personalverwaltungssystem von $_companyName');
    buffer.writeln('───────────────────────────────────────────────────────────────');

    return buffer.toString();
  }

  String _buildCapacityReportContent(WorkforceAnalytics analytics, DateTime reportDate) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('═══════════════════════════════════════════════════════════════');
    buffer.writeln('                KAPAZITÄTSANALYSE BERICHT');
    buffer.writeln('═══════════════════════════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('Unternehmen: $_companyName');
    buffer.writeln('Adresse:     $_companyAddress');
    buffer.writeln('Erstellt am: ${reportDate.day}.${reportDate.month}.${reportDate.year} ${reportDate.hour}:${reportDate.minute.toString().padLeft(2, '0')}');
    buffer.writeln();

    // Executive Summary
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('EXECUTIVE SUMMARY');
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('Gesamtmitarbeiter:     ${analytics.totalEmployees}');
    buffer.writeln('Aktive Mitarbeiter:    ${analytics.activeEmployees}');
    buffer.writeln('Verfügbarkeitsrate:    ${analytics.availabilityRate.toStringAsFixed(1)}%');
    buffer.writeln('Gesamtkapazität:       ${analytics.overallCapacity.toStringAsFixed(1)}%');
    buffer.writeln('Durchschn. Arbeitszeit: ${analytics.averageWorkload.toStringAsFixed(1)} h');
    buffer.writeln('Überstundenrate:       ${analytics.overtimePercentage.toStringAsFixed(1)}%');
    buffer.writeln();

    // Team Analysis
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('TEAM ANALYSE');
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('Anzahl Teams:          ${analytics.teamCapacities.length}');
    buffer.writeln('Kritische Teams:       ${analytics.criticalTeams}');
    buffer.writeln('Unterbesetzte Teams:   ${analytics.understaffedTeams}');
    buffer.writeln();

    // Team Details
    if (analytics.teamCapacities.isNotEmpty) {
      buffer.writeln('TEAM DETAILS:');
      buffer.writeln();

      for (final team in analytics.teamCapacities) {
        buffer.writeln('${team.teamName}:');
        buffer.writeln('  Status:           ${team.statusLabel}');
        buffer.writeln('  Kapazität:        ${team.capacityPercentage.toStringAsFixed(1)}%');
        buffer.writeln('  Verfügbar/Benötigt: ${team.availableStaff}/${team.requiredStaff}');
        buffer.writeln('  Aktive Mitarbeiter: ${team.activeStaff}');

        if (team.warnings.isNotEmpty) {
          buffer.writeln('  Warnungen:');
          for (final warning in team.warnings) {
            buffer.writeln('    - $warning');
          }
        }
        buffer.writeln();
      }
    }

    // Critical Alerts
    if (analytics.criticalAlerts.isNotEmpty) {
      buffer.writeln('───────────────────────────────────────────────────────────────');
      buffer.writeln('KRITISCHE WARNUNGEN');
      buffer.writeln('───────────────────────────────────────────────────────────────');

      for (int i = 0; i < analytics.criticalAlerts.length; i++) {
        buffer.writeln('${i + 1}. ${analytics.criticalAlerts[i]}');
      }
      buffer.writeln();
    }

    // Department Distribution
    if (analytics.departmentDistribution.isNotEmpty) {
      buffer.writeln('───────────────────────────────────────────────────────────────');
      buffer.writeln('ABTEILUNGSVERTEILUNG');
      buffer.writeln('───────────────────────────────────────────────────────────────');

      analytics.departmentDistribution.forEach((department, count) {
        buffer.writeln('${department.padRight(25)}: $count Mitarbeiter');
      });
      buffer.writeln();
    }

    // Skills Gaps
    if (analytics.skillsGaps.isNotEmpty) {
      buffer.writeln('───────────────────────────────────────────────────────────────');
      buffer.writeln('QUALIFIKATIONSLÜCKEN');
      buffer.writeln('───────────────────────────────────────────────────────────────');

      analytics.skillsGaps.forEach((skill, gap) {
        buffer.writeln('${skill.padRight(25)}: ${gap.toStringAsFixed(1)}% Lücke');
      });
      buffer.writeln();
    }

    // Recommendations
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('EMPFEHLUNGEN');
    buffer.writeln('───────────────────────────────────────────────────────────────');

    final recommendations = _generateCapacityRecommendations(analytics);
    for (int i = 0; i < recommendations.length; i++) {
      buffer.writeln('${i + 1}. ${recommendations[i]}');
    }
    buffer.writeln();

    // Footer
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('Dieser Bericht wurde automatisch generiert durch das');
    buffer.writeln('Kapazitätsanalysesystem von $_companyName');
    buffer.writeln('Analyse basiert auf Daten vom ${analytics.generatedAt.day}.${analytics.generatedAt.month}.${analytics.generatedAt.year}');
    buffer.writeln('───────────────────────────────────────────────────────────────');

    return buffer.toString();
  }

  String _buildTeamCapacityReportContent(List<TeamCapacity> teamCapacities, DateTime reportDate) {
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════════════════════════════════');
    buffer.writeln('                  TEAM KAPAZITÄTS BERICHT');
    buffer.writeln('═══════════════════════════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('Erstellt am: ${reportDate.day}.${reportDate.month}.${reportDate.year}');
    buffer.writeln('Anzahl Teams: ${teamCapacities.length}');
    buffer.writeln();

    for (final team in teamCapacities) {
      buffer.writeln('───────────────────────────────────────────────────────────────');
      buffer.writeln('TEAM: ${team.teamName.toUpperCase()}');
      buffer.writeln('───────────────────────────────────────────────────────────────');
      buffer.writeln('Status:               ${team.statusLabel}');
      buffer.writeln('Kapazität:            ${team.capacityPercentage.toStringAsFixed(1)}%');
      buffer.writeln('Benötigte Mitarbeiter: ${team.requiredStaff}');
      buffer.writeln('Verfügbare Mitarbeiter: ${team.availableStaff}');
      buffer.writeln('Aktive Mitarbeiter:   ${team.activeStaff}');
      buffer.writeln('Berechnet am:         ${team.calculatedAt.day}.${team.calculatedAt.month}.${team.calculatedAt.year}');

      if (team.warnings.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('WARNUNGEN:');
        for (final warning in team.warnings) {
          buffer.writeln('• $warning');
        }
      }

      buffer.writeln();
      buffer.writeln('ARBEITSBELASTUNG:');
      team.workloadDistribution.forEach((type, percentage) {
        final label = _getWorkloadTypeLabel(type);
        buffer.writeln('  ${label.padRight(20)}: ${percentage.toStringAsFixed(1)}%');
      });
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _buildMonthlyTimesheetSummary(List<Timesheet> timesheets, DateTime month, Map<String, Employee> employees) {
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════════════════════════════════');
    buffer.writeln('               MONATSBERICHT ZEITNACHWEISE');
    buffer.writeln('═══════════════════════════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('Monat: ${month.month.toString().padLeft(2, '0')}/${month.year}');
    buffer.writeln('Erstellt am: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}');
    buffer.writeln('Anzahl Zeitnachweise: ${timesheets.length}');
    buffer.writeln();

    // Summary by status
    final byStatus = <TimesheetStatus, int>{};
    double totalHours = 0;
    double totalPay = 0;

    for (final timesheet in timesheets) {
      byStatus[timesheet.status] = (byStatus[timesheet.status] ?? 0) + 1;
      totalHours += timesheet.calculatedTotalHours;
      totalPay += timesheet.calculatedTotalPay;
    }

    buffer.writeln('ÜBERSICHT NACH STATUS:');
    byStatus.forEach((status, count) {
      buffer.writeln('  ${_getStatusLabel(status).padRight(15)}: $count');
    });
    buffer.writeln();
    buffer.writeln('GESAMT STATISTIKEN:');
    buffer.writeln('  Gesamtstunden:    ${totalHours.toStringAsFixed(2)} h');
    buffer.writeln('  Gesamtvergütung:  €${totalPay.toStringAsFixed(2)}');
    buffer.writeln();

    // Details per timesheet
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('DETAILS');
    buffer.writeln('───────────────────────────────────────────────────────────────');

    for (final timesheet in timesheets) {
      final employee = employees[timesheet.employeeId];
      buffer.writeln('${timesheet.id} | ${employee?.fullName ?? 'Unbekannt'} | ${timesheet.statusLabel} | ${timesheet.calculatedTotalHours.toStringAsFixed(1)}h | €${timesheet.calculatedTotalPay.toStringAsFixed(2)}');
    }

    return buffer.toString();
  }

  List<String> _generateCapacityRecommendations(WorkforceAnalytics analytics) {
    final recommendations = <String>[];

    if (analytics.criticalTeams > 0) {
      recommendations.add('Sofortige Personalmaßnahmen für ${analytics.criticalTeams} kritische Teams erforderlich');
    }

    if (analytics.understaffedTeams > 0) {
      recommendations.add('Personalaufstockung für ${analytics.understaffedTeams} unterbesetzte Teams planen');
    }

    if (analytics.overtimePercentage > 15) {
      recommendations.add('Überstundenrate von ${analytics.overtimePercentage.toStringAsFixed(1)}% durch Effizienzmaßnahmen reduzieren');
    }

    if (analytics.availabilityRate < 85) {
      recommendations.add('Verfügbarkeitsrate von ${analytics.availabilityRate.toStringAsFixed(1)}% durch Gesundheitsmaßnahmen verbessern');
    }

    if (analytics.skillsGaps.isNotEmpty) {
      recommendations.add('Weiterbildungsprogramme für identifizierte Qualifikationslücken entwickeln');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Aktuelle Kapazitätssituation ist zufriedenstellend - regelmäßige Überwachung fortsetzen');
    }

    return recommendations;
  }

  String _getTypeLabel(TimesheetEntryType type) {
    switch (type) {
      case TimesheetEntryType.regular:
        return 'Reguläre Arbeitszeit';
      case TimesheetEntryType.overtime:
        return 'Überstunden';
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

  String _getWorkloadTypeLabel(WorkloadType type) {
    switch (type) {
      case WorkloadType.regular:
        return 'Regulär';
      case WorkloadType.overtime:
        return 'Überstunden';
      case WorkloadType.vacation:
        return 'Urlaub';
      case WorkloadType.sick:
        return 'Krankheit';
      case WorkloadType.training:
        return 'Schulung';
    }
  }

  String _getStatusLabel(TimesheetStatus status) {
    switch (status) {
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