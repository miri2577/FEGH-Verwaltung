import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/hidrive_webdav_client.dart';
import '../services/hidrive_webdav_client.dart' show HiDriveConfig;

final hidriveClientProvider = Provider<HiDriveWebDAVClient>((ref) {
  final s = ref.watch(appSettingsProvider);
  final sub = (s.rootSubdirectory != null && s.rootSubdirectory!.trim().isNotEmpty)
      ? s.rootSubdirectory!.trim()
      : null;
  final customBase = HiDriveConfig.buildWebDAVUrl(s.hidriveUsername ?? '', subdirectory: sub);
  return HiDriveWebDAVClient(
    username: s.hidriveUsername ?? '',
    password: s.hidrivePassword ?? '',
    customBaseUrl: customBase,
  );
});
