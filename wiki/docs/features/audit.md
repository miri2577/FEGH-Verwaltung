# Audit-Log

Das Audit-Log protokolliert **alle sicherheits- und revisionssensiblen Aktionen** in beiden Apps (Verwaltung und Dokumentation). Es ist die Basis fuer DSGVO-Nachweispflichten (Art. 32 TOM, Art. 30 Verarbeitungsverzeichnis) und fuer Pruefungen durch Kostentraeger oder Revisionen.

## Funktionsweise im Detail

### Das Problem, das wir loesen

Bei einer Datenschutzpruefung oder einem Zwischenfall ("Wer hat am
15. Maerz die Medikation von Herrn K. geaendert?") reicht es nicht,
dass die Information theoretisch verfuegbar ist — sie muss
**unveraenderlich protokolliert** sein. Ein Excel-Protokoll kann
nachtraeglich geaendert werden; ein Word-Bericht auch. Eine seriose
Nachweisbarkeit verlangt:

- **Zeitgebunden**: UTC-Zeitstempel mit Millisekunden
- **Aktorgebunden**: eindeutige Mitarbeiter-ID
- **Kontextbindend**: welche Entitaet wurde beruehrt
- **Append-only**: keine nachtraeglichen Aenderungen moeglich
- **Verteilt speicherbar**: sowohl lokal (offline-Arbeit) als auch
  zentral (Cloud-Backup)
- **Exportierbar**: in Formate, die SIEM/Pruefwerkzeuge verstehen

Das Audit-Log ist die **technische Umsetzung** der Rechenschafts-
pflicht nach Art. 5 Abs. 2 DSGVO: "Der Verantwortliche muss
nachweisen koennen, dass die Grundsaetze eingehalten werden."

### Konkretes Szenario: Anfrage vom LfDI

**08. Juli — LfDI meldet sich.** Ein Klient hat behauptet, seine
Kasse sei von einem unbefugten Mitarbeiter eingesehen worden.

**10:00 Uhr — Anja oeffnet das Audit-Log.**

1. `Admin-Console → Audit-Tab`
2. Filter: Klient-ID `12345`, Zeitraum `01.05.2026 - 30.06.2026`,
   Aktion beginnt mit `kassenbuch.`
3. Ergebnis: 14 Treffer
   - 8x `kassenbuch.entry.created` durch Mia (regulaer)
   - 6x `kassenbuch.entry.confirmed` durch Lars (Teamleitung,
     Freigabe)

4. Anja erweitert den Filter auf `client.read` — alle Klient-
   Oeffnungen:
   - 47 Treffer, verteilt auf 6 verschiedene Mitarbeiter
   - **Davon 3 von `felix.schmitt@assistenz.local`** — das ist
     ein Kollege aus einem **anderen Team**, der fuer eine
     Vertretung am 12. Juni im Einsatz war.

5. Anja prueft Felix' Schichten:
   - `Dienstplan → Schichten → Felix`, Zeitraum 12. Juni
   - Tatsaechlich: Felix hat am 12. Juni die Nachmittagsschicht in
     Hauptstrasse uebernommen (Krankmeldung Mia).
   - Legitimer Zugriff.

6. Anja exportiert den gefilterten Audit-Log als **Syslog RFC 5424**
   und schickt ihn an den LfDI mit dem Kommentar "Felix hatte
   Vertretungsauftrag am 12.06. (siehe Dienstplan im Anhang)".

**11:00 Uhr — Anfrage geklaert.** Der Klient hatte sich mit Felix
auf Grund einer anderen Beschwerde (Umgangston) angelegt; der LfDI
bestaetigt, dass der Zugriff rechtmaessig war.

Ohne das strukturierte Audit-Log haette das Taetigkeitsnachweis
zwei Tage Excel-Sortieren gekostet.

### Was genau geloggt wird

Das Audit-Log **protokolliert Handlungen**, nicht Inhalte. Das
heisst konkret:

- `medication.given` mit `{clientId, medicationId, employeeId,
  witnessEmployeeId}` — **nicht** die Art der Medikation
  (Sertralin 50 mg bleibt unsichtbar im Log; nur die `medicationId`
  wandert rein — das reicht fuer die Rueckverfolgung und schuetzt
  den Klienten vor sekundaerer Offenlegung).
- `kassenbuch.entry.created` mit `{clientId, kategorie, betrag}` —
  **nicht** die Freitext-Beschreibung der Buchung.
- `client.read` mit `{clientId, employeeId}` — **nicht**, welche
  konkreten Felder der Mitarbeiter gesehen hat.

Das ist eine bewusste Designentscheidung: das Log muss oft genug
exportiert werden, dass man ihn nicht wie die eigentliche
Klientenakte schuetzen will — aber er darf keine sensiblen
Sekundaer-Informationen lecken.

### Append-Only — warum technisch und warum rechtlich

**Technisch**: Das Log wird als JSON Lines geschrieben, jede neue
Zeile angehaengt. Der AuditLogger hat **keine Methoden** zum
`update` oder `delete` einzelner Zeilen. Die `clear()`-Methode ist
mit DSGVO-Loeschungs-Kontext dokumentiert — sie ist nicht
"undo"-Funktion sondern Ausnahme fuer bestaetigte Loeschbefehle.

**Rechtlich**: §147 AO / HGB §257 verlangen Unveraenderbarkeit fuer
Rechnungsdaten. Das Audit-Log selbst ist zwar kein Rechnungsnach-
weis, aber es **dokumentiert** Rechnungsaenderungen. Waere das Log
nachtraeglich aenderbar, waere die Beweiskraft null.

### Die drei Ebenen der Persistenz

| Ebene | Standort | Zweck |
|-------|----------|-------|
| **Device-lokal** | `ApplicationSupportDirectory/audit.log` | Sofort schreibbar, offline-faehig |
| **Cloud-Backup** | Via `fegh_backup` in verschluesseltem Envelope | Geraete-Verlust abgefedert |
| **SIEM-Export** | On-demand in Syslog/CEF/JSONL | Long-term Retention im Unternehmens-SIEM |

Die App schreibt sofort lokal. Beim Backup-Lauf (24h-Zyklus) wandert
das Log mit in das Backup-Envelope. Fuer Unternehmen mit SIEM ist
der SIEM-Export der Primaer-Kanal — dort ist Retention konfigurier-
bar (z. B. 7 Jahre nach HGB §257).

### Rotation und DSGVO-Loeschung

- **Rotation**: Der `AuditLogger` entfernt automatisch Eintraege
  aelter als 1.095 Tage (3 Jahre — DSGVO Art. 5 Abs. 1 lit. e
  Speicherbegrenzung).
- **DSGVO-Loeschung**: Bei Antrag eines Klienten auf Loeschung
  (Art. 17) werden alle seine personenbezogenen Eintraege
  gesucht und **pseudonymisiert** (Klient-ID durch Hash ersetzt).
  Das Audit-Log selbst bleibt, aber der Klient ist nicht mehr
  identifizierbar.

### Rechtlicher Hintergrund

- **Art. 5 Abs. 2 DSGVO** — Rechenschaftspflicht. Audit-Log
  dokumentiert die Einhaltung der Grundsaetze.
- **Art. 32 DSGVO** — Sicherheit der Verarbeitung. Logs als TOM
  gegen unbefugte Kenntnisnahme und zur Aufklaerung.
- **Art. 33/34 DSGVO** — Meldepflicht bei Datenschutzverletzung
  binnen 72h. Das Log ist die Grundlage fuer die Meldung.
- **§147 AO + HGB §257** — Aufbewahrung 10 Jahre fuer
  Rechnungsdaten; rechnungsrelevante Audit-Events muessen so
  lange aufbewahrt werden.
- **§87 BetrVG** — Betriebsrat kann bei Ueberwachungsverdacht
  Einsicht ins Audit-Log nehmen.

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
