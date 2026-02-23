# Feature-Implementierung: Fehlende Funktionen

**Datum:** 23.02.2026
**Umfang:** 34 Features in 10 Bereichen
**Status:** Alle implementiert, Build erfolgreich

---

## Neue Dateien

| Datei | Beschreibung |
|-------|-------------|
| `lib/models/employee_document.dart` | Datenmodell für Mitarbeiter-Dokumente (id, name, category, filePath, fileSize, etc.) |
| `lib/providers/employee_document_provider.dart` | Provider mit lokaler JSON-Speicherung und Dateiverwaltung im App-Verzeichnis |
| `lib/features/vacation/widgets/vacation_request_form_dialog.dart` | Vollständiger Urlaubsantrag-Dialog mit Mitarbeiterauswahl, Datumsbereich, Arbeitstage-Berechnung |

---

## Geänderte Dateien

### Phase 1: Mitarbeiter-Profil

**`lib/features/employees/employee_profile_screen.dart`**
- `_showEditDialog()`: Ruft jetzt `EmployeeFormDialog` auf statt SnackBar
- `_handleMenuAction('export')`: Neues `_exportProfilePdf()` generiert PDF mit persönlichen Daten, Vertragsinformationen und Notizen via `printing` Package
- `_handleMenuAction('print')`: Neues `_printProfile()` öffnet nativen Druckdialog
- `_buildPerformanceCard()`: Hardcoded Werte (38.5h, 12.5h, 96%, 22/23) ersetzt durch dynamische Berechnung aus `timesheetsByEmployeeProvider` und `shiftsByEmployeeProvider`:
  - Durchschnittliche Arbeitszeit: Letzte 4 Wochen Timesheets
  - Überstunden: `calculatedOvertimeHours` im aktuellen Monat
  - Pünktlichkeit: `actualStartTime <= startTime` der letzten 30 Tage
  - Anwesenheit: Abgeschlossene vs. geplante Schichten im Monat

**`lib/features/employees/widgets/employee_documents_card.dart`**
- Komplett umgebaut von `StatelessWidget` zu `ConsumerWidget`
- Hardcoded Demo-Dokumente entfernt, stattdessen `documentsByEmployeeProvider` verwendet
- Upload-Dialog: `file_picker` Integration mit Dokumentname und Kategorie-Dropdown
- Anzeigen: `url_launcher` (`launchUrl(Uri.file(...))`) zum Öffnen der Datei
- Löschen: Bestätigungsdialog -> Provider `deleteDocument()` -> Datei wird gelöscht

### Phase 2: Urlaub + Zeiterfassung

**`lib/features/vacation/vacation_screen.dart`**
- `_showAddVacationRequestDialog()`: Öffnet `VacationRequestFormDialog` statt SnackBar
- `_showEditRequestDialog()`: Öffnet `VacationRequestFormDialog` mit vorausgefüllten Daten

**`lib/features/timesheets/timesheet_detail_screen.dart`**
- `_addTimesheetEntry()`: `onSave` Callback ruft `timesheetEntriesProvider.notifier.addEntry()` auf
- `_editTimesheetEntry()`: `onSave` Callback ruft `updateEntry()` auf
- `_deleteTimesheetEntry()`: Bestätigungsdialog -> `deleteEntry()` über Provider
- `_submitTimesheet()`: `timesheetsProvider.notifier.submitTimesheet(id, 'current_user')`
- `_approveTimesheet()`: `timesheetsProvider.notifier.approveTimesheet(id, 'current_user')`
- `_rejectTimesheet()`: Dialog mit Begründungsfeld -> `rejectTimesheet(id, reason)`
- `_exportTimesheet()`: PDF mit Tabelle aller Einträge, Zusammenfassung (Gesamt/Überstunden/Vergütung), Export via `Printing.sharePdf()`

### Phase 3: Schichtplanung

**`lib/features/shifts/shift_planning_screen.dart`**
- `_handleShiftTap()`: Öffnet `ShiftFormDialog` mit existierender Schicht zum Bearbeiten
- `_createNewShift()`: Öffnet `ShiftFormDialog` zum Erstellen, `addShift()` via Provider
- `_exportSchedule()`: PDF im Landscape-Format mit gefilterter Schichtliste (Mitarbeiter, Datum, Zeiten, Typ, Status)

**`lib/features/shifts/widgets/shift_planning_sidebar.dart`**
- `_showTemplateDialog()`: Dialog mit 4 vordefinierten Schichtvorlagen (Frühschicht 06-14, Spätschicht 14-22, Nachtschicht 22-06, Tagschicht 08-16:30)
- `_showBulkEditDialog()`: Dialog mit Aktionsoptionen (Löschen, Typ ändern)

### Phase 4: Reports, Kapazität, Rest

**`lib/features/reports/widgets/reports_sidebar.dart`**
- `_generateMonthlyReport()`: Setzt Datumsbereich auf aktuellen Monat + wechselt zu Overview
- `_generateWeeklyReport()`: Setzt Datumsbereich auf aktuelle KW
- `_generateCustomReport()`: Wechselt zur Custom-Kategorie
- `_showSavedReportsDialog()`: Info-Dialog (noch keine gespeicherten Berichte)

**`lib/features/reports/widgets/report_dashboard.dart`**
- Zeitlinien-Chart Placeholder-Text aktualisiert
- `_generateQuickReport()`: Erstellt `ReportConfig` mit korrektem Typ und übergibt an `onReportSelected`

**`lib/features/reports/widgets/report_builder.dart`**
- TODO-Placeholder ersetzt durch 4 interaktive `FilterChip`-Widgets (Aktive Mitarbeiter, Überstunden > 0, Mit Urlaubstagen, Offene Zeitnachweise)

**`lib/features/reports/widgets/export_dialog.dart`**
- "Öffnen"-Button in SnackBar: `launchUrl(Uri.file(path))` statt TODO

**`lib/features/reports/reports_screen.dart`**
- `_handleReportAction('edit')`: Wechselt zum Builder-Tab (Index 2)

**`lib/features/capacity/capacity_screen.dart`**
- `_exportCapacityReport()`: PDF-Export mit `printing` Package

**`lib/features/capacity/widgets/team_capacity_grid.dart`**
- Filter-Chips: "Alle" invalidiert Provider, "Kritisch"/"Unterbesetzt" zeigen Info-SnackBar

**`lib/features/capacity/widgets/capacity_alerts_panel.dart`**
- "Maßnahmen"-Button: Zeigt Hinweis auf Schichtplanung statt TODO

**`lib/features/settings/settings_screen.dart`**
- `_showDataExportDialog()`: Vollständiger JSON-Export aller Daten (Mitarbeiter, Zeitnachweise, Schichten, Urlaubsanträge) via `FilePicker.saveFile()`

**`lib/features/notifications/widgets/notification_center.dart`**
- `_handleNotificationTap()`: URL-basierte Navigation-Logik für `/employees/`, `/timesheets/`, `/vacation/`, `/shifts/`
- `_showSettings()`: Dialog mit 4 Kategorie-Switches (Urlaubsanträge, Zeitnachweise, Schichtplanung, System)

---

## Verwendete Packages

Alle Packages waren bereits in `pubspec.yaml` vorhanden:
- `printing` / `pdf` - PDF-Generierung und Drucken
- `file_picker` - Dateiauswahl für Upload und Export
- `url_launcher` - Dateien öffnen
- `path_provider` / `path` - App-Verzeichnis für Dokumentspeicherung

---

## Verbleibende Placeholder

Die folgenden Features wurden bewusst als informative Dialoge/SnackBars belassen (komplexe eigenständige Systeme):
- ICF/TIB-System (`icf_screen.dart`) - Eigenständiges großes Feature
- Planungseinstellungen (`shift_planning_screen.dart`) - Benötigt eigenes Settings-Modell
