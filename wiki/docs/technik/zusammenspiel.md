# Zusammenspiel FEGH-Verwaltung und FEGH-Dokumentation

Beide Apps sind technisch eigenstaendig, teilen aber Datenmodelle und
Wire-Formate. Diese Seite beschreibt wie sie zusammenarbeiten und wo
die Grenzen liegen.

## Funktionsweise im Detail

### Das Problem, das wir loesen

Ein Mitarbeiter schreibt am Nachmittag einen Verlaufsbericht auf
dem **Tablet** (Doku-App). Die Teamleitung liest ihn abends am
**Buero-PC** (Verwaltungs-App) — und ergaenzt ihn um Abrechnungs-
notizen. Beide sehen denselben Klienten, dieselbe Schicht, dasselbe
Ereignis — aber mit **unterschiedlichen Werkzeugen** und
**unterschiedlichen Berechtigungen**.

Naive Umsetzung: zwei getrennte Apps, die beide den Klient-Record
haben und sich ueber irgendeine Schnittstelle gegenseitig updaten.
Ergebnis: Schema-Drift, Merge-Konflikte, Inkonsistenzen. Wenn der
Mitarbeiter in Version 1.2 der Doku-App ein neues Feld anlegt und
die Verwaltung in Version 2.0 haengt, passt es nicht zusammen.

Unsere Loesung: **Ein einziges Datenmodell**, geteilt ueber das
Paket `fegh_core`. Beide Apps instantiieren dieselbe Dart-Klasse
`Client`, serialisieren sie identisch, speichern sie mit
identischen Cloud-Pfaden. Schema-Drift ist per Definition
unmoeglich.

### Konkretes Szenario: Ein Klient im Tagesverlauf

**09:00 Uhr — Admin Anja legt in der Verwaltung einen neuen
Klienten an**:

- Name Frau S., geboren 1985, Bundesland Berlin
- Kostentraeger Sozialamt Friedrichshain-Kreuzberg, Fallnummer
  EGH-2026-0987
- Team Hauptstrasse zugewiesen

Verwaltung schreibt das als `Client`-JSON in
`/teams/hauptstrasse/clients/<clientId>.bin`
(AES-256-GCM, mit dem Team-Key).

**09:05 Uhr — Mitarbeiterin Mia oeffnet die Doku-App auf ihrem
Tablet**:

- Geraet synct: laedt den neuen verschluesselten Record von der
  Cloud.
- Lokaler DEK entschluesselt Team-Key.
- Team-Key entschluesselt Frau S.'s Record.
- `Client.fromJson(...)` — dasselbe Model wie die Verwaltung
  benutzt.
- Mia sieht Frau S. in ihrer Klientenliste.

**11:30 Uhr — Mia dokumentiert einen Termin bei Frau S.** —
schreibt einen kurzen Verlaufsbericht. Doku-App schreibt das als
`Termin`-Record in die Cloud.

**17:45 Uhr — Anja sieht den Bericht im Buero in der
Verwaltung.** Beide Apps nutzen denselben `Termin`-Record, dieselbe
`Client`-Referenz, denselben Verlaufsbericht-Text.

Keine Synchronisation-Merge-Logik. Kein Schema-Mapping. Kein
"import/export". Beide Apps lesen und schreiben **dieselben Dateien
auf demselben Cloud-Speicher, mit demselben Datenmodell**.

### Die Trennlinien zwischen den Apps

Obwohl sie Daten teilen, haben die Apps **eigene Verantwortungs-
bereiche**:

| Funktion | Doku-App | Verwaltung |
|----------|:--------:|:----------:|
| Klient anlegen | ✗ | ✓ |
| Klient-Stammdaten bearbeiten | ✗ | ✓ |
| Verlaufsbericht schreiben | ✓ | ✓ |
| Termin dokumentieren | ✓ | ✓ |
| Medikationsgabe quittieren | ✓ | (eher nicht) |
| Medikationsplan anlegen | ✗ | ✓ |
| Kassenbuch-Eintrag buchen | ✓ | (moeglich) |
| Kassenbuch-Eintrag freigeben | ✓ | ✓ |
| Monatsabschluss Kassenbuch | ✗ | ✓ |
| Schicht starten/beenden (stempeln) | ✓ | ✓ |
| Dienstplan anlegen | ✗ | ✓ |
| Tausch-Anfrage stellen | ✓ | ✓ |
| Tausch-Anfrage genehmigen | ✗ | ✓ |
| XRechnung erstellen | ✗ | ✓ |
| Monatsbericht | ✓ (Wirkungsmessung) | ✓ (alle Typen) |

Die Trennung ist keine UI-Entscheidung, sondern folgt aus dem
**Usecase**: wer sitzt gerade am Geraet? Im Einsatz am Klienten
steht das Tablet im Vordergrund; im Buero der Bildschirm mit
Tabellen und PDF-Viewer.

### Konflikt-Behandlung bei gleichzeitigen Aenderungen

Selten, aber passiert: Mia und Anja aendern **gleichzeitig** denselben
Klient-Record (z. B. Mia traegt eine neue Anschrift ein, Anja
korrigiert zeitgleich die Telefonnummer).

Beide Geraete haben lokal eine neue Version. Beim Upload:

1. **Geraet A** lookte den `eTag`/`updatedAt` des letzten Servers
   und schreibt mit `If-Unmodified-Since`-Header.
2. **Geraet B** kommt eine Sekunde spaeter — Server hat neuen Stand
   von A.
3. `If-Unmodified-Since` schlaegt fehl → HTTP 412.
4. Geraet B laedt die neue Version von A, merged lokal beide
   Aenderungen (Mias Adresse + Anjas Telefon), schreibt erneut.
5. Audit-Event `sync.conflict.resolved` mit beiden Versionen.

Fuer append-only Daten (BtM-Gabe, Audit-Log) gibt es keinen Konflikt
— nur die Summe wird hochgeladen.

### Rechtlicher Hintergrund

- **Art. 5 DSGVO** (Datensparsamkeit, Richtigkeit) — ein einziges
  Datenmodell ueber beide Apps verhindert abweichende Datenstaende.
- **§67a SGB X** — Sozialgeheimnis; gemeinsame Cloud mit
  Team-Key-Verschluesselung setzt Need-to-know um.
- **Art. 32 DSGVO** — Verschluesselung + konsistente Schemata
  reduzieren Angriffsflaeche (kein Gateway-Service zum Abfangen).

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
