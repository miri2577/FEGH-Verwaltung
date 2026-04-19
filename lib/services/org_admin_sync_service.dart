import 'package:flutter/foundation.dart';
import '../services/cloud_webdav_client.dart';

class OrgAdminSyncService {
  final CloudWebDavClient client;
  final String orgId;

  OrgAdminSyncService({required this.client, required this.orgId});

  Future<bool> run() async {
    try {
      final base = 'eingliederungshilfe/organizations/$orgId';
      final dirs = [
        base,
        '$base/teams',
        '$base/employees',
        '$base/administration',
        '$base/shared',
        '$base/shared/calendar-sync',
        '$base/shared/messages',
      ];
      for (final d in dirs) {
        await client.mkcol(d);
      }
      if (kDebugMode) {
        print('✅ OrgAdminSync: Ordnerstruktur bereit');
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ OrgAdminSync failed: $e');
      return false;
    }
  }
}

