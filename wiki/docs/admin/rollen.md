# Rollen und Berechtigungen

Die FEGH-Apps nutzen ein **rollen-basiertes Zugriffsmodell (RBAC)** mit fuenf Rollen, zentral gepflegt in der Cloud-Datei `administration/users/roles.json`.

## Die fuenf Rollen

| Rolle | Bedeutung |
|-------|-----------|
| `orgAdmin` | Volladministration — kann Organisation, Admins, Team-Keys und die `roles.json` selbst verwalten. |
| `pvAdmin` | Personalverwaltungs-Admin — alle Funktionen von `orgAdmin` **ausser** Organisationsaenderungen und Key-Rotation. |
| `teamLead` | Team-Leitung — pflegt Mitarbeiter, Dienstplan, Klienten der **eigenen Teams**. |
| `teamMember` | Mitarbeiter — sieht nur Dinge, die ihn/sie direkt betreffen: eigene Schichten, zugewiesene Klienten, Medikationsgaben, Kassenbuch-Eintraege. |
| `orgAuditor` | Revisor — zeitlich und team-bezogen beschraenkter Lesezugriff (z. B. fuer Wirtschaftspruefer). |

## roles.json

Die Datei liegt im Cloud-Unterordner `administration/users/roles.json` und ist **mit dem Master-Encryption-Key verschluesselt**:

```json
{
  "users": [
    {
      "id": "anna.meier@traeger.de",
      "role": "team_lead",
      "teams": ["team-ost", "team-tagesstaette"]
    },
    {
      "id": "pruefer@externe-kanzlei.de",
      "role": "org_auditor",
      "auditScope": {
        "teams": ["team-ost"],
        "from": "2026-05-01T00:00:00Z",
        "to": "2026-05-31T23:59:59Z",
        "reason": "Jahrespruefung 2025"
      }
    }
  ]
}
```

- **`id`** — der Cloud-Benutzername (meist E-Mail), normalisiert in Kleinschrift.
- **`role`** — einer der fuenf Werte: `org_admin`, `pv_admin`, `team_lead`, `team_member`, `org_auditor`.
- **`teams`** — die IDs der Teams, fuer die die Rolle gilt (nur bei `team_lead` und `team_member` relevant).
- **`auditScope`** — nur bei `org_auditor`: Zeitfenster (from/to) und optional Team-Filter.

## Sichtbarkeits-Matrix (Auszug)

Die Hauptnavigation der Verwaltung blendet Eintraege rollenabhaengig ein oder aus. Die [Navigations-Registry](../technik/architektur.md#navigation) entscheidet per `visibleFor(UserRole)`-Praedikat.

| Bereich | `orgAdmin` | `pvAdmin` | `teamLead` | `teamMember` | `orgAuditor` |
|---------|:-:|:-:|:-:|:-:|:-:|
| Meine Arbeit | — | — | ✓ | ✓ | — |
| Medikation (geben) | — | — | ✓ | ✓ | — |
| Kassenbuch (Eintrag) | — | — | ✓ | ✓ | — |
| Klienten-Liste | ✓ | ✓ | ✓ (Team) | ✓ (zugewiesen) | ✓ (Scope) |
| ICF | ✓ | ✓ | ✓ | ✓ | ✓ |
| Medikationsplaene (admin) | ✓ | ✓ | ✓ | — | ✓ |
| Dashboard | ✓ | ✓ | ✓ | — | ✓ |
| Mitarbeiter | ✓ | ✓ | ✓ | — | ✓ |
| Teams | ✓ | ✓ | ✓ | — | ✓ |
| Urlaub | ✓ | ✓ | ✓ | ✓ | — |
| Kapazitaet | ✓ | ✓ | ✓ | — | ✓ |
| Wohnraum | ✓ | ✓ | ✓ | — | ✓ |
| Dienstplan | ✓ | ✓ | ✓ | — | ✓ |
| Zeitnachweise | ✓ | ✓ | ✓ | ✓ | ✓ |
| Rechnungen | ✓ | ✓ | — | — | ✓ |
| Berichte | ✓ | ✓ | ✓ | — | ✓ |
| Einstellungen | ✓ | ✓ | ✓ | ✓ | ✓ |
| Backup-Manager | ✓ | — | — | — | — |

## Lifecycle einer Rolle

1. **Anlage**: Admin traegt den User in der `roles.json` ein (ueber Admin-Console oder direkte Bearbeitung).
2. **Provisioning**: Der neue Mitarbeiter bekommt einen Provisioning-QR (siehe [Einladung](einladung.md)), scannt ihn in der Doku-App oder Verwaltung ein.
3. **Zugriff**: Die App ruft `RolesPolicyService.refresh()` beim Start und zyklisch — Rolle wird aktuell gehalten.
4. **Wechsel**: Admin aktualisiert `roles.json` — bei der naechsten Sync sieht der User die neue Rolle.
5. **Revoke**: Admin entfernt den Eintrag — beim naechsten App-Start landet der User in der Default-Rolle `teamMember` mit leerer Team-Liste (keine Klienten sichtbar).

## Siehe auch

- [Mitarbeiter-Einladung](einladung.md)
- [Architektur](../technik/architektur.md)
