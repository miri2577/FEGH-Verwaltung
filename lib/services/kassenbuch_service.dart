import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/kassenbuch_eintrag.dart';
import 'audit_logger.dart';

/// Kassenbuch-Service pro Klient. Persistenz in SharedPreferences
/// unter `kassenbuch_eintraege_v1`. Freigegebene (`confirmed=true`)
/// Eintraege sind immutable — kein Update/Delete mehr moeglich, nur
/// Storno ueber einen Gegenbuchungs-Eintrag.
class KassenbuchService {
  static const _key = 'kassenbuch_eintraege_v1';

  Future<List<KassenbuchEintrag>> _loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => KassenbuchEintrag.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[KB] loadAll: $e');
      return [];
    }
  }

  Future<bool> _saveAll(List<KassenbuchEintrag> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(list.map((e) => e.toJson()).toList()));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[KB] saveAll: $e');
      return false;
    }
  }

  Future<List<KassenbuchEintrag>> loadForClient(String clientId) async {
    final all = await _loadAll();
    final mine = all.where((e) => e.clientId == clientId).toList();
    mine.sort((a, b) => b.datum.compareTo(a.datum));
    return mine;
  }

  /// Laedt Eintraege fuer einen Klient in einem Monat (YYYY-MM).
  Future<List<KassenbuchEintrag>> loadForClientInMonth(
      String clientId, DateTime month) async {
    final all = await loadForClient(clientId);
    return all
        .where((e) =>
            e.datum.year == month.year && e.datum.month == month.month)
        .toList();
  }

  /// Berechnet den aktuellen Saldo eines Klienten ueber alle Eintraege.
  Future<double> saldoForClient(String clientId) async {
    final all = await loadForClient(clientId);
    return all.fold<double>(0, (sum, e) => sum + e.betrag);
  }

  /// Berechnet Saldo zum Monatsanfang (alles vor [month]).
  Future<double> saldoBeforeMonth(
      String clientId, DateTime month) async {
    final all = await loadForClient(clientId);
    final start = DateTime(month.year, month.month, 1);
    return all
        .where((e) => e.datum.isBefore(start))
        .fold<double>(0, (sum, e) => sum + e.betrag);
  }

  Future<bool> addEintrag(KassenbuchEintrag entry) async {
    final all = await _loadAll();
    all.add(entry);
    final ok = await _saveAll(all);
    if (ok) {
      await AuditLogger.log('kassenbuch.entry.created', context: {
        'clientId': entry.clientId,
        'entryId': entry.id,
        'kategorie': entry.kategorie.name,
        'betrag': entry.betrag,
        'by': entry.erfasstVonEmployeeId,
      });
    }
    return ok;
  }

  /// Update nur erlaubt, wenn Original **noch nicht** freigegeben ist.
  Future<bool> updateEintrag(KassenbuchEintrag entry) async {
    final all = await _loadAll();
    final idx = all.indexWhere((x) => x.id == entry.id);
    if (idx < 0) return false;
    if (all[idx].confirmed) {
      if (kDebugMode) {
        debugPrint('[KB] update blocked: entry ${entry.id} is confirmed');
      }
      return false;
    }
    all[idx] = entry;
    final ok = await _saveAll(all);
    if (ok) {
      await AuditLogger.log('kassenbuch.entry.updated', context: {
        'clientId': entry.clientId,
        'entryId': entry.id,
      });
    }
    return ok;
  }

  /// Markiert Eintrag als freigegeben (immutable).
  Future<bool> confirmEintrag(String id, {required String byEmployeeId}) async {
    final all = await _loadAll();
    final idx = all.indexWhere((x) => x.id == id);
    if (idx < 0) return false;
    if (all[idx].confirmed) return true;
    all[idx] = all[idx].copyWith(confirmed: true);
    final ok = await _saveAll(all);
    if (ok) {
      await AuditLogger.log('kassenbuch.entry.confirmed', context: {
        'entryId': id,
        'clientId': all[idx].clientId,
        'by': byEmployeeId,
      });
    }
    return ok;
  }

  /// Loescht einen Eintrag, nur wenn noch nicht freigegeben.
  Future<bool> deleteEintrag(String id,
      {required String byEmployeeId, String? reason}) async {
    final all = await _loadAll();
    final idx = all.indexWhere((x) => x.id == id);
    if (idx < 0) return false;
    if (all[idx].confirmed) {
      if (kDebugMode) {
        debugPrint('[KB] delete blocked: entry $id is confirmed');
      }
      return false;
    }
    final removed = all.removeAt(idx);
    final ok = await _saveAll(all);
    if (ok) {
      await AuditLogger.log('kassenbuch.entry.deleted', context: {
        'entryId': removed.id,
        'clientId': removed.clientId,
        'by': byEmployeeId,
        if (reason != null) 'reason': reason,
      });
    }
    return ok;
  }
}
