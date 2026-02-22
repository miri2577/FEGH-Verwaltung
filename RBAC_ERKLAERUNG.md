# RBAC in der Personalverwaltung – Konzept und Funktionsweise

Stand: 2025‑09‑30

## Ziel

Role‑Based Access Control (RBAC) steuert, welche Aktionen und Datenbereiche Nutzer sehen oder ausführen dürfen. Die Rollen werden serverseitig über `roles.json` verwaltet, damit jede Installation deterministisch dieselben Rechte besitzt.

## Quellen der Wahrheit

- Server‑Policy (`roles.json`):
  - Pfad: `eingliederungshilfe/organizations/<org>/administration/users/roles.json`
  - Schema: `{ users: [ { id, role, teams, auditScope? } ] }`
  - `id`: HiDrive‑Login (lowercase), `role`: org_admin | pv_admin | org_auditor | team_lead | team_member
  - `teams`: Liste von Team‑IDs (für team_lead/-member relevant)
  - `auditScope` (optional, nur Auditor): `{ teams?: string[], from?: ISO8601, to?: ISO8601, reason?: string }`
- Lokaler Fallback: Nur bis `roles.json` geladen ist; danach gilt ausschließlich die Server‑Policy.

## Rollen – Kurzüberblick

- `org_admin` | `pv_admin`: Vollzugriff (Admin‑Werkzeuge), jedoch kein Doku‑Zugriff aus Datenschutzgründen.
- `org_auditor`: Lesen nach Bedarf; Doku nur, wenn `auditScope` aktiv (Zeitfenster/Team) oder globaler Settings‑Schalter aktiv.
- `team_lead`: Schreiben/Lesen innerhalb eigener Teams (laut `teams`).
- `team_member`: Lesen eingeschränkt, keine Admin‑Werkzeuge.

## Durchsetzung in der App

- Policy‑Service (Kernlogik): `lib/services/policy_service.dart`
  - Beispiele:
    - `canManageTeams()` – Admin‑only
    - `canCreateClient({teamId})` / `canEditClient({teamId})` – Lead nur im eigenen Team, Admin überall
    - `canDeleteClient({teamId})` – Admin‑only
    - `canChangeClientTeam(...)` – Admin‑only
    - `canViewAdminTools()` – Admin oder Auditor (read)
    - `canViewDocumentation()` – Team‑Lead; Auditor mit aktivem Scope oder Settings‑Schalter
    - `canViewDocumentationForTeam(teamId, when)` – Team‑sensitiver Check (Lead: nur eigenes Team; Auditor: Scope‑Teams + Zeitfenster)

- Server‑Operationen (Provider/Services):
  - Teams/Clients Provider prüfen Policy auch serverseitig, nicht nur per UI‑Button.
  - Admin‑Konsole (Health/Tools) zeigt oder deaktiviert Aktionen entsprechend der Rolle.

## Auditor – Just‑in‑Time Zugriff

- Aktivierung (Admin‑Konsole → Tools → „Auditor‑Leserechte (JIT)“):
  - Auswahl Auditor, Teams, Zeitraum, Begründung.
  - App schreibt `auditScope` in `roles.json` und loggt Aktion (`auditor.scope.set`).
  - Nach Ablauf (to) ist der Zugriff automatisch beendet; „Deaktivieren“ entfernt Scope (`auditor.scope.clear`).

## Team‑Lead‑Scope für Dokumente

- Verwende die Methode `canViewDocumentationForTeam(teamId, when: ts)`
  - Team‑Lead: true nur, wenn `teamId` in `roles.json.teams` enthalten
  - Auditor: true, wenn `auditScope.isActive` und (scope.teams leer oder enthält `teamId`) und `when` im Zeitfenster liegt
  - Admin/Member: false

## Best Practices

- Rollen ausschließlich zentral über `roles.json` verwalten.
- Auditor‑Zugriff nur befristet und begründet (Audit‑Log), mit enger Team‑ und Zeitgrenze.
- HiDrive‑Rechte zusätzlich passend setzen (Least Privilege), damit Server‑Policy und Storage‑Rechte konsistent sind.
- Buttons nur anzeigen, wenn Policy erlaubt, aber entscheidend sind die Server‑/Provider‑Checks.

## Verweise

- Rollen‑Beispiele: `ROLES_POLICY_BEISPIEL.md`
- Mehrbenutzer‑Betrieb & Provisionierung: `HIDRIVE_MEHRBENUTZER_BETRIEBSKONZEPT_UND_PROVISIONIERUNG.md`
- Policy‑Implementierung: `lib/services/policy_service.dart`
- Rollen‑Service (roles.json laden/speichern/Scopes): `lib/services/roles_policy_service.dart`

