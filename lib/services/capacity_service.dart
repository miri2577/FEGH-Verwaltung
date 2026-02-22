import '../models/capacity_analytics.dart';
import '../models/employee.dart';
import '../models/team.dart';
import '../models/shift.dart';
import '../models/timesheet.dart';

class CapacityService {
  Future<WorkforceAnalytics> generateWorkforceAnalytics({
    required List<Employee> employees,
    required List<Team> teams,
    required List<Shift> shifts,
    required List<Timesheet> timesheets,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final analysisDate = DateTime.now();
    final analysisStart = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final analysisEnd = endDate ?? DateTime.now().add(const Duration(days: 7));

    final activeEmployees = employees.where((e) => e.status == EmployeeStatus.active).toList();
    final onVacation = employees.where((e) => e.status == EmployeeStatus.onLeave).length;
    final onSickLeave = 0; // Would be calculated from absence records

    final teamCapacities = await _calculateTeamCapacities(teams, activeEmployees, shifts, analysisStart, analysisEnd);
    final forecasts = await _generateCapacityForecasts(teamCapacities, analysisEnd);

    final recentTimesheets = timesheets.where((ts) =>
      ts.startDate.isAfter(analysisStart) && ts.endDate.isBefore(analysisEnd)
    ).toList();

    final averageWorkload = _calculateAverageWorkload(recentTimesheets);
    final overtimePercentage = _calculateOvertimePercentage(recentTimesheets);

    final departmentDistribution = _calculateDepartmentDistribution(activeEmployees, teams);
    final skillsGaps = _identifySkillsGaps(teams, activeEmployees);

    return WorkforceAnalytics(
      totalEmployees: employees.length,
      activeEmployees: activeEmployees.length,
      onVacation: onVacation,
      onSickLeave: onSickLeave,
      averageWorkload: averageWorkload,
      overtimePercentage: overtimePercentage,
      departmentDistribution: departmentDistribution,
      skillsGaps: skillsGaps,
      teamCapacities: teamCapacities,
      forecasts: forecasts,
      generatedAt: analysisDate,
    );
  }

  Future<List<TeamCapacity>> _calculateTeamCapacities(
    List<Team> teams,
    List<Employee> employees,
    List<Shift> shifts,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final capacities = <TeamCapacity>[];

    for (final team in teams) {
      final teamEmployees = employees.where((e) => team.memberIds.contains(e.id)).toList();
      final teamShifts = shifts.where((s) =>
        teamEmployees.any((e) => e.id == s.employeeId) &&
        s.startTime.isAfter(startDate) &&
        s.startTime.isBefore(endDate)
      ).toList();

      final requiredStaff = teamEmployees.length; // Based on team member count
      final availableStaff = teamEmployees.where((e) =>
        e.status == EmployeeStatus.active
      ).length;

      final activeStaff = teamShifts.map((s) => s.employeeId).toSet().length;
      final capacityPercentage = requiredStaff > 0 ? (availableStaff / requiredStaff) * 100 : 0.0;

      final status = _determineCapacityStatus(capacityPercentage);
      final warnings = _generateCapacityWarnings(team, teamEmployees, teamShifts);
      final workloadDistribution = _calculateWorkloadDistribution(teamShifts);

      capacities.add(TeamCapacity(
        teamId: team.id,
        teamName: team.name,
        requiredStaff: requiredStaff,
        availableStaff: availableStaff,
        activeStaff: activeStaff,
        capacityPercentage: capacityPercentage,
        status: status,
        warnings: warnings,
        workloadDistribution: workloadDistribution,
        calculatedAt: DateTime.now(),
      ));
    }

    return capacities;
  }

  CapacityStatus _determineCapacityStatus(double capacityPercentage) {
    if (capacityPercentage < 60) return CapacityStatus.critical;
    if (capacityPercentage < 80) return CapacityStatus.understaffed;
    if (capacityPercentage > 100) return CapacityStatus.overstaffed;
    return CapacityStatus.optimal;
  }

  List<String> _generateCapacityWarnings(Team team, List<Employee> employees, List<Shift> shifts) {
    final warnings = <String>[];

    final activeEmployees = employees.where((e) => e.status == EmployeeStatus.active).length;
    final requiredStaff = employees.length; // Based on employee count

    if (activeEmployees < requiredStaff * 0.6) {
      warnings.add('Kritischer Personalmangel - nur ${(activeEmployees / requiredStaff * 100).round()}% der Sollbesetzung');
    }

    if (activeEmployees < requiredStaff * 0.8) {
      warnings.add('Unterbesetzung - ${requiredStaff - activeEmployees} Mitarbeiter fehlen');
    }

    final overtimeShifts = shifts.where((s) => s.type == ShiftType.overtime).length;
    if (overtimeShifts > shifts.length * 0.2) {
      warnings.add('Hoher Überstundenanteil - ${(overtimeShifts / shifts.length * 100).round()}% Überstunden');
    }

    final lastWeekShifts = shifts.where((s) =>
      s.startTime.isAfter(DateTime.now().subtract(const Duration(days: 7)))
    ).length;
    if (lastWeekShifts == 0) {
      warnings.add('Keine Schichten in der letzten Woche geplant');
    }

    return warnings;
  }

  Map<WorkloadType, double> _calculateWorkloadDistribution(List<Shift> shifts) {
    if (shifts.isEmpty) {
      return {
        WorkloadType.regular: 0.0,
        WorkloadType.overtime: 0.0,
        WorkloadType.vacation: 0.0,
        WorkloadType.sick: 0.0,
        WorkloadType.training: 0.0,
      };
    }

    final distribution = <WorkloadType, double>{};
    final totalShifts = shifts.length.toDouble();

    distribution[WorkloadType.regular] = shifts.where((s) => s.type == ShiftType.regular).length / totalShifts * 100;
    distribution[WorkloadType.overtime] = shifts.where((s) => s.type == ShiftType.overtime).length / totalShifts * 100;
    distribution[WorkloadType.vacation] = 0.0; // From vacation records
    distribution[WorkloadType.sick] = 0.0; // From sick leave records
    distribution[WorkloadType.training] = 0.0; // Training would be tracked separately

    return distribution;
  }

  Future<List<CapacityForecast>> _generateCapacityForecasts(
    List<TeamCapacity> currentCapacities,
    DateTime forecastStart,
  ) async {
    final forecasts = <CapacityForecast>[];

    for (int i = 1; i <= 30; i++) {
      final forecastDate = forecastStart.add(Duration(days: i));
      final averageCapacity = currentCapacities.isEmpty ? 0.0 :
        currentCapacities.map((c) => c.capacityPercentage).reduce((a, b) => a + b) / currentCapacities.length;

      final trend = _calculateCapacityTrend(currentCapacities);
      final predictedCapacity = averageCapacity + (trend * i);
      final predictedStaff = currentCapacities.isEmpty ? 0 :
        (currentCapacities.map((c) => c.availableStaff).reduce((a, b) => a + b) * predictedCapacity / 100).round();

      final recommendations = _generateRecommendations(predictedCapacity, currentCapacities);
      final riskFactors = _calculateRiskFactors(predictedCapacity, currentCapacities);

      forecasts.add(CapacityForecast(
        date: forecastDate,
        predictedCapacity: predictedCapacity,
        predictedStaff: predictedStaff,
        recommendations: recommendations,
        riskFactors: riskFactors,
      ));
    }

    return forecasts;
  }

  double _calculateCapacityTrend(List<TeamCapacity> capacities) {
    if (capacities.isEmpty) return 0.0;

    final criticalTeams = capacities.where((c) => c.status == CapacityStatus.critical).length;
    final understaffedTeams = capacities.where((c) => c.status == CapacityStatus.understaffed).length;

    if (criticalTeams > capacities.length * 0.3) return -0.5;
    if (understaffedTeams > capacities.length * 0.5) return -0.2;
    return 0.1;
  }

  List<String> _generateRecommendations(double predictedCapacity, List<TeamCapacity> capacities) {
    final recommendations = <String>[];

    if (predictedCapacity < 60) {
      recommendations.add('Sofortige Personaleinstellung erforderlich');
      recommendations.add('Überstunden temporär genehmigen');
      recommendations.add('Externe Dienstleister kontaktieren');
    } else if (predictedCapacity < 80) {
      recommendations.add('Personalbeschaffung einleiten');
      recommendations.add('Schichtplanung optimieren');
      recommendations.add('Urlaubssperren prüfen');
    } else if (predictedCapacity > 120) {
      recommendations.add('Personalüberhang prüfen');
      recommendations.add('Schulungen und Weiterbildungen planen');
      recommendations.add('Flexible Arbeitszeiten anbieten');
    }

    final highWarningTeams = capacities.where((c) => c.warnings.isNotEmpty).length;
    if (highWarningTeams > capacities.length * 0.5) {
      recommendations.add('Team-spezifische Maßnahmen erforderlich');
    }

    return recommendations;
  }

  Map<String, double> _calculateRiskFactors(double predictedCapacity, List<TeamCapacity> capacities) {
    return {
      'understaffing': predictedCapacity < 80 ? (80 - predictedCapacity) / 80 : 0.0,
      'burnout': capacities.where((c) => c.workloadDistribution[WorkloadType.overtime]! > 20).length / capacities.length,
      'turnover': 0.1, // Would be calculated from historical data
      'seasonal': 0.05, // Seasonal demand fluctuations
      'regulatory': 0.02, // Regulatory compliance risks
    };
  }

  double _calculateAverageWorkload(List<Timesheet> timesheets) {
    if (timesheets.isEmpty) return 0.0;

    final totalHours = timesheets.fold(0.0, (sum, ts) => sum + ts.calculatedTotalHours);
    return totalHours / timesheets.length;
  }

  double _calculateOvertimePercentage(List<Timesheet> timesheets) {
    if (timesheets.isEmpty) return 0.0;

    final totalHours = timesheets.fold(0.0, (sum, ts) => sum + ts.calculatedTotalHours);
    final overtimeHours = timesheets.fold(0.0, (sum, ts) => sum + ts.calculatedOvertimeHours);

    return totalHours > 0 ? (overtimeHours / totalHours) * 100 : 0.0;
  }

  Map<String, int> _calculateDepartmentDistribution(List<Employee> employees, List<Team> teams) {
    final distribution = <String, int>{};

    for (final team in teams) {
      final teamEmployees = employees.where((e) => team.memberIds.contains(e.id)).length;
      distribution[team.name] = teamEmployees;
    }

    final unassignedEmployees = employees.where((e) =>
      !teams.any((t) => t.memberIds.contains(e.id))
    ).length;

    if (unassignedEmployees > 0) {
      distribution['Nicht zugeordnet'] = unassignedEmployees;
    }

    return distribution;
  }

  Map<String, double> _identifySkillsGaps(List<Team> teams, List<Employee> employees) {
    final skillsGaps = <String, double>{};

    for (final team in teams) {
      final teamEmployees = employees.where((e) => team.memberIds.contains(e.id)).toList();
      final requiredStaff = teamEmployees.length; // Based on team member count
      final availableStaff = teamEmployees.where((e) => e.status == EmployeeStatus.active).length;

      if (availableStaff < requiredStaff) {
        final gapPercentage = ((requiredStaff - availableStaff) / requiredStaff) * 100;
        skillsGaps[team.name] = gapPercentage;
      }
    }

    return skillsGaps;
  }

  String generateCapacityId() {
    return 'cap_${DateTime.now().millisecondsSinceEpoch}';
  }
}