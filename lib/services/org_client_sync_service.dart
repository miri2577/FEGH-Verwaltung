import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'crypto_storage.dart';
import 'cloud_webdav_client.dart';
import '../models/client.dart';

class OrgClientSyncService {
  final CloudWebDavClient client;
  final CryptoStorage crypto;
  final String orgBase; // e.g. eingliederungshilfe/organizations/<org>

  OrgClientSyncService({required this.client, required this.crypto, required this.orgBase});

  Future<bool> uploadOrUpdateClient(Client c) async {
    if (c.teamId == null || c.teamId!.isEmpty) {
      if (kDebugMode) debugPrint('[CLIENT SYNC] skip: no teamId for client ${c.id}');
      return false;
    }
    final teamId = c.teamId!;
    final clientsDir = '$orgBase/teams/$teamId/clients';
    await client.mkcol('$orgBase');
    await client.mkcol('$orgBase/teams');
    await client.mkcol('$orgBase/teams/$teamId');
    await client.mkcol(clientsDir);

    final enc = await crypto.encryptJson('client', c.toJson());
    final bytes = Uint8List.fromList(utf8.encode(enc));
    final res = await client.put('$clientsDir/${c.id}.bin', bytes);
    if (!res.success) return false;

    await _clientsIndexAddOrUpdate(c);
    return true;
  }

  Future<bool> deleteClient(Client c) async {
    if (c.teamId == null || c.teamId!.isEmpty) return false;
    final teamId = c.teamId!;
    final clientsDir = '$orgBase/teams/$teamId/clients';
    await client.delete('$clientsDir/${c.id}.bin');
    await _clientsIndexRemove(c.id);
    return true;
  }

  Future<bool> migrateClientTeam({
    required Client clientModel,
    required String oldTeamId,
    required String newTeamId,
  }) async {
    try {
      final oldPath = '$orgBase/teams/$oldTeamId/clients/${clientModel.id}.bin';
      final getOld = await client.get(oldPath);
      if (!getOld.success || getOld.data == null) {
        // Fallback: neu schreiben
        final updated = clientModel.copyWith(teamId: newTeamId);
        return await uploadOrUpdateClient(updated);
      }
      // Entschlüsseln, teamId anpassen, neu verschlüsseln und in neues Verzeichnis schreiben
      final encJson = utf8.decode(getOld.data!);
      final clear = await crypto.decryptJson(encJson);
      final map = {...?clear};
      map['teamId'] = newTeamId;
      final updatedEnc = await crypto.encryptJson('client', map);
      final data = Uint8List.fromList(utf8.encode(updatedEnc));
      final newDir = '$orgBase/teams/$newTeamId/clients';
      await client.mkcol('$orgBase/teams/$newTeamId');
      await client.mkcol(newDir);
      final put = await client.put('$newDir/${clientModel.id}.bin', data);
      if (!put.success) return false;
      // alten löschen und Index updaten
      await client.delete(oldPath);
      await _clientsIndexAddOrUpdate(clientModel.copyWith(teamId: newTeamId));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _clientsIndexAddOrUpdate(Client c) async {
    final indexPath = '$orgBase/administration/clients-index';
    await client.mkcol('$orgBase/administration');

    final current = await _loadClientsIndex();
    final entries = (current['entries'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
    final filtered = entries.where((e) => e['uuid'] != c.id).toList();
    filtered.add({
      'uuid': c.id,
      'teamId': c.teamId,
      'name': c.fullName,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
    final newIndex = {
      'version': 1,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'entries': filtered,
    };
    final encRec = await crypto.encryptJson('clients-index', newIndex);
    final data = Uint8List.fromList(utf8.encode(encRec));
    await client.put('$indexPath.bin', data);
  }

  Future<void> _clientsIndexRemove(String uuid) async {
    final indexPath = '$orgBase/administration/clients-index';
    final current = await _loadClientsIndex();
    final entries = (current['entries'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
    final filtered = entries.where((e) => e['uuid'] != uuid).toList();
    final newIndex = {
      'version': 1,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'entries': filtered,
    };
    final encRec = await crypto.encryptJson('clients-index', newIndex);
    final data = Uint8List.fromList(utf8.encode(encRec));
    await client.put('$indexPath.bin', data);
  }

  Future<Map<String, dynamic>> _loadClientsIndex() async {
    try {
      final res = await client.get('$orgBase/administration/clients-index.bin');
      if (!res.success || res.data == null) return {'version': 1, 'updatedAt': null, 'entries': <Map<String, dynamic>>[]};
      final encJson = utf8.decode(res.data!);
      final clear = await crypto.decryptJson(encJson);
      return clear ?? {'version': 1, 'updatedAt': null, 'entries': <Map<String, dynamic>>[]};
    } catch (_) {
      return {'version': 1, 'updatedAt': null, 'entries': <Map<String, dynamic>>[]};
    }
  }
}
