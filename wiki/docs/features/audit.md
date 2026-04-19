# Audit-Log

Das Audit-Log protokolliert **alle sicherheits- und revisionssensiblen Aktionen** in beiden Apps (Verwaltung und Dokumentation). Es ist die Basis fuer DSGVO-Nachweispflichten (Art. 32 TOM, Art. 30 Verarbeitungsverzeichnis) und fuer Pruefungen durch Kostentraeger oder Revisionen.

## Gemeinsames Format

Das Audit-Log wird zentral ueber das Shared-Package **`fegh_compliance`** gefuehrt. Beide Apps schreiben in dieselbe JSON-Lines-Datei im `ApplicationSupportDirectory`, mit identischem Schema:

```json
{"ts":"2026-04-19T21:15:30.000Z","action":"rechnung.created","userId":"system","ctx":{"rechnungsnr":"2026-0042","empfaenger":"Sozialamt XY"}}
```

- `ts` — UTC-Zeitstempel, ISO 8601
- `action` — Event-Name im Format `modul.aktion` (z.B. `medication.given`, `kassenbuch.entry.created`)
- `userId` — Cloud-Benutzername oder `system` bei nicht-attributierten Aktionen
- `ctx` — Frei definierbarer Kontext (Klient-ID, Rechnungsnummer, etc.)

## Was wird geloggt?

### Stammdaten
- `team.created` / `team.updated` / `team.deleted`
- `employee.created` / `employee.updated` / `employee.deactivated`
- `client.created` / `client.updated` / `client.archived`
- `wohnraum.created` / `wohnraum.assigned` / `wohnraum.released` / `wohnraum.deactivated`

### Rollen und Berechtigungen
- `role.assigned` (User → Rolle via `roles.json`)
- `role.revoked`
- `provisioning.token.generated`
- `provisioning.token.redeemed`

### Transaktionen
- `rechnung.created` / `rechnung.sent` / `rechnung.cancelled`
- `kassenbuch.entry.created` / `kassenbuch.entry.updated` / `kassenbuch.entry.deleted` / `kassenbuch.entry.confirmed`
- `medication.plan.created` / `medication.plan.updated` / `medication.plan.deactivated`
- `medication.given` / `medication.refused` / `medication.missed`

### Cloud und Backup
- `cloud.sync.started` / `cloud.sync.completed` / `cloud.sync.failed`
- `backup.created` / `backup.restored` / `backup.deleted`
- `mek.created` / `mek.rotated` / `mek.recovery.used`

### Datenschutz
- `dsgvo.export.requested` / `dsgvo.export.delivered`
- `dsgvo.delete.requested` / `dsgvo.delete.executed`

## Wo liegt die Datei?

- **Windows**: `%APPDATA%\fegh\audit.jsonl`
- **macOS**: `~/Library/Application Support/fegh/audit.jsonl`
- **Linux**: `~/.local/share/fegh/audit.jsonl`

Das ist bewusst eine **lokale** Datei pro Geraet. Eine zusaetzliche Cloud-Ablage (mit AES-256-GCM verschluesselt) ist geplant, damit Audit-Eintraege auch Admin-uebergreifend gesichert sind.

## Einsicht und Export

Im Admin-Bereich: *Einstellungen → Audit-Log* (die letzten 300 Zeilen). Kompletter Export als `.jsonl`-Datei moeglich. Fuer Pruefungen kann die Datei direkt aus dem Dateisystem kopiert werden.

## Aufbewahrung

Empfohlene Aufbewahrungsfrist: **10 Jahre** (analog HGB §257 / AO §147 fuer buchungsrelevante Eintraege). Ein automatisches Loeschen auf Basis der Frist ist nicht implementiert — die Datei waechst, muss manuell archiviert werden.

## Siehe auch

- [Shared-Packages](../technik/shared-packages.md) — Aufbau von `fegh_compliance`
- [Backup und Recovery](backup.md) — Audit-Log ist Bestandteil des Voll-Backups
