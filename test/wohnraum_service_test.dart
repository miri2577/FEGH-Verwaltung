import 'package:flutter_test/flutter_test.dart';
import 'package:personalverwaltung/models/wohnraum.dart';
import 'package:personalverwaltung/services/wohnraum_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Wohnraum _wr({
  String id = 'w1',
  String? clientId,
  String bezeichnung = 'Haus 1, Zimmer 3',
  double kaltmiete = 500,
  double nebenkosten = 150,
  WohnraumStatus status = WohnraumStatus.free,
}) {
  return Wohnraum(
    id: id,
    clientId: clientId,
    bezeichnung: bezeichnung,
    kaltmiete: kaltmiete,
    nebenkosten: nebenkosten,
    status: status,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 4, 19),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('WohnraumService — CRUD', () {
    test('add + loadAll Roundtrip', () async {
      final s = WohnraumService();
      final ok = await s.addWohnraum(_wr());
      expect(ok, isTrue);
      final all = await s.loadAll();
      expect(all, hasLength(1));
      expect(all.first.bezeichnung, 'Haus 1, Zimmer 3');
    });

    test('update aendert Felder', () async {
      final s = WohnraumService();
      await s.addWohnraum(_wr());
      final updated = _wr(kaltmiete: 550);
      await s.updateWohnraum(updated);
      final all = await s.loadAll();
      expect(all.first.kaltmiete, 550);
    });

    test('deactivate setzt Status inactive (bleibt in Liste)', () async {
      final s = WohnraumService();
      await s.addWohnraum(_wr());
      await s.deactivate('w1');
      final all = await s.loadAll();
      expect(all, hasLength(1));
      expect(all.first.status, WohnraumStatus.inactive);
      final active = await s.loadActive();
      expect(active, isEmpty);
    });

    test('loadById findet Eintrag, null bei unbekannt', () async {
      final s = WohnraumService();
      await s.addWohnraum(_wr());
      expect((await s.loadById('w1'))?.bezeichnung, 'Haus 1, Zimmer 3');
      expect(await s.loadById('nope'), isNull);
    });
  });

  group('WohnraumService — Zuweisung', () {
    test('assignClient setzt Status auf occupied + clientId', () async {
      final s = WohnraumService();
      await s.addWohnraum(_wr());
      await s.assignClient('w1', 'c-42');
      final wr = await s.loadById('w1');
      expect(wr!.status, WohnraumStatus.occupied);
      expect(wr.clientId, 'c-42');
      expect(wr.mietbeginn, isNotNull);
    });

    test('releaseClient setzt Status free + clientId null + mietende', () async {
      final s = WohnraumService();
      await s.addWohnraum(_wr());
      await s.assignClient('w1', 'c-42');
      await s.releaseClient('w1');
      final wr = await s.loadById('w1');
      expect(wr!.status, WohnraumStatus.free);
      expect(wr.clientId, isNull);
      expect(wr.mietende, isNotNull);
    });

    test('assignClient bei unbekannter ID → false', () async {
      final s = WohnraumService();
      expect(await s.assignClient('unknown', 'c-1'), isFalse);
    });
  });

  group('WohnraumService — Filter', () {
    test('loadFree filtert nach status=free', () async {
      final s = WohnraumService();
      await s.addWohnraum(_wr(id: 'a'));
      await s.addWohnraum(_wr(id: 'b', clientId: 'c1', status: WohnraumStatus.occupied));
      await s.addWohnraum(_wr(id: 'c', status: WohnraumStatus.reserved));
      final free = await s.loadFree();
      expect(free.map((w) => w.id), ['a']);
    });

    test('loadForClient liefert Platz eines Klienten', () async {
      final s = WohnraumService();
      await s.addWohnraum(_wr(id: 'a', clientId: 'c1', status: WohnraumStatus.occupied));
      await s.addWohnraum(_wr(id: 'b', clientId: 'c2', status: WohnraumStatus.occupied));
      final c1 = await s.loadForClient('c1');
      expect(c1.map((w) => w.id), ['a']);
    });
  });

  group('Wohnraum-Model', () {
    test('warmmiete = kalt + neben', () {
      final w = _wr(kaltmiete: 500, nebenkosten: 150);
      expect(w.warmmiete, 650);
    });

    test('copyWith clearClient=true entfernt clientId', () {
      final w = _wr(clientId: 'c-1');
      final cleared = w.copyWith(clearClient: true);
      expect(cleared.clientId, isNull);
    });

    test('JSON roundtrip erhaelt alle Felder', () {
      final w = _wr(clientId: 'c-1', status: WohnraumStatus.occupied);
      final j = w.toJson();
      final restored = Wohnraum.fromJson(j);
      expect(restored.clientId, 'c-1');
      expect(restored.status, WohnraumStatus.occupied);
      expect(restored.warmmiete, 650);
    });
  });
}
