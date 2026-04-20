# Einstellungen

## Ueberblick

Die Einstellungen sind in drei Ebenen aufgeteilt:

1. **Persoenlich** — Profil, Theme, PIN
2. **Organisation** — Cloud, Rollen, Teams, Default-Stundenlohn
3. **Sicherheit** — MEK, DEK, Recovery, 2FA

!!! note "Berechtigung"
    Persoenliche Einstellungen aendern: alle Mitarbeiter. Organisationseinstellungen: Admin.

## Funktionsweise im Detail

### Das Problem, das wir loesen

Die Verwaltungs-App bedient einen grossen Parameterraum:
Mitarbeiter-Defaults (Stundenlohn, Wochenarbeitszeit),
Organisations-Defaults (Bundesland, FLS-Stundensatz), Cloud-
Zugang, Rollen-Policy, Verschluesselungs-Material, Backup-
Strategie, 2FA, Recovery-Codes.

Ohne zentrale Einstellungen landen diese Parameter entweder
verstreut in Feature-Dialogen oder sie werden hardcoded —
beides fuehrt zu Inkonsistenzen und fehleranfaelligen Updates.
Der Settings-Bereich strukturiert das in drei klare Ebenen
(persoenlich / organisation / sicherheit), sodass ein Admin
einmal pflegt und alle Teile der App den aktuellen Stand
sehen.

### Konkretes Szenario: Neue Einrichtung komplett einrichten

**Tag 1 — Admin Anja hat die Verwaltungs-App frisch installiert.**

1. **Einstellungen → Organisation → Cloud-Zugang**: HiDrive
   URL, App-Passwort, Root-Pfad. "Verbindung testen" → gruener Haken.
2. **Einstellungen → Organisation → Einrichtung**: Name "Assistenz
   gGmbH", Adresse, USt-ID, Bundesland Berlin, Logo hochladen.
3. **Einstellungen → Organisation → Abrechnung**: Default-FLS-Stundensatz
   52 EUR, Kalkulationsfaktor 1,33, Jahreskapazitaetsbudget 300.000 EUR
   pro Team.
4. **Einstellungen → Sicherheit → Master Encryption Key**: Key wird
   generiert, Recovery-Codes angezeigt. Anja druckt, versiegelt,
   legt in den Tresor.
5. **Einstellungen → Sicherheit → Backup**: Automatischer Lauf
   alle 24 h aktivieren, Ablageort HiDrive `/backup/`.

**Tag 2 — Rollen-Datei pflegen.**

1. `Einstellungen → Organisation → Rollen (roles.json)`
2. Anja fuegt die Email-Adressen der Teamleitungen als
   `teamLead`-Eintraege ein, sich selbst als `orgAdmin`.
3. Speichern → `roles.json` landet verschluesselt auf HiDrive unter
   `administration/users/roles.json`.

**Tag 3 — Admin-Verifizierung mit 2FA.**

1. `Einstellungen → Sicherheit → 2FA einrichten`
2. QR-Code scannen mit Authenticator-App (Bitwarden),
   Backup-Codes drucken.
3. Einloggen ab jetzt: Passwort + 6-stelliger TOTP-Code.

**Tag 10 — Stundensatz-Anpassung.**

Der Rahmenvertrag mit Sozialamt Friedrichshain-Kreuzberg aktualisiert
den Stundensatz. Anja oeffnet `Einstellungen → Abrechnung → FLS-
Stundensatz`, setzt 54,50 statt 52,00, speichert.

**Was automatisch passiert:**
- Neue Rechnungen ab heute nutzen 54,50
- Bestehende Rechnungen unberuehrt (GoBD)
- Klienten mit `stundensatzOverride` unberuehrt (individuelle
  Vereinbarung bleibt)
- Audit-Event `settings.updated` mit alt/neu

### Drei Ebenen — unterschiedlich persistiert

| Ebene | Wer setzt | Wo gespeichert | Wie verteilt |
|-------|-----------|----------------|--------------|
| Persoenlich | Mitarbeiter | Geraete-lokal (shared_prefs) | nicht verteilt |
| Organisation | Admin | HiDrive unter `administration/` | Cloud-Sync |
| Sicherheit | Admin | z. T. secure_storage (Keys), z. T. HiDrive (Policies) | differenziert |

Persoenliche Einstellungen (Theme, Dashboard-Anordnung) gelten
nur fuer den einen Mitarbeiter auf dem einen Geraet. Organisations-
Einstellungen werden beim naechsten Sync von allen Geraeten der
Organisation gelesen. Sicherheits-Einstellungen sind kritisch:
Keys bleiben lokal und sind kryptographisch geschuetzt; nur die
daraus abgeleiteten Policies (roles.json) wandern in die Cloud.

### Reset und Rollback

"Einstellungen zuruecksetzen" stellt **nur die UI-Praeferenzen**
zurueck — Theme, Dashboard-Layout, Sprach-Auswahl. Cloud-Zugang,
Rollen, Schluesselmaterial und Daten bleiben unangetastet.

Rollback organisationsweiter Aenderungen (z. B. versehentlich einen
falschen FLS-Stundensatz gespeichert): Audit-Log zeigt alt/neu, Admin
setzt den alten Wert manuell zurueck. Historische Rechnungen bleiben
wie sie sind (GoBD-konform).

### Rechtlicher Hintergrund

- **§146 AO / GoBD** — einmal erzeugte Rechnungsdaten duerfen nicht
  rueckwirkend geaendert werden.
- **Art. 32 DSGVO** — angemessene Sicherheit. 2FA und MEK-Recovery
  sind technische-organisatorische Massnahmen.
- **§87 BetrVG** — Betriebsrats-Mitbestimmung bei Zeiterfassungs-
  Defaults, Urlaubstage-Defaults.
- **IT-Sicherheitsgesetz 2.0** — fuer KRITIS-Einrichtungen
  Nachweispflicht ueber Sicherheitsmassnahmen; die Einstellungsseite
  dokumentiert den Stand in einem Screenshot.

## Persoenlich

### Profil

- Name, E-Mail, Telefon — Stammdaten
- Anzeigename im Chat
- Sprache (de/en — derzeit nur de)

### Theme

- Hell / Dunkel / System
- Akzentfarbe (Organisations-Default kann Admin vorgeben)

### Medi-PIN

Optional ein PIN zur Bestaetigung jeder Medikations-Gabe (siehe [Medikation im Doku-Wiki](https://miri2577.github.io/FEGH-Dokumentation/anleitung/medikation/)). PBKDF2-HMAC-SHA256, 100.000 Iterationen, pro-Mitarbeiter-Salt, Speicherung im sicheren Geraetespeicher (Windows DPAPI, macOS Keychain, iOS Keychain, Android Keystore).

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
- Standard-Bedarfsinstrument (default aus Bundesland, siehe [Bundeslaender im Doku-Wiki](https://miri2577.github.io/FEGH-Dokumentation/anleitung/bundeslaender/))

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
