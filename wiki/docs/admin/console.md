# Admin-Console

Die Admin-Console (erreichbar ueber Einstellungen → *Admin-Console oeffnen* oder direkt aus der Navigations-Sektion *System*) buendelt selten genutzte, aber kritische Administrations-Aktionen.

## Funktionsweise im Detail

### Das Problem, das wir loesen

Eine Einrichtung hat **taegliche Admin-Taetigkeiten** (Mitarbeiter-
Onboarding, Team-Umstrukturierung, Ordnerstruktur pruefen) und
**Notfall-Taetigkeiten** (MEK rotieren, Klienten-Index neu
aufbauen, Audit exportieren fuer Pruefung). Ohne eine zentrale
Admin-Console waeren diese ueber Dutzende Settings-Unterseiten
verstreut und schwer auffindbar.

Die Admin-Console ist der **Single Point of Truth fuer Admin-
Taetigkeiten**. Wer orgAdmin ist, findet hier alle Werkzeuge
zusammen. Wer es nicht ist, sieht die Console gar nicht.

### Konkretes Szenario: Typischer Admin-Tag

**Morgens** — Anja nimmt am Montag den Posten auf:

1. `Admin-Console → Tools → Health-Check` (10 sec) — alle gruen.
2. `Audit-Tab → SIEM-Syslog-Export` (30 sec) — gestriger Audit fuer
   die wochentliche Auswertung in Splunk.
3. Fertig, back to routine work.

**Mittags** — 3 neue Mitarbeiter starten naechste Woche:

1. `Admin-Console → Mitarbeiter-Provisioning → Neuen Mitarbeiter
   einladen` (3x)
2. Fuer jeden: Name, Rolle, Team auswaehlen → QR + PIN ausdrucken
3. QRs werden verschlossen im Briefumschlag bereit gelegt.

**Nachmittags** — ein laengerer Wartungsfall:

Der Clients-Index scheint verzogen (einer sucht "Mueller", findet
aber drei Klienten mit dem Namen nicht).

1. `Admin-Console → Tools → Drift-Analyse`
2. Ergebnis: "3 Klient-Records auf HiDrive ohne Eintrag im Index"
3. `Admin-Console → Tools → Clients-Index neu aufbauen`
4. Dauer ~2 min (liest alle Records, schreibt Index-Datei).
5. Suche funktioniert wieder.

### Warum nur orgAdmin?

Admin-Aktionen koennen Daten **verlieren** oder **kompromittieren**
wenn sie falsch bedient werden:

- **MEK-Rotation** schreibt Schluesselmaterial neu; Fehler fuehrt zu
  Datenverlust.
- **Team-Key-Rotation** erzwingt Re-Encryption aller Team-Files;
  Fehler kann Dateien unbrauchbar machen.
- **Clients-Index-Rebuild** ueberschreibt den Index; falsche
  Implementierung koennte Such-Funktion zerstoeren.

Deshalb wird der Zugriff auf **eine einzige Person(-engruppe)**
beschraenkt. Ein Teamleiter, der sich "mal eben was anschauen will",
kann die Console gar nicht erst oeffnen — kein Weg zum
destruktiven Button.

### Rechtlicher Hintergrund

- **Art. 5 Abs. 1 lit. f DSGVO** — Integritaet und Vertraulichkeit;
  Schluesselverwaltung ist kritisch.
- **Art. 32 DSGVO** — Zugriffskontrolle; separate Admin-Rolle
  erfuellt das Need-to-know-Prinzip.
- **§87 BetrVG** — Betriebsrat kann auf Admin-Logs zugreifen, wenn
  Ueberwachungs-Verdacht besteht (Einsicht in Audit-Log).

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
