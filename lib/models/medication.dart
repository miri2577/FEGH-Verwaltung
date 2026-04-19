/// Einnahme-Zeiten eines Medikaments im Tagesraster.
///
/// Im MVP sind die Zeiten fest (08:00 / 12:00 / 18:00 / 22:00). In Scope B
/// werden diese pro Einrichtung konfigurierbar.
class MedicationSchedule {
  final bool morning;
  final bool noon;
  final bool evening;
  final bool night;

  const MedicationSchedule({
    this.morning = false,
    this.noon = false,
    this.evening = false,
    this.night = false,
  });

  bool get isEmpty => !morning && !noon && !evening && !night;

  /// Anzahl der Gaben pro Tag.
  int get dailyCount => [morning, noon, evening, night].where((b) => b).length;

  Map<String, dynamic> toJson() => {
        'morning': morning,
        'noon': noon,
        'evening': evening,
        'night': night,
      };

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) =>
      MedicationSchedule(
        morning: json['morning'] as bool? ?? false,
        noon: json['noon'] as bool? ?? false,
        evening: json['evening'] as bool? ?? false,
        night: json['night'] as bool? ?? false,
      );
}

/// Ein Medikations-Plan-Eintrag pro Klient.
class Medication {
  final String id;
  final String clientId;
  final String name; // z. B. "Sertralin 50 mg"
  final String dosage; // z. B. "1 Tablette"
  final MedicationSchedule schedule;
  final DateTime validFrom;
  final DateTime? validUntil;
  final String? prescribedBy;
  final String? notes;
  final bool requiresBtmLog; // Scope A: immer false
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Medication({
    required this.id,
    required this.clientId,
    required this.name,
    required this.dosage,
    required this.schedule,
    required this.validFrom,
    this.validUntil,
    this.prescribedBy,
    this.notes,
    this.requiresBtmLog = false,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Ist der Plan an diesem Tag gueltig (active + innerhalb Gueltigkeit)?
  bool isValidOn(DateTime day) {
    if (!active) return false;
    final d = DateTime(day.year, day.month, day.day);
    final from = DateTime(validFrom.year, validFrom.month, validFrom.day);
    if (d.isBefore(from)) return false;
    if (validUntil != null) {
      final until = DateTime(
          validUntil!.year, validUntil!.month, validUntil!.day);
      if (d.isAfter(until)) return false;
    }
    return true;
  }

  Medication copyWith({
    String? id,
    String? clientId,
    String? name,
    String? dosage,
    MedicationSchedule? schedule,
    DateTime? validFrom,
    DateTime? validUntil,
    String? prescribedBy,
    String? notes,
    bool? requiresBtmLog,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      schedule: schedule ?? this.schedule,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      notes: notes ?? this.notes,
      requiresBtmLog: requiresBtmLog ?? this.requiresBtmLog,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'name': name,
        'dosage': dosage,
        'schedule': schedule.toJson(),
        'validFrom': validFrom.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
        'prescribedBy': prescribedBy,
        'notes': notes,
        'requiresBtmLog': requiresBtmLog,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        name: json['name'] as String,
        dosage: json['dosage'] as String,
        schedule: MedicationSchedule.fromJson(
            json['schedule'] as Map<String, dynamic>),
        validFrom: DateTime.parse(json['validFrom'] as String),
        validUntil: json['validUntil'] != null
            ? DateTime.parse(json['validUntil'] as String)
            : null,
        prescribedBy: json['prescribedBy'] as String?,
        notes: json['notes'] as String?,
        requiresBtmLog: json['requiresBtmLog'] as bool? ?? false,
        active: json['active'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
