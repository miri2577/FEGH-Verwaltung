# Mitarbeiter-Einladung via QR-Code

Die Verwaltung ist der **primaere Ort** um neue Mitarbeiter an die
FEGH-Dokumentations-App anzubinden. Das passiert ueber einen
QR-Code (Provisioning-Token) plus PIN.

## Ablauf

### In der Verwaltung

1. **Admin-Console oeffnen** (Hauptmenue > Administration)
2. Auf Tab **Provisioning / Mitarbeiter-Einladung** gehen
3. Felder ausfuellen:
   - **E-Mail**: HiDrive-Login des Mitarbeiters (falls gemanaged) oder
     reine Identifikation
   - **Rolle**: `team_member` (Standard), `team_lead` oder
     `org_auditor`
   - **Teams**: kommagetrennte Liste (z.B. `team-nord,team-mitte`)
   - **HiDrive-App-Passwort** (optional): wenn vorgegeben, wird das
     Passwort ins Token eingebettet und der Mitarbeiter muss nichts
     mehr eingeben
   - **Schutz-PIN**: mindestens 6 Ziffern - diese PIN bekommt der
     Mitarbeiter auf separatem Weg (z.B. SMS, Anruf)
4. **QR erzeugen** klicken
5. Der QR-Code erscheint - entweder ausdrucken oder per Screen-Share
   zeigen, **NICHT** zusammen mit der PIN ueber denselben Kanal
   uebermitteln (Stichwort: Defense in Depth)

### Beim Mitarbeiter (Doku-App)

1. Ersteinrichtung der Doku-App starten
2. Pfad **"Einladungscode verwenden"** waehlen
3. QR-Code scannen (oder Token-Text einfuegen)
4. **PIN** eingeben
5. Doku-App entschluesselt Token, uebernimmt automatisch:
   - Organisations-ID
   - HiDrive-Zugangsdaten (falls eingebettet)
   - Team-Zugehoerigkeit
   - Team-Keys
   - Rolle
   - TOTP-Secret fuer 2FA (optional)
6. Mitarbeiter legt persoenliches App-Passwort fest
7. Profil bestaetigen -> fertig, App startet im Team-Modus

## Token-Format

Das QR-Token ist ein PIN-verschluesseltes JSON mit Typ
`egh-provisioning-v1`. Der Klartext-Payload enthaelt:

```json
{
  "type": "egh-provisioning-v1",
  "org": "org-id",
  "user": "max@traeger.de",
  "role": "team_member",
  "teams": ["team-a"],
  "teamKeys": { "team-a": "<base64-32byte>" },
  "totp": "<base32-secret>",
  "hidrive": {
    "username": "hidrive-user@firma.de",
    "appPassword": "..."
  },
  "flags": {
    "managed": true,
    "forceInitialSync": true,
    "hideCredentials": true
  },
  "ts": "2026-04-18T14:30:00Z"
}
```

Verschluesselt via:
- PBKDF2 mit Salt `egh-provisioning-salt-v1`, 10000 Iterationen
- AES-256-GCM, kein AAD
- Output: Base64(utf8(json({nonce, ciphertext, tag})))

Wire-Format identisch zwischen Verwaltung (erzeugt) und
Dokumentation (verbraucht), verifiziert via `fegh_crypto`-
Contract-Tests.

## Sicherheit

!!! warning "Trennung von QR und PIN"
    QR-Code und PIN IMMER ueber unterschiedliche Kanaele. Beispiel:
    QR per E-Mail, PIN per SMS. Oder QR ausdrucken und uebergeben,
    PIN telefonisch.

!!! info "Token-Gueltigkeit"
    Das Token hat aktuell keinen Ablauf (statisches `ts`). Ein
    Mitarbeiter kann es prinzipiell lange nutzen. Fuer zusaetzliche
    Sicherheit: PIN nach erstem Login in der Verwaltung
    widerrufen (Re-Provisioning).

## Rollen-Uebersicht

| Rolle | Rechte |
|---|---|
| `org_admin` | Voller Zugriff, Org-Verwaltung |
| `pv_admin` | Verwaltungs-Admin (nur Verwaltungs-App) |
| `team_lead` | Team fuehren, Klienten + Mitarbeiter im Team verwalten |
| `team_member` | Fachkraft, Dokumentation + Terminerfassung |
| `org_auditor` | Nur-Lesen |

Siehe auch: [Rollen und Berechtigungen](rollen.md).

## Vergleich zur Doku-App

Die Doku-App hat einen eigenen Provisioning-Flow ueber
Einstellungen > Admin > Mitarbeiter einladen. Der erzeugte QR ist
**bitidentisch** zu dem der Verwaltung (selbes `fegh_crypto`).

Nutzung:

- **Solo-Admin (kleiner Traeger):** Doku-App reicht
- **Groessere Orga:** Verwaltung besser, wegen besserem Rollen-
  Editor, Batch-Provisioning und Integration mit Mitarbeiter-
  Stammdaten
