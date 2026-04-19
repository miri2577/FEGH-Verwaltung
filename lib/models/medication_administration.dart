import 'medication.dart';

/// Status einer Medikationsgabe.
enum AdministrationStatus {
  /// Geplanter Slot, noch nicht bearbeitet.
  pending,

  /// Medikament wurde verabreicht.
  given,

  /// Klient:in hat verweigert (mit Grund).
  refused,

  /// Gabe wurde verpasst (mit Grund, z. B. Klient abwesend).
  missed,
}

extension AdministrationStatusLabel on AdministrationStatus {
  String get label {
    switch (this) {
      case AdministrationStatus.pending:
        return 'Offen';
      case AdministrationStatus.given:
        return 'Gegeben';
      case AdministrationStatus.refused:
        return 'Verweigert';
      case AdministrationStatus.missed:
        return 'Verpasst';
    }
  }
}

/// Eine konkrete Gabe-Quittung (wurde gegeben/verweigert/verpasst).
class MedicationAdministration {
  final String id;
  final String medicationId;
  final String clientId;
  final DateTime scheduledAt;
  final DateTime? administeredAt;
  final String? administeredByEmployeeId;

  /// Zeuge der Gabe (Vier-Augen-Prinzip). Pflicht bei BtM oder wenn
  /// [Medication.requiresWitness] gesetzt ist.
  final String? witnessEmployeeId;

  final AdministrationStatus status;
  final String? reason;
  final String? notes;
  final DateTime createdAt;

  const MedicationAdministration({
    required this.id,
    required this.medicationId,
    required this.clientId,
    required this.scheduledAt,
    this.administeredAt,
    this.administeredByEmployeeId,
    this.witnessEmployeeId,
    required this.status,
    this.reason,
    this.notes,
    required this.createdAt,
  });

  MedicationAdministration copyWith({
    String? id,
    String? medicationId,
    String? clientId,
    DateTime? scheduledAt,
    DateTime? administeredAt,
    String? administeredByEmployeeId,
    String? witnessEmployeeId,
    AdministrationStatus? status,
    String? reason,
    String? notes,
    DateTime? createdAt,
  }) {
    return MedicationAdministration(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      clientId: clientId ?? this.clientId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      administeredAt: administeredAt ?? this.administeredAt,
      administeredByEmployeeId:
          administeredByEmployeeId ?? this.administeredByEmployeeId,
      witnessEmployeeId: witnessEmployeeId ?? this.witnessEmployeeId,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicationId': medicationId,
        'clientId': clientId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'administeredAt': administeredAt?.toIso8601String(),
        'administeredByEmployeeId': administeredByEmployeeId,
        if (witnessEmployeeId != null)
          'witnessEmployeeId': witnessEmployeeId,
        'status': status.name,
        'reason': reason,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MedicationAdministration.fromJson(Map<String, dynamic> json) =>
      MedicationAdministration(
        id: json['id'] as String,
        medicationId: json['medicationId'] as String,
        clientId: json['clientId'] as String,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        administeredAt: json['administeredAt'] != null
            ? DateTime.parse(json['administeredAt'] as String)
            : null,
        administeredByEmployeeId: json['administeredByEmployeeId'] as String?,
        witnessEmployeeId: json['witnessEmployeeId'] as String?,
        status: AdministrationStatus.values
            .firstWhere((s) => s.name == json['status']),
        reason: json['reason'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Ein berechneter Slot aus Plan × geplanter Zeit.
/// [existing] ist die bereits erfasste Quittung (falls vorhanden).
class AdministrationSlot {
  final Medication medication;
  final DateTime scheduledAt;
  final MedicationAdministration? existing;

  const AdministrationSlot({
    required this.medication,
    required this.scheduledAt,
    this.existing,
  });

  AdministrationStatus get status =>
      existing?.status ?? AdministrationStatus.pending;

  String get clientId => medication.clientId;
  String get medicationId => medication.id;
}
