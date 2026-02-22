// Timesheet model for Personalverwaltung

enum TimesheetStatus {
  draft,
  submitted,
  approved,
  rejected,
  finalized,
}

enum TimesheetEntryType {
  regular,
  overtime,
  travel,
  break_,
  training,
  administrative,
}

class TimesheetEntry {
  final String id;
  final String timesheetId;
  final String? shiftId;
  final TimesheetEntryType type;
  final DateTime startTime;
  final DateTime endTime;
  final double? breakDurationMinutes;
  final String? description;
  final String? location;
  final String? clientId;
  final double? travelDistance;
  final double? hourlyRate;
  final double? overtimeMultiplier;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimesheetEntry({
    required this.id,
    required this.timesheetId,
    this.shiftId,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.breakDurationMinutes,
    this.description,
    this.location,
    this.clientId,
    this.travelDistance,
    this.hourlyRate,
    this.overtimeMultiplier,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration get totalDuration {
    return endTime.difference(startTime);
  }

  Duration get workingDuration {
    final breakDuration = breakDurationMinutes != null
        ? Duration(minutes: breakDurationMinutes!.round())
        : Duration.zero;
    return totalDuration - breakDuration;
  }

  double get totalHours {
    return workingDuration.inMinutes / 60.0;
  }

  double get calculatedPay {
    final rate = hourlyRate ?? 15.0;
    final multiplier = overtimeMultiplier ?? 1.0;
    return totalHours * rate * multiplier;
  }

  TimesheetEntry copyWith({
    String? id,
    String? timesheetId,
    String? shiftId,
    TimesheetEntryType? type,
    DateTime? startTime,
    DateTime? endTime,
    double? breakDurationMinutes,
    String? description,
    String? location,
    String? clientId,
    double? travelDistance,
    double? hourlyRate,
    double? overtimeMultiplier,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimesheetEntry(
      id: id ?? this.id,
      timesheetId: timesheetId ?? this.timesheetId,
      shiftId: shiftId ?? this.shiftId,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      description: description ?? this.description,
      location: location ?? this.location,
      clientId: clientId ?? this.clientId,
      travelDistance: travelDistance ?? this.travelDistance,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      overtimeMultiplier: overtimeMultiplier ?? this.overtimeMultiplier,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TimesheetEntry.fromJson(Map<String, dynamic> json) {
    return TimesheetEntry(
      id: json['id'] as String,
      timesheetId: json['timesheetId'] as String,
      shiftId: json['shiftId'] as String?,
      type: TimesheetEntryType.values.firstWhere((e) => e.name == json['type']),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      breakDurationMinutes: (json['breakDurationMinutes'] as num?)?.toDouble(),
      description: json['description'] as String?,
      location: json['location'] as String?,
      clientId: json['clientId'] as String?,
      travelDistance: (json['travelDistance'] as num?)?.toDouble(),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      overtimeMultiplier: (json['overtimeMultiplier'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timesheetId': timesheetId,
      'shiftId': shiftId,
      'type': type.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'breakDurationMinutes': breakDurationMinutes,
      'description': description,
      'location': location,
      'clientId': clientId,
      'travelDistance': travelDistance,
      'hourlyRate': hourlyRate,
      'overtimeMultiplier': overtimeMultiplier,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Timesheet {
  final String id;
  final String employeeId;
  final DateTime startDate;
  final DateTime endDate;
  final TimesheetStatus status;
  final List<TimesheetEntry> entries;
  final String? submittedBy;
  final DateTime? submittedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final double? totalHours;
  final double? regularHours;
  final double? overtimeHours;
  final double? totalPay;
  final String? notes;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Timesheet({
    required this.id,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.entries,
    this.submittedBy,
    this.submittedAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.totalHours,
    this.regularHours,
    this.overtimeHours,
    this.totalPay,
    this.notes,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  double get calculatedTotalHours {
    return entries.fold(0.0, (sum, entry) => sum + entry.totalHours);
  }

  double get calculatedRegularHours {
    return entries
        .where((e) => e.type == TimesheetEntryType.regular)
        .fold(0.0, (sum, entry) => sum + entry.totalHours);
  }

  double get calculatedOvertimeHours {
    return entries
        .where((e) => e.type == TimesheetEntryType.overtime)
        .fold(0.0, (sum, entry) => sum + entry.totalHours);
  }

  double get calculatedTotalPay {
    return entries.fold(0.0, (sum, entry) => sum + entry.calculatedPay);
  }

  bool get canBeEdited {
    return status == TimesheetStatus.draft || status == TimesheetStatus.rejected;
  }

  bool get canBeSubmitted {
    return status == TimesheetStatus.draft && entries.isNotEmpty;
  }

  bool get canBeApproved {
    return status == TimesheetStatus.submitted;
  }

  String get statusLabel {
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

  Timesheet copyWith({
    String? id,
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
    TimesheetStatus? status,
    List<TimesheetEntry>? entries,
    String? submittedBy,
    DateTime? submittedAt,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    double? totalHours,
    double? regularHours,
    double? overtimeHours,
    double? totalPay,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Timesheet(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      entries: entries ?? this.entries,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      totalHours: totalHours ?? this.totalHours,
      regularHours: regularHours ?? this.regularHours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      totalPay: totalPay ?? this.totalPay,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Timesheet.fromJson(Map<String, dynamic> json) {
    return Timesheet(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: TimesheetStatus.values.firstWhere((e) => e.name == json['status']),
      entries: (json['entries'] as List<dynamic>?)
          ?.map((e) => TimesheetEntry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      submittedBy: json['submittedBy'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      totalHours: (json['totalHours'] as num?)?.toDouble(),
      regularHours: (json['regularHours'] as num?)?.toDouble(),
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble(),
      totalPay: (json['totalPay'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.name,
      'entries': entries.map((e) => e.toJson()).toList(),
      'submittedBy': submittedBy,
      'submittedAt': submittedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'totalHours': totalHours,
      'regularHours': regularHours,
      'overtimeHours': overtimeHours,
      'totalPay': totalPay,
      'notes': notes,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}