# Syncfusion-Migration: Alle UI-Komponenten

**Datum:** 22.02.2026
**Ziel:** Professionellere UI durch konsequenten Einsatz von Syncfusion-Widgets

---

## 1. Kapazitäts-Prognose Chart (HOCH)

**Datei:** `lib/features/capacity/widgets/capacity_forecast_chart.dart`
**Vorher:** `CustomPaint` mit `ForecastChartPainter` (~100 Zeilen manuelle Zeichenlogik)
**Nachher:** `SfCartesianChart` mit `SplineAreaSeries`

- Farbige Kapazitätszonen (Kritisch/Warnung/Optimal) als `PlotBand`
- Datenpunkte mit `MarkerSettings`
- Interaktive Tooltips beim Hovern
- `ForecastChartPainter` Klasse entfällt komplett

---

## 2. Workload-Verteilung Donut-Chart (HOCH)

**Datei:** `lib/features/capacity/widgets/workload_distribution_chart.dart`
**Vorher:** `CustomPaint` mit `WorkloadDistributionPainter` (~100 Zeilen manuelle Donut-Zeichnung)
**Nachher:** `SfCircularChart` mit `DoughnutSeries`

- Automatische Labels mit `DataLabelSettings`
- Interaktive Legende
- `WorkloadDistributionPainter` Klasse + `cos()`/`sin()` Hilfsfunktionen entfallen
- Manuelle Legend-Widgets durch Syncfusion `Legend` ersetzt

---

## 3. Dashboard Leistungsverteilung (HOCH)

**Datei:** `lib/features/dashboard/dashboard_screen.dart`
**Vorher:** `fl_chart` `PieChart` für Service-Verteilung
**Nachher:** `SfCircularChart` mit `DoughnutSeries`

- `fl_chart`-Import und `_buildPieSections()` entfallen
- FLS-Balken: `LinearProgressIndicator` → `SfLinearGauge` mit Farbzonen
- Konsistentes Design mit den anderen Syncfusion-Charts

---

## 4. Team-Kapazität Fortschrittsanzeigen (HOCH)

**Datei:** `lib/features/capacity/widgets/team_capacity_grid.dart`
**Vorher:** `LinearProgressIndicator` für Kapazitätsanzeige
**Nachher:** `SfLinearGauge` mit farbigen Bereichen (Rot/Orange/Grün)

- Marker für aktuellen Wert
- Beschriftete Farbzonen zeigen Schwellenwerte
- Professionellere Visualisierung der Auslastung

---

## 5. Schichtkalender (HOCH)

**Datei:** `lib/features/shifts/widgets/shift_calendar_widget.dart`
**Vorher:** Custom Widget mit manueller Tag/Woche/Monat-Implementierung (629 Zeilen)
**Nachher:** `SfCalendar` mit `CalendarView.day/week/month`

- Appointments aus Shift-Daten generiert
- Farbkodierung nach Schichttyp
- Eingebaute Navigation und View-Wechsel
- Tap-Events für Shift-Details
- **Anpassung `shift_planning_screen.dart`:** Toolbar und View-Steuerung vereinfacht

---

## 6. DateRangePicker in Reports-Sidebar (MITTEL)

**Datei:** `lib/features/reports/widgets/reports_sidebar.dart`
**Vorher:** `showDateRangePicker()` (Flutter Standard)
**Nachher:** `SfDateRangePicker` inline eingebettet

- Visueller Kalender direkt in der Sidebar sichtbar
- Schnellauswahl-Chips bleiben erhalten
- Kein Dialog-Popup mehr nötig

---

## 7. DataGrid-Erweiterungen (MITTEL)

**Dateien:** Alle `*_list_view.dart` + `shifts_screen.dart`
**Vorher:** SfDataGrid ohne Sorting/Filtering
**Nachher:** SfDataGrid mit `allowSorting: true`, `allowFiltering: true`

- Spaltenüberschriften klickbar zum Sortieren
- Filter-Icons in Spaltenköpfen
- Eingebaute Suchfunktion pro Spalte

---

## 8. KPI-Sparklines im Dashboard (NIEDRIG)

**Datei:** `lib/features/dashboard/dashboard_screen.dart`
**Vorher:** Nur Zahlenwert + Subtitle in KPI-Cards
**Nachher:** `SfSparkLineChart` als Trend-Indikator in jeder KPI-Card

- Kleine Trendlinie zeigt Verlauf
- Benötigt historische Daten (Placeholder mit Beispieldaten)

---

## Neue Syncfusion-Pakete

```yaml
# Bereits installiert:
syncfusion_flutter_charts: ^26.2.11
syncfusion_flutter_datagrid: ^26.2.14

# Neu hinzuzufügen:
syncfusion_flutter_gauges: ^26.2.11
syncfusion_flutter_calendar: ^26.2.11
syncfusion_flutter_datepicker: ^26.2.11
```

## Zu entfernende Pakete

```yaml
# Kann entfernt werden nach Migration:
fl_chart: ^0.68.0  # Ersetzt durch syncfusion_flutter_charts
```

---

## Betroffene Dateien (Übersicht)

| # | Datei | Änderung |
|---|-------|----------|
| 1 | `capacity_forecast_chart.dart` | CustomPaint → SfCartesianChart |
| 2 | `workload_distribution_chart.dart` | CustomPaint → SfCircularChart |
| 3 | `dashboard_screen.dart` | fl_chart PieChart → SfCircularChart, LinearProgressIndicator → SfLinearGauge, + Sparklines |
| 4 | `team_capacity_grid.dart` | LinearProgressIndicator → SfLinearGauge |
| 5 | `shift_calendar_widget.dart` | Custom 629-Zeilen → SfCalendar |
| 6 | `shift_planning_screen.dart` | Anpassung an SfCalendar-API |
| 7 | `reports_sidebar.dart` | showDateRangePicker → SfDateRangePicker |
| 8 | `*_list_view.dart` (4 Dateien) | +allowSorting, +allowFiltering |
| 9 | `shifts_screen.dart` | +allowSorting, +allowFiltering |
| 10 | `pubspec.yaml` | Neue Pakete + fl_chart entfernen |
