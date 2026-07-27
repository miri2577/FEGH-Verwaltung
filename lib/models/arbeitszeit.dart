// Gemeinsames Arbeitszeit-Modell (fegh_core) + Konvertierung zu/von den
// Verwaltungs-internen Timesheet-Strukturen. Die Verwaltung tauscht mit der
// Doku-App Arbeitszeit aus (Cloud-Sync) und rechnet sie in ihre
// Lohn-Zeitnachweise (Timesheet/TimesheetEntry) um.
import 'package:fegh_core/fegh_core.dart';

import 'timesheet.dart';

export 'package:fegh_core/fegh_core.dart'
    show
        Arbeitszeit,
        ArbeitszeitStatus,
        ArbeitszeitTyp,
        ArbeitszeitTaetigkeiten,
        ArbeitszeitStatusDisplay,
        ArbeitszeitTypDisplay;

/// Import: eine (aus der Cloud gelesene) Arbeitszeit als Timesheet-Position.
extension ArbeitszeitToTimesheet on Arbeitszeit {
  TimesheetEntry toTimesheetEntry({required String timesheetId}) {
    return TimesheetEntry(
      id: id,
      timesheetId: timesheetId,
      shiftId: shiftId,
      type: arbeitszeitTypToEntryType(typ),
      startTime: startzeit,
      endTime: endzeit,
      description: taetigkeit.isNotEmpty
          ? taetigkeit
          : (notizen.isEmpty ? null : notizen),
      clientId: clientId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Export: eine Timesheet-Position als Arbeitszeit (fuer den Cloud-Sync).
extension TimesheetEntryToArbeitszeit on TimesheetEntry {
  Arbeitszeit toArbeitszeit({required String mitarbeiterId}) {
    return Arbeitszeit(
      id: id,
      datum: DateTime(startTime.year, startTime.month, startTime.day),
      startzeit: startTime,
      endzeit: endTime,
      taetigkeit: description ?? '',
      notizen: '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      clientId: clientId,
      shiftId: shiftId,
      typ: entryTypeToArbeitszeitTyp(type),
      mitarbeiterId: mitarbeiterId,
    );
  }
}

/// TimesheetEntryType -> ArbeitszeitTyp. `overtime` hat keine fachliche
/// Arbeitszeit-Entsprechung (Ueberstunden ergeben sich aus Dauer/Regeln,
/// nicht aus der Taetigkeitsart) und wird auf Betreuung abgebildet.
ArbeitszeitTyp entryTypeToArbeitszeitTyp(TimesheetEntryType t) {
  switch (t) {
    case TimesheetEntryType.regular:
    case TimesheetEntryType.overtime:
      return ArbeitszeitTyp.betreuung;
    case TimesheetEntryType.travel:
      return ArbeitszeitTyp.fahrt;
    case TimesheetEntryType.training:
      return ArbeitszeitTyp.fortbildung;
    case TimesheetEntryType.administrative:
      return ArbeitszeitTyp.verwaltung;
    case TimesheetEntryType.break_:
      return ArbeitszeitTyp.sonstige;
  }
}

/// ArbeitszeitTyp -> TimesheetEntryType (fuer die Lohn-Kategorisierung).
TimesheetEntryType arbeitszeitTypToEntryType(ArbeitszeitTyp t) {
  switch (t) {
    case ArbeitszeitTyp.betreuung:
      return TimesheetEntryType.regular;
    case ArbeitszeitTyp.fahrt:
      return TimesheetEntryType.travel;
    case ArbeitszeitTyp.fortbildung:
      return TimesheetEntryType.training;
    case ArbeitszeitTyp.buero:
    case ArbeitszeitTyp.dokumentation:
    case ArbeitszeitTyp.verwaltung:
    case ArbeitszeitTyp.teambesprechung:
      return TimesheetEntryType.administrative;
    case ArbeitszeitTyp.sonstige:
      return TimesheetEntryType.regular;
  }
}
