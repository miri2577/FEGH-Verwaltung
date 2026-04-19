/// Ein Monatsabschluss im Kassenbuch eines Klienten.
///
/// Friert den Endsaldo des Monats ein. Wird der Monat abgeschlossen,
/// koennen im gleichen Monat keine neuen Eintraege gebucht werden;
/// Korrekturen nur ueber Storno-Gegenbuchungen im Folgemonat.
class KassenbuchMonatsabschluss {
  final String clientId;
  final int jahr;
  final int monat; // 1..12
  final double saldoEnde;

  /// Optionaler Startsaldo (Rollover aus Vormonat). Wird beim Laden
  /// als Basis fuer [KassenbuchService.saldoBeforeMonth] genutzt.
  final double saldoStart;

  final String abgeschlossenVonEmployeeId;
  final DateTime abgeschlossenAm;

  /// Base64-kodiertes PNG der Unterschrift.
  final String? signaturePngB64;

  const KassenbuchMonatsabschluss({
    required this.clientId,
    required this.jahr,
    required this.monat,
    required this.saldoStart,
    required this.saldoEnde,
    required this.abgeschlossenVonEmployeeId,
    required this.abgeschlossenAm,
    this.signaturePngB64,
  });

  /// Eindeutiger Schluessel: clientId + YYYY-MM.
  String get key => '$clientId|${jahr.toString().padLeft(4, '0')}-'
      '${monat.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'jahr': jahr,
        'monat': monat,
        'saldoStart': saldoStart,
        'saldoEnde': saldoEnde,
        'abgeschlossenVonEmployeeId': abgeschlossenVonEmployeeId,
        'abgeschlossenAm': abgeschlossenAm.toIso8601String(),
        if (signaturePngB64 != null) 'signaturePngB64': signaturePngB64,
      };

  factory KassenbuchMonatsabschluss.fromJson(Map<String, dynamic> json) =>
      KassenbuchMonatsabschluss(
        clientId: json['clientId'] as String,
        jahr: json['jahr'] as int,
        monat: json['monat'] as int,
        saldoStart: (json['saldoStart'] as num?)?.toDouble() ?? 0,
        saldoEnde: (json['saldoEnde'] as num).toDouble(),
        abgeschlossenVonEmployeeId:
            json['abgeschlossenVonEmployeeId'] as String,
        abgeschlossenAm: DateTime.parse(json['abgeschlossenAm'] as String),
        signaturePngB64: json['signaturePngB64'] as String?,
      );
}
