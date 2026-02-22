import 'package:flutter/foundation.dart';

enum ClientStatus {
  active,
  inactive,
  pending,
  archived,
}

enum ClientPriority {
  low,
  medium,
  high,
  urgent,
}

enum ServiceType {
  ambulant,
  stationaer,
  beratung,
  begleitung,
  wohnen,
  arbeit,
  freizeit,
}

@immutable
class Client {
  final String id;
  final String firstName;
  final String lastName;
  final String? teamId;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime dateOfBirth;
  final ClientStatus status;
  final ClientPriority priority;
  final List<ServiceType> services;
  final String? notes;
  final String? caseManager;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? insuranceNumber;
  final String? emergencyContact;
  final String? emergencyPhone;
  final List<String> assignedEmployees;
  final String? responsibleEmployeeId;
  final String? deputyEmployeeId;
  final String? deputy2EmployeeId;
  final Map<String, dynamic> customFields;

  // Eingliederungshilfe-spezifische Felder
  final int? fachleistungsstunden;
  final String? fachleistungsIntervall; // 'woechentlich' | 'monatlich' | 'jaehrlich'
  final String? hilfeTyp; // 'eingliederungshilfe' | 'familienhilfe'
  final String? kostenuebernahme; // Kostenträger-Name
  final DateTime? kostenuebernahmeVon;
  final DateTime? kostenuebernahmeBis;
  final DateTime? betreuungSeit;
  final List<String>? icfBereiche;
  final List<String>? tibZiele;
  final List<String>? individuelleTibZiele;
  final double? kalkulationsfaktorOverride;
  final double? stundensatzOverride;
  final double verbrauchteStunden;

  const Client({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.teamId,
    this.email,
    this.phone,
    this.address,
    required this.dateOfBirth,
    this.status = ClientStatus.active,
    this.priority = ClientPriority.medium,
    this.services = const [],
    this.notes,
    this.caseManager,
    required this.createdAt,
    required this.updatedAt,
    this.insuranceNumber,
    this.emergencyContact,
    this.emergencyPhone,
    this.assignedEmployees = const [],
    this.responsibleEmployeeId,
    this.deputyEmployeeId,
    this.deputy2EmployeeId,
    this.customFields = const {},
    // EH-Felder
    this.fachleistungsstunden,
    this.fachleistungsIntervall,
    this.hilfeTyp,
    this.kostenuebernahme,
    this.kostenuebernahmeVon,
    this.kostenuebernahmeBis,
    this.betreuungSeit,
    this.icfBereiche,
    this.tibZiele,
    this.individuelleTibZiele,
    this.kalkulationsfaktorOverride,
    this.stundensatzOverride,
    this.verbrauchteStunden = 0.0,
  });

  String get fullName => '$firstName $lastName';

  String get displayName => fullName;

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  // Hilfsmethoden für Stundenverbrauch
  double get stundenverbrauchProzent {
    if (fachleistungsstunden == null || fachleistungsstunden == 0) return 0.0;
    return (verbrauchteStunden / fachleistungsstunden!) * 100;
  }

  double get verfuegbareStunden {
    if (fachleistungsstunden == null) return 0.0;
    return fachleistungsstunden!.toDouble() - verbrauchteStunden;
  }

  String get fachleistungsIntervallDisplay {
    switch (fachleistungsIntervall) {
      case 'woechentlich':
        return 'wöchentlich';
      case 'monatlich':
        return 'monatlich';
      case 'jaehrlich':
        return 'jährlich';
      default:
        return fachleistungsIntervall ?? '';
    }
  }

  String get hilfeTypDisplay {
    switch (hilfeTyp) {
      case 'eingliederungshilfe':
        return 'Eingliederungshilfe';
      case 'familienhilfe':
        return 'Familienhilfe';
      default:
        return hilfeTyp ?? '';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case ClientStatus.active:
        return 'Aktiv';
      case ClientStatus.inactive:
        return 'Inaktiv';
      case ClientStatus.pending:
        return 'Anstehend';
      case ClientStatus.archived:
        return 'Archiviert';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case ClientPriority.low:
        return 'Niedrig';
      case ClientPriority.medium:
        return 'Mittel';
      case ClientPriority.high:
        return 'Hoch';
      case ClientPriority.urgent:
        return 'Dringend';
    }
  }

  List<String> get serviceDisplayNames {
    return services.map((service) {
      switch (service) {
        case ServiceType.ambulant:
          return 'Ambulant';
        case ServiceType.stationaer:
          return 'Stationär';
        case ServiceType.beratung:
          return 'Beratung';
        case ServiceType.begleitung:
          return 'Begleitung';
        case ServiceType.wohnen:
          return 'Wohnen';
        case ServiceType.arbeit:
          return 'Arbeit';
        case ServiceType.freizeit:
          return 'Freizeit';
      }
    }).toList();
  }

  Client copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? teamId,
    String? email,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
    ClientStatus? status,
    ClientPriority? priority,
    List<ServiceType>? services,
    String? notes,
    String? caseManager,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? insuranceNumber,
    String? emergencyContact,
    String? emergencyPhone,
    List<String>? assignedEmployees,
    String? responsibleEmployeeId,
    String? deputyEmployeeId,
    String? deputy2EmployeeId,
    Map<String, dynamic>? customFields,
    int? fachleistungsstunden,
    String? fachleistungsIntervall,
    String? hilfeTyp,
    String? kostenuebernahme,
    DateTime? kostenuebernahmeVon,
    DateTime? kostenuebernahmeBis,
    DateTime? betreuungSeit,
    List<String>? icfBereiche,
    List<String>? tibZiele,
    List<String>? individuelleTibZiele,
    double? kalkulationsfaktorOverride,
    double? stundensatzOverride,
    double? verbrauchteStunden,
  }) {
    return Client(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      teamId: teamId ?? this.teamId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      services: services ?? this.services,
      notes: notes ?? this.notes,
      caseManager: caseManager ?? this.caseManager,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      assignedEmployees: assignedEmployees ?? this.assignedEmployees,
      responsibleEmployeeId: responsibleEmployeeId ?? this.responsibleEmployeeId,
      deputyEmployeeId: deputyEmployeeId ?? this.deputyEmployeeId,
      deputy2EmployeeId: deputy2EmployeeId ?? this.deputy2EmployeeId,
      customFields: customFields ?? this.customFields,
      fachleistungsstunden: fachleistungsstunden ?? this.fachleistungsstunden,
      fachleistungsIntervall: fachleistungsIntervall ?? this.fachleistungsIntervall,
      hilfeTyp: hilfeTyp ?? this.hilfeTyp,
      kostenuebernahme: kostenuebernahme ?? this.kostenuebernahme,
      kostenuebernahmeVon: kostenuebernahmeVon ?? this.kostenuebernahmeVon,
      kostenuebernahmeBis: kostenuebernahmeBis ?? this.kostenuebernahmeBis,
      betreuungSeit: betreuungSeit ?? this.betreuungSeit,
      icfBereiche: icfBereiche ?? this.icfBereiche,
      tibZiele: tibZiele ?? this.tibZiele,
      individuelleTibZiele: individuelleTibZiele ?? this.individuelleTibZiele,
      kalkulationsfaktorOverride: kalkulationsfaktorOverride ?? this.kalkulationsfaktorOverride,
      stundensatzOverride: stundensatzOverride ?? this.stundensatzOverride,
      verbrauchteStunden: verbrauchteStunden ?? this.verbrauchteStunden,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'teamId': teamId,
      'email': email,
      'phone': phone,
      'address': address,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'status': status.name,
      'priority': priority.name,
      'services': services.map((s) => s.name).toList(),
      'notes': notes,
      'caseManager': caseManager,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'insuranceNumber': insuranceNumber,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'assignedEmployees': assignedEmployees,
      'responsibleEmployeeId': responsibleEmployeeId,
      'deputyEmployeeId': deputyEmployeeId,
      'deputy2EmployeeId': deputy2EmployeeId,
      'customFields': customFields,
      // EH-Felder
      'fachleistungsstunden': fachleistungsstunden,
      'fachleistungsIntervall': fachleistungsIntervall,
      'hilfeTyp': hilfeTyp,
      'kostenuebernahme': kostenuebernahme,
      'kostenuebernahmeVon': kostenuebernahmeVon?.toIso8601String(),
      'kostenuebernahmeBis': kostenuebernahmeBis?.toIso8601String(),
      'betreuungSeit': betreuungSeit?.toIso8601String(),
      'icfBereiche': icfBereiche,
      'tibZiele': tibZiele,
      'individuelleTibZiele': individuelleTibZiele,
      'kalkulationsfaktorOverride': kalkulationsfaktorOverride,
      'stundensatzOverride': stundensatzOverride,
      'verbrauchteStunden': verbrauchteStunden,
      // EH-kompatible Alias-Felder (damit die EH-App den Klienten lesen kann)
      'vorname': firstName,
      'nachname': lastName,
      'name': fullName,
      'geburtsdatum': dateOfBirth.toIso8601String(),
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      teamId: json['teamId'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      status: ClientStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ClientStatus.active,
      ),
      priority: ClientPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => ClientPriority.medium,
      ),
      services: (json['services'] as List<dynamic>?)
          ?.map((s) => ServiceType.values.firstWhere(
                (e) => e.name == s,
                orElse: () => ServiceType.ambulant,
              ))
          .toList() ?? [],
      notes: json['notes'] as String?,
      caseManager: json['caseManager'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      insuranceNumber: json['insuranceNumber'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      emergencyPhone: json['emergencyPhone'] as String?,
      assignedEmployees: (json['assignedEmployees'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      responsibleEmployeeId: json['responsibleEmployeeId'] as String?,
      deputyEmployeeId: json['deputyEmployeeId'] as String?,
      deputy2EmployeeId: json['deputy2EmployeeId'] as String?,
      customFields: (json['customFields'] as Map<String, dynamic>?) ?? {},
      // EH-Felder
      fachleistungsstunden: json['fachleistungsstunden'] as int?,
      fachleistungsIntervall: json['fachleistungsIntervall'] as String?,
      hilfeTyp: json['hilfeTyp'] as String?,
      kostenuebernahme: json['kostenuebernahme'] as String?,
      kostenuebernahmeVon: json['kostenuebernahmeVon'] != null
          ? DateTime.parse(json['kostenuebernahmeVon'] as String)
          : null,
      kostenuebernahmeBis: json['kostenuebernahmeBis'] != null
          ? DateTime.parse(json['kostenuebernahmeBis'] as String)
          : null,
      betreuungSeit: json['betreuungSeit'] != null
          ? DateTime.parse(json['betreuungSeit'] as String)
          : null,
      icfBereiche: (json['icfBereiche'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      tibZiele: (json['tibZiele'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      individuelleTibZiele: (json['individuelleTibZiele'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      kalkulationsfaktorOverride: (json['kalkulationsfaktorOverride'] as num?)?.toDouble(),
      stundensatzOverride: (json['stundensatzOverride'] as num?)?.toDouble(),
      verbrauchteStunden: (json['verbrauchteStunden'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Client && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Client(id: $id, name: $fullName, status: $status)';
  }
}
