import 'package:fegh_cloud/fegh_cloud.dart' show FeghPaths;
import 'package:flutter/foundation.dart';

import '../services/cloud_webdav_client.dart';

/// Legt die kanonische Org-Ordnerstruktur auf der Cloud an.
///
/// Die Pfade kommen aus `FeghPaths` — dasselbe Helper-Paket, das auch
/// die Doku-App nutzt. Beide Apps sehen damit exakt dieselbe
/// Ordnerstruktur.
class OrgAdminSyncService {
  final CloudWebDavClient client;
  final String orgId;

  OrgAdminSyncService({required this.client, required this.orgId});

  Future<bool> run() async {
    try {
      final paths = FeghPaths(orgId: orgId);
      for (final d in paths.bootstrapDirectories()) {
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
