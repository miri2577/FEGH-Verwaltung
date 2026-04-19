import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medication.dart';
import 'audit_logger.dart';

/// CRUD fuer Medikations-Plaene. Persistenz in SharedPreferences,
/// Schluessel `medications_v1`. Ein „Loeschen" existiert nicht — Eintraege
/// werden als inaktiv markiert, damit die Historie lesbar bleibt.
class MedicationService {
  static const _key = 'medications_v1';

  Future<List<Medication>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Medication.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[MED] loadAll: $e');
      return [];
    }
  }

  Future<List<Medication>> loadAllActive() async {
    final all = await loadAll();
    return all.where((m) => m.active).toList();
  }

  Future<List<Medication>> loadForClient(String clientId,
      {bool activeOnly = true}) async {
    final all = await loadAll();
    return all
        .where((m) => m.clientId == clientId && (!activeOnly || m.active))
        .toList();
  }

  Future<bool> saveAll(List<Medication> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(list.map((m) => m.toJson()).toList()));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[MED] saveAll: $e');
      return false;
    }
  }

  Future<bool> addMedication(Medication m) async {
    final all = await loadAll();
    all.add(m);
    final ok = await saveAll(all);
    if (ok) {
      await AuditLogger.log('medication.plan.created', context: {
        'clientId': m.clientId,
        'medicationId': m.id,
        'name': m.name,
      });
    }
    return ok;
  }

  Future<bool> updateMedication(Medication m) async {
    final all = await loadAll();
    final idx = all.indexWhere((x) => x.id == m.id);
    if (idx < 0) return false;
    all[idx] = m;
    final ok = await saveAll(all);
    if (ok) {
      await AuditLogger.log('medication.plan.updated', context: {
        'clientId': m.clientId,
        'medicationId': m.id,
      });
    }
    return ok;
  }

  /// Markiert ein Medikament als inaktiv. Es bleibt in der Liste
  /// (Historie), wird aber nicht mehr in offene Slots einbezogen.
  Future<bool> deactivateMedication(String id) async {
    final all = await loadAll();
    final idx = all.indexWhere((x) => x.id == id);
    if (idx < 0) return false;
    final m = all[idx];
    all[idx] = m.copyWith(active: false, updatedAt: DateTime.now());
    final ok = await saveAll(all);
    if (ok) {
      await AuditLogger.log('medication.plan.deactivated', context: {
        'clientId': m.clientId,
        'medicationId': m.id,
      });
    }
    return ok;
  }
}
