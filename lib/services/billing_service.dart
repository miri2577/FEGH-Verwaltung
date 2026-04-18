import 'dart:convert';

import 'package:fegh_billing/fegh_billing.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistenz-Service fuer Rechnungen und Rechnungs-Empfaenger.
///
/// MVP: lokale SharedPreferences. In spaeteren Iterationen Cloud-Sync
/// ueber fegh_cloud (gemeinsamer HiDrive-/Nextcloud-Ordner mit der
/// Dokumentations-App).
class BillingService {
  static const _rechnungenKey = 'pv_rechnungen_v1';
  static const _empfaengerKey = 'pv_rechnung_empfaenger_v1';

  Future<List<Rechnung>> loadRechnungen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_rechnungenKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((j) => Rechnung.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[Billing] loadRechnungen error: $e');
      return [];
    }
  }

  Future<bool> saveRechnungen(List<Rechnung> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(list.map((r) => r.toJson()).toList());
      return await prefs.setString(_rechnungenKey, json);
    } catch (e) {
      if (kDebugMode) debugPrint('[Billing] saveRechnungen error: $e');
      return false;
    }
  }

  Future<bool> addRechnung(Rechnung r) async {
    final all = await loadRechnungen();
    all.add(r);
    return saveRechnungen(all);
  }

  Future<bool> updateRechnung(Rechnung r) async {
    final all = await loadRechnungen();
    final idx = all.indexWhere((x) => x.id == r.id);
    if (idx < 0) return false;
    all[idx] = r;
    return saveRechnungen(all);
  }

  Future<bool> deleteRechnung(String id) async {
    final all = await loadRechnungen();
    all.removeWhere((x) => x.id == id);
    return saveRechnungen(all);
  }

  Future<String> nextRechnungsnummer() async {
    final all = await loadRechnungen();
    final now = DateTime.now();
    final year = now.year;
    final yearPrefix = '$year-';
    final thisYear =
        all.where((r) => r.rechnungsnummer.startsWith(yearPrefix)).length;
    final seq = (thisYear + 1).toString().padLeft(4, '0');
    return '$yearPrefix$seq';
  }

  // ── Empfaenger ───────────────────────────────────────────────

  Future<List<RechnungEmpfaenger>> loadEmpfaenger() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_empfaengerKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((j) =>
              RechnungEmpfaenger.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[Billing] loadEmpfaenger error: $e');
      return [];
    }
  }

  Future<bool> saveEmpfaenger(List<RechnungEmpfaenger> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(list.map((e) => e.toJson()).toList());
      return await prefs.setString(_empfaengerKey, json);
    } catch (e) {
      if (kDebugMode) debugPrint('[Billing] saveEmpfaenger error: $e');
      return false;
    }
  }

  Future<bool> addEmpfaenger(RechnungEmpfaenger e) async {
    final all = await loadEmpfaenger();
    all.add(e);
    return saveEmpfaenger(all);
  }

  Future<bool> updateEmpfaenger(RechnungEmpfaenger e) async {
    final all = await loadEmpfaenger();
    final idx = all.indexWhere((x) => x.id == e.id);
    if (idx < 0) return false;
    all[idx] = e;
    return saveEmpfaenger(all);
  }

  Future<bool> deleteEmpfaenger(String id) async {
    final all = await loadEmpfaenger();
    all.removeWhere((x) => x.id == id);
    return saveEmpfaenger(all);
  }
}
