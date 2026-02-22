import 'package:flutter/foundation.dart';

enum ShiftStatus { scheduled, inProgress, completed, cancelled, noShow }

enum ShiftType { regular, overtime, holiday, night, weekend }

class Shift {
  final String id;
  final String employeeId;
  final String? teamId;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final ShiftStatus status;
  final ShiftType type;
  final String? location;
  final String? description;
  final double? breakDurationMinutes;
  final double hourlyRate;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shift({
    required this.id,
    required this.employeeId,
    this.teamId,
    required this.startTime,
    required this.endTime,
    this.actualStartTime,
    this.actualEndTime,
    required this.status,
    required this.type,
    this.location,
    this.description,
    this.breakDurationMinutes,
    required this.hourlyRate,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration get scheduledDuration => endTime.difference(startTime);

  Duration? get actualDuration {
    if (actualStartTime != null && actualEndTime != null) {
      return actualEndTime!.difference(actualStartTime!);
    }
    return null;
  }

  double get scheduledHours => scheduledDuration.inMinutes / 60.0;

  double? get actualHours {
    final duration = actualDuration;
    if (duration != null) {
      double hours = duration.inMinutes / 60.0;
      if (breakDurationMinutes != null) {
        hours -= breakDurationMinutes! / 60.0;
      }
      return hours;
    }
    return null;
  }

  double get scheduledPay => scheduledHours * hourlyRate;

  double get actualPay {
    final hours = actualHours;
    if (hours != null) {
      double rate = hourlyRate;
      if (type == ShiftType.overtime) {
        rate *= 1.5; // 150% for overtime
      } else if (type == ShiftType.holiday) {
        rate *= 2.0; // 200% for holidays
      } else if (type == ShiftType.night || type == ShiftType.weekend) {
        rate *= 1.25; // 125% for night/weekend
      }
      return hours * rate;
    }
    return 0.0;
  }

  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final shiftDate = DateTime(startTime.year, startTime.month, startTime.day);
    return shiftDate == today;
  }

  bool get isUpcoming => startTime.isAfter(DateTime.now());

  bool get isOverdue {
    return status == ShiftStatus.scheduled &&
           endTime.isBefore(DateTime.now());
  }

  bool get isInProgress => status == ShiftStatus.inProgress;

  bool get isCompleted => status == ShiftStatus.completed;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'teamId': teamId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'actualStartTime': actualStartTime?.toIso8601String(),
      'actualEndTime': actualEndTime?.toIso8601String(),
      'status': status.name,
      'type': type.name,
      'location': location,
      'description': description,
      'breakDurationMinutes': breakDurationMinutes,
      'hourlyRate': hourlyRate,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'],
      employeeId: json['employeeId'],
      teamId: json['teamId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      actualStartTime: json['actualStartTime'] != null
          ? DateTime.parse(json['actualStartTime'])
          : null,
      actualEndTime: json['actualEndTime'] != null
          ? DateTime.parse(json['actualEndTime'])
          : null,
      status: ShiftStatus.values.byName(json['status']),
      type: ShiftType.values.byName(json['type']),
      location: json['location'],
      description: json['description'],
      breakDurationMinutes: json['breakDurationMinutes']?.toDouble(),
      hourlyRate: json['hourlyRate'].toDouble(),
      notes: json['notes'],
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Shift copyWith({
    String? id,
    String? employeeId,
    String? teamId,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    ShiftStatus? status,
    ShiftType? type,
    String? location,
    String? description,
    double? breakDurationMinutes,
    double? hourlyRate,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shift(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      teamId: teamId ?? this.teamId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      status: status ?? this.status,
      type: type ?? this.type,
      location: location ?? this.location,
      description: description ?? this.description,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Shift startShift() {
    return copyWith(
      status: ShiftStatus.inProgress,
      actualStartTime: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Shift endShift() {
    return copyWith(
      status: ShiftStatus.completed,
      actualEndTime: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Shift cancelShift() {
    return copyWith(
      status: ShiftStatus.cancelled,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Shift && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Shift(id: $id, employee: $employeeId, start: $startTime, status: $status)';
}