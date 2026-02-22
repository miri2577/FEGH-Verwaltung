import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'crypto_storage.dart';
import 'hidrive_webdav_client.dart';

/// Admin-Service zum Erzeugen und Verteilen von Team-Keys.
/// Speichert Team-Key verschlüsselt unter administration/teams/<teamId>/team-key.bin
class TeamKeyAdminService {
  final CryptoStorage crypto;
  final HiDriveWebDAVClient client;
  final String orgBase; // e.g. eingliederungshilfe/organizations/<org>

  TeamKeyAdminService({required this.crypto, required this.client, required this.orgBase});

  Future<bool> ensureTeamKey(String teamId) async {
    final sw = Stopwatch()..start();
    final relDir = '$orgBase/administration/teams/$teamId';
    await client.mkcol('$orgBase/administration');
    await client.mkcol('$orgBase/administration/teams');
    await client.mkcol(relDir);

    // Prüfen ob vorhanden
    final existing = await client.get('$relDir/team-key.bin');
    if (existing.success) {
      if (kDebugMode) debugPrint('[TEAMKEY] ensureTeamKey: bereits vorhanden (team=$teamId) in ${sw.elapsedMilliseconds}ms');
      return true;
    }

    // Erzeuge 32-Byte Team-Key und verschlüssele mit Org-MEK
    final key = _randomBytes(32);
    final payload = jsonEncode({'teamKey': base64Encode(key), 'ts': DateTime.now().toIso8601String()});
    final enc = await crypto.encryptJson('team-key', {'teamKey': base64Encode(key), 'ts': DateTime.now().toIso8601String()});
    final bytes = Uint8List.fromList(utf8.encode(enc));
    final res = await client.put('$relDir/team-key.bin', bytes);
    if (kDebugMode) debugPrint('[TEAMKEY] ensureTeamKey: put success=${res.success} size=${bytes.length}B in ${sw.elapsedMilliseconds}ms');
    return res.success;
  }

  /// Erzwingt die (Neu‑)Erzeugung eines Team‑Keys, überschreibt bestehende Datei.
  Future<String?> recreateTeamKey(String teamId) async {
    final sw = Stopwatch()..start();
    final relDir = '$orgBase/administration/teams/$teamId';
    await client.mkcol('$orgBase/administration');
    await client.mkcol('$orgBase/administration/teams');
    await client.mkcol(relDir);

    final key = _randomBytes(32);
    final enc = await crypto.encryptJson('team-key', {
      'teamKey': base64Encode(key),
      'ts': DateTime.now().toIso8601String(),
      'rotated': true,
    });
    final bytes = Uint8List.fromList(utf8.encode(enc));
    final res = await client.put('$relDir/team-key.bin', bytes);
    if (kDebugMode) debugPrint('[TEAMKEY] recreate: put success=${res.success} size=${bytes.length}B in ${sw.elapsedMilliseconds}ms');
    return res.success ? base64Encode(key) : null;
  }

  /// Lädt den Team‑Key (falls vorhanden) und gibt ihn als Base64 zurück
  Future<String?> fetchTeamKeyBase64(String teamId) async {
    try {
      final sw = Stopwatch()..start();
      final relDir = '$orgBase/administration/teams/$teamId';
      final res = await client.get('$relDir/team-key.bin');
      if (!res.success || res.data == null) return null;
      // Entschlüsseln via CryptoStorage
      final encJson = utf8.decode(res.data!, allowMalformed: true);
      final clear = await crypto.decryptJson(encJson);
      if (clear == null) return null;
      final key = clear['teamKey'] as String?;
      if (kDebugMode) debugPrint('[TEAMKEY] fetch: ok bytes=${res.data!.length} elapsed=${sw.elapsedMilliseconds}ms');
      return key;
    } catch (_) {
      if (kDebugMode) debugPrint('[TEAMKEY] fetch: Fehler beim Laden/Decrypt (team=$teamId)');
      return null;
    }
  }

  Uint8List _randomBytes(int len) {
    final rnd = Uint8List(len);
    for (int i = 0; i < len; i++) {
      rnd[i] = (DateTime.now().microsecondsSinceEpoch >> (i % 24)) & 0xFF;
    }
    return rnd;
  }
}
