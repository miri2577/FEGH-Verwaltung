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
//
// Implementation nutzt `dart:io` HttpClient direkt — das webdav_client
// Dart-Package kommt mit dufs' doppeltem WWW-Authenticate-Header
// ("www-authenticate header has more than one value") nicht klar.
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:fegh_cloud/fegh_cloud.dart' show FeghPaths;
import 'package:fegh_core/fegh_core.dart';
import 'package:flutter_test/flutter_test.dart';

String _basicAuth(String user, String pass) =>
    'Basic ${base64Encode(utf8.encode('$user:$pass'))}';

Future<int> _mkcol(String url, String user, String pass) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl('MKCOL', Uri.parse(url));
    req.headers.set('Authorization', _basicAuth(user, pass));
    final res = await req.close();
    await res.drain<void>();
    return res.statusCode;
  } finally {
    client.close();
  }
}

Future<int> _put(
    String url, String user, String pass, List<int> body) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl('PUT', Uri.parse(url));
    req.headers.set('Authorization', _basicAuth(user, pass));
    req.headers.set('Content-Type', 'application/json');
    req.add(body);
    final res = await req.close();
    await res.drain<void>();
    return res.statusCode;
  } finally {
    client.close();
  }
}

Future<(int, List<int>)> _get(
    String url, String user, String pass) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl('GET', Uri.parse(url));
    req.headers.set('Authorization', _basicAuth(user, pass));
    final res = await req.close();
    final bytes = <int>[];
    await res.forEach(bytes.addAll);
    return (res.statusCode, bytes);
  } finally {
    client.close();
  }
}

Future<int> _delete(String url, String user, String pass) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl('DELETE', Uri.parse(url));
    req.headers.set('Authorization', _basicAuth(user, pass));
    final res = await req.close();
    await res.drain<void>();
    return res.statusCode;
  } finally {
    client.close();
  }
}

Future<bool> _webdavReachable(String url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  try {
    final req = await client.openUrl('PROPFIND', Uri.parse(url));
    req.headers.set('Depth', '0');
    final res = await req.close();
    await res.drain<void>();
    return res.statusCode == 207 || res.statusCode == 401;
  } catch (_) {
    return false;
  } finally {
    client.close();
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
      final reachable = await _webdavReachable(url!);
      if (!reachable) {
        markTestSkipped('dufs/WebDAV-Server unter $url nicht erreichbar - '
            'Server starten mit: dufs --auth user:pass@/:rw --port 5000');
        return;
      }

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
      final baseUrl = url.replaceAll(RegExp(r'/+$'), '');
      final remoteUrl = '$baseUrl/$remotePath';

      // Zielverzeichnisse anlegen (idempotent — 405 bedeutet "existiert").
      final parts = remotePath.split('/')..removeLast();
      for (var i = 1; i <= parts.length; i++) {
        await _mkcol('$baseUrl/${parts.take(i).join('/')}', user!, pass!);
      }

      // Schreiben.
      final bytes = utf8.encode(jsonEncode(client.toJson()));
      final putStatus = await _put(remoteUrl, user!, pass!, bytes);
      expect(putStatus, anyOf(200, 201, 204),
          reason: 'PUT auf $remoteUrl schlug fehl: HTTP $putStatus');

      // Lesen.
      final (getStatus, getBytes) = await _get(remoteUrl, user, pass);
      expect(getStatus, 200, reason: 'GET $remoteUrl schlug fehl');
      final readJson =
          jsonDecode(utf8.decode(getBytes)) as Map<String, dynamic>;
      final readClient = Client.fromJson(readJson);

      expect(readClient.id, client.id);
      expect(readClient.firstName, 'Max');
      expect(readClient.lastName, 'Mustermann');
      expect(readClient.bundeslandOverride, Bundesland.berlin);
      expect(readClient.dateOfBirth, DateTime(1990, 5, 17));

      // Aufraeumen.
      await _delete(remoteUrl, user, pass);
    }, skip: skipReason);
  });
}
