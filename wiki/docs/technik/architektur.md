# Architektur

## Stack

- **Flutter 3.9.2 / Dart 3** — Cross-platform Desktop-App (Windows/macOS/Linux)
- **State-Management**: [Riverpod 2.x](https://riverpod.dev/) — Provider und StateNotifier, einige FutureProvider-Families
- **Persistenz**: `SharedPreferences` fuer Nutzdaten, `flutter_secure_storage` fuer Cloud-Credentials und MEK
- **Cloud**: WebDAV via `webdav_client`-Paket, abstrahiert durch den Shared-Adapter `fegh_cloud`
- **Kryptographie**: AES-256-GCM mit DEK-Wrapping (PBKDF2-MEK aus Sync-Passphrase), via `fegh_crypto`

## Navigation

Die Haupt-Shell ist `AppShell` (`lib/widgets/layouts/app_shell.dart`). Sie kombiniert:

- **NavigationRail** links (ab 1024 px extended, sonst compact)
- **AppBar** oben mit Suche-Placeholder, NotificationBell und Rollen-Chip
- **Content-Area** rechts — haelt den Builder des aktiven `NavEntry`

Alle Screens sind in einer zentralen `NavEntry`-Registry deklariert (`lib/navigation/nav_registry.dart`), jeder mit einem `visibleFor(UserRole)`-Praedikat. Das macht neue Features zum One-Liner und die Rollen-Sichtbarkeit deklarativ pruefbar.

Sektionen (Gruppen der Rail):

1. **Arbeit** — Meine Arbeit, Medikation, Kassenbuch (fuer Staff)
2. **Klienten** — Liste, ICF/TIB, Medikationsplaene (admin)
3. **Personal** — Dashboard, Mitarbeiter, Teams, Urlaub, Kapazitaet, Wohnraum
4. **Planung** — Dienstplan, Zeitnachweise
5. **Finanzen** — Rechnungen, Berichte
6. **System** — Einstellungen, Backup, Admin-Konsole

## Shared-Packages

Beide Apps (Doku und Verwaltung) teilen sich **sechs** lokale Pakete aus `C:/fegh-shared/`, eingebunden per `path:`-Dependency (kein Pub-Publish):

| Paket | Zweck |
|-------|-------|
| `fegh_crypto` | Wire-Format, AES-256-GCM + DEK-Wrapping, Provisioning-Token |
| `fegh_cloud` | WebDAV-Adapter fuer HiDrive, Nextcloud, ownCloud, Generic |
| `fegh_billing` | Rechnungs-Modelle, XRechnung UBL 2.1 |
| `fegh_compliance` | Audit-Logger (JSON-Lines, gemeinsam fuer beide Apps) |
| `fegh_pdf_kit` | Design-Tokens, Header/Footer, KPI-Row, Standard-Tabellen, Preview |
| `fegh_backup` | Recovery-Phrase, BackupCodec (AES-256-GCM+PBKDF2), Envelope |

Details: [Shared-Packages](shared-packages.md).

## Datenfluss (vereinfacht)

```
UI-Widget
   │
   ▼  ref.watch / ref.read
Riverpod-Provider (FutureProvider, StateNotifier)
   │
   ▼
Service (MedicationService, KassenbuchService, ...)
   │
   ├──► SharedPreferences (lokal)
   │
   ├──► AuditLogger (fegh_compliance, JSON-Lines)
   │
   └──► CloudSyncService ──► CloudAdapter (fegh_cloud) ──► WebDAV
                                       │
                                       ▼
                                FeghCrypto.encryptRecord
                                       │
                                       ▼
                             verschluesselte Cloud-Datei
```

Jede Service-Aktion, die schreibt, ruft zusaetzlich `AuditLogger.log(action, context: …)`. Das macht das Audit-Verhalten zentral und nicht am UI festgezurrt.

## Rollen

`PolicyService` (in `lib/services/policy_service.dart`) liest die Rolle aus der `roles.json` (via `RolesPolicyService`) und bietet feingranulare Methoden: `canCreateClient()`, `canEditClient()`, `canManageTeams()`, `canRebuildIndexes()`, `canViewDocumentation()`. Die Navigation und die Screens fragen diese Methoden ab.

## Cloud-Sync

Drei Abstraktionsebenen:

1. **`CloudAdapter`** (abstract, in `fegh_cloud`) — provider-agnostisches Interface (list, get, put, mkcol, delete).
2. **Konkreter Adapter** (HidriveAdapter, NextcloudAdapter, ...) — Provider-spezifische Quirks (z. B. STRATO HiDrive erwartet bei MKCOL keinen Content-Type).
3. **`CloudSyncService`** (in der Verwaltung) — domaenen-spezifische Logik fuer "saveRecord", "loadRecord", "syncFromRemote".

Der Sync-Service arbeitet mit `EncryptedRecord` aus `fegh_crypto`: Plaintext JSON wird mit einem **DEK** (Data Encryption Key, pro Record frisch) verschluesselt; der DEK wird mit dem **MEK** (Master Encryption Key) gewrappt. So kann die Organisation ihren MEK rotieren, ohne alle Records neu zu verschluesseln — nur die Wraps werden ausgetauscht.

## Siehe auch

- [Shared-Packages](shared-packages.md)
- [Zusammenspiel mit FEGH-Dokumentation](zusammenspiel.md)
- [State-Management (Riverpod)](state.md)
- [Cloud-Storage](cloud-storage.md)
