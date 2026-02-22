import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'crypto_storage.dart';
import 'hidrive_webdav_client.dart';

class ClientsIndexRebuilder {
  final HiDriveWebDAVClient client;
  final CryptoStorage crypto;
  final String orgBase; // eingliederungshilfe/organizations/<org>

  ClientsIndexRebuilder({required this.client, required this.crypto, required this.orgBase});

  Future<int> rebuild() async {
    int processed = 0;
    final teamsDir = '$orgBase/teams';
    // try to list teams folder
    // ignore: unused_local_variable
    final teamsListAttempt = await client.listDetailed('$orgBase/teams');
    // Fallback: naive approach – we attempt to list via propfind on teams/
    final teamNames = <String>[];
    try {
      final res = await client.listDetailed('$orgBase/teams');
      if (res.success && res.data != null) {
        for (final item in res.data!) {
          if (item.isCollection) {
            final name = item.displayName;
            if (name.isNotEmpty) teamNames.add(name);
          }
        }
      }
    } catch (_) {}

    final entries = <Map<String, dynamic>>[];
    for (final teamId in teamNames) {
      try {
        final clientsPath = '$orgBase/teams/$teamId/clients';
        final files = await client.list(clientsPath);
        if (!files.success || files.data == null) continue;
        for (final fname in files.data!) {
          if (!fname.endsWith('.bin')) continue;
          final uuid = fname.replaceAll('.bin', '');
          // optional: decrypt to get name
          String? name;
          try {
            final dl = await client.get('$clientsPath/$fname');
            if (dl.success && dl.data != null) {
              final encJson = utf8.decode(dl.data!);
              final clear = await crypto.decryptJson(encJson);
              name = (clear?['firstName'] ?? '') + ' ' + (clear?['lastName'] ?? '');
            }
          } catch (_) {}
          entries.add({
            'uuid': uuid,
            'teamId': teamId,
            'name': name ?? uuid,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          });
          processed++;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[INDEX] failed for team $teamId: $e');
      }
    }

    final newIndex = {
      'version': 1,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'entries': entries,
    };
    final enc = await crypto.encryptJson('clients-index', newIndex);
    final data = Uint8List.fromList(utf8.encode(enc));
    await client.mkcol('$orgBase/administration');
    await client.put('$orgBase/administration/clients-index.bin', data);
    return processed;
  }
}
