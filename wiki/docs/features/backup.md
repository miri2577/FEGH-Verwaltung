# Backup und Recovery

Die Verwaltung bietet ueber das Shared-Package **`fegh_backup`** verschluesselte Voll-Backups aller Nutzdaten. Gleiche Bausteine nutzen Doku-App und Verwaltung.

## Was wird gesichert?

Das Backup umfasst die wichtigen SharedPreferences-Keys:

- Mitarbeiter, Teams, Klienten
- Schichten, Urlaub, Zeitnachweise
- Rechnungen und Empfaenger
- Medikationsplaene und -quittungen
- Wohnraum und Kassenbuch-Eintraege
- Benachrichtigungen und Settings

**Nicht enthalten**: Cloud-Zugangsdaten (Cloud-Benutzer und -Passwort) und Master-Encryption-Key (MEK). Diese sind geraetegebunden — nach einer Wiederherstellung muessen sie neu hinterlegt werden.

## Dateiformat

Ein Backup ist eine einzelne `.ehbackup`-Datei mit folgendem Byte-Layout:

```
[ 1 Byte Version (0x01) ]
[ 16 Byte Salt          ]
[ 12 Byte Nonce         ]
[ 16 Byte GCM-MAC       ]
[ n Bytes Ciphertext    ]
```

Der Ciphertext ist ein JSON-Envelope mit:

- **Metadaten**: Backup-ID, Erstellzeit, Geraet, App-Version, Daten-Version
- **Payload**: Eine Map `<Key, JSON-String>` aller gesicherten SharedPreferences-Keys

## Kryptographie

- **AES-256-GCM** (authentifizierte Verschluesselung)
- **PBKDF2 mit HMAC-SHA-256 und 100 000 Runden** fuer den Key aus dem Passwort
- **Zufaelliges Salt** pro Backup — gleiches Passwort erzeugt nie dasselbe Output

Ein GCM-Tag am Anfang verhindert nachtraeglich modifizierte Dateien — Manipulation fuehrt zu einem kontrollierten Entschluesselungsfehler.

## Bedienung

*Einstellungen → Backup & Wiederherstellung → Backup-Manager oeffnen* zeigt drei Sektionen:

1. **Backup erstellen** — Passwort vergeben (doppelt eingegeben), sofortige Erzeugung in `ApplicationSupportDirectory/backups/`.
2. **Backup wiederherstellen** — Datei auswaehlen, Passwort eingeben, Warn-Dialog bestaetigen. Bestehende Daten werden **ueberschrieben**.
3. **Liste vorhandener Backups** — mit Dateigroesse, Erstelldatum, Restore- und Delete-Action pro Eintrag.

## Recovery-Phrase (Admin-MEK)

Unabhaengig vom Backup bietet `fegh_backup` die **12-Wort Recovery-Phrase** fuer Administratoren — ein zweiter Weg, den Master-Encryption-Key wiederherzustellen, falls die Sync-Passphrase verloren geht:

- 12 Woerter aus einer deutschen 128-Wort-Liste (nicht BIP39)
- MEK wird mit der Phrase verschluesselt und optional auf der Cloud abgelegt
- PBKDF2 mit 50 000 HMAC-SHA-256-Runden fuer die Key-Ableitung

Die Phrase wird **einmal angezeigt**, sollte physisch notiert und an einem sicheren Ort aufbewahrt werden (Tresor, Wertschließfach).

## Was tun bei Verlust?

| Verlust | Ausweg |
|---------|--------|
| Cloud-Passwort | Neu vergeben im Cloud-Portal, in der App anpassen |
| Sync-Passphrase | Recovery-Phrase nutzen, MEK wiederherstellen |
| Recovery-Phrase | Keine Datenwiederherstellung moeglich — **Daten verloren** |
| Backup-Passwort | Kein Zugriff auf die konkrete Backup-Datei |

Die **drei Geheimnisse** (Cloud-Passwort, Sync-Passphrase, Recovery-Phrase) sollten getrennt und redundant aufbewahrt werden — mindestens eine Instanz jeweils offline.

## Geplant (nicht im MVP)

- Automatisches taegliches Backup in die Cloud
- Recovery-Code fuer einzelne Mitarbeiter (Passwort-Reset via Teamleitung)
- Incremental Backup statt Voll-Backup

## Siehe auch

- [Shared-Packages](../technik/shared-packages.md) — `fegh_backup` im Detail
- [Audit-Log](audit.md) — Backup-Events sind protokolliert
