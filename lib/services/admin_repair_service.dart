import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'cloud_webdav_client.dart';
import 'crypto_storage.dart';

class AdminRepairService {
  final CloudWebDavClient client;
  final CryptoStorage crypto;
  final String orgBase; // eingliederungshilfe/organizations/<org>

  AdminRepairService({required this.client, required this.crypto, required this.orgBase});

  Future<Map<String, dynamic>> loadClientsIndex() async {
    try {
      final dl = await client.get('$orgBase/administration/clients-index.bin');
      if (!dl.success || dl.data == null) return {'version': 1, 'entries': <Map<String, dynamic>>[]};
      final enc = utf8.decode(dl.data!);
      final clear = await crypto.decryptJson(enc);
      return clear ?? {'version': 1, 'entries': <Map<String, dynamic>>[]};
    } catch (_) {
      return {'version': 1, 'entries': <Map<String, dynamic>>[]};
    }
  }

  Future<Map<String, List<Map<String, String>>>> analyzeIndexDrift() async {
    final index = await loadClientsIndex();
    final entries = (index['entries'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
    final indexSet = <String, String>{}; // uuid -> teamId
    for (final e in entries) {
      final uuid = (e['uuid'] ?? '').toString();
      final team = (e['teamId'] ?? '').toString();
      if (uuid.isNotEmpty && team.isNotEmpty) indexSet[uuid] = team;
    }

    final missingInIndex = <Map<String, String>>[];
    final staleInIndex = <Map<String, String>>[];

    // Scan team folders
    try {
      final teamsList = await client.listDetailed('$orgBase/teams');
      if (teamsList.success && teamsList.data != null) {
        for (final item in teamsList.data!) {
          if (!item.isCollection) continue;
          final teamId = item.displayName;
          if (teamId.isEmpty) continue;
          final files = await client.list('$orgBase/teams/$teamId/clients');
          if (!files.success || files.data == null) continue;
          for (final f in files.data!) {
            if (!f.endsWith('.bin')) continue;
            final uuid = f.substring(0, f.length - 4);
            if (!indexSet.containsKey(uuid)) {
              missingInIndex.add({'uuid': uuid, 'teamId': teamId});
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[REPAIR] scan teams error: $e');
    }

    // Find stale entries (index points to non-existing file)
    for (final entry in indexSet.entries) {
      final path = '$orgBase/teams/${entry.value}/clients/${entry.key}.bin';
      final dl = await client.get(path);
      if (!dl.success || dl.data == null) {
        staleInIndex.add({'uuid': entry.key, 'teamId': entry.value});
      }
    }

    return {
      'missingInIndex': missingInIndex,
      'staleInIndex': staleInIndex,
    };
  }

  Future<bool> addMissingIndexEntries(List<Map<String, String>> items) async {
    try {
      final index = await loadClientsIndex();
      final entries = (index['entries'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
      final filtered = entries.where((e) => !items.any((i) => i['uuid'] == e['uuid'])).toList();
      for (final i in items) {
        filtered.add({
          'uuid': i['uuid'],
          'teamId': i['teamId'],
          'name': i['uuid'],
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        });
      }
      final newIndex = {'version': 1, 'updatedAt': DateTime.now().toUtc().toIso8601String(), 'entries': filtered};
      final enc = await crypto.encryptJson('clients-index', newIndex);
      final data = Uint8List.fromList(utf8.encode(enc));
      await client.mkcol('$orgBase/administration');
      final res = await client.put('$orgBase/administration/clients-index.bin', data);
      return res.success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeStaleIndexEntries(List<Map<String, String>> items) async {
    try {
      final index = await loadClientsIndex();
      final entries = (index['entries'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
      final uuids = items.map((e) => e['uuid']).toSet();
      final filtered = entries.where((e) => !uuids.contains(e['uuid'])).toList();
      final newIndex = {'version': 1, 'updatedAt': DateTime.now().toUtc().toIso8601String(), 'entries': filtered};
      final enc = await crypto.encryptJson('clients-index', newIndex);
      final data = Uint8List.fromList(utf8.encode(enc));
      await client.mkcol('$orgBase/administration');
      final res = await client.put('$orgBase/administration/clients-index.bin', data);
      return res.success;
    } catch (_) {
      return false;
    }
  }
}

