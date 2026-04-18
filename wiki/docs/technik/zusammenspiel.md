# Zusammenspiel FEGH-Verwaltung und FEGH-Dokumentation

Beide Apps sind technisch eigenstaendig, teilen aber Datenmodelle und
Wire-Formate. Diese Seite beschreibt wie sie zusammenarbeiten und wo
die Grenzen liegen.

## Architektur-Ueberblick

```
┌─────────────────────────────────────────────────────────────┐
│  FEGH-Verwaltung           FEGH-Dokumentation               │
│  (Desktop, Buero)          (iOS/Android/Desktop, Feld)      │
│  ├─ Dashboard              ├─ Klienten                      │
│  ├─ Mitarbeiter            ├─ Termine                       │
│  ├─ Teams                  ├─ Dokumentation                 │
│  ├─ Schichten              ├─ Wirkungsmessung               │
│  ├─ Rechnungen             ├─ Rechnungen (optional)         │
│  └─ Admin-Console          └─ Admin (light)                 │
│                                                              │
│         │                         │                          │
│         └────────┬────────────────┘                          │
│                  │                                           │
│      ┌───────────┴──────────┐                                │
│      │   Shared-Packages    │                                │
│      ├──────────────────────┤                                │
│      │ fegh_crypto          │  AES-256-GCM, ProvisioningToken│
│      │ fegh_cloud           │  WebDAV-Adapter                │
│      │ fegh_compliance (*)  │  Audit-Log + DSGVO             │
│      │ fegh_pdf_kit (*)     │  Hybrid-Report-Design          │
│      │ fegh_backup (*)      │  Backup + Recovery             │
│      └──────────────────────┘                                │
│                  │                                           │
│      ┌───────────┴──────────┐                                │
│      │  Cloud-Storage        │                                │
│      │  (HiDrive, Nextcloud, │                                │
│      │   ownCloud, WebDAV)   │                                │
│      └──────────────────────┘                                │
└─────────────────────────────────────────────────────────────┘

(*) In Planung, siehe PLAN_CLOUD_STORAGE_REFACTOR.md im Doku-Repo
```

## Wer ist Master fuer welche Daten?

| Datentyp | Master | Begruendung |
|---|---|---|
| **Klient-Stammdaten** | Doku-App | Werden beim Klientenkontakt erfasst/aktualisiert |
| **Termine** | Doku-App | Fieldwork, entstehen bei der Dokumentation |
| **Wirkungsmessung** (GAS/POS) | Doku-App | Werden waehrend Betreuung erhoben |
| **Mitarbeiter-Stammdaten** | Verwaltung | Stammdaten-Pflege ist Buero-Arbeit |
| **Teams** | Verwaltung | Orga-Hoheit bei der Verwaltung |
| **Schichtplan** | Verwaltung | Dienstplanung nur sinnvoll zentral |
| **Urlaub/Abwesenheit** | Verwaltung | Genehmigungsworkflow |
| **Rechnungen** | beides | Kann erzeugt werden wo sinnvoll |
| **Bedarfsermittlung** (TIB/BEI_NRW) | Doku-App | Fachliche Erfassung |
| **Rollen** (`roles.json`) | Verwaltung | Admin-Hoheit |
| **Team-Keys** | Verwaltung | Admin-Hoheit |

## Wire-Format: `fegh_crypto`

Alle verschluesselten Records haben identisches JSON-Format:

```json
{
  "v": 1,
  "alg": "AES-256-GCM",
  "nonce": "<base64, 12 Byte>",
  "aad": { "schema": "client", "id": "..." },
  "ciphertext": "<base64>",
  "tag": "<base64, 16 Byte>",
  "dekWrapped": {
    "alg": "AES-256-GCM",
    "nonce": "<base64, 12 Byte>",
    "ciphertext": "<base64>",
    "tag": "<base64, 16 Byte>"
  }
}
```

Provisioning-Tokens (egh-provisioning-v1) werden mit PIN
verschluesselt (PBKDF2 10000 Iter. + AES-256-GCM).

## Cloud-Sync: `fegh_cloud`

Beide Apps nutzen dasselbe Shared-Package fuer WebDAV-Zugriff.
Das Package kennt provider-spezifische Quirks (z.B. STRATO-MKCOL-
Content-Type-Sensitivitaet).

Unterstuetzte Provider:

- **STRATO HiDrive** (SPKI-Cert-Pinning moeglich)
- **Nextcloud** (App-Token-Auth empfohlen)
- **ownCloud** (gleich wie Nextcloud, eigener Provider-Type fuer
  Telemetrie)
- **Generic WebDAV** (Basic Auth, beliebige URL)

## Ordnerstruktur auf HiDrive / Nextcloud

```
{root}/
└── eingliederungshilfe/
    └── organizations/{orgId}/
        ├── administration/          [Admin-only: roles.json, Team-Keys]
        │   └── users/
        │       └── roles.json
        ├── teams/{teamId}/
        │   ├── team-info.bin        [verschluesselt]
        │   ├── clients/             [Klient-Records]
        │   ├── schedules/           [Termine]
        │   ├── reports/             [Berichte]
        │   └── worktime/            [Arbeitszeit]
        ├── shared/
        │   ├── calendar-sync/       [Kalender-Events]
        │   └── messages/            [Matrix-unabhaengige Nachrichten]
        └── employees/               [Mitarbeiter-Profile]
```

## Identische Konfiguration erforderlich

Damit beide Apps auf dieselben Daten zugreifen koennen, muessen
**drei Werte** identisch sein:

1. **HiDrive-User + Passwort** (oder gleicher Nextcloud-Account)
2. **Organization-ID** (z.B. `default`)
3. **Sync-Passphrase** (leitet den Master-Key ab)

Ohne gleiche Sync-Passphrase erzeugt jede App einen anderen MEK -
die Daten der anderen sind dann nicht entschluesselbar.

## Debugging: Sync-Diagnose

Beide Apps haben einen **Sync-Diagnose-Screen**:

- **Verwaltung:** Admin-Console > Sync-Diagnose
- **Doku:** Admin-Dashboard > Sync-Diagnose

Zeigt:
- HiDrive-Verbindungs-Status
- MEK-Quelle (Passphrase / Keychain / Team-Key)
- Teams: lokal vs. Cloud, mit Diff-Anzeige

## Weitere Links

- [FEGH-Dokumentation Wiki - HiDrive-Integration](https://miri2577.github.io/FEGH-Dokumentation/technik/hidrive/)
- [FEGH-Dokumentation Wiki - Verschluesselung](https://miri2577.github.io/FEGH-Dokumentation/sicherheit/verschluesselung/)
- [Architektur im Verwaltungs-Repo](architektur.md)
