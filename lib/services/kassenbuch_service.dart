import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/kassenbuch_eintrag.dart';
import '../models/kassenbuch_monatsabschluss.dart';
import 'audit_logger.dart';

/// Kassenbuch-Service pro Klient. Persistenz in SharedPreferences
/// unter `kassenbuch_eintraege_v1`. Freigegebene (`confirmed=true`)
/// Eintraege sind immutable — kein Update/Delete mehr moeglich, nur
/// Storno ueber einen Gegenbuchungs-Eintrag.
class KassenbuchService {
  static const _key = 'kassenbuch_eintraege_v1';
  static const _abschlussKey = 'kassenbuch_monatsabschluesse_v1';
  static const _uuid = Uuid();

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
  ///
  /// Wenn der Vormonat einen Monatsabschluss hat, wird dessen `saldoEnde`
  /// als Rollover verwendet — spaetere Stornos oder Nachbuchungen in
  /// abgeschlossenen Monaten duerfen nicht mehr einfliessen.
  Future<double> saldoBeforeMonth(
      String clientId, DateTime month) async {
    final all = await loadForClient(clientId);
    final start = DateTime(month.year, month.month, 1);

    // Letzter Abschluss vor [month] suchen
    final closed = await _loadMonatsabschluesse();
    final forClient = closed.where((a) => a.clientId == clientId).toList()
      ..sort((a, b) {
        final av = a.jahr * 12 + a.monat;
        final bv = b.jahr * 12 + b.monat;
        return av.compareTo(bv);
      });
    KassenbuchMonatsabschluss? lastBefore;
    for (final a in forClient) {
      final firstOfNext = DateTime(
        a.monat == 12 ? a.jahr + 1 : a.jahr,
        a.monat == 12 ? 1 : a.monat + 1,
        1,
      );
      if (!firstOfNext.isAfter(start)) {
        lastBefore = a;
      }
    }

    if (lastBefore == null) {
      return all
          .where((e) => e.datum.isBefore(start))
          .fold<double>(0, (sum, e) => sum + e.betrag);
    }
    // Rollover: saldoEnde des letzten Abschlusses + alles nach dem Abschluss
    // bis zum Monatsanfang.
    final afterClose = DateTime(
      lastBefore.monat == 12 ? lastBefore.jahr + 1 : lastBefore.jahr,
      lastBefore.monat == 12 ? 1 : lastBefore.monat + 1,
      1,
    );
    final delta = all
        .where((e) => !e.datum.isBefore(afterClose) && e.datum.isBefore(start))
        .fold<double>(0, (sum, e) => sum + e.betrag);
    return lastBefore.saldoEnde + delta;
  }

  Future<bool> addEintrag(KassenbuchEintrag entry) async {
    // Monatsabschluss-Schutz: Kein Einbuchen in bereits abgeschlossene Monate.
    final closed = await _loadMonatsabschluesse();
    final keyMonth =
        '${entry.clientId}|${entry.datum.year.toString().padLeft(4, '0')}-'
        '${entry.datum.month.toString().padLeft(2, '0')}';
    if (closed.any((a) => a.key == keyMonth)) {
      if (kDebugMode) {
        debugPrint('[KB] add blocked: month $keyMonth already closed');
      }
      return false;
    }
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

  /// Storniert einen freigegebenen Eintrag durch Gegenbuchung.
  ///
  /// Erzeugt einen neuen [KassenbuchEintrag] mit umgekehrtem Vorzeichen,
  /// der direkt freigegeben ist und ueber [KassenbuchEintrag.stornoOfEntryId]
  /// auf das Original verweist. Das Original bleibt unveraendert —
  /// Audit-Nachvollziehbarkeit bleibt so gewahrt.
  ///
  /// Gibt die ID des neuen Storno-Eintrags zurueck, oder null bei Fehler.
  Future<String?> stornoEintrag(
    String originalId, {
    required String byEmployeeId,
    required String reason,
    String? signaturePngB64,
  }) async {
    if (reason.trim().isEmpty) return null;
    final all = await _loadAll();
    final idx = all.indexWhere((x) => x.id == originalId);
    if (idx < 0) return null;
    final original = all[idx];
    if (!original.confirmed) {
      if (kDebugMode) {
        debugPrint('[KB] storno blocked: entry $originalId not confirmed '
            '(unconfirmed entries can be deleted directly)');
      }
      return null;
    }
    // Schon storniert? (einmaliger Storno pro Original)
    final alreadyStorniert =
        all.any((e) => e.stornoOfEntryId == originalId);
    if (alreadyStorniert) {
      if (kDebugMode) {
        debugPrint('[KB] storno blocked: entry $originalId already reversed');
      }
      return null;
    }

    final now = DateTime.now();
    final storno = KassenbuchEintrag(
      id: _uuid.v4(),
      clientId: original.clientId,
      datum: now,
      betrag: -original.betrag,
      kategorie: original.kategorie,
      beschreibung: 'Storno zu #${original.id.substring(0, 8)}: '
          '${original.beschreibung}',
      belegnummer: original.belegnummer,
      erfasstVonEmployeeId: byEmployeeId,
      confirmed: true,
      signaturePngB64: signaturePngB64,
      stornoOfEntryId: original.id,
      stornoReason: reason.trim(),
      createdAt: now,
    );
    all.add(storno);
    final ok = await _saveAll(all);
    if (ok) {
      await AuditLogger.log('kassenbuch.entry.storno', context: {
        'originalId': original.id,
        'stornoId': storno.id,
        'clientId': original.clientId,
        'by': byEmployeeId,
        'reason': reason,
        'betrag': storno.betrag,
      });
      return storno.id;
    }
    return null;
  }

  /// Liefert IDs aller Eintraege, die eines der [originalIds] stornieren.
  Future<Map<String, String>> stornoMapForClient(String clientId) async {
    final all = await loadForClient(clientId);
    final map = <String, String>{};
    for (final e in all) {
      if (e.stornoOfEntryId != null) {
        map[e.stornoOfEntryId!] = e.id;
      }
    }
    return map;
  }

  // ── Monatsabschluss ─────────────────────────────────────────────

  Future<List<KassenbuchMonatsabschluss>> _loadMonatsabschluesse() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_abschlussKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => KassenbuchMonatsabschluss.fromJson(
              e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[KB] loadAbschluesse: $e');
      return [];
    }
  }

  Future<bool> _saveMonatsabschluesse(
      List<KassenbuchMonatsabschluss> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _abschlussKey, jsonEncode(list.map((a) => a.toJson()).toList()));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[KB] saveAbschluesse: $e');
      return false;
    }
  }

  /// Lade Abschluss-Lookup-Map fuer einen Klient.
  /// Schluessel: "YYYY-MM", Wert: der Abschluss.
  Future<Map<String, KassenbuchMonatsabschluss>>
      abschluesseForClient(String clientId) async {
    final all = await _loadMonatsabschluesse();
    return {
      for (final a in all)
        if (a.clientId == clientId)
          '${a.jahr.toString().padLeft(4, '0')}-'
              '${a.monat.toString().padLeft(2, '0')}': a,
    };
  }

  /// Schliesst einen Monat ab — friert den Endsaldo ein.
  ///
  /// Gibt bei Erfolg den erzeugten Abschluss zurueck. Gibt `null` zurueck,
  /// wenn:
  /// - der Monat bereits abgeschlossen ist,
  /// - im Monat unkonfirmierte Eintraege existieren (muessen erst
  ///   freigegeben oder geloescht werden).
  Future<KassenbuchMonatsabschluss?> closeMonth(
    String clientId,
    DateTime month, {
    required String byEmployeeId,
    String? signaturePngB64,
  }) async {
    final jahr = month.year;
    final monat = month.month;
    final key = '$clientId|${jahr.toString().padLeft(4, '0')}-'
        '${monat.toString().padLeft(2, '0')}';

    final closed = await _loadMonatsabschluesse();
    if (closed.any((a) => a.key == key)) {
      if (kDebugMode) debugPrint('[KB] close blocked: $key already closed');
      return null;
    }

    // Alle Eintraege im Monat muessen confirmed sein.
    final monatsEintraege = await loadForClientInMonth(
        clientId, DateTime(jahr, monat, 1));
    final offene = monatsEintraege.where((e) => !e.confirmed).toList();
    if (offene.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('[KB] close blocked: ${offene.length} open entries');
      }
      return null;
    }

    final saldoStart =
        await saldoBeforeMonth(clientId, DateTime(jahr, monat, 1));
    final delta = monatsEintraege.fold<double>(0, (s, e) => s + e.betrag);
    final saldoEnde = saldoStart + delta;

    final abschluss = KassenbuchMonatsabschluss(
      clientId: clientId,
      jahr: jahr,
      monat: monat,
      saldoStart: saldoStart,
      saldoEnde: saldoEnde,
      abgeschlossenVonEmployeeId: byEmployeeId,
      abgeschlossenAm: DateTime.now(),
      signaturePngB64: signaturePngB64,
    );
    closed.add(abschluss);
    final ok = await _saveMonatsabschluesse(closed);
    if (!ok) return null;
    await AuditLogger.log('kassenbuch.month.closed', context: {
      'clientId': clientId,
      'jahr': jahr,
      'monat': monat,
      'saldoEnde': saldoEnde,
      'by': byEmployeeId,
    });
    return abschluss;
  }

  /// Prueft ob Monat fuer [clientId] geschlossen ist.
  Future<bool> isMonthClosed(String clientId, DateTime month) async {
    final closed = await _loadMonatsabschluesse();
    final key = '$clientId|${month.year.toString().padLeft(4, '0')}-'
        '${month.month.toString().padLeft(2, '0')}';
    return closed.any((a) => a.key == key);
  }
}
