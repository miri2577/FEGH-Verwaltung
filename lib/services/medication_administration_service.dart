import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/medication.dart';
import '../models/medication_administration.dart';
import 'audit_logger.dart';
import 'medication_service.dart';

/// Erzeugt offene Slots aus Plaenen und nimmt Gabe-Quittungen entgegen.
///
/// Slots werden pro Abruf neu aus den aktiven Medikationsplaenen
/// berechnet (Fixzeiten: 08:00/12:00/18:00/22:00 fuer morning/noon/
/// evening/night). Bereits erfasste Quittungen werden den Slots
/// zugeordnet.
class MedicationAdministrationService {
  static const _key = 'medication_administrations_v1';
  static const _uuid = Uuid();

  final MedicationService _medications;

  MedicationAdministrationService({MedicationService? medications})
      : _medications = medications ?? MedicationService();

  /// Feste Tageszeiten fuer Slots (MVP).
  static const slotHours = <String, int>{
    'morning': 8,
    'noon': 12,
    'evening': 18,
    'night': 22,
  };

  // ── Persistenz ──────────────────────────────────────────────────

  Future<List<MedicationAdministration>> _loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) =>
              MedicationAdministration.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[MED-ADM] loadAll: $e');
      return [];
    }
  }

  Future<bool> _saveAll(List<MedicationAdministration> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(list.map((a) => a.toJson()).toList()));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[MED-ADM] saveAll: $e');
      return false;
    }
  }

  // ── Slot-Generierung ────────────────────────────────────────────

  /// Erzeugt aus den aktiven Medikationsplaenen alle geplanten Slots
  /// fuer [date]. Falls schon eine Quittung existiert, wird sie am
  /// Slot angehaengt.
  Future<List<AdministrationSlot>> openSlotsForDate(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final medications = await _medications.loadAllActive();
    final existing = await _loadAll();
    final slots = <AdministrationSlot>[];

    for (final m in medications) {
      if (!m.isValidOn(day)) continue;
      _addSlotIfScheduled(slots, m, day, m.schedule.morning, 'morning');
      _addSlotIfScheduled(slots, m, day, m.schedule.noon, 'noon');
      _addSlotIfScheduled(slots, m, day, m.schedule.evening, 'evening');
      _addSlotIfScheduled(slots, m, day, m.schedule.night, 'night');
    }

    // Existierende Quittungen zuordnen (gleiche medication + scheduledAt).
    final attached = <AdministrationSlot>[];
    for (final s in slots) {
      final match = existing.firstWhere(
        (a) => a.medicationId == s.medicationId && a.scheduledAt == s.scheduledAt,
        orElse: () => MedicationAdministration(
          id: '',
          medicationId: '',
          clientId: '',
          scheduledAt: DateTime(0),
          status: AdministrationStatus.pending,
          createdAt: DateTime(0),
        ),
      );
      attached.add(AdministrationSlot(
        medication: s.medication,
        scheduledAt: s.scheduledAt,
        existing: match.id.isEmpty ? null : match,
      ));
    }

    attached.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return attached;
  }

  /// Nur die Slots mit Status `pending` (noch nicht erfasst).
  Future<List<AdministrationSlot>> openUnfinishedSlotsForDate(
      DateTime date) async {
    final all = await openSlotsForDate(date);
    return all
        .where((s) => s.status == AdministrationStatus.pending)
        .toList();
  }

  void _addSlotIfScheduled(List<AdministrationSlot> into, Medication m,
      DateTime day, bool scheduled, String slotKey) {
    if (!scheduled) return;
    final hour = slotHours[slotKey]!;
    final scheduledAt =
        DateTime(day.year, day.month, day.day, hour);
    into.add(AdministrationSlot(medication: m, scheduledAt: scheduledAt));
  }

  // ── Aktionen ────────────────────────────────────────────────────

  Future<bool> administer(
    AdministrationSlot slot, {
    required String employeeId,
    String? notes,
    DateTime? at,
  }) async {
    return _record(
      slot,
      status: AdministrationStatus.given,
      employeeId: employeeId,
      notes: notes,
      administeredAt: at ?? DateTime.now(),
      auditAction: 'medication.given',
    );
  }

  Future<bool> markRefused(
    AdministrationSlot slot, {
    required String employeeId,
    required String reason,
    String? notes,
  }) async {
    return _record(
      slot,
      status: AdministrationStatus.refused,
      employeeId: employeeId,
      reason: reason,
      notes: notes,
      auditAction: 'medication.refused',
    );
  }

  Future<bool> markMissed(
    AdministrationSlot slot, {
    required String employeeId,
    required String reason,
    String? notes,
  }) async {
    return _record(
      slot,
      status: AdministrationStatus.missed,
      employeeId: employeeId,
      reason: reason,
      notes: notes,
      auditAction: 'medication.missed',
    );
  }

  Future<bool> _record(
    AdministrationSlot slot, {
    required AdministrationStatus status,
    required String employeeId,
    required String auditAction,
    String? reason,
    String? notes,
    DateTime? administeredAt,
  }) async {
    final all = await _loadAll();
    final existing = slot.existing;
    final MedicationAdministration record;

    if (existing == null) {
      record = MedicationAdministration(
        id: _uuid.v4(),
        medicationId: slot.medicationId,
        clientId: slot.clientId,
        scheduledAt: slot.scheduledAt,
        administeredAt: administeredAt,
        administeredByEmployeeId: employeeId,
        status: status,
        reason: reason,
        notes: notes,
        createdAt: DateTime.now(),
      );
      all.add(record);
    } else {
      record = existing.copyWith(
        administeredAt: administeredAt ?? existing.administeredAt,
        administeredByEmployeeId: employeeId,
        status: status,
        reason: reason,
        notes: notes,
      );
      final idx = all.indexWhere((a) => a.id == existing.id);
      if (idx >= 0) all[idx] = record;
    }

    final ok = await _saveAll(all);
    if (ok) {
      await AuditLogger.log(auditAction, context: {
        'clientId': record.clientId,
        'medicationId': record.medicationId,
        'employeeId': employeeId,
        'scheduledAt': record.scheduledAt.toIso8601String(),
        if (administeredAt != null)
          'administeredAt': administeredAt.toIso8601String(),
        if (reason != null) 'reason': reason,
      });
    }
    return ok;
  }

  /// Historische Quittungen eines Klienten, neueste zuerst.
  Future<List<MedicationAdministration>> historyForClient(
    String clientId, {
    int days = 30,
  }) async {
    final all = await _loadAll();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return all
        .where((a) => a.clientId == clientId && a.scheduledAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  }
}
