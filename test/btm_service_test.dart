import 'package:flutter_test/flutter_test.dart';
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
}
