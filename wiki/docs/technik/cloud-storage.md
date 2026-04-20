# Cloud-Storage

Die FEGH-Verwaltung speichert ihre verschluesselten Daten in einer WebDAV-Cloud — kompatibel mit STRATO HiDrive, Nextcloud, ownCloud und jedem generischen WebDAV-Server. Der Adapter ist provider-agnostisch.

## Funktionsweise im Detail

### Das Problem, das wir loesen

EGH-Einrichtungen haben unterschiedliche Bedarfe an Cloud-Storage:

- **Kleine Traeger** (1-2 Standorte, 3-5 Mitarbeiter): wollen
  keine eigene IT betreiben, nehmen einen Managed Service wie
  STRATO HiDrive oder Nextcloud-Hosting (~30 EUR/Monat).
- **Mittlere Traeger** (5-10 Standorte): betreiben eigenes
  Nextcloud — Kosten skalieren nicht mit Mitarbeiter-Zahl,
  Datenhoheit bleibt vollstaendig intern.
- **Grosse Traeger / KRITIS**: nutzen ownCloud Enterprise oder
  selbst geschriebenen WebDAV-Server mit Audit-Anbindung.

Einen einzigen Provider vorzuschreiben waere falsch. Eine
**WebDAV-Abstraktion** mit vier Adaptern passt sich jeder
Infrastruktur an — und ermoeglicht sogar den **Wechsel** (z. B.
Migration von HiDrive zu einem eigenen Nextcloud), ohne dass die
App geaendert werden muss.

### Konkretes Szenario: Migration von HiDrive zu Nextcloud

**Ausgangslage**: Assistenz gGmbH hat 2 Jahre mit HiDrive gearbeitet
(30 EUR/Monat bei 600 GB). Neue Entscheidung: wegen Datenhoheits-
Anforderungen Nextcloud bei einem deutschen Anbieter (Hetzner).

**Migrations-Ablauf**:

1. **Parallelbetrieb einrichten**: Bei Hetzner Nextcloud-Instanz
   bestellen, TLS einrichten, Admin-Account anlegen.
2. **Alle Dateien kopieren**: `rclone` (Open-Source-Tool) von
   HiDrive nach Nextcloud. Dauer ~4 h fuer 600 GB (abhaengig von
   DSL-Upload).
3. **In der FEGH-App** Einstellungen aendern:
   - `Einstellungen → Cloud-Zugang → Provider wechseln`
   - Auswahl: Nextcloud statt HiDrive
   - Neue URL, neue Credentials
   - "Verbindung testen" → OK
4. **Sync-Diagnose** auf **allen Geraeten**: jeder Client sollte
   die Dateien in der neuen Location lesen koennen.
5. **Verifikation**: ein paar Klient-Records oeffnen, ein
   Monatslauf simulieren (ohne Versand).
6. **HiDrive-Kuendigung** zum naechsten Quartal.

Die App selbst hat davon **nichts gemerkt** — die `CloudAdapter`-
Schnittstelle bleibt identisch, nur der konkrete Adapter wechselt
von `HidriveAdapter` zu `NextcloudAdapter`.

### Die `CloudAdapter`-Schnittstelle

Alle vier Adapter implementieren dasselbe Interface:

```dart
abstract class CloudAdapter {
  Future<CloudResult<void>> testConnection();
  Future<CloudResult<void>> createDirectory(String path);
  Future<CloudResult<void>> upload(String path, Uint8List data);
  Future<CloudResult<Uint8List>> download(String path);
  Future<CloudResult<void>> delete(String path);
  Future<CloudResult<List<CloudFile>>> list(String path);
  Future<CloudResult<void>> move(String from, String to);
}
```

Der Code, der den Adapter nutzt, sieht nicht welcher Provider
darunter liegt. Er ruft `adapter.upload(path, bytes)` und bekommt
ein `CloudResult<void>` zurueck — entweder Erfolg oder Fehler mit
strukturierter Beschreibung.

### Provider-Eigenheiten (und wie sie gekapselt sind)

Jeder Provider hat eigene Macken:

- **HiDrive** braucht bei MKCOL den Content-Type **nicht** zu
  setzen (manche HTTP-Clients schlagen sonst auf).
- **Nextcloud** will TLS-Zertifikate strikt — Self-Signed-Dev-Certs
  muessen explizit als trusted markiert werden.
- **ownCloud Enterprise** nutzt `/remote.php/dav/files/<user>/`
  als Root-Pfad statt `/`.
- **Generic WebDAV** ist unterschiedlich je nach Server-Implementierung
  (dufs vs. nginx vs. Apache mod_dav).

Diese Eigenheiten sind **im jeweiligen Adapter** versteckt. Die
App ruft immer `adapter.upload(path, ...)` — der Adapter
uebersetzt den Pfad, setzt die richtigen Headers, handhabt
Retry-Logik bei 5xx.

### Die Pfad-Struktur ueber `FeghPaths`

Um zu verhindern, dass die App-Logik selbst Pfade zusammenbaut
(Quelle unzaehliger Bugs), gibt es die Helper-Klasse
`FeghPaths`:

```dart
final paths = FeghPaths(orgId: 'assistenz-ggmbh');

paths.administration               // /eingliederungshilfe/organizations/assistenz-ggmbh/administration
paths.teamRoot('hauptstrasse')     // .../teams/hauptstrasse
paths.teamClientRecord('hauptstrasse', clientId)
                                   // .../teams/hauptstrasse/clients/<clientId>.bin
paths.teamShiftRecord('hauptstrasse', shiftId)
                                   // .../teams/hauptstrasse/schedules/<shiftId>.bin
```

Alle Cloud-Operationen nutzen diese Helper-Methoden — nie
Pfad-Strings direkt. Damit ist der **gesamte Pfad-Aufbau an
genau einer Stelle** und Cross-App-konsistent (15 Unit-Tests
in `fegh_cloud/test/fegh_paths_test.dart`).

### Verschluesselung vor Upload

Wichtig: **Alles, was in die Cloud geht, ist vorher verschluesselt.**

Der Cloud-Adapter sieht nur `Uint8List`. Was drin steht — Klartext,
verschluesseltes JSON, Schluesselmaterial — ist ihm egal. Die
Verschluesselung passiert **eine Ebene hoch** im Service-Layer:

```
Client.toJson() → jsonEncode → utf8-Bytes → AES-256-GCM mit
Team-Key + Nonce → ciphertext → adapter.upload(path, ciphertext)
```

Selbst wer root-Zugriff auf den Cloud-Speicher hat (z. B. ein
Admin beim Cloud-Provider), sieht nur zufaellige Bytes. Ohne
Team-Key keine Dekodierung.

### Rechtlicher Hintergrund

- **Art. 32 DSGVO** — Verschluesselung ist eine der TOMs; wir
  verschluesseln **sowohl Transport (TLS) als auch Storage (AES-GCM)**.
- **§67a SGB X** — Sozialgeheimnis; der Cloud-Provider hat keinen
  Zugriff auf den Inhalt (Zero-Trust gegenueber Provider).
- **Art. 28 DSGVO** (AV-Vertrag) — bei HiDrive/Nextcloud-Hosting
  braucht der Traeger einen AV-Vertrag mit dem Provider. Bei
  selbst gehostetem Nextcloud entfaellt das.
- **BSI IT-Grundschutz OPS.2.2 (Cloud-Nutzung)** — Verschluesselung
  vor Upload ist dort explizit gefordert.

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
