# Rollen‑Policy (roles.json) – Beispiel und Vorgehen

Stand: 2025‑09‑30

## Zweck

Die App liest die Benutzer‑Rollen aus der Datei `roles.json` in HiDrive:

`/users/<hidrive-user>/eingliederungshilfe/organizations/<org>/administration/users/roles.json`

Je nach Eintrag startet die App mit der zugewiesenen Rolle (RBAC). Ohne `roles.json` nutzt die App vorübergehend die lokal eingestellte Rolle aus den Einstellungen (Fallback), bis die Policy geladen wird.

## Schema (vereinfachter Überblick)

```
{
  "users": [
    {
      "id": "<hidrive-login-email-oder-benutzername in lowercase>",
      "role": "org_admin | pv_admin | org_auditor | team_lead | team_member",
      "teams": ["<team-id>", "<weitere-team-id>"]
    }
  ]
}
```

## Beispiel – Admin‑Eintrag

```
{
  "users": [
    {
      "id": "admin@example.org",
      "role": "org_admin",
      "teams": ["team-a", "team-b"]
    }
  ]
}
```

Hinweise:
- `id` muss exakt dem HiDrive‑Login entsprechen und in Kleinbuchstaben eingetragen werden.
- `role` bestimmt die Berechtigungen (Admins: `org_admin` oder `pv_admin`).
- `teams` wird für `team_lead`/`team_member` zur Team‑Zuordnung genutzt; bei Admins optional.

## Weitere Rollen – Beispiele

### 1) PV‑Admin (gleiche Rechte wie Org‑Admin innerhalb der App)

```
{
  "users": [
    { "id": "pvadmin@example.org", "role": "pv_admin", "teams": [] }
  ]
}
```

### 2) Org‑Auditor (lesen, Admin‑Konsole sichtbar, keine Schreibaktionen)

```
{
  "users": [
    { "id": "auditor@example.org", "role": "org_auditor", "teams": [] }
  ]
}
```

### 3) Team‑Lead (aktuelle Implementierung: Schreibrechte wie Lead, team‑Liste wird bereits gespeichert; Team‑Scope folgt in Phase 2)

```
{
  "users": [
    {
      "id": "lead.wohnen@example.org",
      "role": "team_lead",
      "teams": ["team-wohnen-nord", "team-wohnen-sued"]
    }
  ]
}
```

### 4) Team‑Member (lesen, keine administrativen Aktionen)

```
{
  "users": [
    {
      "id": "mitarbeiter@example.org",
      "role": "team_member",
      "teams": ["team-ambulant-sued"]
    }
  ]
}
```

Hinweis zur Team‑Liste: Die App speichert und lädt die `teams`‑Zuordnung bereits aus der `roles.json`. In der aktuellen Version werden Schreibrechte für Leads jedoch noch nicht strikt auf diese Teams begrenzt (globaler Lead). Die Team‑Scope‑Durchsetzung ist in Phase 2 vorgesehen.

## Einrichtung für eine Person als Admin

1) In der Personalverwaltungs‑App (Admin):
   - Einstellungen → HiDrive Zugang hinterlegen, Org‑ID setzen, Cloud‑Sync aktivieren.
   - Admin‑Konsole → Tab „Tools“ → Karte „Rollen‑Policy (roles.json)“ öffnen.
   - JSON wie im Beispiel oben eintragen (id = HiDrive‑Login der Person) → „Speichern“.

2) Auf dem Zielgerät der Person (neue Installation):
   - App starten → Einstellungen → HiDrive Benutzer/Passwort eintragen → „Anmeldedaten speichern“.
   - Optional (einmalig): „Rollen‑Policy aktualisieren“ drücken (lädt `roles.json`).
   - Ab jetzt greift die serverseitige Rolle stabil bei jedem Start.

3) Optionaler Fallback (lokal):
   - In Einstellungen kann kurzfristig eine Rolle ausgewählt werden (Dropdown „Rolle“). Diese greift nur als Fallback, wenn noch keine `roles.json` geladen wurde.
- Für dauerhafte, feste Rollen VERPFLICHTEND über `roles.json` arbeiten.

## Wie die App die Rolle bestimmt

1) Server‑Policy (bevorzugt):
   - Service lädt `roles.json` (Admin‑Konsole „Tools“ → Laden/Speichern oder Settings → „Rollen‑Policy aktualisieren“).
   - Mapping erfolgt über `id` = HiDrive‑Login.

2) Lokaler Fallback:
   - Wenn (noch) keine `roles.json` geladen ist, wird die lokal eingestellte Rolle verwendet.
- Sobald `roles.json` geladen wurde, überschreibt die serverseitige Rolle den lokalen Fallback.

## UI‑Auswirkungen je Rolle (aktueller Stand)

- `org_admin` / `pv_admin`:
  - Admin‑Konsole sichtbar (alle Tabs inkl. Health/Tools/Audit)
  - Teams verwalten: erlaubt (Neues Team, Bearbeiten, Löschen)
  - Team‑Key erzeugen/QR: erlaubt
  - Clients‑Index neu aufbauen: erlaubt
  - Klienten anlegen/bearbeiten/löschen: erlaubt
  - Klient „Team wechseln“: erlaubt
  - Berichte/Export/Report‑Vorlagen: vollumfänglich

- `org_auditor`:
  - Admin‑Konsole sichtbar (Read‑Only Fokus)
  - Keine Schreibaktionen (Teams verwalten, Team‑Key, Index‑Rebuild deaktiviert)
  - Klienten‑Schreibaktionen deaktiviert
  - Lesen/Reports erlaubt

- `team_lead`:
  - Admin‑Konsole sichtbar? Nur teils (kein Schreib‑Tooling)
  - Klienten anlegen/bearbeiten (global, Team‑Scope folgt in Phase 2)
  - Klienten löschen: nicht erlaubt
  - Teams verwalten: nicht erlaubt
  - Reports: nutzen (Vorlagen anwenden), aber keine Vorlagen verwalten

- `team_member`:
  - Lesen erlaubt
  - Keine administrativen Aktionen (Teams, Team‑Key, Index‑Rebuild)
  - Klienten anlegen/bearbeiten/löschen: nicht erlaubt

Technische Referenz: Siehe `PolicyService` (Methoden wie `canManageTeams`, `canRotateKeys`, `canRebuildIndexes`, `canCreateClient`, `canEditClient`, `canDeleteClient`, `canChangeClientTeam`, `canViewAdminTools`).

## Best Practices

- Immer `roles.json` pflegen, damit die Rolle fest und reproduzierbar ist.
- `id` in Kleinbuchstaben pflegen (z. B. `vorname.nachname@domain.tld`).
- Für jede neue Person vorab einen Eintrag in `roles.json` anlegen.
- Änderungen an Rollen nur über `roles.json` durchführen (nicht über die lokale Dropdown‑Rolle).

## Troubleshooting

- „Rollen‑Policy vorhanden“ im Health‑Tab ist rot:
  - `roles.json` fehlt oder Pfad stimmt nicht → über Admin‑Konsole „Tools“ speichern.
- Benutzer hat trotz Eintrag falsche Rolle:
  - `id` stimmt nicht exakt mit HiDrive‑Login überein → in Kleinbuchstaben korrigieren.
  - Nach dem ersten Login „Rollen‑Policy aktualisieren“ drücken, damit geladen wird.
- Admin‑Buttons deaktiviert:
  - Rolle ist nicht `org_admin`/`pv_admin` → `roles.json` prüfen und speichern.
