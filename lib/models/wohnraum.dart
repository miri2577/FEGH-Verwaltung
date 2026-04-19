/// Status eines Wohnraums / Platzes.
enum WohnraumStatus {
  /// Frei, kann vergeben werden.
  free,

  /// Einem Klient fest zugewiesen.
  occupied,

  /// Reserviert (z. B. fuer anstehenden Einzug).
  reserved,

  /// Nicht mehr in Nutzung (Historie).
  inactive,
}

extension WohnraumStatusLabel on WohnraumStatus {
  String get label {
    switch (this) {
      case WohnraumStatus.free:
        return 'Frei';
      case WohnraumStatus.occupied:
        return 'Belegt';
      case WohnraumStatus.reserved:
        return 'Reserviert';
      case WohnraumStatus.inactive:
        return 'Inaktiv';
    }
  }
}

/// Ein Wohnraum / Platz in einer stationaeren Einrichtung.
///
/// Bewusst **nicht** auf einen Klienten fixiert — ein Platz hat eine
/// Historie an Bewohner:innen. [clientId] ist der aktuelle Bewohner,
/// null falls leerstehend.
class Wohnraum {
  final String id;
  final String? clientId;
  final String bezeichnung; // z. B. "Haus 1, Zimmer 3"
  final String? adresse;
  final double kaltmiete; // EUR/Monat
  final double nebenkosten; // EUR/Monat
  final double? kaution;
  final DateTime? mietbeginn;
  final DateTime? mietende;
  final String? vermieter;
  final String? vertragsnummer;
  final WohnraumStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wohnraum({
    required this.id,
    this.clientId,
    required this.bezeichnung,
    this.adresse,
    this.kaltmiete = 0,
    this.nebenkosten = 0,
    this.kaution,
    this.mietbeginn,
    this.mietende,
    this.vermieter,
    this.vertragsnummer,
    this.status = WohnraumStatus.free,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  double get warmmiete => kaltmiete + nebenkosten;

  Wohnraum copyWith({
    String? id,
    String? clientId,
    bool clearClient = false,
    String? bezeichnung,
    String? adresse,
    double? kaltmiete,
    double? nebenkosten,
    double? kaution,
    DateTime? mietbeginn,
    DateTime? mietende,
    String? vermieter,
    String? vertragsnummer,
    WohnraumStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wohnraum(
      id: id ?? this.id,
      clientId: clearClient ? null : (clientId ?? this.clientId),
      bezeichnung: bezeichnung ?? this.bezeichnung,
      adresse: adresse ?? this.adresse,
      kaltmiete: kaltmiete ?? this.kaltmiete,
      nebenkosten: nebenkosten ?? this.nebenkosten,
      kaution: kaution ?? this.kaution,
      mietbeginn: mietbeginn ?? this.mietbeginn,
      mietende: mietende ?? this.mietende,
      vermieter: vermieter ?? this.vermieter,
      vertragsnummer: vertragsnummer ?? this.vertragsnummer,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'bezeichnung': bezeichnung,
        'adresse': adresse,
        'kaltmiete': kaltmiete,
        'nebenkosten': nebenkosten,
        'kaution': kaution,
        'mietbeginn': mietbeginn?.toIso8601String(),
        'mietende': mietende?.toIso8601String(),
        'vermieter': vermieter,
        'vertragsnummer': vertragsnummer,
        'status': status.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Wohnraum.fromJson(Map<String, dynamic> json) => Wohnraum(
        id: json['id'] as String,
        clientId: json['clientId'] as String?,
        bezeichnung: json['bezeichnung'] as String,
        adresse: json['adresse'] as String?,
        kaltmiete: (json['kaltmiete'] as num?)?.toDouble() ?? 0,
        nebenkosten: (json['nebenkosten'] as num?)?.toDouble() ?? 0,
        kaution: (json['kaution'] as num?)?.toDouble(),
        mietbeginn: json['mietbeginn'] != null
            ? DateTime.parse(json['mietbeginn'] as String)
            : null,
        mietende: json['mietende'] != null
            ? DateTime.parse(json['mietende'] as String)
            : null,
        vermieter: json['vermieter'] as String?,
        vertragsnummer: json['vertragsnummer'] as String?,
        status: WohnraumStatus.values
            .firstWhere((s) => s.name == json['status'],
                orElse: () => WohnraumStatus.free),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
