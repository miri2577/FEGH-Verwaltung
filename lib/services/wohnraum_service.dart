import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/wohnraum.dart';
import 'audit_logger.dart';

/// CRUD fuer Wohnraeume / Plaetze. Persistenz in SharedPreferences
/// unter `wohnraeume_v1`. Keine harte Loeschung — `status=inactive`
/// als Soft-Delete.
class WohnraumService {
  static const _key = 'wohnraeume_v1';

  Future<List<Wohnraum>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Wohnraum.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[WR] loadAll: $e');
      return [];
    }
  }

  Future<List<Wohnraum>> loadActive() async {
    final all = await loadAll();
    return all.where((w) => w.status != WohnraumStatus.inactive).toList();
  }

  Future<List<Wohnraum>> loadForClient(String clientId) async {
    final all = await loadAll();
    return all.where((w) => w.clientId == clientId).toList();
  }

  Future<List<Wohnraum>> loadFree() async {
    final all = await loadAll();
    return all.where((w) => w.status == WohnraumStatus.free).toList();
  }

  Future<Wohnraum?> loadById(String id) async {
    final all = await loadAll();
    for (final w in all) {
      if (w.id == id) return w;
    }
    return null;
  }

  Future<bool> _saveAll(List<Wohnraum> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(list.map((w) => w.toJson()).toList()));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[WR] saveAll: $e');
      return false;
    }
  }

  Future<bool> addWohnraum(Wohnraum w) async {
    final all = await loadAll();
    all.add(w);
    final ok = await _saveAll(all);
    if (ok) {
      await AuditLogger.log('wohnraum.created', context: {
        'id': w.id,
        'bezeichnung': w.bezeichnung,
        'kaltmiete': w.kaltmiete,
      });
    }
    return ok;
  }

  Future<bool> updateWohnraum(Wohnraum w) async {
    final all = await loadAll();
    final idx = all.indexWhere((x) => x.id == w.id);
    if (idx < 0) return false;
    all[idx] = w.copyWith(updatedAt: DateTime.now());
    final ok = await _saveAll(all);
    if (ok) {
      await AuditLogger.log('wohnraum.updated', context: {'id': w.id});
    }
    return ok;
  }

  Future<bool> assignClient(String wohnraumId, String clientId,
      {DateTime? mietbeginn}) async {
    final all = await loadAll();
    final idx = all.indexWhere((x) => x.id == wohnraumId);
    if (idx < 0) return false;
    final current = all[idx];
    all[idx] = current.copyWith(
      clientId: clientId,
      status: WohnraumStatus.occupied,
      mietbeginn: mietbeginn ?? current.mietbeginn ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final ok = await _saveAll(all);
    if (ok) {
      await AuditLogger.log('wohnraum.assigned', context: {
        'id': wohnraumId,
        'clientId': clientId,
      });
    }
    return ok;
  }

  Future<bool> releaseClient(String wohnraumId, {DateTime? mietende}) async {
    final all = await loadAll();
    final idx = all.indexWhere((x) => x.id == wohnraumId);
    if (idx < 0) return false;
    final prev = all[idx];
    all[idx] = prev.copyWith(
      clearClient: true,
      status: WohnraumStatus.free,
      mietende: mietende ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final ok = await _saveAll(all);
    if (ok) {
      await AuditLogger.log('wohnraum.released', context: {
        'id': wohnraumId,
        'previousClient': prev.clientId,
      });
    }
    return ok;
  }

  Future<bool> deactivate(String id) async {
    final all = await loadAll();
    final idx = all.indexWhere((x) => x.id == id);
    if (idx < 0) return false;
    all[idx] = all[idx].copyWith(
      status: WohnraumStatus.inactive,
      updatedAt: DateTime.now(),
    );
    final ok = await _saveAll(all);
    if (ok) {
      await AuditLogger.log('wohnraum.deactivated', context: {'id': id});
    }
    return ok;
  }
}
