// Capacity Analytics model for Personalverwaltung Enterprise

enum CapacityStatus {
  optimal,     // 80-100% capacity
  understaffed, // < 80% capacity
  overstaffed,  // > 100% capacity
  critical,     // < 60% capacity
}

enum WorkloadType {
  regular,
  overtime,
  vacation,
  sick,
  training,
}

class TeamCapacity {
  final String teamId;
  final String teamName;
  final int requiredStaff;
  final int availableStaff;
  final int activeStaff;
  final double capacityPercentage;
  final CapacityStatus status;
  final List<String> warnings;
  final Map<WorkloadType, double> workloadDistribution;
  final DateTime calculatedAt;

  TeamCapacity({
    required this.teamId,
    required this.teamName,
    required this.requiredStaff,
    required this.availableStaff,
    required this.activeStaff,
    required this.capacityPercentage,
    required this.status,
    required this.warnings,
    required this.workloadDistribution,
    required this.calculatedAt,
  });

  bool get isUnderCapacity => capacityPercentage < 80.0;
  bool get isOverCapacity => capacityPercentage > 100.0;
  bool get isCritical => capacityPercentage < 60.0;
  bool get isOptimal => capacityPercentage >= 80.0 && capacityPercentage <= 100.0;

  String get statusLabel {
    switch (status) {
      case CapacityStatus.optimal:
        return 'Optimal';
      case CapacityStatus.understaffed:
        return 'Unterbesetzt';
      case CapacityStatus.overstaffed:
        return 'Überbesetzt';
      case CapacityStatus.critical:
        return 'Kritisch';
    }
  }

  factory TeamCapacity.fromJson(Map<String, dynamic> json) {
    return TeamCapacity(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      requiredStaff: json['requiredStaff'] as int,
      availableStaff: json['availableStaff'] as int,
      activeStaff: json['activeStaff'] as int,
      capacityPercentage: (json['capacityPercentage'] as num).toDouble(),
      status: CapacityStatus.values.firstWhere((e) => e.name == json['status']),
      warnings: (json['warnings'] as List<dynamic>).cast<String>(),
      workloadDistribution: Map<WorkloadType, double>.from(
        (json['workloadDistribution'] as Map).map(
          (key, value) => MapEntry(
            WorkloadType.values.firstWhere((e) => e.name == key),
            (value as num).toDouble(),
          ),
        ),
      ),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'requiredStaff': requiredStaff,
      'availableStaff': availableStaff,
      'activeStaff': activeStaff,
      'capacityPercentage': capacityPercentage,
      'status': status.name,
      'warnings': warnings,
      'workloadDistribution': workloadDistribution.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }
}

class CapacityForecast {
  final DateTime date;
  final double predictedCapacity;
  final int predictedStaff;
  final List<String> recommendations;
  final Map<String, double> riskFactors;

  CapacityForecast({
    required this.date,
    required this.predictedCapacity,
    required this.predictedStaff,
    required this.recommendations,
    required this.riskFactors,
  });

  factory CapacityForecast.fromJson(Map<String, dynamic> json) {
    return CapacityForecast(
      date: DateTime.parse(json['date'] as String),
      predictedCapacity: (json['predictedCapacity'] as num).toDouble(),
      predictedStaff: json['predictedStaff'] as int,
      recommendations: (json['recommendations'] as List<dynamic>).cast<String>(),
      riskFactors: Map<String, double>.from(json['riskFactors']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'predictedCapacity': predictedCapacity,
      'predictedStaff': predictedStaff,
      'recommendations': recommendations,
      'riskFactors': riskFactors,
    };
  }
}

class WorkforceAnalytics {
  final int totalEmployees;
  final int activeEmployees;
  final int onVacation;
  final int onSickLeave;
  final double averageWorkload;
  final double overtimePercentage;
  final Map<String, int> departmentDistribution;
  final Map<String, double> skillsGaps;
  final List<TeamCapacity> teamCapacities;
  final List<CapacityForecast> forecasts;
  final DateTime generatedAt;

  WorkforceAnalytics({
    required this.totalEmployees,
    required this.activeEmployees,
    required this.onVacation,
    required this.onSickLeave,
    required this.averageWorkload,
    required this.overtimePercentage,
    required this.departmentDistribution,
    required this.skillsGaps,
    required this.teamCapacities,
    required this.forecasts,
    required this.generatedAt,
  });

  double get availabilityRate =>
      totalEmployees > 0 ? (activeEmployees / totalEmployees) * 100 : 0.0;

  int get criticalTeams =>
      teamCapacities.where((t) => t.status == CapacityStatus.critical).length;

  int get understaffedTeams =>
      teamCapacities.where((t) => t.status == CapacityStatus.understaffed).length;

  double get overallCapacity {
    if (teamCapacities.isEmpty) return 0.0;
    final totalCapacity = teamCapacities
        .map((t) => t.capacityPercentage)
        .reduce((a, b) => a + b);
    return totalCapacity / teamCapacities.length;
  }

  List<String> get criticalAlerts {
    final alerts = <String>[];

    if (criticalTeams > 0) {
      alerts.add('$criticalTeams Teams kritisch unterbesetzt');
    }

    if (understaffedTeams > 0) {
      alerts.add('$understaffedTeams Teams unterbesetzt');
    }

    if (overtimePercentage > 20) {
      alerts.add('Hohe Überstundenrate: ${overtimePercentage.toStringAsFixed(1)}%');
    }

    if (availabilityRate < 80) {
      alerts.add('Niedrige Verfügbarkeit: ${availabilityRate.toStringAsFixed(1)}%');
    }

    return alerts;
  }

  factory WorkforceAnalytics.fromJson(Map<String, dynamic> json) {
    return WorkforceAnalytics(
      totalEmployees: json['totalEmployees'] as int,
      activeEmployees: json['activeEmployees'] as int,
      onVacation: json['onVacation'] as int,
      onSickLeave: json['onSickLeave'] as int,
      averageWorkload: (json['averageWorkload'] as num).toDouble(),
      overtimePercentage: (json['overtimePercentage'] as num).toDouble(),
      departmentDistribution: Map<String, int>.from(json['departmentDistribution']),
      skillsGaps: Map<String, double>.from(json['skillsGaps']),
      teamCapacities: (json['teamCapacities'] as List<dynamic>)
          .map((e) => TeamCapacity.fromJson(e as Map<String, dynamic>))
          .toList(),
      forecasts: (json['forecasts'] as List<dynamic>)
          .map((e) => CapacityForecast.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEmployees': totalEmployees,
      'activeEmployees': activeEmployees,
      'onVacation': onVacation,
      'onSickLeave': onSickLeave,
      'averageWorkload': averageWorkload,
      'overtimePercentage': overtimePercentage,
      'departmentDistribution': departmentDistribution,
      'skillsGaps': skillsGaps,
      'teamCapacities': teamCapacities.map((e) => e.toJson()).toList(),
      'forecasts': forecasts.map((e) => e.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}