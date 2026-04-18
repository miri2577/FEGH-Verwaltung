# Erste Schritte

FEGH-Verwaltung ist ein Desktop-Admin-Tool und laeuft auf **Windows,
macOS und Linux**. Mobile Plattformen werden nicht unterstuetzt - dafuer
ist die [FEGH-Dokumentation](https://miri2577.github.io/FEGH-Dokumentation/).

## Installation

### Windows

1. Installer aus GitHub Releases herunterladen
2. Ausfuehren - Installation nach `C:\Program Files\FEGH-Verwaltung`
3. Start ueber Startmenue

### macOS

1. DMG aus GitHub Releases herunterladen
2. In Applications ziehen
3. Beim ersten Start: Rechtsklick -> "Oeffnen" (unsignierte App)

### Linux (AppImage oder Flatpak)

1. AppImage herunterladen
2. `chmod +x fegh-verwaltung.AppImage`
3. Ausfuehren

## Erstes Setup

Beim ersten Start fuehrt der Einrichtungs-Assistent durch:

1. **Admin-Zugangsdaten festlegen** - Benutzername und Passwort
2. **Organisation anlegen** - Name, Typ (EGH ambulant, stationaer,
   Mischtraeger)
3. **HiDrive / Nextcloud / ownCloud** - fuer Cloud-Sync mit Doku-App
   konfigurieren (optional, fuer Solo-Betrieb)
4. **Sync-Passphrase** setzen - diese muss in Doku-App **identisch**
   sein, damit beide Apps auf dieselben verschluesselten Daten
   zugreifen koennen
5. **Erste Teams und Mitarbeiter** anlegen

!!! tip "Cross-App-Setup"
    Wenn du **beide Apps** nutzt, richte zuerst die Verwaltung ein,
    lege Organisation + Teams an, und provisioniere dann die
    Mitarbeiter via QR-Code fuer die Doku-App. Siehe
    [Mitarbeiter-Einladung](../admin/einladung.md).

## Ueberblick der Tabs

Die Verwaltung ist in 11 Haupt-Tabs organisiert:

| Tab | Funktion |
|---|---|
| **Dashboard** | KPIs, Live-Trends, Kapazitaetsauslastung |
| **Mitarbeiter** | Stammdaten, Qualifikationen, Dokumente |
| **Teams** | Zusammensetzung, Teamleitungen, Klienten-Zuweisung |
| **Klienten** | Uebersicht (Master-Daten aus Doku-App) |
| **Schichten** | Dienstplanung, Bulk-Zuweisung |
| **Zeiten** | Arbeitszeit-Auswertung |
| **Urlaub** | Antraege, Genehmigungen, Saldenauswertung |
| **ICF/TIB** | Read-Only-Sicht auf Bedarfsermittlungen (Pflege in Doku) |
| **Berichte** | PDF/Excel-Reports ueber Teams und Zeitraeume |
| **Kapazitaet** | Auslastungs-Analytics, Planung |
| **Einstellungen** | Provider-Config, Sync-Passphrase, Backup |

## Schnelleinstieg fuer Admins

Falls du direkt loslegen willst:

1. **Einstellungen > Cloud-Sync** - HiDrive-Credentials + Sync-
   Passphrase setzen
2. **Teams** - erstes Team erstellen
3. **Mitarbeiter** - Mitarbeiter anlegen, Team zuweisen
4. **Admin-Console > Provisioning-QR** - QR-Code fuer Mitarbeiter
   generieren, ausdrucken oder per sicherem Weg uebermitteln
5. Mitarbeiter scannen den QR in ihrer Doku-App ein und sind sofort
   verbunden

## Zusammenspiel mit Doku-App

Siehe [Zusammenspiel](../technik/zusammenspiel.md).
