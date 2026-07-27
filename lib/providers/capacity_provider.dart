import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/capacity_analytics.dart';
import '../models/employee.dart';
import '../models/team.dart';
import '../models/shift.dart';
import '../models/timesheet.dart';
import '../services/capacity_service.dart';
import 'client_provider.dart';
import 'employee_provider.dart';
import 'team_provider.dart';
import 'shift_provider.dart';
import 'timesheet_provider.dart';

final capacityServiceProvider = Provider<CapacityService>((ref) {
  return CapacityService();
});

final workforceAnalyticsProvider = FutureProvider<WorkforceAnalytics>((ref) async {
  final capacityService = ref.read(capacityServiceProvider);

  final employeesAsync = ref.watch(employeesProvider);
  final teamsAsync = ref.watch(teamsProvider);
  final shiftsAsync = ref.watch(shiftsProvider);
  final timesheetsAsync = ref.watch(timesheetsProvider);

  // Wait for all data to be available
  final employees = await employeesAsync.whenOrNull(
    data: (data) => data,
  ) ?? <Employee>[];

  final teams = await teamsAsync.whenOrNull(
    data: (data) => data,
  ) ?? <Team>[];

  final shifts = await shiftsAsync.whenOrNull(
    data: (data) => data,
  ) ?? <Shift>[];

  final timesheets = await timesheetsAsync.whenOrNull(
    data: (data) => data,
  ) ?? <Timesheet>[];

  // Klienten liefern den woechentlichen FLS-Bedarf (aus HBG) fuer die
  // bedarfsgetriebene Sollbesetzung je Team.
  final clients = ref.watch(clientProvider);

  return await capacityService.generateWorkforceAnalytics(
    employees: employees,
    teams: teams,
    shifts: shifts,
    timesheets: timesheets,
    clients: clients,
  );
});

final teamCapacitiesProvider = FutureProvider<List<TeamCapacity>>((ref) async {
  final workforceAnalytics = await ref.watch(workforceAnalyticsProvider.future);
  return workforceAnalytics.teamCapacities;
});

final capacityForecastsProvider = FutureProvider<List<CapacityForecast>>((ref) async {
  final workforceAnalytics = await ref.watch(workforceAnalyticsProvider.future);
  return workforceAnalytics.forecasts.take(7).toList(); // Next 7 days
});

final criticalTeamsProvider = FutureProvider<List<TeamCapacity>>((ref) async {
  final teamCapacities = await ref.watch(teamCapacitiesProvider.future);
  return teamCapacities.where((team) =>
    team.status == CapacityStatus.critical ||
    team.status == CapacityStatus.understaffed
  ).toList();
});

final capacityAlertsProvider = FutureProvider<List<String>>((ref) async {
  final workforceAnalytics = await ref.watch(workforceAnalyticsProvider.future);
  return workforceAnalytics.criticalAlerts;
});

final capacityDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final workforceAnalytics = await ref.watch(workforceAnalyticsProvider.future);
  final teamCapacities = workforceAnalytics.teamCapacities;

  final optimalTeams = teamCapacities.where((t) => t.status == CapacityStatus.optimal).length;
  final understaffedTeams = teamCapacities.where((t) => t.status == CapacityStatus.understaffed).length;
  final overstaffedTeams = teamCapacities.where((t) => t.status == CapacityStatus.overstaffed).length;
  final criticalTeams = teamCapacities.where((t) => t.status == CapacityStatus.critical).length;

  final totalStaffRequired = teamCapacities.fold(0, (sum, team) => sum + team.requiredStaff);
  final totalStaffAvailable = teamCapacities.fold(0, (sum, team) => sum + team.availableStaff);
  final totalStaffActive = teamCapacities.fold(0, (sum, team) => sum + team.activeStaff);

  return {
    // Overall metrics
    'totalEmployees': workforceAnalytics.totalEmployees,
    'activeEmployees': workforceAnalytics.activeEmployees,
    'onVacation': workforceAnalytics.onVacation,
    'onSickLeave': workforceAnalytics.onSickLeave,
    'availabilityRate': workforceAnalytics.availabilityRate,
    'overallCapacity': workforceAnalytics.overallCapacity,
    'averageWorkload': workforceAnalytics.averageWorkload,
    'overtimePercentage': workforceAnalytics.overtimePercentage,

    // Team status breakdown
    'optimalTeams': optimalTeams,
    'understaffedTeams': understaffedTeams,
    'overstaffedTeams': overstaffedTeams,
    'criticalTeams': criticalTeams,
    'totalTeams': teamCapacities.length,

    // Capacity metrics
    'totalStaffRequired': totalStaffRequired,
    'totalStaffAvailable': totalStaffAvailable,
    'totalStaffActive': totalStaffActive,
    'capacityUtilization': totalStaffRequired > 0 ? (totalStaffAvailable / totalStaffRequired * 100) : 0.0,
    'activityRate': totalStaffAvailable > 0 ? (totalStaffActive / totalStaffAvailable * 100) : 0.0,

    // Alerts and warnings
    'criticalAlerts': workforceAnalytics.criticalAlerts,
    'hasWarnings': understaffedTeams > 0 || criticalTeams > 0,
    'warningLevel': criticalTeams > 0 ? 'critical' : understaffedTeams > 0 ? 'warning' : 'normal',

    // Department distribution
    'departmentDistribution': workforceAnalytics.departmentDistribution,
    'skillsGaps': workforceAnalytics.skillsGaps,

    // Forecast preview
    'nextWeekCapacity': workforceAnalytics.forecasts.isNotEmpty ? workforceAnalytics.forecasts.first.predictedCapacity : 0.0,
    'forecastTrend': _calculateForecastTrend(workforceAnalytics.forecasts),

    // Generation info
    'generatedAt': workforceAnalytics.generatedAt,
    'lastUpdated': DateTime.now(),
  };
});

String _calculateForecastTrend(List<CapacityForecast> forecasts) {
  if (forecasts.length < 2) return 'stable';

  final firstWeek = forecasts.take(7).map((f) => f.predictedCapacity).reduce((a, b) => a + b) / 7;
  final currentCapacity = forecasts.first.predictedCapacity;

  if (firstWeek > currentCapacity * 1.05) return 'improving';
  if (firstWeek < currentCapacity * 0.95) return 'declining';
  return 'stable';
}

// Filtered providers for specific use cases
final capacityByStatusProvider = FutureProvider.family<List<TeamCapacity>, CapacityStatus>((ref, status) async {
  final teamCapacities = await ref.watch(teamCapacitiesProvider.future);
  return teamCapacities.where((team) => team.status == status).toList();
});

final capacityByTeamProvider = FutureProvider.family<TeamCapacity?, String>((ref, teamId) async {
  final teamCapacities = await ref.watch(teamCapacitiesProvider.future);
  try {
    return teamCapacities.firstWhere((team) => team.teamId == teamId);
  } catch (e) {
    return null;
  }
});

final workloadDistributionProvider = FutureProvider<Map<WorkloadType, double>>((ref) async {
  final teamCapacities = await ref.watch(teamCapacitiesProvider.future);

  if (teamCapacities.isEmpty) {
    return {
      WorkloadType.regular: 0.0,
      WorkloadType.overtime: 0.0,
      WorkloadType.vacation: 0.0,
      WorkloadType.sick: 0.0,
      WorkloadType.training: 0.0,
    };
  }

  final combinedDistribution = <WorkloadType, double>{};

  for (final workloadType in WorkloadType.values) {
    final totalPercentage = teamCapacities.fold(0.0, (sum, team) =>
      sum + (team.workloadDistribution[workloadType] ?? 0.0)
    );
    combinedDistribution[workloadType] = totalPercentage / teamCapacities.length;
  }

  return combinedDistribution;
});

// Real-time update triggers
final capacityRefreshProvider = StateProvider<DateTime>((ref) => DateTime.now());

final refreshCapacityAnalyticsProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(workforceAnalyticsProvider);
    ref.read(capacityRefreshProvider.notifier).state = DateTime.now();
  };
});

// Historical capacity data (mock for now, would connect to analytics service)
final historicalCapacityProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  // This would typically fetch from a time-series database
  final mockData = <Map<String, dynamic>>[];
  final now = DateTime.now();

  for (int i = days; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    mockData.add({
      'date': date,
      'capacity': 85.0 + (i % 10) - 5, // Mock fluctuation
      'activeStaff': 25 + (i % 5),
      'warnings': i % 7 == 0 ? 1 : 0,
    });
  }

  return mockData;
});