import 'package:flutter/foundation.dart';

enum TeamStatus { active, inactive, onHold }

class Team {
  final String id;
  final String name;
  final String description;
  final String? department;
  final String? teamLeaderId;
  final List<String> memberIds;
  final TeamStatus status;
  final double? budget;
  final String? location;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Team({
    required this.id,
    required this.name,
    required this.description,
    this.department,
    this.teamLeaderId,
    this.memberIds = const [],
    required this.status,
    this.budget,
    this.location,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  int get memberCount => memberIds.length;

  bool get hasTeamLeader => teamLeaderId != null;

  bool get isActive => status == TeamStatus.active;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'department': department,
      'teamLeaderId': teamLeaderId,
      'memberIds': memberIds,
      'status': status.name,
      'budget': budget,
      'location': location,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      department: json['department'],
      teamLeaderId: json['teamLeaderId'],
      memberIds: List<String>.from(json['memberIds'] ?? []),
      status: TeamStatus.values.byName(json['status']),
      budget: json['budget']?.toDouble(),
      location: json['location'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Team copyWith({
    String? id,
    String? name,
    String? description,
    String? department,
    String? teamLeaderId,
    List<String>? memberIds,
    TeamStatus? status,
    double? budget,
    String? location,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      department: department ?? this.department,
      teamLeaderId: teamLeaderId ?? this.teamLeaderId,
      memberIds: memberIds ?? this.memberIds,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Team addMember(String employeeId) {
    if (memberIds.contains(employeeId)) return this;
    return copyWith(
      memberIds: [...memberIds, employeeId],
      updatedAt: DateTime.now(),
    );
  }

  Team removeMember(String employeeId) {
    return copyWith(
      memberIds: memberIds.where((id) => id != employeeId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Team && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Team(id: $id, name: $name, members: $memberCount)';
}