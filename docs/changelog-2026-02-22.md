# Changelog 22.02.2026 - Report Builder Vorschau & Listenansicht

## Report Builder: Live-Vorschau im Preview-Panel

**Datei:** `lib/features/reports/widgets/report_builder.dart`

### Vorher
Das rechte Panel zeigte nur ein Platzhalter-Icon mit Report-Name und Metadaten. Keine echte Datenvorschau.

### Nachher
- **Header**: Report-Name, Typ (z.B. Zeiterfassung), Format (PDF/Excel/CSV/JSON), Zeitraum
- **Live-DataTable**: Zeigt echte Daten aus den Providern basierend auf dem gewählten Report-Typ:
  - `Zeiterfassung` / `Schichten` -> Schicht-Daten mit Mitarbeiternamen aufgelöst
  - `Mitarbeiter` -> Mitarbeiterdaten (Name, Position, Abteilung, etc.)
  - `Anwesenheit` / `Lohnabrechnung` / `Urlaub` -> Aggregierte Beispieldaten pro Mitarbeiter
  - Andere Typen -> Generische Kategorien-Ansicht
- **Max. 10 Zeilen** mit Hinweis "... und X weitere Datensätze"
- **Footer**: Zusammenfassung (Anzahl Datensätze, Spalten, Mitarbeiter)
- **Fullscreen-Dialog**: "Vorschau"-Button öffnet scrollbare Vollbild-Tabelle

### Neue Imports
- `models/shift.dart`
- `providers/shift_provider.dart`
- `providers/client_provider.dart`

### Neue Methoden
- `_getPreviewData()` - Liefert Vorschaudaten je nach Report-Typ
- `_getTotalDataCount()` - Gesamtanzahl der Datensätze
- `_previewReport()` - Öffnet Fullscreen-Dialog (ersetzt SnackBar-Platzhalter)

---

## Listenansicht (Tabellen-Toggle) in allen 4 Haupt-Tabs

Alle Tabs haben jetzt einen `SegmentedButton` im Header zum Umschalten zwischen Grid- und Tabellenansicht.

### 2a. Klienten

**Dateien:**
- `lib/features/clients/clients_screen.dart`
- `lib/features/clients/widgets/client_list_view.dart`

**Änderungen:**
- `_isTableView` State + SegmentedButton im Header (clients_screen.dart)
- Neuer Parameter `bool isTableView` in `ClientListView`
- Neue Methode `_buildClientTable()` mit DataTable

**Tabellen-Spalten:** Name | Status | Prioritat | Hilfe-Typ | FLS | Kostentrager | Aktionen

### 2b. Teams

**Dateien:**
- `lib/features/teams/teams_screen.dart`
- `lib/features/teams/widgets/team_list_view.dart`

**Änderungen:**
- `TeamsScreen`: ConsumerWidget -> ConsumerStatefulWidget (fuer _isTableView State)
- SegmentedButton im Header
- Neuer Parameter `bool isTableView` in `TeamListView`
- Neue Methode `_buildTeamTable()` mit DataTable

**Tabellen-Spalten:** Team | Abteilung | Status | Mitglieder | Standort | Aktionen

### 2c. Mitarbeiter

**Dateien:**
- `lib/features/employees/employees_screen.dart`
- `lib/features/employees/widgets/employee_list_view.dart`

**Änderungen:**
- `EmployeesScreen`: ConsumerWidget -> ConsumerStatefulWidget (fuer _isTableView State)
- SegmentedButton im Header
- Neuer Parameter `bool isTableView` in `EmployeeListView`
- Neue Methode `_buildEmployeeTable()` mit DataTable

**Tabellen-Spalten:** Name | Nr. | Position | Abteilung | Status | Std/Woche | Stundenlohn | Aktionen

### 2d. Schichten

**Datei:** `lib/features/shifts/shifts_screen.dart`

**Änderungen:**
- `_isTableView` State + SegmentedButton im Header
- Neuer Import: `employee_provider.dart` (fuer Mitarbeiternamen-Aufloesung)
- Neue Methoden: `_buildShiftsTable()`, `_getShiftStatusLabel()`, `_getShiftTypeLabel()`
- Tabellen-Aktionen kontextsensitiv: Start-Button nur bei "Geplant", Stop-Button nur bei "Aktiv"

**Tabellen-Spalten:** Mitarbeiter | Datum | Zeit | Typ | Status | Geplant (h) | Ist (h) | Aktionen

---

## Betroffene Dateien (Zusammenfassung)

| # | Datei | Art der Aenderung |
|---|-------|-------------------|
| 1 | `lib/features/reports/widgets/report_builder.dart` | Live-DataTable-Vorschau, Fullscreen-Dialog |
| 2 | `lib/features/clients/clients_screen.dart` | +_isTableView, +SegmentedButton |
| 3 | `lib/features/clients/widgets/client_list_view.dart` | +isTableView Parameter, +_buildClientTable() |
| 4 | `lib/features/teams/teams_screen.dart` | ConsumerWidget -> ConsumerStatefulWidget |
| 5 | `lib/features/teams/widgets/team_list_view.dart` | +isTableView Parameter, +_buildTeamTable() |
| 6 | `lib/features/employees/employees_screen.dart` | ConsumerWidget -> ConsumerStatefulWidget |
| 7 | `lib/features/employees/widgets/employee_list_view.dart` | +isTableView Parameter, +_buildEmployeeTable() |
| 8 | `lib/features/shifts/shifts_screen.dart` | +_isTableView, +_buildShiftsTable(), +employee_provider Import |
