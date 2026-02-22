import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'hidrive_webdav_client.dart';

class AdminHealthService {
  final HiDriveWebDAVClient client;
  final String orgBase;

  AdminHealthService({required this.client, required this.orgBase});

  Future<Map<String, bool>> check() async {
    final results = <String, bool>{};
    try {
      final admin = await client.listDetailed('$orgBase/administration');
      results['administration_access'] = admin.success;
    } catch (_) {
      results['administration_access'] = false;
    }
    try {
      final teams = await client.listDetailed('$orgBase/teams');
      results['teams_access'] = teams.success;
    } catch (_) {
      results['teams_access'] = false;
    }
    // roles.json vorhanden?
    try {
      final roles = await client.get('$orgBase/administration/users/roles.json');
      results['roles_policy_exists'] = roles.success && roles.data != null;
    } catch (_) {
      results['roles_policy_exists'] = false;
    }
    // Schreibrecht-Test
    results['write_access'] = await checkWriteAccess();
    if (kDebugMode) debugPrint('[HEALTH] $results');
    return results;
  }

  Future<bool> checkWriteAccess() async {
    try {
      final tmpDir = '$orgBase/administration/.health';
      await client.mkcol('$orgBase/administration');
      await client.mkcol(tmpDir);
      final path = '$tmpDir/write_test_${DateTime.now().millisecondsSinceEpoch}.txt';
      final ok = await client.put(path, Uint8List.fromList('ok'.codeUnits));
      if (!ok.success) return false;
      await client.delete(path);
      return true;
    } catch (_) {
      return false;
    }
  }
}
