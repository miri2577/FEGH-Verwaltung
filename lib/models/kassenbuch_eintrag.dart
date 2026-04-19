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

  /// Base64-kodiertes PNG der Unterschrift (Canvas).
  /// Nur gesetzt bei freigegebenen Eintraegen mit Canvas-Unterschrift.
  final String? signaturePngB64;

  /// Base64-kodierte Beleg-Datei (Foto oder PDF). Maximal ~5 MB — wird
  /// am Eintrag mitgespeichert, damit er portabel bleibt.
  final String? belegBytesB64;

  /// MIME-Type der Beleg-Datei, z. B. `image/jpeg`, `image/png`, `application/pdf`.
  final String? belegMimeType;

  /// Dateiname des Belegs (fuer Anzeige und Download).
  final String? belegFileName;

  /// ID des Eintrags, den dieser Eintrag storniert (Gegenbuchung).
  /// Wenn gesetzt, ist dieser Eintrag selbst eine Stornobuchung.
  final String? stornoOfEntryId;

  /// Begruendung fuer die Stornierung. Pflicht, wenn [stornoOfEntryId]
  /// gesetzt ist.
  final String? stornoReason;

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
    this.signaturePngB64,
    this.belegBytesB64,
    this.belegMimeType,
    this.belegFileName,
    this.stornoOfEntryId,
    this.stornoReason,
    required this.createdAt,
  });

  bool get isEinzahlung => betrag >= 0;

  /// Dieser Eintrag ist eine Stornobuchung.
  bool get isStorno => stornoOfEntryId != null;

  /// Eintrag hat einen Beleg angehaengt.
  bool get hasBeleg => belegBytesB64 != null && belegBytesB64!.isNotEmpty;

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
    String? signaturePngB64,
    String? belegBytesB64,
    String? belegMimeType,
    String? belegFileName,
    String? stornoOfEntryId,
    String? stornoReason,
    DateTime? createdAt,
    bool clearBeleg = false,
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
      signaturePngB64: signaturePngB64 ?? this.signaturePngB64,
      belegBytesB64:
          clearBeleg ? null : (belegBytesB64 ?? this.belegBytesB64),
      belegMimeType:
          clearBeleg ? null : (belegMimeType ?? this.belegMimeType),
      belegFileName:
          clearBeleg ? null : (belegFileName ?? this.belegFileName),
      stornoOfEntryId: stornoOfEntryId ?? this.stornoOfEntryId,
      stornoReason: stornoReason ?? this.stornoReason,
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
        if (signaturePngB64 != null) 'signaturePngB64': signaturePngB64,
        if (belegBytesB64 != null) 'belegBytesB64': belegBytesB64,
        if (belegMimeType != null) 'belegMimeType': belegMimeType,
        if (belegFileName != null) 'belegFileName': belegFileName,
        if (stornoOfEntryId != null) 'stornoOfEntryId': stornoOfEntryId,
        if (stornoReason != null) 'stornoReason': stornoReason,
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
        signaturePngB64: json['signaturePngB64'] as String?,
        belegBytesB64: json['belegBytesB64'] as String?,
        belegMimeType: json['belegMimeType'] as String?,
        belegFileName: json['belegFileName'] as String?,
        stornoOfEntryId: json['stornoOfEntryId'] as String?,
        stornoReason: json['stornoReason'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
