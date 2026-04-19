import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/btm_destruction.dart';
import '../models/btm_entry.dart';
import 'audit_logger.dart';

/// BtM-Zusatzdokumentation (§13 BtMG / §§ 12, 13 BtMVV).
///
/// BtM-Eintraege sind **append-only**: Weder Update noch Delete.
/// Korrekturen erfolgen ueber einen neuen Eintrag mit Notiz-Bezug
/// auf den vorigen. Audit-Events werden fuer jede Aktion geschrieben.
class BtmService {
  static const _key = 'btm_entries_v1';
  static const _destructionKey = 'btm_destructions_v1';
  static const _uuid = Uuid();

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

  // ── Bestandsliste ──────────────────────────────────────────────

  /// Bestandsuebersicht pro Medikation — letzter erfasster Restbestand.
  ///
  /// Falls fuer eine Medikation sowohl Gaben (Entries) als auch
  /// Vernichtungen existieren, wird der juengste Eintrag (nach [createdAt])
  /// als aktuell angenommen.
  Future<List<BtmStockRow>> stockOverview() async {
    final entries = await _loadAll();
    final destructions = await _loadDestructions();
    final byMed = <String, BtmStockRow>{};
    for (final e in entries) {
      final existing = byMed[e.medicationId];
      if (existing == null || e.createdAt.isAfter(existing.at)) {
        byMed[e.medicationId] = BtmStockRow(
          medicationId: e.medicationId,
          clientId: e.clientId,
          stock: e.restbestand,
          at: e.createdAt,
          unit: '', // Einheit steckt im Freitext `menge` der Gabe
        );
      }
    }
    for (final d in destructions) {
      final existing = byMed[d.medicationId];
      if (existing == null || d.createdAt.isAfter(existing.at)) {
        final subtract = existing == null ? 0 : d.menge;
        byMed[d.medicationId] = BtmStockRow(
          medicationId: d.medicationId,
          clientId: d.clientId,
          stock: (existing?.stock ?? 0) - subtract,
          at: d.createdAt,
          unit: d.mengeEinheit,
        );
      }
    }
    final rows = byMed.values.toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    return rows;
  }

  // ── Vernichtung ────────────────────────────────────────────────

  Future<List<BtmDestruction>> _loadDestructions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_destructionKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => BtmDestruction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[BTM] loadDestructions: $e');
      return [];
    }
  }

  Future<bool> _saveDestructions(List<BtmDestruction> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _destructionKey, jsonEncode(list.map((e) => e.toJson()).toList()));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[BTM] saveDestructions: $e');
      return false;
    }
  }

  Future<List<BtmDestruction>> destructionsForClient(String clientId) async {
    final all = await _loadDestructions();
    return all.where((d) => d.clientId == clientId).toList()
      ..sort((a, b) => b.destroyedAt.compareTo(a.destroyedAt));
  }

  Future<List<BtmDestruction>> destructionsForMedication(
      String medicationId) async {
    final all = await _loadDestructions();
    return all.where((d) => d.medicationId == medicationId).toList()
      ..sort((a, b) => b.destroyedAt.compareTo(a.destroyedAt));
  }

  /// Speichert eine BtM-Vernichtung. Gibt die erzeugte ID zurueck oder
  /// `null` bei Fehler.
  ///
  /// Pflichtfelder werden hier validiert: Zeuge != Verantwortlicher,
  /// Grund nicht leer, Menge > 0.
  Future<String?> addDestruction({
    required String medicationId,
    required String clientId,
    required double menge,
    required String mengeEinheit,
    required String reason,
    String? reasonDetails,
    required String destroyerEmployeeId,
    required String witnessEmployeeId,
    required DateTime destroyedAt,
    String? signaturePngB64,
  }) async {
    if (menge <= 0) return null;
    if (witnessEmployeeId.isEmpty ||
        witnessEmployeeId == destroyerEmployeeId) {
      return null;
    }
    if (reason.isEmpty || !BtmDestructionReasons.all.contains(reason)) {
      return null;
    }
    final all = await _loadDestructions();
    final rec = BtmDestruction(
      id: _uuid.v4(),
      medicationId: medicationId,
      clientId: clientId,
      menge: menge,
      mengeEinheit: mengeEinheit,
      reason: reason,
      reasonDetails: reasonDetails,
      destroyerEmployeeId: destroyerEmployeeId,
      witnessEmployeeId: witnessEmployeeId,
      destroyedAt: destroyedAt,
      signaturePngB64: signaturePngB64,
      createdAt: DateTime.now(),
    );
    all.add(rec);
    final ok = await _saveDestructions(all);
    if (!ok) return null;
    await AuditLogger.log('medication.btm.destroyed', context: {
      'id': rec.id,
      'medicationId': medicationId,
      'clientId': clientId,
      'menge': menge,
      'einheit': mengeEinheit,
      'reason': reason,
      'destroyer': destroyerEmployeeId,
      'witness': witnessEmployeeId,
    });
    return rec.id;
  }
}

/// Row fuer die BtM-Bestandsliste.
class BtmStockRow {
  final String medicationId;
  final String clientId;
  final double stock;
  final DateTime at;
  final String unit;

  const BtmStockRow({
    required this.medicationId,
    required this.clientId,
    required this.stock,
    required this.at,
    required this.unit,
  });
}
