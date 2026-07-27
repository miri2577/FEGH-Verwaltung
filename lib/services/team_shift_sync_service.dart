import 'dart:convert';
import 'dart:typed_data';

import 'package:fegh_cloud/fegh_cloud.dart';
import 'package:flutter/foundation.dart';

import '../models/shift.dart';
import 'cloud_webdav_client.dart';
import 'crypto_storage.dart';

/// Synchronisiert Dienstplan-Schichten ueber das **kanonische** FeghPaths-Layout
/// (`teams/<teamId>/schedules/<shiftId>.bin`). Dadurch liest die Doku-App genau
/// die Schichten, die die Verwaltung schreibt – statt der bisherigen, nur lokal
/// gehaltenen `shifts.json`. Muster analog zu [OrgClientSyncService].
class TeamShiftSyncService {
  final CloudWebDavClient client;
  final CryptoStorage crypto;
  final FeghPaths paths;

  TeamShiftSyncService({
    required this.client,
    required this.crypto,
    required this.paths,
  });

  Future<void> _ensureSchedulesDir(String teamId) async {
    await client.mkcol(paths.organization);
    await client.mkcol(paths.teams);
    await client.mkcol(paths.teamRoot(teamId));
    await client.mkcol(paths.teamSchedulesDir(teamId));
  }

  /// Legt eine Schicht verschluesselt im Team-Dienstplan ab. `false`, wenn die
  /// Schicht keinem Team zugeordnet ist (dann gibt es keinen kanonischen Pfad).
  Future<bool> uploadShift(Shift s) async {
    final teamId = s.teamId;
    if (teamId == null || teamId.isEmpty) {
      if (kDebugMode) {
        debugPrint('[SHIFT SYNC] skip: kein teamId fuer Schicht ${s.id}');
      }
      return false;
    }
    await _ensureSchedulesDir(teamId);
    final enc = await crypto.encryptJson('shift', s.toJson());
    final bytes = Uint8List.fromList(utf8.encode(enc));
    final res = await client.put(paths.teamShiftRecord(teamId, s.id), bytes);
    return res.success;
  }

  Future<bool> deleteShift(Shift s) async {
    final teamId = s.teamId;
    if (teamId == null || teamId.isEmpty) return false;
    final res = await client.delete(paths.teamShiftRecord(teamId, s.id));
    return res.success;
  }

  /// Liest alle Schichten eines Teams aus dem Dienstplan-Verzeichnis.
  /// Beschaedigte oder fremde Records werden uebersprungen.
  Future<List<Shift>> downloadShifts(String teamId) async {
    final dir = paths.teamSchedulesDir(teamId);
    final listRes = await client.list(dir);
    if (!listRes.success || listRes.data == null) return const [];
    final shifts = <Shift>[];
    for (final name in listRes.data!) {
      if (!name.endsWith('.bin')) continue;
      final res = await client.get('$dir/$name');
      if (!res.success || res.data == null) continue;
      try {
        final clear = await crypto.decryptJson(utf8.decode(res.data!));
        if (clear != null) shifts.add(Shift.fromJson(clear));
      } catch (_) {
        // beschaedigten Record ueberspringen
      }
    }
    return shifts;
  }
}
