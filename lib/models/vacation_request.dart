import 'package:flutter/foundation.dart';

enum VacationRequestStatus {
  pending,
  approved,
  rejected,
  cancelled
}

enum VacationType {
  annual,
  sick,
  personal,
  maternity,
  paternity,
  emergency,
  unpaid,
  sabbatical
}

@immutable
class VacationRequest {
  final String id;
  final String employeeId;
  final DateTime startDate;
  final DateTime endDate;
  final VacationType type;
  final VacationRequestStatus status;
  final String reason;
  final String? notes;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final int workingDays;
  final DateTime requestDate;
  final String createdAt;
  final String updatedAt;

  const VacationRequest({
    required this.id,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.status,
    required this.reason,
    this.notes,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.workingDays,
    required this.requestDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration get duration => endDate.difference(startDate);

  int get totalDays => duration.inDays + 1;

  bool get isPending => status == VacationRequestStatus.pending;
  bool get isApproved => status == VacationRequestStatus.approved;
  bool get isRejected => status == VacationRequestStatus.rejected;
  bool get isCancelled => status == VacationRequestStatus.cancelled;

  bool get isActive {
    final now = DateTime.now();
    return isApproved &&
           startDate.isBefore(now.add(const Duration(days: 1))) &&
           endDate.isAfter(now.subtract(const Duration(days: 1)));
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return isApproved && startDate.isAfter(now);
  }

  bool get isPast {
    final now = DateTime.now();
    return endDate.isBefore(now);
  }

  bool get requiresApproval => status == VacationRequestStatus.pending;

  VacationRequest copyWith({
    String? id,
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
    VacationType? type,
    VacationRequestStatus? status,
    String? reason,
    String? notes,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    int? workingDays,
    DateTime? requestDate,
    String? createdAt,
    String? updatedAt,
  }) {
    return VacationRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      workingDays: workingDays ?? this.workingDays,
      requestDate: requestDate ?? this.requestDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  VacationRequest approve(String approvedById) {
    return copyWith(
      status: VacationRequestStatus.approved,
      approvedBy: approvedById,
      approvedAt: DateTime.now(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  VacationRequest reject(String rejectionReason) {
    return copyWith(
      status: VacationRequestStatus.rejected,
      rejectionReason: rejectionReason,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  VacationRequest cancel() {
    return copyWith(
      status: VacationRequestStatus.cancelled,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'type': type.name,
      'status': status.name,
      'reason': reason,
      'notes': notes,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'workingDays': workingDays,
      'requestDate': requestDate.toIso8601String(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory VacationRequest.fromJson(Map<String, dynamic> json) {
    return VacationRequest(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      type: VacationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VacationType.annual,
      ),
      status: VacationRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VacationRequestStatus.pending,
      ),
      reason: json['reason'] as String,
      notes: json['notes'] as String?,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      workingDays: json['workingDays'] as int,
      requestDate: DateTime.parse(json['requestDate'] as String),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  @override
  String toString() {
    return 'VacationRequest(id: $id, employeeId: $employeeId, startDate: $startDate, endDate: $endDate, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VacationRequest &&
        other.id == id &&
        other.employeeId == employeeId &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.type == type &&
        other.status == status &&
        other.reason == reason &&
        other.notes == notes &&
        other.approvedBy == approvedBy &&
        other.approvedAt == approvedAt &&
        other.rejectionReason == rejectionReason &&
        other.workingDays == workingDays &&
        other.requestDate == requestDate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      employeeId,
      startDate,
      endDate,
      type,
      status,
      reason,
      notes,
      approvedBy,
      approvedAt,
      rejectionReason,
      workingDays,
      requestDate,
      createdAt,
      updatedAt,
    ]);
  }

  static int calculateWorkingDays(DateTime startDate, DateTime endDate) {
    int workingDays = 0;
    DateTime current = startDate;

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      // Monday = 1, Sunday = 7
      if (current.weekday <= 5) {
        workingDays++;
      }
      current = current.add(const Duration(days: 1));
    }

    return workingDays;
  }
}