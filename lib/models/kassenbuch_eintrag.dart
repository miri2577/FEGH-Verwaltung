/// Kategorien fuer Kassenbuch-Eintraege.
///
/// `eingang` ist positiv (Eingang/Gutschrift), alle anderen sind
/// typischerweise negativ (Auszahlung) — das Vorzeichen liegt aber
/// am Betrag, nicht an der Kategorie.
enum KassenbuchKategorie {
  eingang,
  taschengeld,
  haushaltsgeld,
  gesundheit,
  freizeit,
  bekleidung,
  verpflegung,
  sonstiges,
}

extension KassenbuchKategorieLabel on KassenbuchKategorie {
  String get label {
    switch (this) {
      case KassenbuchKategorie.eingang:
        return 'Eingang';
      case KassenbuchKategorie.taschengeld:
        return 'Taschengeld';
      case KassenbuchKategorie.haushaltsgeld:
        return 'Haushaltsgeld';
      case KassenbuchKategorie.gesundheit:
        return 'Gesundheit';
      case KassenbuchKategorie.freizeit:
        return 'Freizeit';
      case KassenbuchKategorie.bekleidung:
        return 'Bekleidung';
      case KassenbuchKategorie.verpflegung:
        return 'Verpflegung';
      case KassenbuchKategorie.sonstiges:
        return 'Sonstiges';
    }
  }
}

/// Ein einzelner Buchungssatz im Kassenbuch.
///
/// [betrag] ist positiv fuer Einzahlungen, negativ fuer Auszahlungen.
/// [confirmed] = true heisst: freigegebene Buchung — nicht mehr aenderbar.
class KassenbuchEintrag {
  final String id;
  final String clientId;
  final DateTime datum;
  final double betrag;
  final KassenbuchKategorie kategorie;
  final String beschreibung;
  final String? belegnummer;
  final String? erfasstVonEmployeeId;
  final bool confirmed;
  final DateTime createdAt;

  const KassenbuchEintrag({
    required this.id,
    required this.clientId,
    required this.datum,
    required this.betrag,
    required this.kategorie,
    required this.beschreibung,
    this.belegnummer,
    this.erfasstVonEmployeeId,
    this.confirmed = false,
    required this.createdAt,
  });

  bool get isEinzahlung => betrag >= 0;

  KassenbuchEintrag copyWith({
    String? id,
    String? clientId,
    DateTime? datum,
    double? betrag,
    KassenbuchKategorie? kategorie,
    String? beschreibung,
    String? belegnummer,
    String? erfasstVonEmployeeId,
    bool? confirmed,
    DateTime? createdAt,
  }) {
    return KassenbuchEintrag(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      datum: datum ?? this.datum,
      betrag: betrag ?? this.betrag,
      kategorie: kategorie ?? this.kategorie,
      beschreibung: beschreibung ?? this.beschreibung,
      belegnummer: belegnummer ?? this.belegnummer,
      erfasstVonEmployeeId: erfasstVonEmployeeId ?? this.erfasstVonEmployeeId,
      confirmed: confirmed ?? this.confirmed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'datum': datum.toIso8601String(),
        'betrag': betrag,
        'kategorie': kategorie.name,
        'beschreibung': beschreibung,
        'belegnummer': belegnummer,
        'erfasstVonEmployeeId': erfasstVonEmployeeId,
        'confirmed': confirmed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory KassenbuchEintrag.fromJson(Map<String, dynamic> json) =>
      KassenbuchEintrag(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        datum: DateTime.parse(json['datum'] as String),
        betrag: (json['betrag'] as num).toDouble(),
        kategorie: KassenbuchKategorie.values
            .firstWhere((k) => k.name == json['kategorie'],
                orElse: () => KassenbuchKategorie.sonstiges),
        beschreibung: json['beschreibung'] as String,
        belegnummer: json['belegnummer'] as String?,
        erfasstVonEmployeeId: json['erfasstVonEmployeeId'] as String?,
        confirmed: json['confirmed'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
