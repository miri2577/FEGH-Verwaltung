// Integrationstest: Klient-Schema laesst sich zwischen beiden Apps
// ueber WebDAV roundtrip'en (Schreiben durch Verwaltung, Lesen analog
// zu Doku).
//
// Nutzt `dufs` als lokalen WebDAV-Server. Benoetigt:
//   - `FEGH_WEBDAV_URL`   (z. B. http://localhost:5000)
//   - `FEGH_WEBDAV_USER`
//   - `FEGH_WEBDAV_PASS`
//
// dufs starten:
//   dufs $env:FEGH_WEBDAV_DIR --auth "user:pass@/:rw" --port 5000
//
// Wenn der Server nicht erreichbar ist, wird der Test geskipt.
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fegh_cloud/fegh_cloud.dart';
import 'package:fegh_core/fegh_core.dart';
import 'package:flutter_test/flutter_test.dart';

Future<bool> _webdavReachable(String url) async {
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    final req = await client.openUrl('PROPFIND', Uri.parse(url));
    req.headers.set('Depth', '0');
    final res = await req.close();
    await res.drain<void>();
    client.close();
    // 207 Multi-Status (WebDAV) oder 401 Unauthorized = Server lebt.
    return res.statusCode == 207 || res.statusCode == 401;
  } catch (_) {
    return false;
  }
}

void main() {
  final url = Platform.environment['FEGH_WEBDAV_URL'];
  final user = Platform.environment['FEGH_WEBDAV_USER'];
  final pass = Platform.environment['FEGH_WEBDAV_PASS'];
  final envConfigured = url != null &&
      url.isNotEmpty &&
      user != null &&
      user.isNotEmpty &&
      pass != null;
  final skipReason = envConfigured
      ? null
      : 'WebDAV-Env nicht gesetzt - setze FEGH_WEBDAV_URL/_USER/_PASS '
          'und starte dufs (siehe scripts/install-test-tools).';

  group('Cross-App-Interop ueber WebDAV', () {
    test('Klient-JSON laesst sich schreiben und wieder lesen', () async {
      // Laufzeit-Pruefung, ob der Server auch tatsaechlich erreichbar ist.
      final reachable = await _webdavReachable(url!);
      if (!reachable) {
        markTestSkipped('dufs/WebDAV-Server unter $url nicht erreichbar - '
            'Server starten mit: dufs --auth user:pass@/:rw --port 5000');
        return;
      }
      final adapter = GenericWebdavAdapter(
        baseUrl: url,
        username: user!,
        password: pass!,
      );

      final client = Client.create(
        klientenId: 'test-klient-interop-001',
        firstName: 'Max',
        lastName: 'Mustermann',
        dateOfBirth: DateTime(1990, 5, 17),
        bundeslandOverride: Bundesland.berlin,
      );

      final paths = FeghPaths(orgId: 'integration-test');
      final remotePath =
          paths.teamClientRecord('team-integration', client.id);

      // Sicherstellen, dass die Verzeichnisse existieren.
      for (final dir in paths.bootstrapDirectories()) {
        await adapter.createDirectory(dir);
      }
      final teamDirParts = remotePath.split('/')..removeLast();
      await adapter.createDirectory(teamDirParts.join('/'));

      // Schreiben (Verwaltung-artig).
      final jsonBytes =
          Uint8List.fromList(utf8.encode(jsonEncode(client.toJson())));
      final putResult = await adapter.upload(remotePath, jsonBytes);
      expect(putResult.isSuccess, isTrue,
          reason: 'upload failed: ${putResult.error}');

      // Lesen (Doku-artig).
      final getResult = await adapter.download(remotePath);
      expect(getResult.isSuccess, isTrue,
          reason: 'download failed: ${getResult.error}');
      final readJson =
          jsonDecode(utf8.decode(getResult.data!)) as Map<String, dynamic>;
      final readClient = Client.fromJson(readJson);

      // Kernfelder muessen roundtrip-sicher sein.
      expect(readClient.id, client.id);
      expect(readClient.firstName, 'Max');
      expect(readClient.lastName, 'Mustermann');
      expect(readClient.bundeslandOverride, Bundesland.berlin);
      expect(readClient.dateOfBirth, DateTime(1990, 5, 17));

      // Aufraeumen.
      await adapter.delete(remotePath);
    }, skip: skipReason);
  });
}
