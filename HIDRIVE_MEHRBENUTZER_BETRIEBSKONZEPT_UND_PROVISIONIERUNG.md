# HiDrive Mehrbenutzer – Betriebsmodell A und Provisionierung per QR

Stand: 2025‑09‑30

## Zielbild (Modell A – empfohlen)

- Jeder Mitarbeiter besitzt einen eigenen HiDrive‑Benutzer (Login + App‑Passwort).
- Die App arbeitet über WebDAV auf einem gemeinsamen Organisations‑Ordner (Team‑Ordner).
- Rollen und Teambereiche werden serverseitig über `roles.json` festgelegt.
- Erstinbetriebnahme auf Mobilgeräten erfolgt per Provisionierungs‑QR aus der Personalverwaltung.
- Team‑Leads dürfen nur in ihren Teams schreiben; Dokumentation (ICF/TIB) ist nur für Team‑Leads sichtbar (Auditor optional).

## HiDrive Vorbereitung

1) Gemeinsamen Ordner anlegen (nicht „public“/„privat“)
- HiDrive Admin → Verwaltung → Gemeinsame Ordner → Neu, z. B. „Eingliederungshilfe“.
- Darunter wird (manuell oder von der App) die Struktur angelegt:
  - `eingliederungshilfe/organizations/<org>/administration/...`
  - `eingliederungshilfe/organizations/<org>/teams/<teamId>/clients/...`

2) Nutzerrechte setzen (Richtwert)
- Admins (org_admin/pv_admin): RW auf `administration` und alle `teams/*`
- Team‑Lead: RW nur auf `teams/<eigene>/*` (je nach HiDrive‑Rechtesystem pro Teamordner setzen)
- Team‑Member: R nur auf `teams/<eigene>/*`
- Auditor (optional): R auf alles

3) Mount‑Pfad prüfen
- Der gemeinsame Ordner erscheint bei Mitarbeitern oft unter einem Unterordner wie „Gemeinsam/…“, „Teamfreigaben/…“.
- Diesen relativen Pfad merken (z. B. `Gemeinsam/Eingliederungshilfe`).

4) Protokolle
- Beim Nutzer unter „Zugriffsrechte und Protokolle“ WebDAV aktivieren.

Wichtig: Die App legt KEINE HiDrive‑Benutzer an. Benutzer und deren App‑Passwörter müssen im HiDrive‑Adminbereich erstellt werden.

## App‑Einstellungen (Personalverwaltung)

- Org‑ID setzen (muss zur Ordnerstruktur passen).
- Cloud‑Sync aktivieren.
- Root‑Unterordner (optional): den Mount‑Pfad aus HiDrive eintragen, z. B. `Gemeinsam/Eingliederungshilfe`.
  - Dadurch nutzt die App nicht mehr „Privat“, sondern genau den gemeinsamen Ordner als Wurzel.
- Health (Admin‑Konsole → „Health“): Administration/Teams/Schreibrechte/roles.json sollten grün sein.

## Rollen‑Policy (`roles.json`)

- Pfad: `eingliederungshilfe/organizations/<org>/administration/users/roles.json`
- Administration: In der App unter Admin‑Konsole → Tab „Tools“ → „Rollen‑Policy (roles.json)“ (Editor zum Laden/Speichern)
- Beispiele und UI‑Auswirkungen je Rolle siehe `ROLES_POLICY_BEISPIEL.md`.

Kurzbeispiel:
```
{
  "users": [
    { "id": "admin@example.org", "role": "org_admin", "teams": ["team-a","team-b"] },
    { "id": "lead.ambulant@example.org", "role": "team_lead", "teams": ["team-ambulant-sued"] },
    { "id": "mitarbeiter@example.org", "role": "team_member", "teams": ["team-ambulant-sued"] }
  ]
}
```

## Team‑Lead‑Scope und Dokumentation

- Team‑Lead Schreibrechte: Team‑Leads dürfen Klienten nur in den Teams anlegen/bearbeiten, die in `roles.json.teams` stehen.
  - Löschen und Teamwechsel bleiben Admin‑only.
- Dokumentation (ICF/TIB): Nur Team‑Leads sehen diesen Bereich (Admins bewusst ausgeschlossen).
  - Optionaler Schalter in Einstellungen: „Auditor darf Dokumentation lesen“.

Technische Referenzen:
- Team‑Lead‑Scope: `lib/services/policy_service.dart`
- Doku‑Guard: `lib/features/icf/icf_screen.dart`
- Settings‑Schalter: `auditorCanViewDocs` in `AppSettings` + UI in Settings‑Screen

## Provisionierung per QR (Mitarbeiter)

Ziel: Einmal‑QR richtet HiDrive‑Zugang, Org, Rolle, Teams und Team‑Keys automatisch ein und startet den Erst‑Sync.

1) QR erzeugen (Personalverwaltung)
- Admin‑Konsole → Tab „Tools“ → „Mitarbeiter provisionieren (QR)“
- Eingeben: HiDrive‑Login (E‑Mail/Benutzer), Rolle, Teams, optional App‑Passwort
- Die App:
  - aktualisiert/schreibt `roles.json` (Rolle + Teams der Person)
  - stellt Team‑Keys sicher (`team-key.bin`) und packt sie in die QR‑Payload
  - erzeugt QR (PNG) und zeigt die JSON‑Payload an

2) QR‑Payload (Beispiel)
```
{
  "type": "egh-provisioning-v1",
  "org": "dasi",
  "user": "max.mustermann@example.org",
  "role": "team_member",
  "teams": ["team-ambulant-sued"],
  "teamKeys": { "team-ambulant-sued": "BASE64_TEAMKEY" },
  "hidrive": { "username": "max.mustermann@example.org", "appPassword": "<optional>" },
  "flags": { "managed": true, "hideCredentials": true, "forceInitialSync": true },
  "ts": "2025-09-30T12:34:56Z"
}
```
Hinweise:
- Verwende App‑Passwörter von HiDrive (pro Mitarbeiter rotierbar).
- QR mit kurzer Gültigkeit und Einmalnutzung behandeln (operativ). 

3) Onboarding (Mobilgerät)
- App → „QR scannen zur Ersteinrichtung“ (Implementierung in der Mobil‑App)
- App setzt HiDrive‑Zugang (Managed Mode), Org‑ID, Rolle, Teams, Team‑Keys
- Erst‑Sync läuft automatisch, danach ist die App nutzbar

## End‑to‑End Checkliste

1) HiDrive
- Gemeinsamen Ordner angelegt
- Nutzerrechte gemäß Matrix gesetzt
- WebDAV aktiv, Mount‑Pfad notiert (z. B. `Gemeinsam/Eingliederungshilfe`)

2) App (PV)
- Org‑ID und Cloud‑Sync aktiv
- Root‑Unterordner eingetragen
- `roles.json` gepflegt
- Health‑Tab grün

3) Provisionierung
- Provisionierungs‑QR je Mitarbeiter erzeugt und gescannt
- Mobilgerät synchronisiert, sieht eigene Team‑Klienten

## Troubleshooting

- Nur „public“ sichtbar / alles landet unter „Privat“:
  - Es existiert kein gemeinsamer Ordner mit Rechten für den Nutzer. Unter Verwaltung → Gemeinsame Ordner einen Ordner anlegen, Nutzer zuweisen. Den Mount‑Pfad in der App als Root‑Unterordner eintragen.
- Rollen greifen nicht:
  - `roles.json` prüfen (id exakt wie HiDrive‑Login, lowercase). In der App „Rollen‑Policy aktualisieren“.
- Team‑Lead kann nicht schreiben:
  - Ist das Zielteam in `roles.json.teams` enthalten? Hat der Nutzer HiDrive‑Schreibrechte auf den Teamordner?
- Doku nicht sichtbar:
  - Nur Team‑Leads (optional Auditor per Settings). Admins absichtlich ausgeschlossen.

## Hinweise

- Die App verwaltet keine HiDrive‑Benutzer. Nutzer werden im HiDrive‑Adminbereich angelegt.
- Für initiale Struktur kann in der App der AppBar‑Sync („Admin‑Sync“) genutzt werden.
- Weitere Details zu Rollen und UI: `ROLES_POLICY_BEISPIEL.md`.

## Rollen‑Matrix (Überblick)

| Rolle         | Admin‑Konsole | Teams verwalten | Klienten anlegen | Klienten bearbeiten | Klienten löschen | Team‑Wechsel | ICF/TIB sehen | ICF/TIB bearbeiten | Index‑Rebuild | Team‑Key/QR |
|---------------|---------------|-----------------|------------------|---------------------|------------------|--------------|---------------|---------------------|---------------|-------------|
| org_admin     | Ja            | Ja              | Ja               | Ja                  | Ja               | Ja           | Nein          | Nein                | Ja            | Ja          |
| pv_admin      | Ja            | Ja              | Ja               | Ja                  | Ja               | Ja           | Nein          | Nein                | Ja            | Ja          |
| org_auditor   | Ja (Read)     | Nein            | Nein             | Nein                | Nein             | Nein         | Optional      | Nein                | Nein          | Nein        |
| team_lead     | Eingeschränkt | Nein            | Nur eigene Teams | Nur eigene Teams    | Nein             | Nein         | Ja            | Ja                  | Nein          | Nein        |
| team_member   | Nein          | Nein            | Nein             | Nein                | Nein             | Nein         | Nein          | Nein                | Nein          | Nein        |

Hinweise:
- „Nur eigene Teams“ wird über `roles.json.teams` erzwungen und HiDrive‑Rechte sollten dies zusätzlich absichern.
- Admins sehen die Dokumentation absichtlich nicht (Datensparsamkeit). Auditoren können per Settings‑Schalter Leserechte erhalten.

## UI‑Hinweise / Screenshots (Beschreibung)

- Einstellungen (PV):
  - Felder „HiDrive Benutzername/Passwort“, „Organisation/Träger ID“, „Root‑Unterordner (optional)“
  - Schalter: „Auditor darf Dokumentation lesen“
  - Buttons: „Verbindung testen“, „Admin‑Konsole“, „Clients‑Index neu aufbauen“
- Admin‑Konsole → Tools:
  - Rollen‑Editor (roles.json Laden/Speichern) mit JSON‑Textfeld
  - „Mitarbeiter provisionieren (QR)“: E‑Mail, Rolle, Teams, optional App‑Passwort → QR‑Bild + Payload
  - „Team‑Key als QR“
- Admin‑Konsole → Health:
  - Prüft Administration/Teams erreichbar, Schreibrechte, `roles.json` vorhanden

