import 'dart:convert';
import 'dart:typed_data';

import 'package:fegh_cloud/fegh_cloud.dart';
import 'package:flutter/foundation.dart';

import '../models/arbeitszeit.dart';
import 'cloud_webdav_client.dart';
import 'crypto_storage.dart';

/// Synchronisiert Arbeitszeit ueber das **kanonische** FeghPaths-Layout
/// (`teams/<teamId>/worktime/<employeeId>/<yyyy-mm>.bin`). Pro Mitarbeiter und
/// Monat wird die gesamte Eintragsliste als **ein** verschluesselter Record
/// abgelegt. Die Doku-App erfasst die Zeiten im Feld, die Verwaltung liest sie
/// (via [Arbeitszeit]-Konvertierung) fuer Abrechnung und Kapazitaet.
class TeamWorktimeSyncService {
  final CloudWebDavClient client;
  final CryptoStorage crypto;
  final FeghPaths paths;

  TeamWorktimeSyncService({
    required this.client,
    required this.crypto,
    required this.paths,
  });

  String _ym(DateTime month) =>
      '${month.year.toString().padLeft(4, "0")}-${month.month.toString().padLeft(2, "0")}';

  Future<void> _ensureWorktimeDir(String teamId, String employeeId) async {
    await client.mkcol(paths.organization);
    await client.mkcol(paths.teams);
    await client.mkcol(paths.teamRoot(teamId));
    await client.mkcol(paths.teamWorktimeDir(teamId));
    await client.mkcol('${paths.teamWorktimeDir(teamId)}/$employeeId');
  }

  /// Legt die Arbeitszeit-Eintraege eines Mitarbeiters fuer einen Monat als
  /// einen verschluesselten Record ab (ueberschreibt den Monats-Record).
  Future<bool> uploadMonth({
    required String teamId,
    required String employeeId,
    required DateTime month,
    required List<Arbeitszeit> eintraege,
  }) async {
    await _ensureWorktimeDir(teamId, employeeId);
    final payload = <String, dynamic>{
      'version': 1,
      'employeeId': employeeId,
      'month': _ym(month),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'entries': eintraege.map((e) => e.toJson()).toList(),
    };
    final enc = await crypto.encryptJson('worktime', payload);
    final bytes = Uint8List.fromList(utf8.encode(enc));
    final res =
        await client.put(paths.teamWorktimeRecord(teamId, employeeId, month), bytes);
    return res.success;
  }

  /// Liest die Arbeitszeit-Eintraege eines Mitarbeiters fuer einen Monat.
  Future<List<Arbeitszeit>> downloadMonth({
    required String teamId,
    required String employeeId,
    required DateTime month,
  }) async {
    final res =
        await client.get(paths.teamWorktimeRecord(teamId, employeeId, month));
    if (!res.success || res.data == null) return const [];
    try {
      final clear = await crypto.decryptJson(utf8.decode(res.data!));
      final entries =
          (clear?['entries'] as List?)?.cast<Map<String, dynamic>>() ??
              const <Map<String, dynamic>>[];
      return entries.map(Arbeitszeit.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }
}
