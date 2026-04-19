/// Status einer Tausch-Anfrage.
///
/// Lifecycle:
/// `pending` → `accepted` → `approved` (final — Schicht wird umgebucht)
///
/// Abbruch-Pfade: `declined` (Empfaenger lehnt ab), `rejected`
/// (Teamleitung lehnt final ab), `cancelled` (Antragsteller zieht zurueck).
enum ShiftSwapStatus {
  pending,
  accepted,
  approved,
  declined,
  rejected,
  cancelled,
}

extension ShiftSwapStatusLabel on ShiftSwapStatus {
  String get label {
    switch (this) {
      case ShiftSwapStatus.pending:
        return 'Offen';
      case ShiftSwapStatus.accepted:
        return 'Angenommen (wartet auf Leitung)';
      case ShiftSwapStatus.approved:
        return 'Genehmigt';
      case ShiftSwapStatus.declined:
        return 'Abgelehnt (Empfaenger)';
      case ShiftSwapStatus.rejected:
        return 'Abgelehnt (Leitung)';
      case ShiftSwapStatus.cancelled:
        return 'Zurueckgezogen';
    }
  }

  bool get isOpen =>
      this == ShiftSwapStatus.pending || this == ShiftSwapStatus.accepted;
  bool get isFinal => !isOpen;
}

/// Antrag zum Tausch einer Schicht zwischen zwei Mitarbeitern.
///
/// Der Schicht-Inhaber ([requesterEmployeeId]) bietet seine Schicht
/// entweder einem konkreten Kollegen ([offeredToEmployeeId]) oder offen
/// dem Team an. Die Teamleitung bestaetigt final.
class ShiftSwapRequest {
  final String id;
  final String shiftId;
  final String? teamId;
  final String requesterEmployeeId;

  /// Optional: konkreter Empfaenger. Wenn `null`, ist die Anfrage offen
  /// fuer alle Team-Mitglieder.
  final String? offeredToEmployeeId;

  /// Wer (bei Annahme) die Schicht uebernimmt. Wird erst bei
  /// `accepted`-Zustand gesetzt.
  final String? acceptingEmployeeId;

  /// Begruendung fuer den Antrag (Pflicht bei Erstellung).
  final String reason;

  /// Notiz der Teamleitung bei Genehmigung/Ablehnung.
  final String? leadNote;

  final String? leadDecisionByEmployeeId;
  final DateTime? leadDecisionAt;

  final ShiftSwapStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShiftSwapRequest({
    required this.id,
    required this.shiftId,
    this.teamId,
    required this.requesterEmployeeId,
    this.offeredToEmployeeId,
    this.acceptingEmployeeId,
    required this.reason,
    this.leadNote,
    this.leadDecisionByEmployeeId,
    this.leadDecisionAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  ShiftSwapRequest copyWith({
    String? id,
    String? shiftId,
    String? teamId,
    String? requesterEmployeeId,
    String? offeredToEmployeeId,
    String? acceptingEmployeeId,
    String? reason,
    String? leadNote,
    String? leadDecisionByEmployeeId,
    DateTime? leadDecisionAt,
    ShiftSwapStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShiftSwapRequest(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      teamId: teamId ?? this.teamId,
      requesterEmployeeId: requesterEmployeeId ?? this.requesterEmployeeId,
      offeredToEmployeeId: offeredToEmployeeId ?? this.offeredToEmployeeId,
      acceptingEmployeeId: acceptingEmployeeId ?? this.acceptingEmployeeId,
      reason: reason ?? this.reason,
      leadNote: leadNote ?? this.leadNote,
      leadDecisionByEmployeeId:
          leadDecisionByEmployeeId ?? this.leadDecisionByEmployeeId,
      leadDecisionAt: leadDecisionAt ?? this.leadDecisionAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shiftId': shiftId,
        if (teamId != null) 'teamId': teamId,
        'requesterEmployeeId': requesterEmployeeId,
        if (offeredToEmployeeId != null)
          'offeredToEmployeeId': offeredToEmployeeId,
        if (acceptingEmployeeId != null)
          'acceptingEmployeeId': acceptingEmployeeId,
        'reason': reason,
        if (leadNote != null) 'leadNote': leadNote,
        if (leadDecisionByEmployeeId != null)
          'leadDecisionByEmployeeId': leadDecisionByEmployeeId,
        if (leadDecisionAt != null)
          'leadDecisionAt': leadDecisionAt!.toIso8601String(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ShiftSwapRequest.fromJson(Map<String, dynamic> json) =>
      ShiftSwapRequest(
        id: json['id'] as String,
        shiftId: json['shiftId'] as String,
        teamId: json['teamId'] as String?,
        requesterEmployeeId: json['requesterEmployeeId'] as String,
        offeredToEmployeeId: json['offeredToEmployeeId'] as String?,
        acceptingEmployeeId: json['acceptingEmployeeId'] as String?,
        reason: json['reason'] as String,
        leadNote: json['leadNote'] as String?,
        leadDecisionByEmployeeId:
            json['leadDecisionByEmployeeId'] as String?,
        leadDecisionAt: json['leadDecisionAt'] != null
            ? DateTime.parse(json['leadDecisionAt'] as String)
            : null,
        status: ShiftSwapStatus.values
            .firstWhere((s) => s.name == json['status'],
                orElse: () => ShiftSwapStatus.pending),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
