# Architektur

## Funktionsweise im Detail (fuer Entwickler)

### Das Problem, das wir loesen

Die Verwaltungs-App ist kein 1-Mann-1-Feature-Tool. Sie muss:

- **Mehrere Apps bedienen** — FEGH-Dokumentation (mobile) und
  FEGH-Verwaltung (Desktop) teilen ~80 % der Datenmodelle.
- **Mehrere Cloud-Provider unterstuetzen** — HiDrive, Nextcloud,
  ownCloud, generisches WebDAV.
- **Offline-faehig sein** — die Doku-App muss ohne Netz arbeiten
  (Schicht im Keller ohne WLAN), Sync nachholen wenn verfuegbar.
- **Kryptographisch stark getrennte Teams** — Team A darf Team B's
  Daten nicht einmal entschluesseln koennen.
- **Buchhalterisch korrekt sein** — GoBD verbietet nachtraegliche
  Aenderungen, Rechnungen sind unveraenderlich.

Diese Anforderungen treiben die Architektur zu einer **modularen
Shared-Package-Struktur** mit scharfer Trennung zwischen App-
spezifischer Logik und wiederverwendbarem Kern.

### Konkretes Szenario: Ein Klient-Record wird erstellt

So laeuft es durch die Schichten:

1. **UI** (`lib/features/clients/client_form_dialog.dart`) sammelt
   das Formular-Input.
2. **Provider** (`lib/providers/client_provider.dart`) ruft
   `ClientService.create(client)` auf.
3. **Service** (in der Doku-App: `lib/services/client_service.dart`)
   validiert, erzeugt UUID, legt die Instanz als `Client` aus
   `fegh_core` an.
4. **Local Storage**: JSON-serialisierter Record wird in
   `SharedPreferences` (Schluessel `clients_v1`) gespeichert.
5. **Crypto Layer** (`fegh_crypto`): Falls Cloud-Sync aktiv, wird der
   Record mit dem Team-Key verschluesselt (AES-256-GCM mit
   pro-Record-Nonce).
6. **Cloud-Adapter** (`fegh_cloud`, `GenericWebdavAdapter` oder
   `HidriveAdapter`): `PUT` zum Pfad aus `FeghPaths.teamClientRecord(...)`.
7. **Audit-Log** (`fegh_compliance`): Event `client.create` mit
   ClientId + EmployeeId.

Jede Schicht hat **eine Verantwortung** und ist isoliert testbar.
Beim Wechsel des Cloud-Providers wird nur der Adapter getauscht —
der Service und die UI bleiben unberuehrt.

### Die Schichten im Ueberblick

| Schicht | Ort | Aufgabe |
|---------|-----|---------|
| **UI-Komponenten** | `lib/features/<modul>/` | Flutter-Widgets, Dialoge, Listen |
| **Provider** | `lib/providers/` | Riverpod-State fuer UI |
| **Services** | `lib/services/` | Business-Logik pro App |
| **Models (gemeinsam)** | `fegh_core/` | Entitaeten Client, Employee, Team, Shift |
| **Cloud-Adapter** | `fegh_cloud/` | WebDAV-Abstraktion mit 4 Adaptern |
| **Kryptographie** | `fegh_crypto/` | DEK/MEK/Team-Keys, AES-256-GCM |
| **Compliance** | `fegh_compliance/` | AuditLogger + SIEM-Exporter |
| **PDF-Erzeugung** | `fegh_pdf_kit/` | Design-Tokens, Layout-Bausteine |
| **Rechnung** | `fegh_billing/` | XRechnung UBL 2.1 |
| **Chat** | `fegh_chat/` | Matrix/Olm-Adapter |
| **Backup** | `fegh_backup/` | RecoveryService, BackupCodec |
| **OIDC SSO** | `fegh_auth_oidc/` | OAuth 2.0 + PKCE + RFC 8252 Loopback |

### Warum Shared-Packages statt Monorepo?

Doku-App und Verwaltung haben **unterschiedliche Nutzer-Workflows**
(mobile Schicht vs. stationaer Buero) und **unterschiedliche
Deployment-Targets** (Mobile Stores vs. Desktop). Sie teilen aber
die Datenmodelle, Crypto-Stack, Cloud-Layer.

Eine naive Monorepo-Loesung haette beide Apps in eine riesige
Flutter-Code-Basis gezwungen, mit Dead Code fuer jeweils die andere
Plattform. Shared-Packages trennen sauber:

- `fegh_core` kann standalone gebaut und unit-getestet werden
- Jede App pullt nur die Packages, die sie braucht
- Updates am Core brechen nie zwingend beide Apps gleichzeitig
- Testabdeckung ist pro Package messbar

### Die kryptographische Schichtung (Tiefe fuer Security-Auditoren)

```
Login-Passwort (in-memory only)
    |
    v PBKDF2-HMAC-SHA256 (100.000 Iterationen, Salt aus flutter_secure_storage)
    v
DEK (Data Encryption Key, 32 Byte, geraete-lokal)
    |
    v AES-256-GCM-Unwrap
    v
MEK (Master Encryption Key, 32 Byte, org-weit)
    |
    v AES-256-GCM-Unwrap pro Team
    v
Team-Keys (32 Byte pro Team)
    |
    v AES-256-GCM mit per-Record Nonce
    v
Record (Client, Shift, Medication, etc.)
```

Keine Schicht kann ihre uebergeordnete entschluesseln — das Geraet
kennt nur den DEK, ableiten kann es nur bei Login (PBKDF2 verlangt
das Original-Passwort). Der MEK liegt **nur** vom DEK-wrapped
auf dem Geraet.

### Offline-Strategie

Die Doku-App laeuft in Wohngruppen ohne WLAN. Strategie:

1. **Lokale Schreiboperationen** laufen sofort — kein Netz-Wait.
2. **Outgoing Queue** (in `SharedPreferences`) sammelt ausstehende
   Cloud-Uploads.
3. **Sync-Scheduler** versucht alle 5 Minuten oder beim App-Start
   die Queue zu leeren.
4. **Konflikte** (zwei Geraete haben denselben Record geaendert):
   der neuere `updatedAt`-Timestamp gewinnt; der Verlierer wandert
   ins Audit-Log als `sync.conflict.resolved`.

Das ist **Last-Write-Wins** — simpel, aber fuer die meisten
EGH-Szenarien ausreichend (zwei Mitarbeiter aendern selten
denselben Record zeitgleich). Fuer BtM-Buchungen waere LWW zu
wenig (Gabe wird nie ueberschrieben, sondern hinzugefuegt —
append-only fuer medication_administrations_v1).

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
