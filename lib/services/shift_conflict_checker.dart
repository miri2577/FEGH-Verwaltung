import '../models/shift.dart';

/// Schwere eines Konfliktes — UI entscheidet, ob blockierend oder Warnung.
enum ShiftConflictSeverity {
  /// Harter Verstoss, Schicht darf so nicht gespeichert werden.
  blocking,

  /// Grenzwertig, Nutzer entscheidet (z. B. exakt an der Grenze).
  warning,
}

/// Typ des Verstosses. Labels werden im UI ergaenzt.
enum ShiftConflictKind {
  /// Doppelte Belegung: derselbe Mitarbeiter hat parallel eine andere
  /// Schicht.
  employeeOverlap,

  /// Ruhezeit-Verletzung: zwischen zwei Schichten desselben
  /// Mitarbeiters liegen weniger als 11 Stunden (§5 Abs. 1 ArbZG).
  restPeriodTooShort,

  /// Wochenarbeitszeit-Ueberschreitung: Summe in einer 7-Tage-Fenster
  /// > 48 Stunden (§3 S. 2 ArbZG).
  weeklyHoursExceeded,

  /// Tagesarbeitszeit-Ueberschreitung: einzelne Schicht laenger als
  /// 10 Stunden (§3 S. 1 ArbZG).
  dailyHoursExceeded,
}

class ShiftConflict {
  final ShiftConflictKind kind;
  final ShiftConflictSeverity severity;
  final String message;

  /// Andere Schicht, die an dem Konflikt beteiligt ist (bei Overlap/
  /// RestPeriod). Bei Wochen-/Tagesverstoss `null`.
  final Shift? otherShift;

  const ShiftConflict({
    required this.kind,
    required this.severity,
    required this.message,
    this.otherShift,
  });
}

/// Prueft eine zu planende [Shift] gegen eine Liste existierender
/// Schichten und liefert alle Verstoesse zurueck.
///
/// Die Pruefung ist eine reine Funktion — kein Zustand, kein I/O.
/// Konventionen:
/// - `[existing]` enthaelt **nicht** die zu pruefende Schicht. Falls
///   du eine bereits gespeicherte Schicht pruefen willst (Edit-Fall),
///   filtere sie vorher raus (`existing.where((s) => s.id != shift.id)`).
/// - Gecancelte Schichten (`status == cancelled`) werden ignoriert.
class ShiftConflictChecker {
  ShiftConflictChecker._();

  /// §3 S. 1 ArbZG: werktaegliche Arbeitszeit maximal 8 h, bis 10 h zulaessig.
  static const Duration dailyMaxDuration = Duration(hours: 10);

  /// §3 S. 2 ArbZG: im 6-Monats-Durchschnitt max. 48 h/Woche.
  /// Vereinfachung: harter Cut bei 48 h im Rolling-7-Tage-Fenster.
  static const Duration weeklyMaxDuration = Duration(hours: 48);

  /// §5 Abs. 1 ArbZG: mind. 11 h Ruhezeit zwischen zwei Schichten.
  static const Duration minRestPeriod = Duration(hours: 11);

  /// Prueft [shift] gegen alle Schichten des gleichen Mitarbeiters.
  static List<ShiftConflict> check(
    Shift shift,
    List<Shift> existing,
  ) {
    final conflicts = <ShiftConflict>[];
    final relevant = existing
        .where((s) => s.id != shift.id)
        .where((s) => s.status != ShiftStatus.cancelled)
        .where((s) => s.employeeId == shift.employeeId)
        .toList();

    // 1) Tagesarbeitszeit
    if (shift.scheduledDuration > dailyMaxDuration) {
      conflicts.add(ShiftConflict(
        kind: ShiftConflictKind.dailyHoursExceeded,
        severity: ShiftConflictSeverity.blocking,
        message:
            'Schicht dauert ${_formatHours(shift.scheduledDuration)}. '
            '§3 ArbZG erlaubt maximal 10 Stunden am Tag.',
      ));
    }

    // 2) Ueberlappungen und Ruhezeit
    for (final other in relevant) {
      if (_overlap(shift, other)) {
        conflicts.add(ShiftConflict(
          kind: ShiftConflictKind.employeeOverlap,
          severity: ShiftConflictSeverity.blocking,
          otherShift: other,
          message:
              'Mitarbeiter hat parallel eine andere Schicht '
              '(${_formatRange(other)}).',
        ));
        continue;
      }

      final rest = _restBetween(shift, other);
      if (rest != null && rest < minRestPeriod) {
        conflicts.add(ShiftConflict(
          kind: ShiftConflictKind.restPeriodTooShort,
          severity: rest < const Duration(hours: 9)
              ? ShiftConflictSeverity.blocking
              : ShiftConflictSeverity.warning,
          otherShift: other,
          message:
              'Nur ${_formatHours(rest)} Ruhezeit zur Schicht am '
              '${_formatDate(other.startTime)}. §5 ArbZG verlangt 11 h.',
        ));
      }
    }

    // 3) Wochenarbeitszeit im rollenden 7-Tage-Fenster
    final weeklySum = _totalInRolling7Days(shift, relevant);
    if (weeklySum > weeklyMaxDuration) {
      conflicts.add(ShiftConflict(
        kind: ShiftConflictKind.weeklyHoursExceeded,
        severity: ShiftConflictSeverity.warning,
        message:
            'Im 7-Tage-Fenster stehen ${_formatHours(weeklySum)} an. '
            '§3 ArbZG setzt 48 h als Obergrenze (6-Monats-Durchschnitt).',
      ));
    }

    return conflicts;
  }

  // ── intern ──────────────────────────────────────────────────────

  static bool _overlap(Shift a, Shift b) {
    return a.startTime.isBefore(b.endTime) && b.startTime.isBefore(a.endTime);
  }

  /// Rueckgabe: Ruhezeit zwischen [a] und [b], oder `null` wenn sie
  /// ueberlappen oder mit einer anderen Logik zusammengefasst werden.
  static Duration? _restBetween(Shift a, Shift b) {
    if (_overlap(a, b)) return null;
    if (a.startTime.isAfter(b.endTime)) {
      return a.startTime.difference(b.endTime);
    }
    if (b.startTime.isAfter(a.endTime)) {
      return b.startTime.difference(a.endTime);
    }
    return null;
  }

  /// Summiert die geplante Dauer aller Schichten, die innerhalb des
  /// rollenden 7-Tage-Fensters liegen, das mit dem Tag der neuen
  /// Schicht endet (`[start-6d, end+1d]`). Das ist eine robuste
  /// Annaeherung, weil ArbZG §3 S. 2 tatsaechlich einen
  /// 6-Monats-Durchschnitt verlangt; wir fangen damit jedoch
  /// offensichtliche Ueberlast ab.
  static Duration _totalInRolling7Days(Shift shift, List<Shift> others) {
    final from = shift.startTime.subtract(const Duration(days: 6));
    final until = shift.endTime.add(const Duration(days: 1));
    var total = shift.scheduledDuration;
    for (final s in others) {
      if (s.endTime.isAfter(from) && s.startTime.isBefore(until)) {
        total += s.scheduledDuration;
      }
    }
    return total;
  }

  static String _formatHours(Duration d) {
    final h = d.inMinutes / 60.0;
    return '${h.toStringAsFixed(1)} h';
  }

  static String _formatRange(Shift s) {
    String t(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${_formatDate(s.startTime)} ${t(s.startTime)}-${t(s.endTime)}';
  }

  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}
