import 'dart:typed_data';

import 'package:fegh_cloud/fegh_cloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalverwaltung/models/arbeitszeit.dart';
import 'package:personalverwaltung/models/shift.dart';
import 'package:personalverwaltung/services/cloud_webdav_client.dart';
import 'package:personalverwaltung/services/crypto_storage.dart';
import 'package:personalverwaltung/services/team_shift_sync_service.dart';
import 'package:personalverwaltung/services/team_worktime_sync_service.dart';

/// In-Memory-WebDAV: haelt geschriebene Records in einer Map (kein Netzwerk).
class _FakeWebDav extends CloudWebDavClient {
  _FakeWebDav() : super(username: 'test', password: 'test');
  final Map<String, List<int>> store = {};

  @override
  Future<WebDAVResult<void>> mkcol(String path) async =>
      WebDAVResult.success(null);

  @override
  Future<WebDAVResult<void>> put(String path, List<int> data) async {
    store[path] = data;
    return WebDAVResult.success(null);
  }

  @override
  Future<WebDAVResult<List<int>>> get(String path) async {
    final d = store[path];
    return d == null
        ? WebDAVResult.failure('404', 404)
        : WebDAVResult.success(d);
  }

  @override
  Future<WebDAVResult<void>> delete(String path) async {
    store.remove(path);
    return WebDAVResult.success(null);
  }

  @override
  Future<WebDAVResult<List<String>>> list(String path) async {
    final prefix = '$path/';
    final names = store.keys
        .where((k) => k.startsWith(prefix))
        .map((k) => k.substring(prefix.length))
        .where((n) => !n.contains('/'))
        .toList();
    return WebDAVResult.success(names);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const paths = FeghPaths(orgId: 'org1');
  late CryptoStorage crypto;

  setUp(() {
    crypto = CryptoStorage();
    crypto.setExternalMEK(Uint8List.fromList(List.filled(32, 7)));
  });

  Shift shift(String id, {String? teamId = 't1'}) => Shift(
        id: id,
        employeeId: 'e1',
        teamId: teamId,
        startTime: DateTime(2026, 5, 10, 8),
        endTime: DateTime(2026, 5, 10, 16),
        status: ShiftStatus.scheduled,
        type: ShiftType.regular,
        hourlyRate: 20,
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
      );

  group('TeamShiftSyncService', () {
    test('upload -> download Roundtrip, kanonischer Pfad, verschluesselt',
        () async {
      final fake = _FakeWebDav();
      final sync =
          TeamShiftSyncService(client: fake, crypto: crypto, paths: paths);

      expect(await sync.uploadShift(shift('s1')), isTrue);

      // Kanonischer Pfad wurde genutzt ...
      final stored = fake.store[paths.teamShiftRecord('t1', 's1')];
      expect(stored, isNotNull);
      // ... und der Inhalt ist verschluesselt (kein Klartext-employeeId).
      expect(String.fromCharCodes(stored!).contains('e1'), isFalse);

      final loaded = await sync.downloadShifts('t1');
      expect(loaded, hasLength(1));
      expect(loaded.first.id, 's1');
      expect(loaded.first.employeeId, 'e1');
      expect(loaded.first.teamId, 't1');
    });

    test('ohne teamId kein Upload', () async {
      final sync = TeamShiftSyncService(
          client: _FakeWebDav(), crypto: crypto, paths: paths);
      expect(await sync.uploadShift(shift('s2', teamId: null)), isFalse);
    });

    test('delete entfernt den Record', () async {
      final fake = _FakeWebDav();
      final sync =
          TeamShiftSyncService(client: fake, crypto: crypto, paths: paths);
      await sync.uploadShift(shift('s3'));
      expect(await sync.downloadShifts('t1'), hasLength(1));
      expect(await sync.deleteShift(shift('s3')), isTrue);
      expect(await sync.downloadShifts('t1'), isEmpty);
    });
  });

  group('TeamWorktimeSyncService', () {
    test('Monat upload -> download Roundtrip', () async {
      final fake = _FakeWebDav();
      final sync =
          TeamWorktimeSyncService(client: fake, crypto: crypto, paths: paths);
      final month = DateTime(2026, 5);
      final eintraege = [
        Arbeitszeit(
          id: 'a1',
          datum: DateTime(2026, 5, 10),
          startzeit: DateTime(2026, 5, 10, 9),
          endzeit: DateTime(2026, 5, 10, 12),
          taetigkeit: 'Einzelbetreuung',
          notizen: '',
          createdAt: DateTime(2026, 5, 10),
          mitarbeiterId: 'e1',
        ),
        Arbeitszeit(
          id: 'a2',
          datum: DateTime(2026, 5, 11),
          startzeit: DateTime(2026, 5, 11, 9),
          endzeit: DateTime(2026, 5, 11, 11),
          taetigkeit: 'Hausbesuch',
          notizen: '',
          createdAt: DateTime(2026, 5, 11),
          mitarbeiterId: 'e1',
        ),
      ];
      expect(
        await sync.uploadMonth(
            teamId: 't1', employeeId: 'e1', month: month, eintraege: eintraege),
        isTrue,
      );
      expect(fake.store[paths.teamWorktimeRecord('t1', 'e1', month)], isNotNull);

      final loaded = await sync.downloadMonth(
          teamId: 't1', employeeId: 'e1', month: month);
      expect(loaded, hasLength(2));
      expect(loaded.map((e) => e.id), containsAll(['a1', 'a2']));
      expect(loaded.first.stunden, closeTo(3.0, 1e-9));
    });

    test('leerer Monat -> leere Liste', () async {
      final sync = TeamWorktimeSyncService(
          client: _FakeWebDav(), crypto: crypto, paths: paths);
      final loaded = await sync.downloadMonth(
          teamId: 't1', employeeId: 'e1', month: DateTime(2026, 6));
      expect(loaded, isEmpty);
    });
  });
}
