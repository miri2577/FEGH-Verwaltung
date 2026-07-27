import 'package:flutter_test/flutter_test.dart';
import 'package:personalverwaltung/models/arbeitszeit.dart';
import 'package:personalverwaltung/models/timesheet.dart';

void main() {
  final t0 = DateTime(2026, 5, 10, 9);
  final t1 = DateTime(2026, 5, 10, 12, 30);

  group('Arbeitszeit <-> TimesheetEntry', () {
    test('TimesheetEntry -> Arbeitszeit uebernimmt Kernfelder', () {
      final e = TimesheetEntry(
        id: 'e1',
        timesheetId: 'ts1',
        shiftId: 's1',
        type: TimesheetEntryType.travel,
        startTime: t0,
        endTime: t1,
        description: 'Fahrt zum Klienten',
        clientId: 'c1',
        createdAt: t0,
        updatedAt: t1,
      );
      final az = e.toArbeitszeit(mitarbeiterId: 'm1');
      expect(az.id, 'e1');
      expect(az.startzeit, t0);
      expect(az.endzeit, t1);
      expect(az.taetigkeit, 'Fahrt zum Klienten');
      expect(az.clientId, 'c1');
      expect(az.shiftId, 's1');
      expect(az.mitarbeiterId, 'm1');
      expect(az.typ, ArbeitszeitTyp.fahrt);
      expect(az.stunden, closeTo(3.5, 1e-9));
    });

    test('Roundtrip erhaelt Zeiten, Ids und bijektive Typen', () {
      for (final type in [
        TimesheetEntryType.regular,
        TimesheetEntryType.travel,
        TimesheetEntryType.training,
        TimesheetEntryType.administrative,
      ]) {
        final e = TimesheetEntry(
          id: 'e_${type.name}',
          timesheetId: 'ts1',
          shiftId: 's1',
          type: type,
          startTime: t0,
          endTime: t1,
          description: 'x',
          clientId: 'c1',
          createdAt: t0,
          updatedAt: t1,
        );
        final back =
            e.toArbeitszeit(mitarbeiterId: 'm1').toTimesheetEntry(timesheetId: 'ts1');
        expect(back.id, e.id);
        expect(back.startTime, e.startTime);
        expect(back.endTime, e.endTime);
        expect(back.clientId, e.clientId);
        expect(back.shiftId, e.shiftId);
        expect(back.type, type, reason: 'Typ $type sollte bijektiv sein');
      }
    });

    test('Arbeitszeit -> TimesheetEntry mappt Betreuung auf regular', () {
      final az = Arbeitszeit.create(
        datum: DateTime(2026, 5, 10),
        startzeit: t0,
        endzeit: t1,
        taetigkeit: 'Einzelbetreuung',
        notizen: '',
        typ: ArbeitszeitTyp.betreuung,
        mitarbeiterId: 'm1',
      );
      final e = az.toTimesheetEntry(timesheetId: 'ts1');
      expect(e.type, TimesheetEntryType.regular);
      expect(e.description, 'Einzelbetreuung');
      expect(e.timesheetId, 'ts1');
    });
  });
}
