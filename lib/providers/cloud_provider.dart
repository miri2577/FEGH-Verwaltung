import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/cloud_webdav_client.dart';
import '../services/cloud_webdav_client.dart' show HiDriveConfig;

final cloudClientProvider = Provider<CloudWebDavClient>((ref) {
  final s = ref.watch(appSettingsProvider);
  final sub = (s.rootSubdirectory != null && s.rootSubdirectory!.trim().isNotEmpty)
      ? s.rootSubdirectory!.trim()
      : null;
  final customBase = HiDriveConfig.buildWebDAVUrl(s.cloudUsername ?? '', subdirectory: sub);
  return CloudWebDavClient(
    username: s.cloudUsername ?? '',
    password: s.cloudPassword ?? '',
    customBaseUrl: customBase,
  );
});
