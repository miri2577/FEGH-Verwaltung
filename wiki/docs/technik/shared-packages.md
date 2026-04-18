# Shared-Packages

Beide Apps (Verwaltung + Dokumentation) teilen zentrale Komponenten
ueber lokale Dart-Packages in einem gemeinsamen Workspace. Das
vermeidet Code-Duplikation und garantiert kompatible Wire-Formate.

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
