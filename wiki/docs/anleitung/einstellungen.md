# Einstellungen

## Ueberblick

Die Einstellungen sind in drei Ebenen aufgeteilt:

1. **Persoenlich** — Profil, Theme, PIN
2. **Organisation** — Cloud, Rollen, Teams, Default-Stundenlohn
3. **Sicherheit** — MEK, DEK, Recovery, 2FA

!!! note "Berechtigung"
    Persoenliche Einstellungen aendern: alle Mitarbeiter. Organisationseinstellungen: Admin.

## Persoenlich

### Profil

- Name, E-Mail, Telefon — Stammdaten
- Anzeigename im Chat
- Sprache (de/en — derzeit nur de)

### Theme

- Hell / Dunkel / System
- Akzentfarbe (Organisations-Default kann Admin vorgeben)

### Medi-PIN

Optional ein PIN zur Bestaetigung jeder Medikations-Gabe (siehe [Medikation](medikation.md)). PBKDF2-HMAC-SHA256, 100.000 Iterationen, pro-Mitarbeiter-Salt, Speicherung im sicheren Geraetespeicher (Windows DPAPI, macOS Keychain, iOS Keychain, Android Keystore).

Zugriff: AppBar in der Medikationsgaben-Ansicht → Symbol "PIN". Drei Falscheingaben brechen die Gabe ab.

## Organisation (nur Admin)

### Cloud-Zugang

- HiDrive-Benutzername, App-Passwort
- Alternative Provider: Nextcloud, ownCloud, generischer WebDAV
- Basis-URL (ggf. mit Port)
- Root-Ordner fuer die Organisation

### Rollen

`roles.json` auf HiDrive unter `administration/users/roles.json`. Enthaelt pro Benutzer:

- Rolle (`orgAdmin`, `pvAdmin`, `teamLead`, `teamMember`, `orgAuditor`)
- Teamzuordnung (fuer `teamLead`/`teamMember`)

Aenderungen propagieren beim naechsten Sync-Zyklus. Rollen-Downgrade wird sofort durchgesetzt, Upgrade erst nach Re-Bestaetigung des Team-Keys.

### Einrichtung

- Name, Adresse, USt-ID, Bundesland
- Logo (fuer PDF-Header)
- Standard-Bedarfsinstrument (default aus Bundesland, siehe [Bundeslaender](bundeslaender.md))

### Abrechnung

- Default-Stundenlohn fuer neue Mitarbeiter
- Standard-Lohnkostenzuschlag (fuer Kapazitaetsplanung)
- Jahreskapazitaetsbudget pro Team (Default fuer neue Teams)

## Sicherheit

### Master Encryption Key (MEK)

Organisationsweiter Schluessel fuer die Verschluesselung von Team-Keys. Wird bei erstem Setup erzeugt und geteilt. **Verlust bedeutet Datenverlust** — deshalb Recovery-Codes (s. u.).

### Data Encryption Key (DEK)

Pro-Geraet-Schluessel, abgeleitet vom Login-Passwort via PBKDF2. Rotiert automatisch bei Passwort-Aenderung.

### Recovery-Codes

Bei Setup generiert — 10 Codes, einzeln einloesbar, fuer Passwort-Recovery. **Ausdrucken und sicher verwahren.** Codes werden hashed gespeichert (keine Klartext-Rueckgewinnung).

### Zwei-Faktor-Authentifizierung (TOTP)

Optional. Nutzt RFC 6238 (30s Zeitraster, SHA-1/256). Kompatibel mit allen gaengigen Authenticator-Apps (Google Authenticator, Authy, 1Password, Bitwarden).

### Backup

Automatischer Backup-Lauf alle 24 Stunden. Erzeugt verschluesseltes Envelope (`fegh_backup`) mit allen Organisationsdaten. Ablageort: HiDrive `backup/<timestamp>.fegh.bak`. Wiederherstellung via `RecoveryService`.

## Reset

"Einstellungen zuruecksetzen" stellt nur die UI-Praeferenzen zurueck (Theme, Layout), **nicht** Cloud-Zugaenge, Rollen oder Daten.
