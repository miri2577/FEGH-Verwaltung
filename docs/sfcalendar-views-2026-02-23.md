# SfCalendar-Ansichten - 23.02.2026

## Zusammenfassung

Drei neue Kalenderansichten mit Syncfusion SfCalendar implementiert. Alle Syncfusion-Pakete von 26.x auf 32.x aktualisiert (Flutter 3.35 Kompatibilität).

---

## 1. Urlaubs-Kalender (Monatsansicht)

**Datei:** `lib/features/vacation/vacation_screen.dart`

- Neuer 5. Tab "Kalender" in der Urlaubsplanung
- `SfCalendar` mit `CalendarView.month` und Agenda-Panel (200px)
- `_VacationCalendarDataSource` mappt `VacationRequest` auf ganztägige `Appointment`-Objekte
- Farbcodierung nach Urlaubstyp:
  - Jahresurlaub = Blau, Krankenstand = Rot, Persönlich = Lila
  - Mutterschaft = Pink, Vaterschaft = Teal, Notfall = Orange
  - Unbezahlt = Braun, Sabbatical = Indigo
- Status-Darstellung: Ausstehend = halbtransparent, Abgelehnt/Storniert = Grau
- Drag & Drop zum Verschieben von Urlaubszeiträumen
- Tap auf Termin öffnet Detailansicht
- Montag als erster Wochentag

## 2. Zeiterfassungs-Kalender (Wochenansicht)

**Datei:** `lib/features/timesheets/timesheets_screen.dart`

- Neuer 6. Tab "Kalender" in Arbeitszeitnachweise
- `SfCalendar` mit `CalendarView.week`, Zeitslots 06:00-22:00
- `_TimesheetCalendarDataSource` mappt `TimesheetEntry` auf zeitgebundene `Appointment`-Objekte
- Farbcodierung nach Eintragstyp:
  - Regulär = Blau, Überstunden = Rot, Reise = Orange
  - Pause = Grau, Schulung = Grün, Verwaltung = Lila
- Mitarbeitername als Prefix im Termintext
- Drag & Drop zum Verschieben von Einträgen
- Resize zum Anpassen der Arbeitszeiten
- Tap auf Eintrag öffnet Zeitnachweis-Details

## 3. Mitarbeiter-Profil Kombikalender

**Datei:** `lib/features/employees/employee_profile_screen.dart`

- Neuer 5. Tab "Kalender" im Mitarbeiter-Profil
- `_EmployeeCalendarDataSource` kombiniert drei Datenquellen:
  - **Schichten** (blau/rot/grün/indigo/amber je nach ShiftType)
  - **Urlaub** (ganztägig, farbcodiert nach VacationType, ausstehend halbtransparent)
  - **Zeiterfassung** (zeitgebunden, lila/rot/orange/grau/grün je nach EntryType)
- Umschaltbar zwischen Tag-, Wochen- und Monatsansicht (`allowedViews`)
- Farbige Legende im Header
- Agenda-Panel (250px) in der Monatsansicht
- Anwesenheitskalender im Statistik-Tab: Platzhalter durch echten SfCalendar mit Indikator-Modus ersetzt

## 4. Profil-Navigation

**Datei:** `lib/features/employees/widgets/employee_list_view.dart`

- Neuer "Profil öffnen"-Button im Mitarbeiter-Detail-Dialog
- Navigiert zum `EmployeeProfileScreen` (inkl. neuem Kalender-Tab)
- "Bearbeiten"-Button auf OutlinedButton geändert (visuelle Unterscheidung)

---

## Paket-Updates

| Paket | Alt | Neu |
|-------|-----|-----|
| syncfusion_flutter_charts | 26.2.11 | 32.1.23+ |
| syncfusion_flutter_gauges | 26.2.11 | 32.1.23+ |
| syncfusion_flutter_calendar | 26.2.11 | 32.1.23 |
| syncfusion_flutter_datepicker | 26.2.11 | 32.1.23+ |
| syncfusion_flutter_datagrid | 26.2.14 | 32.1.23+ |
| intl | 0.19.0 | 0.20.2 |

**Grund:** Syncfusion 26.x hatte einen `SelectionDetails`-Namenskonflikt mit Flutter 3.35. Ab Version 31.1.20 wurde die Kompatibilität hergestellt.

---

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/vacation/vacation_screen.dart` | +5. Tab, +`_buildCalendarView()`, +`_VacationCalendarDataSource` |
| `lib/features/timesheets/timesheets_screen.dart` | +6. Tab, +`_buildCalendarView()`, +`_TimesheetCalendarDataSource` |
| `lib/features/employees/employee_profile_screen.dart` | +5. Tab, +`_buildCalendarTab()`, +`_EmployeeCalendarDataSource`, Anwesenheitskalender ersetzt |
| `lib/features/employees/widgets/employee_list_view.dart` | +"Profil öffnen"-Button, Import EmployeeProfileScreen |
| `pubspec.yaml` | Syncfusion 26→32, intl 0.19→0.20 |
| `pubspec.lock` | Aktualisierte Abhängigkeiten |
