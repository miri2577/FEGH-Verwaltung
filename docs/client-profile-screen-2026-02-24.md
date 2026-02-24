# Klienten-Profilseite mit Dokumenten & Berichten

**Datum:** 2026-02-24

## Zusammenfassung

Implementierung einer dedizierten Klienten-Profilseite als Ersatz fuer den bisherigen einfachen AlertDialog. Analog zum Mitarbeiter-Profil bietet die neue Seite eine umfassende Darstellung aller Klientendaten ueber 4 Tabs hinweg, inklusive Dokumentenverwaltung und PDF-Export.

## Neue Dateien

### 1. `lib/models/client_document.dart`
- Datenmodell fuer Klienten-Dokumente
- Felder: id, clientId, name, fileName, category, filePath, uploadedAt, fileSize
- Methoden: toJson(), fromJson(), copyWith(), formattedSize (Getter)
- Analog zu `EmployeeDocument`, aber mit `clientId` statt `employeeId`

### 2. `lib/providers/client_document_provider.dart`
- `clientDocumentsProvider` - StateNotifierProvider fuer alle Klienten-Dokumente
- `documentsByClientProvider` - Family-Provider, filtert nach clientId
- `ClientDocumentsNotifier` - Verwaltet Dokumente mit:
  - Dateispeicherung unter `~/Documents/personalverwaltung/client_documents/{clientId}/`
  - JSON-Index-Datei fuer Metadaten
  - `addDocument()` - Kopiert Datei und erstellt Index-Eintrag
  - `deleteDocument()` - Loescht Datei und Index-Eintrag
  - `refresh()` - Laedt Index neu

### 3. `lib/features/clients/widgets/client_documents_card.dart`
- ConsumerWidget zur Anzeige und Verwaltung von Klienten-Dokumenten
- 4 klientenspezifische Kategorien:
  - **Bescheide & Bewilligungen** (Symbols.gavel, blau) - Kostenzusagen, Bescheide
  - **Berichte & Dokumentation** (Symbols.summarize, gruen) - Informationsberichte, Verlaufsberichte
  - **Teilhabeplanung** (Symbols.track_changes, orange) - TIB-Dokumente, ICF-Einschaetzungen
  - **Sonstige Dokumente** (Symbols.description, lila)
- Features: Upload via FilePicker, Anzeigen via url_launcher, Loeschen mit Bestaetigungsdialog
- Dateityp-Icons (PDF, DOC, XLS, Bilder)
- Relative Zeitanzeige (Heute, Gestern, vor X Tagen/Wochen/Monaten)

### 4. `lib/features/clients/client_profile_screen.dart`
- ConsumerStatefulWidget mit TabController (4 Tabs)

#### Tab 1 - Profil
- **Info-Card**: Initialen-Avatar, Name, Alter, Status-Badge, Prioritaet-Badge, Service-Chips
- **Persoenliche Daten**: Geburtsdatum, E-Mail, Telefon, Adresse, Versicherungsnr., Notfallkontakt
- **Eingliederungshilfe-Card**: Hilfe-Typ, FLS mit Fortschrittsbalken (farbcodiert: gruen/orange/rot), Kostentraeger, Kostenuebernahme-Zeitraum, Betreuung seit, Kalkulationsfaktor, Stundensatz
- **Zuweisungen-Card**: Zustaendiger MA, Vertretung 1+2, Case Manager, alle zugewiesenen MA als Chips (Namen aus employeesProvider aufgeloest)

#### Tab 2 - Dokumente
- Einbettung des ClientDocumentsCard Widgets

#### Tab 3 - Teilhabe
- **ICF-Bereiche**: Als farbige Chips dargestellt
- **Allgemeine TIB-Ziele**: Nummerierte Liste mit Kreis-Nummern
- **Individuelle TIB-Ziele**: Liste mit Haekchen-Icons
- **Notizen-Card**: Freitextanzeige

#### Tab 4 - Uebersicht
- **FLS-Verbrauchsuebersicht**: Fortschrittsbalken + 3 Metrik-Tiles (Bewilligt, Verbraucht, Verfuegbar)
- **Kostenuebernahme-Info**: Kostentraeger, Von/Bis, Restlaufzeit in Tagen (farbcodiert: rot <30, orange <90, gruen >=90)
- **Case Manager Info**
- **Zeitstempel**: Erstellt/Aktualisiert mit Datum und Uhrzeit

#### AppBar
- Klientenname als Titel
- Bearbeiten-Button (nur bei Berechtigung via Policy)
- PopupMenu: Profil exportieren (PDF), Profil drucken, Archivieren/Aktivieren

#### PDF-Export
- Vollstaendige Profil-Zusammenfassung auf A4
- Sektionen: Persoenliche Daten, Eingliederungshilfe, Zuweisungen, ICF-Bereiche, TIB-Ziele, Notizen
- Export via `Printing.sharePdf()` und Drucken via `Printing.layoutPdf()`

## Geaenderte Dateien

### `lib/features/clients/widgets/client_list_view.dart`
- **Vorher**: `_showClientDetails()` zeigte einen AlertDialog mit Textinfos
- **Nachher**: `_showClientDetails()` navigiert via `Navigator.push()` zum `ClientProfileScreen`
- Import fuer `ClientProfileScreen` hinzugefuegt
- Sowohl Grid-View (ClientCard.onTap) als auch Table-View (onCellTap) oeffnen das Profil

## Architektur

```
client_list_view.dart
  └── onTap → Navigator.push(ClientProfileScreen)
        ├── Tab Profil
        │     ├── Info-Card (Avatar, Badges, Chips)
        │     ├── Persoenliche Daten Card
        │     ├── Eingliederungshilfe Card (FLS-Fortschrittsbalken)
        │     └── Zuweisungen Card (MA-Namen via employeesProvider)
        ├── Tab Dokumente
        │     └── ClientDocumentsCard
        │           └── clientDocumentsProvider / documentsByClientProvider
        │                 └── Dateisystem: ~/Documents/personalverwaltung/client_documents/{clientId}/
        ├── Tab Teilhabe
        │     ├── ICF-Bereiche (Chips)
        │     ├── Allgemeine TIB-Ziele (Liste)
        │     ├── Individuelle TIB-Ziele (Liste)
        │     └── Notizen
        └── Tab Uebersicht
              ├── FLS-Verbrauch (Metriken)
              ├── Kostenuebernahme (Restlaufzeit)
              ├── Case Manager
              └── Zeitstempel
```

## Wiederverwendete Patterns
- Model-Struktur identisch zu `EmployeeDocument`
- Provider-Pattern identisch zu `EmployeeDocumentsNotifier`
- Widget-Struktur identisch zu `EmployeeDocumentsCard`
- Screen-Struktur analog zu `EmployeeProfileScreen` (TabController, PDF-Export, AppBar-Actions)
- Gleiche Packages: file_picker, url_launcher, pdf, printing, path_provider
