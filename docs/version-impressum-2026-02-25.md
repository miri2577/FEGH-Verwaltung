# Changelog 2026-02-25 - Versionierung, Impressum & Umbenennung

## Version 0.1.0-alpha.1

### Umbenennung
- App-Titel von "Personalverwaltung - Eingliederungshilfe" zu **FEGH-Verwaltung** geaendert
- Betrifft: Window-Title, MaterialApp title, AppBar, About-Dialog, Settings About-Section

### Versionierung
- Version von `1.0.0+1` auf `0.1.0-alpha.1` gesetzt (semantisch korrekt fuer Pre-Release)
- Statusbar zeigt jetzt `v0.1.0-alpha.1`
- pubspec.yaml description aktualisiert

### Impressum
- **About-Dialog** (Menue > Ueber):
  - App-Name: FEGH-Verwaltung
  - Version: 0.1.0-alpha.1
  - Entwickler: Mirko Richter
  - Copyright: 2025-2026 Mirko Richter. Alle Rechte vorbehalten.
- **Settings About-Section** analog aktualisiert

### Geaenderte Dateien
| Datei | Aenderung |
|-------|-----------|
| `pubspec.yaml` | Version + Description |
| `lib/main.dart` | Window-Title + MaterialApp title |
| `lib/widgets/layouts/main_layout.dart` | AppBar-Titel, About-Dialog, Statusbar-Version |
| `lib/features/settings/settings_screen.dart` | About-Section mit Impressum |
