import 'package:flutter/foundation.dart';

enum EmployeeStatus { active, inactive, onLeave, terminated }

enum ContractType { fullTime, partTime, freelance, intern, temporary }

class Employee {
  final String id;
  final String employeeNumber;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final DateTime dateOfBirth;
  final DateTime hireDate;
  final DateTime? terminationDate;
  final EmployeeStatus status;
  final ContractType contractType;
  final double hoursPerWeek;
  final double hourlyRate;
  final String position;
  final String department;
  final String? supervisor;
  final Address address;
  final EmergencyContact? emergencyContact;
  final List<String> qualifications;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.employeeNumber,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.dateOfBirth,
    required this.hireDate,
    this.terminationDate,
    required this.status,
    required this.contractType,
    required this.hoursPerWeek,
    required this.hourlyRate,
    required this.position,
    required this.department,
    this.supervisor,
    required this.address,
    this.emergencyContact,
    this.qualifications = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  String get displayName => '$lastName, $firstName';

  bool get isActive => status == EmployeeStatus.active;

  String get statusLabel {
    switch (status) {
      case EmployeeStatus.active:
        return 'Aktiv';
      case EmployeeStatus.inactive:
        return 'Inaktiv';
      case EmployeeStatus.onLeave:
        return 'Beurlaubt';
      case EmployeeStatus.terminated:
        return 'Beendet';
    }
  }

  double get contractualHours => hoursPerWeek;

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  Duration get employmentDuration {
    final endDate = terminationDate ?? DateTime.now();
    return endDate.difference(hireDate);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeNumber': employeeNumber,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'hireDate': hireDate.toIso8601String(),
      'terminationDate': terminationDate?.toIso8601String(),
      'status': status.name,
      'contractType': contractType.name,
      'hoursPerWeek': hoursPerWeek,
      'hourlyRate': hourlyRate,
      'position': position,
      'department': department,
      'supervisor': supervisor,
      'address': address.toJson(),
      'emergencyContact': emergencyContact?.toJson(),
      'qualifications': qualifications,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      employeeNumber: json['employeeNumber'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phone: json['phone'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      hireDate: DateTime.parse(json['hireDate']),
      terminationDate: json['terminationDate'] != null
          ? DateTime.parse(json['terminationDate'])
          : null,
      status: EmployeeStatus.values.byName(json['status']),
      contractType: ContractType.values.byName(json['contractType']),
      hoursPerWeek: json['hoursPerWeek'].toDouble(),
      hourlyRate: json['hourlyRate'].toDouble(),
      position: json['position'],
      department: json['department'],
      supervisor: json['supervisor'],
      address: Address.fromJson(json['address']),
      emergencyContact: json['emergencyContact'] != null
          ? EmergencyContact.fromJson(json['emergencyContact'])
          : null,
      qualifications: List<String>.from(json['qualifications'] ?? []),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Employee copyWith({
    String? id,
    String? employeeNumber,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    DateTime? hireDate,
    DateTime? terminationDate,
    EmployeeStatus? status,
    ContractType? contractType,
    double? hoursPerWeek,
    double? hourlyRate,
    String? position,
    String? department,
    String? supervisor,
    Address? address,
    EmergencyContact? emergencyContact,
    List<String>? qualifications,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      hireDate: hireDate ?? this.hireDate,
      terminationDate: terminationDate ?? this.terminationDate,
      status: status ?? this.status,
      contractType: contractType ?? this.contractType,
      hoursPerWeek: hoursPerWeek ?? this.hoursPerWeek,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      position: position ?? this.position,
      department: department ?? this.department,
      supervisor: supervisor ?? this.supervisor,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      qualifications: qualifications ?? this.qualifications,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Employee && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Employee(id: $id, name: $fullName, status: $status)';
}

class Address {
  final String street;
  final String city;
  final String postalCode;
  final String? state;
  final String country;

  Address({
    required this.street,
    required this.city,
    required this.postalCode,
    this.state,
    required this.country,
  });

  String get fullAddress {
    final parts = [street, '$postalCode $city'];
    if (state != null) parts.add(state!);
    parts.add(country);
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'state': state,
      'country': country,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      city: json['city'],
      postalCode: json['postalCode'],
      state: json['state'],
      country: json['country'],
    );
  }

  Address copyWith({
    String? street,
    String? city,
    String? postalCode,
    String? state,
    String? country,
  }) {
    return Address(
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      state: state ?? this.state,
      country: country ?? this.country,
    );
  }

  @override
  String toString() => fullAddress;
}

class EmergencyContact {
  final String name;
  final String relationship;
  final String phone;
  final String? email;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'email': email,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'],
      relationship: json['relationship'],
      phone: json['phone'],
      email: json['email'],
    );
  }

  EmergencyContact copyWith({
    String? name,
    String? relationship,
    String? phone,
    String? email,
  }) {
    return EmergencyContact(
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  @override
  String toString() => '$name ($relationship) - $phone';
}