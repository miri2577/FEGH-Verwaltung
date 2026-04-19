import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/shift.dart';
import '../models/shift_swap_request.dart';
import 'audit_logger.dart';

/// Service fuer den Tausch-Anfrage-Workflow.
///
/// Persistenz in SharedPreferences unter `shift_swap_requests_v1`.
/// Der Service verwaltet ausschliesslich den Anfrage-Zustand. Die
/// eigentliche Schicht-Umbuchung (nach finaler Genehmigung) wird vom
/// Provider ausgeloest, der [approveByLead] aufruft und den
/// zurueckgegebenen `ShiftSwapRequest` nutzt, um via `shiftsProvider`
/// die `employeeId` der Schicht zu aendern.
class ShiftSwapService {
  static const _key = 'shift_swap_requests_v1';
  static const _uuid = Uuid();

  // ── Persistenz ────────────────────────────────────────────────

  Future<List<ShiftSwapRequest>> _loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => ShiftSwapRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[SWAP] loadAll: $e');
      return [];
    }
  }

  Future<bool> _saveAll(List<ShiftSwapRequest> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(list.map((r) => r.toJson()).toList()));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[SWAP] saveAll: $e');
      return false;
    }
  }

  // ── Abfragen ──────────────────────────────────────────────────

  Future<List<ShiftSwapRequest>> loadAll() async {
    final all = await _loadAll();
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  Future<List<ShiftSwapRequest>> loadForRequester(String employeeId) async {
    final all = await _loadAll();
    return all.where((r) => r.requesterEmployeeId == employeeId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Offene Anfragen, die [employeeId] annehmen kann (direkt adressiert
  /// oder offen und in seinem Team).
  Future<List<ShiftSwapRequest>> loadOpenForRecipient(
    String employeeId, {
    required Iterable<String> myTeamIds,
  }) async {
    final all = await _loadAll();
    return all
        .where((r) =>
            r.status == ShiftSwapStatus.pending &&
            r.requesterEmployeeId != employeeId &&
            (r.offeredToEmployeeId == employeeId ||
                (r.offeredToEmployeeId == null &&
                    r.teamId != null &&
                    myTeamIds.contains(r.teamId))))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Angenommene Anfragen, die noch auf Teamleitungs-Entscheidung warten.
  Future<List<ShiftSwapRequest>> loadForLeadReview(
      Iterable<String> teamIds) async {
    final all = await _loadAll();
    return all
        .where((r) =>
            r.status == ShiftSwapStatus.accepted &&
            r.teamId != null &&
            teamIds.contains(r.teamId))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // ── Aktionen ──────────────────────────────────────────────────

  /// Antragsteller oeffnet eine Anfrage.
  Future<String?> createRequest({
    required Shift shift,
    required String requesterEmployeeId,
    String? offeredToEmployeeId,
    required String reason,
  }) async {
    if (shift.employeeId != requesterEmployeeId) return null;
    if (shift.status == ShiftStatus.cancelled ||
        shift.status == ShiftStatus.completed) {
      return null;
    }
    if (reason.trim().isEmpty) return null;
    if (offeredToEmployeeId == requesterEmployeeId) return null;

    final all = await _loadAll();
    // Nur eine offene Anfrage pro Schicht.
    final open = all.any((r) =>
        r.shiftId == shift.id &&
        (r.status == ShiftSwapStatus.pending ||
            r.status == ShiftSwapStatus.accepted));
    if (open) {
      if (kDebugMode) {
        debugPrint('[SWAP] shift ${shift.id} has open request already');
      }
      return null;
    }

    final now = DateTime.now();
    final req = ShiftSwapRequest(
      id: _uuid.v4(),
      shiftId: shift.id,
      teamId: shift.teamId,
      requesterEmployeeId: requesterEmployeeId,
      offeredToEmployeeId: offeredToEmployeeId,
      reason: reason.trim(),
      status: ShiftSwapStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    all.add(req);
    final ok = await _saveAll(all);
    if (!ok) return null;
    await AuditLogger.log('shift.swap.created', context: {
      'swapId': req.id,
      'shiftId': shift.id,
      'requester': requesterEmployeeId,
      if (offeredToEmployeeId != null) 'offeredTo': offeredToEmployeeId,
      'reason': reason,
    });
    return req.id;
  }

  Future<bool> cancel(String requestId, String byEmployeeId) async {
    return _transition(
      requestId,
      expected: const {ShiftSwapStatus.pending, ShiftSwapStatus.accepted},
      guard: (r) => r.requesterEmployeeId == byEmployeeId,
      apply: (r) => r.copyWith(status: ShiftSwapStatus.cancelled),
      auditAction: 'shift.swap.cancelled',
      auditContext: {'by': byEmployeeId},
    );
  }

  Future<bool> accept(String requestId, String acceptingEmployeeId) async {
    return _transition(
      requestId,
      expected: const {ShiftSwapStatus.pending},
      guard: (r) =>
          r.requesterEmployeeId != acceptingEmployeeId &&
          (r.offeredToEmployeeId == null ||
              r.offeredToEmployeeId == acceptingEmployeeId),
      apply: (r) => r.copyWith(
        status: ShiftSwapStatus.accepted,
        acceptingEmployeeId: acceptingEmployeeId,
      ),
      auditAction: 'shift.swap.accepted',
      auditContext: {'acceptor': acceptingEmployeeId},
    );
  }

  Future<bool> decline(String requestId, String byEmployeeId,
      {String? reason}) async {
    return _transition(
      requestId,
      expected: const {ShiftSwapStatus.pending},
      guard: (r) =>
          r.offeredToEmployeeId == null ||
          r.offeredToEmployeeId == byEmployeeId,
      apply: (r) => r.copyWith(
        status: ShiftSwapStatus.declined,
        leadNote: reason,
      ),
      auditAction: 'shift.swap.declined',
      auditContext: {
        'by': byEmployeeId,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Markiert die Anfrage als genehmigt und gibt den aktualisierten
  /// Record zurueck. Der Caller (Provider) ist fuer die Schicht-Umbuchung
  /// (Aenderung von [Shift.employeeId] auf [ShiftSwapRequest.acceptingEmployeeId])
  /// zustaendig.
  ///
  /// Gibt `null` zurueck, wenn die Anfrage nicht im Zustand
  /// [ShiftSwapStatus.accepted] ist.
  Future<ShiftSwapRequest?> approveByLead(
    String requestId,
    String leadEmployeeId, {
    String? note,
  }) async {
    final all = await _loadAll();
    final idx = all.indexWhere((r) => r.id == requestId);
    if (idx < 0) return null;
    final r = all[idx];
    if (r.status != ShiftSwapStatus.accepted) return null;
    if (r.acceptingEmployeeId == null) return null;

    final updated = r.copyWith(
      status: ShiftSwapStatus.approved,
      leadDecisionByEmployeeId: leadEmployeeId,
      leadDecisionAt: DateTime.now(),
      leadNote: note,
    );
    all[idx] = updated;
    final ok = await _saveAll(all);
    if (!ok) return null;
    await AuditLogger.log('shift.swap.approved', context: {
      'swapId': r.id,
      'shiftId': r.shiftId,
      'fromEmployeeId': r.requesterEmployeeId,
      'toEmployeeId': r.acceptingEmployeeId,
      'by': leadEmployeeId,
      if (note != null) 'note': note,
    });
    return updated;
  }

  Future<bool> rejectByLead(String requestId, String leadEmployeeId,
      {String? note}) async {
    return _transition(
      requestId,
      expected: const {ShiftSwapStatus.accepted},
      guard: (_) => true,
      apply: (r) => r.copyWith(
        status: ShiftSwapStatus.rejected,
        leadDecisionByEmployeeId: leadEmployeeId,
        leadDecisionAt: DateTime.now(),
        leadNote: note,
      ),
      auditAction: 'shift.swap.rejected',
      auditContext: {
        'by': leadEmployeeId,
        if (note != null) 'note': note,
      },
    );
  }

  // ── intern ────────────────────────────────────────────────────

  Future<bool> _transition(
    String requestId, {
    required Set<ShiftSwapStatus> expected,
    required bool Function(ShiftSwapRequest) guard,
    required ShiftSwapRequest Function(ShiftSwapRequest) apply,
    required String auditAction,
    Map<String, dynamic>? auditContext,
  }) async {
    final all = await _loadAll();
    final idx = all.indexWhere((r) => r.id == requestId);
    if (idx < 0) return false;
    if (!expected.contains(all[idx].status)) return false;
    if (!guard(all[idx])) return false;
    all[idx] = apply(all[idx]);
    final ok = await _saveAll(all);
    if (!ok) return false;
    await AuditLogger.log(auditAction, context: {
      'swapId': requestId,
      'shiftId': all[idx].shiftId,
      ...?auditContext,
    });
    return true;
  }
}
