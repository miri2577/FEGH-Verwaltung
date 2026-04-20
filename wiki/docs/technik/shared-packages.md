# Shared-Packages

Beide Apps (Verwaltung + Dokumentation) teilen zentrale Komponenten
ueber lokale Dart-Packages in einem gemeinsamen Workspace. Das
vermeidet Code-Duplikation und garantiert kompatible Wire-Formate.

## Funktionsweise im Detail

### Das Problem, das wir loesen

Als wir die beiden Apps parallel entwickelten, divergierte der Code
innerhalb weniger Wochen:

- Die Doku-App hatte ihren eigenen `Client`-Datensatz mit
  `geburtsdatum`, `vorname`, `nachname`.
- Die Verwaltung hatte einen eigenen `Client` mit `dateOfBirth`,
  `firstName`, `lastName`, zusaetzlichen Admin-Feldern.
- Beide schrieben auf **denselben Cloud-Speicher**.
- Ein Klient, in der Verwaltung angelegt, war in der Doku-App
  unlesbar — das JSON-Schema passte nicht.

Das klassische Shared-Library-Problem. Loesung: **gemeinsame
Packages im `fegh-shared/`-Workspace**, referenziert per
`path:`-Dependency aus beiden Apps. Beide Apps pullen exakt **denselben
Dart-Code** fuer die geteilten Bausteine.

Zusaetzlicher Vorteil: Packages sind **unabhaengig unit-testbar** —
`fegh_billing` kann gegen KoSIT validieren, ohne dass Flutter
ueberhaupt involviert ist.

### Konkretes Szenario: Ein neues Feld zum Client-Datensatz

**Situation**: Wir wollen einem Klient das neue Feld
`gesetzlicheBetreuung: String?` geben.

**Schritt 1**: Aenderung in `fegh_core/lib/src/models/client.dart`.
Neues Feld hinzufuegen, fromJson/toJson anpassen.

**Schritt 2**: Unit-Test in `fegh_core/test/client_test.dart`: neues
Feld roundtrip-serialisieren.

**Schritt 3**: Commit in `fegh_core`.

**Schritt 4**: In **beiden** Apps `flutter pub get` — der `path:`-
Resolver liest die neue Version automatisch, kein Publishing,
keine Version-Bumps.

**Schritt 5**: UI anpassen:
- Verwaltung: Client-Form erweitern, neues Feld pflegbar
- Doku-App: nur anzeigen (Admin setzt)

**Ergebnis**: Eine Schema-Aenderung, ein zentraler Commit, beide
Apps zur gleichen Zeit kompatibel.

### Warum `path:` statt Pub.dev?

Pub.dev braucht Versionsnummern, Publish-Schritte, manuelle
Releases. Fuer **privat genutzte** Packages, die sich synchron
mit der App-Entwicklung aendern, ist das Overhead. `path:` zeigt
direkt auf das lokale Verzeichnis — Aenderung in shared wirkt sofort
in beiden Apps.

Wenn die Packages spaeter open-source oder commercial verteilt
werden, kann man jederzeit auf Pub.dev umstellen. Heute bleiben
sie privat im Monorepo-aehnlichen Layout.

### Test-Strategie pro Package

Jedes Package hat sein eigenes `test/`-Verzeichnis. Pro Paket
wird fuer Dart-only-Code das `test`-Package benutzt (schneller
als `flutter_test`, keine Flutter-Umgebung noetig). Die
Package-Tests laufen in CI/CD separat — Aenderungen am Core
brechen sofort sichtbar **genau ein** Package, nicht die ganze
App.

| Package | Tests | Abdeckung |
|---------|-------|-----------|
| fegh_core | 38 Tests (Client, Employee, Team, Shift, Bundesland) | Modelle + fromJson/toJson |
| fegh_cloud | 15 Tests (FeghPaths) | Pfad-Helper |
| fegh_billing | 12 Tests | XRechnung-XML, VATEX-Codes |
| fegh_crypto | ~20 Tests | AES-GCM, PBKDF2, Provisioning |
| fegh_compliance | 12 SIEM + 10 Audit-Tests | Exports, Schema |
| fegh_auth_oidc | 13 Tests (PKCE, Tokens) | OIDC-Flow |
| fegh_backup | 8 Tests (Envelope-Roundtrip) | Backup/Restore |
| fegh_pdf_kit | 5 Tests | Design-Tokens |
| fegh_chat | 6 Tests | Matrix-Adapter |

### Veroeffentlichungs-Perspektive

Diese Packages sind so gebaut, dass sie potenziell **einzeln
ausgekoppelt werden koennen**:

- `fegh_cloud` — generischer WebDAV-Adapter mit vier Providern,
  koennte anderen Flutter-Apps dienen
- `fegh_billing` — XRechnung-UBL-Generator (deutscher Markt)
- `fegh_auth_oidc` — OIDC-SSO fuer Desktop-Apps mit Loopback-
  Redirect
- `fegh_compliance` — DSGVO-Audit-Logger + SIEM-Exporter

Wenn ein anderer EGH-Anbieter die Bausteine nutzen moechte, ist die
Umstellung auf Pub.dev-Publishing eine Konfigurationsaenderung,
kein Refactoring.

## Verzeichnisstruktur

```
C:\fegh-shared\
├── fegh_crypto\       (AES-256-GCM, Provisioning-Token)
├── fegh_cloud\        (WebDAV-Adapter: HiDrive, Nextcloud, ownCloud)
├── fegh_compliance\   (GEPLANT: Audit-Log + DSGVO-Export)
├── fegh_pdf_kit\      (GEPLANT: Hybrid-Report-Design)
└── fegh_backup\       (GEPLANT: Backup + Recovery)
```

Beide Apps referenzieren die Packages via `path:`-Dependency in
`pubspec.yaml`:

```yaml
dependencies:
  fegh_crypto:
    path: ../fegh-shared/fegh_crypto
  fegh_cloud:
    path: ../fegh-shared/fegh_cloud
```

## fegh_crypto

Pure Dart-Krypto ohne Storage-Abhaengigkeit.

- **`EncryptedRecord`** - typisierte Huelle fuer JSON-Wire-Format
  (v:1, alg:AES-256-GCM, nonce/aad/ciphertext/tag, dekWrapped)
- **`FeghCrypto.encryptRecord` / `decryptRecord`** - AES-256-GCM mit
  DEK-Wrapping
- **`ProvisioningToken`** - PIN-verschluesseltes egh-provisioning-v1
  Token
- **`HidriveCredentials`** - Sub-Objekt fuer HiDrive-Login im Token

Contract-Tests: 21 Tests (Round-Trip, AAD-Binding, Cross-App-Interop).

## fegh_cloud

WebDAV-Abstraktion, basiert auf `webdav_client: ^1.2.2`.

- **`CloudAdapter`** - abstract Interface (testConnection,
  createDirectory, upload, download, delete, list, listDirectories,
  exists)
- **`CloudResult<T>`** - typisiertes Ergebnis mit statusCode
- **`CloudEntry`** - Datei- oder Ordner-Eintrag

Provider-Adapter:
- `HidriveAdapter` - STRATO HiDrive via Basic Auth + URL-Schema
  `/users/{user}/...`
- `NextcloudAdapter` - URL-Schema `/remote.php/dav/files/{user}/`,
  App-Token-Auth
- `OwncloudAdapter` - erbt Nextcloud-Impl
- `GenericWebdavAdapter` - beliebige WebDAV-Server

**Wichtig:** Das Package behandelt provider-spezifische Quirks wie
den STRATO-MKCOL-Content-Type-Bug korrekt, ohne eigene HTTP-Tricks
im App-Code.

## Wire-Format-Stabilitaet

Das Shared-Package `fegh_crypto` ist **Single Source of Truth**
fuer das JSON-Wire-Format. Solange beide Apps dasselbe Package
nutzen, ist bitidentische Kompatibilitaet garantiert.

Die Contract-Tests im Package pruefen:
- Round-Trip: Encrypt A -> Decrypt A -> identischer Klartext
- Cross-App-Simulation: Verwaltung erzeugt -> Doku liest
- AAD-Canonical-Encoding (Key-Reihenfolge relevant!)
- Auth-Tag bricht bei Bit-Flip
- Falscher MEK = decrypt schlaegt fehl

## Entwicklung

Wenn du eines der Packages weiterentwickelst:

1. Ins Shared-Package wechseln (`cd C:\fegh-shared\fegh_crypto`)
2. Tests schreiben + laufen lassen (`flutter test`)
3. Beide Apps via `flutter pub get` die Aenderungen uebernehmen
   lassen
4. In beiden Apps einmal bauen (`flutter build windows` oder
   `flutter analyze`), um Regressionen zu erkennen

!!! tip "Versionierung"
    Aktuell laufen die Packages alle auf `0.1.0`. Sobald eines
    extern publiziert wird (pub.dev oder interner Mirror), gehen
    wir zu semver 1.0.0.
