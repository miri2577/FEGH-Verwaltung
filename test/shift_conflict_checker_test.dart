import 'package:flutter_test/flutter_test.dart';
import 'package:personalverwaltung/models/shift.dart';
import 'package:personalverwaltung/services/shift_conflict_checker.dart';

Shift _shift({
  String id = 's',
  String employee = 'e1',
  required DateTime start,
  required Duration duration,
  ShiftStatus status = ShiftStatus.scheduled,
}) {
  return Shift(
    id: id,
    employeeId: employee,
    startTime: start,
    endTime: start.add(duration),
    status: status,
    type: ShiftType.regular,
    hourlyRate: 20,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('ShiftConflictChecker', () {
    test('no conflicts for a clean shift in empty schedule', () {
      final s = _shift(start: DateTime(2026, 4, 20, 8), duration: const Duration(hours: 8));
      expect(ShiftConflictChecker.check(s, []), isEmpty);
    });

    test('detects employee overlap (blocking)', () {
      final a = _shift(id: 'a', start: DateTime(2026, 4, 20, 8), duration: const Duration(hours: 8));
      final b = _shift(id: 'b', start: DateTime(2026, 4, 20, 14), duration: const Duration(hours: 4));
      final conflicts = ShiftConflictChecker.check(b, [a]);
      expect(conflicts, hasLength(1));
      expect(conflicts.first.kind, ShiftConflictKind.employeeOverlap);
      expect(conflicts.first.severity, ShiftConflictSeverity.blocking);
    });

    test('ignores cancelled shifts', () {
      final a = _shift(id: 'a', start: DateTime(2026, 4, 20, 8), duration: const Duration(hours: 8), status: ShiftStatus.cancelled);
      final b = _shift(id: 'b', start: DateTime(2026, 4, 20, 14), duration: const Duration(hours: 4));
      expect(ShiftConflictChecker.check(b, [a]), isEmpty);
    });

    test('ignores shifts of other employees', () {
      final a = _shift(id: 'a', employee: 'e2', start: DateTime(2026, 4, 20, 8), duration: const Duration(hours: 8));
      final b = _shift(id: 'b', start: DateTime(2026, 4, 20, 7), duration: const Duration(hours: 4));
      expect(ShiftConflictChecker.check(b, [a]), isEmpty);
    });

    test('rest period < 11h triggers warning/blocking', () {
      // Schicht A endet 22:00, Schicht B beginnt naechster Tag 06:00 -> 8h Pause
      final a = _shift(id: 'a', start: DateTime(2026, 4, 20, 14), duration: const Duration(hours: 8));
      final b = _shift(id: 'b', start: DateTime(2026, 4, 21, 6), duration: const Duration(hours: 6));
      final conflicts = ShiftConflictChecker.check(b, [a]);
      expect(conflicts.any((c) => c.kind == ShiftConflictKind.restPeriodTooShort), isTrue);
    });

    test('exactly 11h rest is accepted', () {
      final a = _shift(id: 'a', start: DateTime(2026, 4, 20, 14), duration: const Duration(hours: 8));
      // Ende 22:00, naechster Beginn 9:00 -> 11h genau
      final b = _shift(id: 'b', start: DateTime(2026, 4, 21, 9), duration: const Duration(hours: 6));
      final conflicts = ShiftConflictChecker.check(b, [a]);
      expect(conflicts.where((c) => c.kind == ShiftConflictKind.restPeriodTooShort), isEmpty);
    });

    test('single shift > 10h is blocking (ArbZG §3)', () {
      final s = _shift(start: DateTime(2026, 4, 20, 8), duration: const Duration(hours: 11));
      final conflicts = ShiftConflictChecker.check(s, []);
      expect(conflicts.any((c) =>
          c.kind == ShiftConflictKind.dailyHoursExceeded &&
          c.severity == ShiftConflictSeverity.blocking), isTrue);
    });

    test('weekly > 48h accumulated triggers warning', () {
      // 5x 10h in Folge = 50h im 7-Tage-Fenster
      final existing = List.generate(5, (i) => _shift(
            id: 's$i',
            start: DateTime(2026, 4, 14 + i, 8),
            duration: const Duration(hours: 10),
          ));
      final newShift = _shift(
        id: 'new',
        start: DateTime(2026, 4, 19, 8),
        duration: const Duration(hours: 4),
      );
      final conflicts = ShiftConflictChecker.check(newShift, existing);
      expect(conflicts.any((c) => c.kind == ShiftConflictKind.weeklyHoursExceeded), isTrue);
    });

    test('editing an existing shift does not flag itself', () {
      final s = _shift(id: 'me', start: DateTime(2026, 4, 20, 8), duration: const Duration(hours: 8));
      expect(ShiftConflictChecker.check(s, [s]), isEmpty);
    });
  });
}
