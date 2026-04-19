# Sync-Diagnose

Die Sync-Diagnose ist ein gefuehrter Test-Lauf, der nach jeder neuen Einrichtung und bei Fehlerbildern den Cloud-Sync Schritt fuer Schritt prueft.

## Aufruf

Einstellungen → *Admin-Tools* → *Sync-Diagnose starten*.

## Was wird geprueft?

1. **Cloud-Verbindung** — TCP + TLS Handshake zum Provider.
2. **Authentifizierung** — Login mit Cloud-Benutzer und App-Passwort.
3. **Root-Verzeichnis** — ist der Root-Pfad lesbar? (`/users/<user>/eingliederungshilfe/` o. a.)
4. **Organisations-Ordner** — existiert `organizations/<orgId>`?
5. **Sync-Passphrase** — ist sie in den Settings gesetzt, und laesst sich damit ein Test-Record entschluesseln?
6. **MEK verfuegbar** — kann der Master-Encryption-Key entschluesselt werden?
7. **`roles.json`** — vorhanden und lesbar?
8. **Teams** — wie viele Teams hat die Organisation?
9. **Schreibtest** — kann eine temporaere Datei geschrieben und wieder geloescht werden?

Jeder Schritt gibt einen Status zurueck: gruen (OK), gelb (Warnung, nicht blockierend), rot (Fehler).

## Haeufige Fehlerbilder

### „Verbindung OK, aber 401 bei Schreiben"
→ App-Passwort hat nicht die Berechtigung „WebDAV Business". Im HiDrive-Portal neu anlegen.

### „Passphrase leer"
→ Sync-Passphrase ist in den Einstellungen nicht gesetzt. Unter *Einstellungen → Sync-Passphrase* nachtragen.

### „Teams: 0"
→ Noch keine Teams angelegt. Das ist bei einem frischen Setup normal — *Personal → Teams → Neu anlegen*.

### „Root nicht gefunden"
→ Der Pfad stimmt nicht (z. B. Tippfehler im Optional-Root-Subdirectory). Im Setup-Wizard korrigieren.

### „415 bei MKCOL (STRATO HiDrive)"
→ Seit dem Umzug auf `webdav_client` geloest. Falls weiterhin: Update der Verwaltungs-App pruefen.

## Ausgabe

Die Diagnose bietet am Ende einen **Copy-Button** fuer den Zusammenfassungs-Text — praktisch fuer Support-Anfragen. Der Output enthaelt keine Passwoerter, nur Timestamps, Statuscodes und Pfade.

## Siehe auch

- [Admin-Console](console.md)
- [Cloud-Storage](../technik/cloud-storage.md)
