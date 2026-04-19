import 'package:flutter_test/flutter_test.dart';
import 'package:personalverwaltung/models/medication.dart';
import 'package:personalverwaltung/models/medication_administration.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personalverwaltung/services/medication_administration_service.dart';
import 'package:personalverwaltung/services/medication_service.dart';

Medication _med({
  String id = 'm1',
  String clientId = 'c1',
  String name = 'Test 10mg',
  String dosage = '1 Tablette',
  MedicationSchedule schedule = const MedicationSchedule(morning: true),
  DateTime? validFrom,
  DateTime? validUntil,
  bool active = true,
}) {
  final now = DateTime(2026, 4, 19);
  return Medication(
    id: id,
    clientId: clientId,
    name: name,
    dosage: dosage,
    schedule: schedule,
    validFrom: validFrom ?? now.subtract(const Duration(days: 30)),
    validUntil: validUntil,
    active: active,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MedicationSchedule', () {
    test('isEmpty + dailyCount', () {
      expect(const MedicationSchedule().isEmpty, isTrue);
      expect(const MedicationSchedule().dailyCount, 0);
      const s = MedicationSchedule(morning: true, evening: true);
      expect(s.isEmpty, isFalse);
      expect(s.dailyCount, 2);
    });

    test('toJson/fromJson roundtrip', () {
      const s = MedicationSchedule(
          morning: true, noon: false, evening: true, night: false);
      final j = s.toJson();
      final r = MedicationSchedule.fromJson(j);
      expect(r.morning, true);
      expect(r.noon, false);
      expect(r.evening, true);
      expect(r.night, false);
    });
  });

  group('Medication.isValidOn', () {
    test('inactive always false', () {
      final m = _med(active: false);
      expect(m.isValidOn(DateTime(2026, 4, 19)), isFalse);
    });

    test('before validFrom → false', () {
      final m = _med(validFrom: DateTime(2026, 4, 20));
      expect(m.isValidOn(DateTime(2026, 4, 19)), isFalse);
    });

    test('after validUntil → false', () {
      final m = _med(
          validFrom: DateTime(2026, 4, 1),
          validUntil: DateTime(2026, 4, 10));
      expect(m.isValidOn(DateTime(2026, 4, 15)), isFalse);
    });

    test('within range → true', () {
      final m = _med(
          validFrom: DateTime(2026, 4, 1),
          validUntil: DateTime(2026, 4, 30));
      expect(m.isValidOn(DateTime(2026, 4, 15)), isTrue);
    });
  });

  group('MedicationService', () {
    test('add + loadAll roundtrip', () async {
      final svc = MedicationService();
      final ok = await svc.addMedication(_med());
      expect(ok, isTrue);
      final all = await svc.loadAll();
      expect(all, hasLength(1));
      expect(all.first.name, 'Test 10mg');
    });

    test('update persists new dosage', () async {
      final svc = MedicationService();
      await svc.addMedication(_med());
      final list = await svc.loadAll();
      final updated = list.first.copyWith(dosage: '2 Tabletten');
      await svc.updateMedication(updated);
      final reloaded = await svc.loadAll();
      expect(reloaded.first.dosage, '2 Tabletten');
    });

    test('deactivate keeps entry but sets inactive', () async {
      final svc = MedicationService();
      await svc.addMedication(_med());
      await svc.deactivateMedication('m1');
      final all = await svc.loadAll();
      expect(all, hasLength(1));
      expect(all.first.active, isFalse);
      final activeOnly = await svc.loadAllActive();
      expect(activeOnly, isEmpty);
    });

    test('loadForClient filters by client and active', () async {
      final svc = MedicationService();
      await svc.addMedication(_med(id: 'm1', clientId: 'A'));
      await svc.addMedication(_med(id: 'm2', clientId: 'B'));
      await svc.addMedication(_med(id: 'm3', clientId: 'A', active: false));
      final a = await svc.loadForClient('A');
      expect(a.map((m) => m.id).toList(), ['m1']);
      final aAll = await svc.loadForClient('A', activeOnly: false);
      expect(aAll.map((m) => m.id).toList(), ['m1', 'm3']);
    });
  });

  group('MedicationAdministrationService.openSlotsForDate', () {
    test('MMAN→4 Slots mit korrekten Zeiten', () async {
      final svc = MedicationService();
      await svc.addMedication(_med(schedule: const MedicationSchedule(
        morning: true, noon: true, evening: true, night: true,
      )));
      final admin = MedicationAdministrationService(medications: svc);
      final slots = await admin.openSlotsForDate(DateTime(2026, 4, 20));
      expect(slots, hasLength(4));
      expect(slots.map((s) => s.scheduledAt.hour).toList(),
          [8, 12, 18, 22]);
    });

    test('keine Slots vor validFrom', () async {
      final svc = MedicationService();
      await svc.addMedication(_med(
        schedule: const MedicationSchedule(morning: true),
        validFrom: DateTime(2026, 4, 25),
      ));
      final admin = MedicationAdministrationService(medications: svc);
      final slots = await admin.openSlotsForDate(DateTime(2026, 4, 20));
      expect(slots, isEmpty);
    });

    test('inaktive Medikamente erzeugen keine Slots', () async {
      final svc = MedicationService();
      await svc.addMedication(_med(active: false));
      final admin = MedicationAdministrationService(medications: svc);
      final slots = await admin.openSlotsForDate(DateTime(2026, 4, 20));
      expect(slots, isEmpty);
    });
  });

  group('MedicationAdministrationService Aktionen', () {
    test('administer erzeugt Eintrag + markiert Slot als given', () async {
      final svc = MedicationService();
      await svc.addMedication(_med(
          schedule: const MedicationSchedule(morning: true)));
      final admin = MedicationAdministrationService(medications: svc);
      var slots = await admin.openSlotsForDate(DateTime(2026, 4, 20));
      expect(slots.first.status, AdministrationStatus.pending);
      final ok = await admin.administer(slots.first, employeeId: 'e1');
      expect(ok, isTrue);
      slots = await admin.openSlotsForDate(DateTime(2026, 4, 20));
      expect(slots.first.status, AdministrationStatus.given);
      expect(slots.first.existing!.administeredByEmployeeId, 'e1');
    });

    test('markRefused speichert Grund', () async {
      final svc = MedicationService();
      await svc.addMedication(_med(
          schedule: const MedicationSchedule(morning: true)));
      final admin = MedicationAdministrationService(medications: svc);
      final slots = await admin.openSlotsForDate(DateTime(2026, 4, 20));
      await admin.markRefused(slots.first,
          employeeId: 'e1', reason: 'Klient schlaeft noch');
      final updated = await admin.openSlotsForDate(DateTime(2026, 4, 20));
      expect(updated.first.status, AdministrationStatus.refused);
      expect(updated.first.existing!.reason, 'Klient schlaeft noch');
    });

    test('historyForClient liefert die letzten Quittungen', () async {
      final svc = MedicationService();
      await svc.addMedication(_med(
          schedule: const MedicationSchedule(morning: true)));
      final admin = MedicationAdministrationService(medications: svc);
      final slots = await admin.openSlotsForDate(DateTime(2026, 4, 20));
      await admin.administer(slots.first, employeeId: 'e1');
      final hist = await admin.historyForClient('c1');
      expect(hist, hasLength(1));
      expect(hist.first.status, AdministrationStatus.given);
    });
  });
}
