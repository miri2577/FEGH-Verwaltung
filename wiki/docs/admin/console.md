# Admin-Console

Die Admin-Console (erreichbar ueber Einstellungen → *Admin-Console oeffnen* oder direkt aus der Navigations-Sektion *System*) buendelt selten genutzte, aber kritische Administrations-Aktionen.

## Zugriff

Nur sichtbar mit der Rolle `orgAdmin`. Andere Rollen bekommen die Aktionen nicht angezeigt; selbst ein direkter Deeplink fuehrt zu einer „Keine Berechtigung"-SnackBar.

## Was drin ist

### Organisation

- **Org-ID anzeigen** — aktuelle Organisation ID (die Basis aller Cloud-Pfade).
- **Org-Ordnerstruktur pruefen/aufbauen** — Prueft ob alle noetigen Unterordner unter `eingliederungshilfe/organizations/<orgId>` existieren und legt fehlende an.

### Mitarbeiter-Provisioning

- **Neuen Mitarbeiter einladen** — Wizard, der ein Provisioning-Token erzeugt und als QR-Code anzeigt. Der neue Mitarbeiter scannt das in der Doku-App oder der Verwaltung.
- **Provisioning-Tokens verwalten** — Liste bestehender Tokens (ausstehend / redeemed / abgelaufen).

### Rollen

- **roles.json anzeigen** — aktuelle Rollen-Zuordnungen.
- **Rolle zuweisen / entziehen** — direktes Editieren.
- **Audit-Scope fuer Auditor** — Zeitfenster und Teams setzen.

### Schluessel

- **Team-Keys** — erzeugen, rotieren, QR-basiert an Mitarbeiter ausgeben.
- **MEK-Rotation** — Master-Encryption-Key austauschen. Rewrap aller Records wird im Hintergrund gestartet.
- **Rewrap-Dialog** — Manueller Rewrap nach Passphrase-Aenderung.

### Health und Diagnose

- **Health Check** — prueft Ordnerstruktur, Schreibrecht, `roles.json`-Existenz, Clients-Index.
- **Clients-Index neu aufbauen** — liest alle Klient-Records und schreibt den Such-Index neu.
- **Drift-Analyse** — Vergleicht Index mit tatsaechlich vorhandenen Dateien (findet Leichen).
- **Sync-Diagnose** — siehe [Sync-Diagnose](sync-diagnose.md).

### Audit

- **Audit-Log ansehen** — letzte 300 Zeilen der lokalen `audit.jsonl`.
- **Audit-Log exportieren** — kompletter Export als `.jsonl`.

## Siehe auch

- [Rollen und Berechtigungen](rollen.md)
- [Mitarbeiter-Einladung (QR)](einladung.md)
- [Team-Keys verwalten](team-keys.md)
- [Sync-Diagnose](sync-diagnose.md)
- [Audit-Log](../features/audit.md)
