# Fix: Reports-Sidebar - Breite, Resize & fehlende Funktionen

**Datum:** 23.02.2026
**Bereich:** Berichte & Analytics

---

## Probleme

1. **Sidebar zu schmal** (250px fest) - Texte wie "Monatsbericht" wurden abgeschnitten/umgebrochen
2. **Nicht verschiebbar** - Keine Möglichkeit, die Sidebar-Breite anzupassen
3. **Fehlende Funktionen** im Filter/Optionen-Bereich:
   - `_setExportFormat()` war TODO (Export-Optionen klickbar aber ohne Funktion)
   - `_loadSavedReport()` zeigte nur SnackBar statt Report zu laden
   - Quick-Action-Buttons hatten feste Breite (200px) statt responsive

---

## Änderungen

### `lib/features/reports/reports_screen.dart`

| Änderung | Beschreibung |
|----------|-------------|
| Sidebar-Breite | Standard von 250px auf 320px erhöht |
| Resizable Sidebar | Drag-Handle zwischen Sidebar und Content (260–500px Bereich) |
| State-Management | `_selectedCategory`, `_dateRange`, `_sidebarWidth` als State-Variablen |
| Callbacks | `onCategoryChanged`, `onDateRangeChanged`, `onReportSelected` korrekt verdrahtet |

**Neuer Resize-Mechanismus:**
- `MouseRegion` mit `SystemMouseCursors.resizeColumn` für visuelles Feedback
- `GestureDetector` mit `onHorizontalDragUpdate` für Drag-Resize
- Visueller Drag-Handle (6px breit, zentrierter 2px-Strich)

### `lib/features/reports/widgets/reports_sidebar.dart`

| Änderung | Beschreibung |
|----------|-------------|
| Button-Breite | `SizedBox(width: 200)` → `SizedBox(width: double.infinity)` bei allen 3 Schnellaktions-Buttons |
| `_setExportFormat()` | Erstellt `ReportConfig` mit gewähltem Format und öffnet Export-Dialog via `onReportSelected` |
| `_loadSavedReport()` | Erstellt `ReportConfig` basierend auf Report-Typ und aktuellem Datumsbereich, öffnet Export-Dialog |
| `_mapStringToReportType()` | Neue Hilfsmethode: String-Kategorie → `ReportType` Enum Mapping |

---

## Ergebnis

- Sidebar ist per Drag stufenlos von 260px bis 500px verstellbar
- Alle Buttons nutzen die volle verfügbare Breite (kein Textumbruch mehr)
- Export-Optionen (PDF/Excel/CSV/JSON) öffnen den Export-Dialog
- Gespeicherte Berichte laden den entsprechenden Report-Typ mit aktuellem Datumsbereich
