import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/btm_entry.dart';
import 'audit_logger.dart';

/// BtM-Zusatzdokumentation (§13 BtMG / §§ 12, 13 BtMVV).
///
/// BtM-Eintraege sind **append-only**: Weder Update noch Delete.
/// Korrekturen erfolgen ueber einen neuen Eintrag mit Notiz-Bezug
/// auf den vorigen. Audit-Events werden fuer jede Aktion geschrieben.
class BtmService {
  static const _key = 'btm_entries_v1';

  Future<List<BtmEntry>> _loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => BtmEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[BTM] loadAll: $e');
      return [];
    }
  }

  Future<bool> _saveAll(List<BtmEntry> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(list.map((e) => e.toJson()).toList()));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[BTM] saveAll: $e');
      return false;
    }
  }

  Future<List<BtmEntry>> loadForClient(String clientId) async {
    final all = await _loadAll();
    final mine = all.where((e) => e.clientId == clientId).toList();
    mine.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  Future<List<BtmEntry>> loadForMedication(String medicationId) async {
    final all = await _loadAll();
    return all.where((e) => e.medicationId == medicationId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Liest den zuletzt protokollierten Restbestand fuer ein Medikament.
  /// Rueckgabe `null` falls noch kein Eintrag existiert.
  Future<double?> letzterRestbestand(String medicationId) async {
    final list = await loadForMedication(medicationId);
    if (list.isEmpty) return null;
    return list.first.restbestand;
  }

  Future<bool> addEntry(BtmEntry entry) async {
    final all = await _loadAll();
    all.add(entry);
    final ok = await _saveAll(all);
    if (ok) {
      await AuditLogger.log('medication.btm.entry', context: {
        'entryId': entry.id,
        'administrationId': entry.administrationId,
        'medicationId': entry.medicationId,
        'clientId': entry.clientId,
        'restbestand': entry.restbestand,
        'witness': entry.witnessEmployeeId,
      });
    }
    return ok;
  }
}
