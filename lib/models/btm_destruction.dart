/// Vernichtungsprotokoll eines Betaeubungsmittels (§ 15 BtMVV).
///
/// Jede Vernichtung ist:
/// - nur im Vier-Augen-Prinzip zulaessig (Verantwortlicher + Zeuge)
/// - Mengenaenderung wird dem Bestand zugeordnet
/// - dauerhaft nicht aenderbar (append-only, Korrekturen nur per neuem
///   Eintrag mit Bezug)
class BtmDestruction {
  final String id;
  final String medicationId;
  final String clientId;

  /// Vernichtete Menge in der Einheit der Medikation (Freitext fuer Menge,
  /// numerisch fuer Rechenoperationen mit dem Bestand).
  final double menge;
  final String mengeEinheit;

  /// Grund: `expired`, `notNeeded`, `contaminated`, `moveOut`, `other`.
  final String reason;

  /// Freitext-Begruendung (ergaenzend zu [reason]).
  final String? reasonDetails;

  /// Verantwortlich fuer die Vernichtung (Mitarbeiter-ID).
  final String destroyerEmployeeId;

  /// Zeuge der Vernichtung (Mitarbeiter-ID). Pflicht.
  final String witnessEmployeeId;

  /// Zeitpunkt der tatsaechlichen Vernichtung.
  final DateTime destroyedAt;

  /// Base64-PNG der Unterschrift des Verantwortlichen (optional, als
  /// zusaetzlicher Nachweis).
  final String? signaturePngB64;

  final DateTime createdAt;

  const BtmDestruction({
    required this.id,
    required this.medicationId,
    required this.clientId,
    required this.menge,
    required this.mengeEinheit,
    required this.reason,
    this.reasonDetails,
    required this.destroyerEmployeeId,
    required this.witnessEmployeeId,
    required this.destroyedAt,
    this.signaturePngB64,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicationId': medicationId,
        'clientId': clientId,
        'menge': menge,
        'mengeEinheit': mengeEinheit,
        'reason': reason,
        if (reasonDetails != null) 'reasonDetails': reasonDetails,
        'destroyerEmployeeId': destroyerEmployeeId,
        'witnessEmployeeId': witnessEmployeeId,
        'destroyedAt': destroyedAt.toIso8601String(),
        if (signaturePngB64 != null) 'signaturePngB64': signaturePngB64,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BtmDestruction.fromJson(Map<String, dynamic> json) => BtmDestruction(
        id: json['id'] as String,
        medicationId: json['medicationId'] as String,
        clientId: json['clientId'] as String,
        menge: (json['menge'] as num).toDouble(),
        mengeEinheit: json['mengeEinheit'] as String,
        reason: json['reason'] as String,
        reasonDetails: json['reasonDetails'] as String?,
        destroyerEmployeeId: json['destroyerEmployeeId'] as String,
        witnessEmployeeId: json['witnessEmployeeId'] as String,
        destroyedAt: DateTime.parse(json['destroyedAt'] as String),
        signaturePngB64: json['signaturePngB64'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Gruende fuer eine BtM-Vernichtung — kanonische Werte.
class BtmDestructionReasons {
  static const expired = 'expired';
  static const notNeeded = 'notNeeded';
  static const contaminated = 'contaminated';
  static const moveOut = 'moveOut';
  static const other = 'other';

  static const all = <String>[
    expired,
    notNeeded,
    contaminated,
    moveOut,
    other,
  ];

  static String label(String reason) {
    switch (reason) {
      case expired:
        return 'Abgelaufen';
      case notNeeded:
        return 'Nicht mehr benoetigt';
      case contaminated:
        return 'Verunreinigt / beschaedigt';
      case moveOut:
        return 'Klient ausgezogen / verstorben';
      case other:
        return 'Sonstiges';
      default:
        return reason;
    }
  }
}
