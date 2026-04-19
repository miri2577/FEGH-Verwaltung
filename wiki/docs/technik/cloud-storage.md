# Cloud-Storage

Die FEGH-Verwaltung speichert ihre verschluesselten Daten in der Cloud — standardmaessig STRATO HiDrive Business, aber der Adapter ist provider-agnostisch.

## Unterstuetzte Anbieter

Ueber das Shared-Paket `fegh_cloud`:

- **HiDrive (STRATO)** — WebDAV mit bestimmten Eigenheiten (z. B. MKCOL ohne Content-Type)
- **Nextcloud** — Standard-WebDAV
- **ownCloud** — Standard-WebDAV
- **Generisches WebDAV** — beliebige RFC-4918-konforme Server

Die Wahl des Providers erfolgt in den Einstellungen; intern ist es egal, weil alle vier dieselbe `CloudAdapter`-Schnittstelle implementieren.

## Warum WebDAV?

- Offener Standard (RFC 4918), weit verbreitet
- Keine proprietaere API, kein Vendor-Lock-in
- Provider wie STRATO HiDrive bieten es fuer privacy-freundliche Business-Accounts
- Flutter-Support ueber das `webdav_client`-Paket — stabil und maintained

Eine eigene REST-API (z. B. S3 oder proprietaerer Backend) wuerde ein zusaetzliches Backend erfordern, das wir bewusst vermeiden. Die App ist **Server-los** in dem Sinn, dass es keine FEGH-Zentral-Instanz gibt — der Traeger mietet seine eigene WebDAV-Kapazitaet.

## Ordnerstruktur (Beispiel)

```
eingliederungshilfe/
├── organizations/
│   └── <orgId>/
│       ├── administration/
│       │   ├── users/
│       │   │   └── roles.json              (encrypted)
│       │   └── organization.bin            (encrypted org metadata)
│       ├── teams/
│       │   └── <teamId>/
│       │       ├── team-key.bin            (wrapped DEK)
│       │       ├── clients/
│       │       │   └── <clientId>.bin      (encrypted Client-Record)
│       │       ├── shifts/
│       │       └── timesheets/
│       └── _index/
│           └── clients.bin                 (encrypted search index)
```

Jede `.bin`-Datei ist ein `EncryptedRecord` aus `fegh_crypto`: Plaintext-JSON → AES-256-GCM mit einem DEK → serialisierter Record mit Nonce, MAC, Key-ID des Wraps.

## Zero-Knowledge-Prinzip

Der Cloud-Anbieter sieht nie Klartext-Daten:

- **Plaintext-Namen** in Pfaden werden vermieden, wo moeglich (UUIDs statt Klient-Namen).
- **Inhalte** sind immer verschluesselt (auch `roles.json`, `team-key.bin`).
- **Metadaten** wie Dateigroesse und Aenderungszeitpunkt sind notgedrungen sichtbar.

Den MEK kennt nur der User (ableitbar aus der Sync-Passphrase). Die Cloud hat keine Kopie davon. Ergo: Wir koennen Passwoerter nicht zuruecksetzen — **ohne Sync-Passphrase keine Daten**. Aus diesem Grund gibt es die [Recovery-Phrase](../features/backup.md#recovery-phrase-admin-mek).

## Cert-Pinning (optional)

Fuer hohe Sicherheitsanforderungen unterstuetzt der Adapter optionales SPKI-Hashing-Pinning des TLS-Zertifikats. Historisch gab es im Projekt Bugs mit einer eigenen `_PinnedHttpClient`-Klasse — diese wurden beim Umzug auf `webdav_client` strukturell eliminiert.

## STRATO HiDrive: Besonderheiten

- **MKCOL** mit `Content-Type: application/octet-stream` fuehrt zu `415 Unsupported Media Type`. Das `webdav_client`-Paket setzt keinen Content-Type bei MKCOL, was die Kompatibilitaet wiederherstellt.
- **App-Passwoerter** statt Haupt-Passwort empfohlen (HiDrive-Portal → Konto → App-Passwoerter). Berechtigung "WebDAV Business" reicht.
- **Path-Praefix** `/users/<username>/` ist bei HiDrive-Business der normale Root.

## Multi-Gerate-Sync

Die Apps synchronisieren bidirektional:

- **Pull**: Start-Sync liest Cloud → lokaler Cache (SharedPreferences)
- **Push**: Bei jeder Schreibaktion wird die Cloud aktualisiert
- **Konflikte**: aktuell Last-Write-Wins (Aenderungszeitpunkt) — Konflikt-Dialog geplant

## Siehe auch

- [Shared-Packages](shared-packages.md) — Aufbau von `fegh_cloud`
- [Zusammenspiel mit FEGH-Dokumentation](zusammenspiel.md)
- [Backup und Recovery](../features/backup.md)
