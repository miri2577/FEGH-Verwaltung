import 'package:flutter_test/flutter_test.dart';
import 'package:personalverwaltung/models/kassenbuch_eintrag.dart';
import 'package:personalverwaltung/services/kassenbuch_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

KassenbuchEintrag _entry({
  String id = 'e1',
  String clientId = 'c1',
  DateTime? datum,
  double betrag = 10,
  KassenbuchKategorie kategorie = KassenbuchKategorie.taschengeld,
  bool confirmed = false,
}) {
  return KassenbuchEintrag(
    id: id,
    clientId: clientId,
    datum: datum ?? DateTime(2026, 4, 19),
    betrag: betrag,
    kategorie: kategorie,
    beschreibung: 'Test',
    confirmed: confirmed,
    createdAt: DateTime(2026, 4, 19),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('KassenbuchService Saldo', () {
    test('leer → 0', () async {
      final s = KassenbuchService();
      expect(await s.saldoForClient('c1'), 0);
    });

    test('Summe korrekt mit gemischten Vorzeichen', () async {
      final s = KassenbuchService();
      await s.addEintrag(_entry(id: 'a', betrag: 100));
      await s.addEintrag(_entry(id: 'b', betrag: -30));
      await s.addEintrag(_entry(id: 'c', betrag: -10));
      expect(await s.saldoForClient('c1'), 60);
    });

    test('nur fuer angefragten Klienten', () async {
      final s = KassenbuchService();
      await s.addEintrag(_entry(id: 'a', clientId: 'c1', betrag: 50));
      await s.addEintrag(_entry(id: 'b', clientId: 'c2', betrag: 1000));
      expect(await s.saldoForClient('c1'), 50);
      expect(await s.saldoForClient('c2'), 1000);
    });
  });

  group('KassenbuchService Update/Delete', () {
    test('update auf unconfirmed erlaubt', () async {
      final s = KassenbuchService();
      await s.addEintrag(_entry());
      final all = await s.loadForClient('c1');
      final edited = all.first.copyWith(betrag: 42);
      expect(await s.updateEintrag(edited), isTrue);
      expect((await s.loadForClient('c1')).first.betrag, 42);
    });

    test('update auf confirmed geblockt', () async {
      final s = KassenbuchService();
      await s.addEintrag(_entry(confirmed: true));
      final all = await s.loadForClient('c1');
      final edited = all.first.copyWith(betrag: 99);
      expect(await s.updateEintrag(edited), isFalse);
      expect((await s.loadForClient('c1')).first.betrag, 10);
    });

    test('delete auf unconfirmed erlaubt', () async {
      final s = KassenbuchService();
      await s.addEintrag(_entry());
      expect(await s.deleteEintrag('e1', byEmployeeId: 'x'), isTrue);
      expect(await s.loadForClient('c1'), isEmpty);
    });

    test('delete auf confirmed geblockt', () async {
      final s = KassenbuchService();
      await s.addEintrag(_entry(confirmed: true));
      expect(await s.deleteEintrag('e1', byEmployeeId: 'x'), isFalse);
      expect(await s.loadForClient('c1'), hasLength(1));
    });

    test('confirm macht Eintrag immutable', () async {
      final s = KassenbuchService();
      await s.addEintrag(_entry());
      expect(await s.confirmEintrag('e1', byEmployeeId: 'x'), isTrue);
      expect((await s.loadForClient('c1')).first.confirmed, isTrue);
      final again =
          await s.updateEintrag((await s.loadForClient('c1')).first);
      expect(again, isFalse);
    });
  });

  group('loadForClientInMonth', () {
    test('filtert nach Jahr und Monat', () async {
      final s = KassenbuchService();
      await s.addEintrag(
          _entry(id: 'a', datum: DateTime(2026, 3, 15)));
      await s.addEintrag(
          _entry(id: 'b', datum: DateTime(2026, 4, 1)));
      await s.addEintrag(
          _entry(id: 'c', datum: DateTime(2026, 4, 28)));
      final april = await s.loadForClientInMonth('c1', DateTime(2026, 4, 1));
      expect(april.map((e) => e.id).toList(), ['c', 'b']); // sort desc
    });
  });
}
