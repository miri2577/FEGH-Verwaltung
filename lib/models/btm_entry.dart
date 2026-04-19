/// Zusaetzliche BtM-spezifische Dokumentation fuer eine Medikationsgabe.
///
/// Das BtMG (§13 BtMG i. V. m. §§ 12, 13 BtMVV) verlangt bei der Anwendung
/// von Betaeubungsmitteln in Einrichtungen:
///
/// - Dokumentation jeder Gabe (Datum, Uhrzeit, Bewohner:in, Menge, Restbestand)
/// - Vier-Augen-Prinzip: Gabe durch eine Person, bestaetigt durch Zeuge:in
/// - Fortlaufender Bestand mit Nachweis bei Pruefungen
/// - Vernichtung nur mit Zeuge, protokolliert
///
/// Dieses Modell haeltert das Zusatz-Record fuer eine bestehende
/// `MedicationAdministration`. Der eigentliche Gabe-Zeitpunkt und die
/// Status-Uebergaenge bleiben in `MedicationAdministration`.
class BtmEntry {
  final String id;

  /// ID der zugehoerigen [MedicationAdministration].
  final String administrationId;

  /// ID der Medikation (redundant fuer schnellen Zugriff).
  final String medicationId;
  final String clientId;

  /// Tatsaechliche Gabe-Menge in der Masseinheit der Medikation
  /// (z. B. Tablette, ml, Tropfen). Freitext, weil Einheiten stark
  /// variieren.
  final String menge;

  /// Restbestand nach dieser Gabe, in derselben Einheit wie [menge].
  final double restbestand;

  /// Zeuge der Gabe (Mitarbeiter-ID). Pflicht nach BtMVV.
  final String witnessEmployeeId;

  /// Ausstellender Arzt / verschreibende Praxis (optional, aus Plan uebernehmbar).
  final String? verordnenderArzt;

  /// Belegnummer / Chargennummer auf der Verordnung oder der Blisterverpackung.
  final String? belegnummer;

  /// Freitext (z. B. „Klient beobachtet, vitale Zeichen unauffaellig").
  final String? notizen;

  final DateTime createdAt;

  const BtmEntry({
    required this.id,
    required this.administrationId,
    required this.medicationId,
    required this.clientId,
    required this.menge,
    required this.restbestand,
    required this.witnessEmployeeId,
    this.verordnenderArzt,
    this.belegnummer,
    this.notizen,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'administrationId': administrationId,
        'medicationId': medicationId,
        'clientId': clientId,
        'menge': menge,
        'restbestand': restbestand,
        'witnessEmployeeId': witnessEmployeeId,
        'verordnenderArzt': verordnenderArzt,
        'belegnummer': belegnummer,
        'notizen': notizen,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BtmEntry.fromJson(Map<String, dynamic> json) => BtmEntry(
        id: json['id'] as String,
        administrationId: json['administrationId'] as String,
        medicationId: json['medicationId'] as String,
        clientId: json['clientId'] as String,
        menge: json['menge'] as String,
        restbestand: (json['restbestand'] as num).toDouble(),
        witnessEmployeeId: json['witnessEmployeeId'] as String,
        verordnenderArzt: json['verordnenderArzt'] as String?,
        belegnummer: json['belegnummer'] as String?,
        notizen: json['notizen'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
