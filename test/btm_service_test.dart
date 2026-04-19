import 'package:flutter_test/flutter_test.dart';
import 'package:personalverwaltung/models/btm_destruction.dart';
import 'package:personalverwaltung/models/btm_entry.dart';
import 'package:personalverwaltung/services/btm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

BtmEntry _entry({
  String id = 'b1',
  String administrationId = 'a1',
  String medicationId = 'm1',
  String clientId = 'c1',
  String menge = '1 Tablette',
  double restbestand = 19,
  String witness = 'emp-2',
  DateTime? createdAt,
}) {
  return BtmEntry(
    id: id,
    administrationId: administrationId,
    medicationId: medicationId,
    clientId: clientId,
    menge: menge,
    restbestand: restbestand,
    witnessEmployeeId: witness,
    createdAt: createdAt ?? DateTime(2026, 4, 19, 10),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('add + load pro Klient + pro Medikation', () async {
    final s = BtmService();
    await s.addEntry(_entry());
    await s.addEntry(_entry(id: 'b2', medicationId: 'm2'));
    await s.addEntry(_entry(id: 'b3', clientId: 'c2', medicationId: 'm3'));

    expect((await s.loadForClient('c1')).map((e) => e.id).toSet(),
        {'b1', 'b2'});
    expect((await s.loadForClient('c2')).single.id, 'b3');
    expect((await s.loadForMedication('m1')).single.id, 'b1');
    expect((await s.loadForMedication('m2')).single.id, 'b2');
  });

  test('letzterRestbestand liefert neuesten Eintrag', () async {
    final s = BtmService();
    await s.addEntry(_entry(id: 'b1', restbestand: 20,
        createdAt: DateTime(2026, 4, 18, 10)));
    await s.addEntry(_entry(id: 'b2', restbestand: 19,
        createdAt: DateTime(2026, 4, 19, 10)));
    expect(await s.letzterRestbestand('m1'), 19);
  });

  test('letzterRestbestand ohne Eintrag → null', () async {
    final s = BtmService();
    expect(await s.letzterRestbestand('m-unbekannt'), isNull);
  });

  test('kein Update/Delete in der Public-API', () {
    final s = BtmService();
    // Beweis ueber die Klassenoberflaeche: weder updateEntry noch deleteEntry
    // sind exponiert. Wenn jemand sie einfuehrt, bricht dieser Reflection-Hint.
    final members = s.runtimeType.toString();
    expect(members, isNot(contains('updateEntry')));
    expect(members, isNot(contains('deleteEntry')));
  });

  group('stockOverview', () {
    test('spiegelt letzten Restbestand pro Medikation', () async {
      final s = BtmService();
      await s.addEntry(_entry(id: 'b1', medicationId: 'm1', restbestand: 20,
          createdAt: DateTime(2026, 4, 17)));
      await s.addEntry(_entry(id: 'b2', medicationId: 'm1', restbestand: 18,
          createdAt: DateTime(2026, 4, 18)));
      await s.addEntry(_entry(id: 'b3', medicationId: 'm2', restbestand: 5,
          createdAt: DateTime(2026, 4, 19)));

      final rows = await s.stockOverview();
      expect(rows.length, 2);
      final byMed = {for (final r in rows) r.medicationId: r};
      expect(byMed['m1']!.stock, 18);
      expect(byMed['m2']!.stock, 5);
    });

    test('Vernichtung reduziert Bestand', () async {
      final s = BtmService();
      await s.addEntry(_entry(id: 'b1', medicationId: 'm1', restbestand: 10,
          createdAt: DateTime(2026, 4, 17)));
      await s.addDestruction(
        medicationId: 'm1',
        clientId: 'c1',
        menge: 3,
        mengeEinheit: 'Tablette(n)',
        reason: BtmDestructionReasons.expired,
        destroyerEmployeeId: 'emp-1',
        witnessEmployeeId: 'emp-2',
        destroyedAt: DateTime(2026, 4, 19),
      );

      final rows = await s.stockOverview();
      expect(rows.single.stock, 7);
    });
  });

  group('addDestruction Validierung', () {
    test('blockt bei fehlendem Zeugen', () async {
      final s = BtmService();
      final id = await s.addDestruction(
        medicationId: 'm1',
        clientId: 'c1',
        menge: 1,
        mengeEinheit: 'Tablette',
        reason: BtmDestructionReasons.expired,
        destroyerEmployeeId: 'emp-1',
        witnessEmployeeId: '',
        destroyedAt: DateTime(2026, 4, 19),
      );
      expect(id, isNull);
    });

    test('blockt wenn Zeuge == Verantwortlicher', () async {
      final s = BtmService();
      final id = await s.addDestruction(
        medicationId: 'm1',
        clientId: 'c1',
        menge: 1,
        mengeEinheit: 'Tablette',
        reason: BtmDestructionReasons.expired,
        destroyerEmployeeId: 'emp-1',
        witnessEmployeeId: 'emp-1',
        destroyedAt: DateTime(2026, 4, 19),
      );
      expect(id, isNull);
    });

    test('blockt bei Menge <= 0', () async {
      final s = BtmService();
      final id = await s.addDestruction(
        medicationId: 'm1',
        clientId: 'c1',
        menge: 0,
        mengeEinheit: 'Tablette',
        reason: BtmDestructionReasons.expired,
        destroyerEmployeeId: 'emp-1',
        witnessEmployeeId: 'emp-2',
        destroyedAt: DateTime(2026, 4, 19),
      );
      expect(id, isNull);
    });

    test('blockt bei unbekanntem Grund', () async {
      final s = BtmService();
      final id = await s.addDestruction(
        medicationId: 'm1',
        clientId: 'c1',
        menge: 1,
        mengeEinheit: 'Tablette',
        reason: 'erfunden',
        destroyerEmployeeId: 'emp-1',
        witnessEmployeeId: 'emp-2',
        destroyedAt: DateTime(2026, 4, 19),
      );
      expect(id, isNull);
    });

    test('persistiert gueltige Vernichtung', () async {
      final s = BtmService();
      final id = await s.addDestruction(
        medicationId: 'm1',
        clientId: 'c1',
        menge: 2,
        mengeEinheit: 'Tablette',
        reason: BtmDestructionReasons.notNeeded,
        destroyerEmployeeId: 'emp-1',
        witnessEmployeeId: 'emp-2',
        destroyedAt: DateTime(2026, 4, 19),
      );
      expect(id, isNotNull);
      final list = await s.destructionsForMedication('m1');
      expect(list.single.menge, 2);
      expect(list.single.reason, BtmDestructionReasons.notNeeded);
    });
  });
}
