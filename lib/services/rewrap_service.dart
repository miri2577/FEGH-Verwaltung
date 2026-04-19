import 'dart:convert';
import 'dart:typed_data';
import '../services/cloud_webdav_client.dart';
import '../services/crypto_storage.dart';

class RewrapService {
  final CloudWebDavClient client;
  final CryptoStorage crypto;
  final String orgBase; // eingliederungshilfe/organizations/<org>

  RewrapService({required this.client, required this.crypto, required this.orgBase});

  Future<int> rewrapTeamToTeamKey(String teamId, Uint8List teamKey) async {
    // Temporär Org‑MEK nutzen, um alte Dateien zu lesen
    crypto.setExternalMEK(null);
    final base = '$orgBase/teams/$teamId';
    final dirs = ['clients', 'schedules', 'worktime'];
    int rewrapped = 0;
    for (final d in dirs) {
      final dirPath = '$base/$d';
      await client.mkcol(dirPath);
      final list = await client.propfind('$dirPath/', depth: 1);
      if (!list.success || list.data == null) continue;
      for (final res in list.data!) {
        if (res.isCollection) continue;
        if (!res.displayName.endsWith('.bin')) continue;
        final filePath = '$dirPath/${res.displayName}';
        final dl = await client.get(filePath);
        if (!dl.success || dl.data == null) continue;
        final encStr = utf8.decode(dl.data!);
        final clear = await crypto.decryptJson(encStr);
        if (clear == null) {
          // wahrscheinlich bereits mit K_team verschlüsselt
          continue;
        }
        // Re‑encrypt mit Team‑Key
        crypto.setExternalMEK(teamKey);
        final newEnc = await crypto.encryptJson('team-data', clear);
        final bytes = Uint8List.fromList(utf8.encode(newEnc));
        final up = await client.put(filePath, bytes);
        if (up.success) rewrapped++;
        // Zurück auf Org‑MEK für nächsten Decrypt
        crypto.setExternalMEK(null);
      }
    }
    return rewrapped;
  }
}

