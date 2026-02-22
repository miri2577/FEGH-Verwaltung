# Analyse & Entwicklungsplan: Personalverwaltung

**Datum:** 2026-02-22
**Status:** Analyse abgeschlossen, Umsetzung offen

---

## 1. IST-Zustand Personalverwaltung

### Architektur
- Flutter Desktop-App (macOS/Windows/Linux), min. 1400x900
- State Management: Riverpod (StateNotifier + Notifier Mix)
- 11-Tab-Layout: Dashboard, Mitarbeiter, Teams, Klienten, Dienstplan, Urlaub, Zeiterfassung, Kapazität, Berichte, ICF, Admin
- Lokale JSON-Dateien + HiDrive WebDAV Cloud-Sync
- AES-256-GCM Verschlüsselung (DEK/MEK)
- RBAC mit 5 Rollen via `roles.json` auf HiDrive

### Was funktioniert (echte Daten)
| Feature | Status | Sync |
|---------|--------|------|
| Mitarbeiter CRUD | Funktional | HiDrive (manifest-basiert) |
| Teams CRUD | Funktional | HiDrive (manifest-basiert) |
| Klienten CRUD | Funktional | HiDrive (team-scoped, verschlüsselt) |
| Dienstplan | Funktional | HiDrive |
| Urlaubsanträge | Funktional | HiDrive |
| Zeiterfassung | Funktional | Lokal |
| RBAC/Berechtigungen | Funktional | roles.json auf HiDrive |
| Admin-Konsole | Funktional | Health-Checks live |
| Audit-Log | Funktional | Lokal (append-only) |
| Benachrichtigungen | Funktional | Lokal |

### Was NICHT funktioniert (Mockup/Stub)
| Feature | Problem |
|---------|---------|
| **Dashboard KPIs** | Komplett hardcoded: "42", "8", "12", "87%", "156", "24" |
| **Dashboard Activity Feed** | Hardcoded Namen: "Maria Schmidt", "Thomas Müller" etc. |
| **Dashboard Pie Chart** | Hardcoded: 35 Ambulant, 30 Stationär, 20 Beratung, 15 Verwaltung |
| **Dashboard Line Chart** | Hardcoded FlSpot-Werte |
| **Statusleiste "Letzte Sync"** | Hardcoded String "vor 2 Min" |
| **Kapazität (historisch)** | Explizit als "mock for now" markiert |
| **ICF/TIB Screen** | Stub: "wird implementiert..." |
| **Fallback-Klienten** | 4 Sample-Clients wenn Laden fehlschlägt |

### Technische Schulden
1. **Manifest nicht persistent** - `_loadLocalManifest()` erstellt immer leeres Manifest (State zwischen Sessions verloren)
2. **Triviale Checksum** - `_calculateChecksum()` nutzt String-Länge statt echtem Hash
3. **Certificate Pinning Placeholder** - `AAAA...`/`BBBB...` Stub-Werte
4. **Debug-MEK unsicher** - Fixed Key `List.filled(32, 42)` im Debug-Modus
5. **Doppeltes VacationRequest Model** - `vacation.dart` vs `vacation_request.dart` (inkompatibel)
6. **Drift deklariert aber ungenutzt** - `drift ^2.18.0` in pubspec.yaml
7. **Passwort im Klartext** - In AppSettings JSON via SharedPreferences

---

## 2. IST-Zustand Eingliederungshilfe-App (Mobile)

### Architektur
- Flutter Mobile/Desktop (iOS/Android/macOS/Web)
- State Management: Provider (ChangeNotifier)
- JSON-Serialisierung via `json_annotation` + `build_runner`
- SecureStorageService mit CryptoStorage (AES-256-GCM)
- HiDrive WebDAV Sync (Bi-direktional)

### Klient-Model (EH-App)
```
Client {
  id, klientenId, name, vorname, nachname
  geburtsdatum, betreuungSeit
  kostenuebernahme, kostenuebernahmeVon/Bis
  fachleistungsstunden (int), fachleistungsIntervall, hilfeTyp
  verbrauchteStunden (double), kalkulationsfaktorOverride, stundensatzOverride
  icfBereiche, tibZiele, individuelleTibZiele
  vertreter1Id, vertreter2Id
}
```

### Klient-Model (Personalverwaltung)
```
Client {
  id, firstName, lastName, teamId
  email, phone, address, dateOfBirth
  status (active/inactive/pending/archived)
  priority (low/medium/high/urgent)
  services (ambulant/stationär/beratung/...)
  caseManager, insuranceNumber
  emergencyContact, emergencyPhone
  assignedEmployees, responsibleEmployeeId, deputyEmployeeId, deputy2EmployeeId
  customFields, notes
}
```

---

## 3. Vergleich: Datenmodell-Lücken

### Felder die in der Personalverwaltung FEHLEN (aber in EH existieren)
| Feld | Beschreibung | Wichtigkeit |
|------|-------------|-------------|
| `fachleistungsstunden` | Bewilligte FLS pro Intervall | **KRITISCH** |
| `fachleistungsIntervall` | woechentlich/monatlich/jaehrlich | **KRITISCH** |
| `hilfeTyp` | Eingliederungshilfe/Familienhilfe | **HOCH** |
| `kostenuebernahme` | Kostenträger | **HOCH** |
| `kostenuebernahmeVon/Bis` | Zeitraum Kostenübernahme | **HOCH** |
| `betreuungSeit` | Betreuungsbeginn | MITTEL |
| `icfBereiche` | ICF-Kategorien | MITTEL |
| `tibZiele` | TIB-Ziele | MITTEL |
| `individuelleTibZiele` | Individuelle Ziele | MITTEL |
| `kalkulationsfaktorOverride` | KLE-Faktor pro Klient | NIEDRIG |
| `stundensatzOverride` | EUR-Satz pro Klient | NIEDRIG |

### Felder die in der EH-App FEHLEN (aber in PV existieren)
| Feld | Beschreibung | Sync-relevant |
|------|-------------|--------------|
| `teamId` | Team-Zuordnung | **JA** - existiert implizit über EH-Settings |
| `status` | Aktiv/Inaktiv/Pending/Archiviert | **JA** - fehlt in EH |
| `priority` | Dringlichkeit | Nein |
| `services` | Leistungsarten | Nein |
| `assignedEmployees` | Zugewiesene MA | **JA** - EH hat vertreter1/2Id |
| `responsibleEmployeeId` | Hauptverantwortlicher | **JA** |
| `insuranceNumber` | Versicherungsnummer | Nein |
| `emergencyContact/Phone` | Notfallkontakt | Nein |
| `customFields` | Erweiterbare Felder | Zukunft |

---

## 4. HiDrive Sync-Architektur (IST)

### Gemeinsame Pfadstruktur (bereits kompatibel!)
```
HiDrive: /users/{username}/
└── eingliederungshilfe/
    └── organizations/{orgId}/
        ├── administration/
        │   ├── clients-index.bin          (verschlüsselt)
        │   ├── users/roles.json           (RBAC)
        │   └── .sync-manifest.json
        ├── teams/
        │   └── {teamId}/
        │       ├── clients/
        │       │   └── {clientId}.bin      (verschlüsselt)
        │       ├── schedules/
        │       ├── worktime/
        │       └── reports/
        └── shared/
            └── messages/
```

### Sync-Flow (Soll)
```
Personalverwaltung (Admin)          HiDrive Cloud              EH-App (Mitarbeiter)
       │                                │                            │
       ├─ Klient anlegen ───────────────►│                            │
       ├─ Team zuweisen ────────────────►│                            │
       ├─ FLS festlegen ───────────────►│                            │
       │                                │◄───── syncFromCloud() ─────┤
       │                                │─────► Klient erscheint ───►│
       │                                │                            │
       │                                │◄───── Termin erstellt ─────┤
       │                                │◄───── FLS verbraucht ──────┤
       │                                │                            │
       ├─ Dashboard live ◄──────────────│                            │
```

---

## 5. Entwicklungsplan

### Phase 1: Client-Model angleichen (Voraussetzung für alles)

**Ziel:** Das PV-Client-Model muss alle EH-relevanten Felder enthalten, damit beim Sync keine Daten verloren gehen.

**Datei:** `lib/models/client.dart`

Neue Felder hinzufügen:
```dart
// Eingliederungshilfe-spezifisch
final int? fachleistungsstunden;
final String? fachleistungsIntervall;     // woechentlich/monatlich/jaehrlich
final String? hilfeTyp;                    // eingliederungshilfe/familienhilfe
final String? kostenuebernahme;            // Kostenträger
final DateTime? kostenuebernahmeVon;
final DateTime? kostenuebernahmeBis;
final DateTime? betreuungSeit;
final List<String>? icfBereiche;
final List<String>? tibZiele;
final List<String>? individuelleTibZiele;
final double? kalkulationsfaktorOverride;
final double? stundensatzOverride;
```

Anpassen: `toJson()`, `fromJson()`, `copyWith()`

**Aufwand:** 1-2 Stunden

---

### Phase 2: Client-Formular erweitern

**Ziel:** Im Client-Formular (PV) müssen alle EH-Felder editierbar sein.

**Datei:** `lib/features/clients/widgets/client_form_dialog.dart`

Neue Tabs/Sections:
1. **Eingliederungshilfe** - FLS, Intervall, HilfeTyp
2. **Kostenübernahme** - Träger, Von/Bis
3. **ICF & TIB** - Bereiche, Ziele
4. **Kalkulation** - Faktor-Override, Stundensatz-Override

**Aufwand:** 3-4 Stunden

---

### Phase 3: Dashboard mit echten Daten

**Ziel:** Alle Mockup-Daten durch Live-Provider-Daten ersetzen.

**Datei:** `lib/features/dashboard/dashboard_screen.dart`

| KPI | Mockup | Echtdaten-Quelle |
|-----|--------|-----------------|
| Mitarbeiter: "42" | → `ref.watch(employeeProvider).length` |
| Aktive Teams: "8" | → `ref.watch(teamProvider).where(active).length` |
| Offene Urlaube: "12" | → `ref.watch(vacationProvider).where(pending).length` |
| Anwesenheitsquote: "87%" | → Berechnung aus Arbeitszeiten |
| Klienten: "156" | → `ref.watch(clientProvider).length` |
| Überstunden: "24" | → Berechnung aus TimesheetService |

Charts:
- Pie Chart: `ref.watch(serviceStatisticsProvider)` (bereits existiert!)
- Line Chart: Monatsweise Berechnung aus Arbeitszeiten
- Activity Feed: Echte Audit-Log-Einträge + Benachrichtigungen

**Aufwand:** 4-6 Stunden

---

### Phase 4: Sync-Brücke PV → EH (Kernstück)

**Ziel:** Klienten die in der PV angelegt werden, erscheinen automatisch in der EH-App.

#### 4a. PV-Seite: Beim Speichern EH-kompatible Daten schreiben

Die `OrgClientSyncService.uploadOrUpdateClient()` schreibt bereits korrekt nach:
`eingliederungshilfe/organizations/{orgId}/teams/{teamId}/clients/{id}.bin`

**Problem:** Das PV-Client-Model hat andere Feldnamen als das EH-Client-Model.

**Lösung:** Ein `ClientSyncAdapter` der zwischen den Formaten konvertiert:

```dart
class ClientSyncAdapter {
  /// PV-Client → EH-kompatibles JSON für HiDrive
  static Map<String, dynamic> toEHFormat(Client pvClient) {
    return {
      'id': pvClient.id,
      'klientenId': pvClient.id,
      'name': pvClient.fullName,
      'vorname': pvClient.firstName,
      'nachname': pvClient.lastName,
      'geburtsdatum': pvClient.dateOfBirth.toIso8601String(),
      'betreuungSeit': pvClient.betreuungSeit?.toIso8601String(),
      'kostenuebernahme': pvClient.kostenuebernahme,
      'kostenuebernahmeVon': pvClient.kostenuebernahmeVon?.toIso8601String(),
      'kostenuebernahmeBis': pvClient.kostenuebernahmeBis?.toIso8601String(),
      'fachleistungsstunden': pvClient.fachleistungsstunden,
      'fachleistungsIntervall': pvClient.fachleistungsIntervall,
      'hilfeTyp': pvClient.hilfeTyp,
      'icfBereiche': pvClient.icfBereiche,
      'tibZiele': pvClient.tibZiele,
      'individuelleTibZiele': pvClient.individuelleTibZiele,
      'verbrauchteStunden': 0.0,  // wird von EH-App gefüllt
      'kalkulationsfaktorOverride': pvClient.kalkulationsfaktorOverride,
      'stundensatzOverride': pvClient.stundensatzOverride,
      'createdAt': pvClient.createdAt.toIso8601String(),
      // Metadaten für PV
      '_pvMeta': {
        'status': pvClient.status.name,
        'priority': pvClient.priority.name,
        'responsibleEmployeeId': pvClient.responsibleEmployeeId,
        'assignedEmployees': pvClient.assignedEmployees,
      },
    };
  }

  /// EH-JSON von HiDrive → PV-Client (für Rücksync)
  static Client fromEHFormat(Map<String, dynamic> json) { ... }
}
```

**Aufwand:** 2-3 Stunden

#### 4b. EH-Seite: Beim Sync PV-Klienten erkennen

Die EH-App liest bereits beim `syncFromCloud()`:
1. `clients-index.bin` → Liste aller Klienten-UUIDs
2. Lädt `.bin` Dateien aus `teams/{teamId}/clients/`
3. Entschlüsselt und speichert lokal

**Problem:** Die EH-App erwartet ihr eigenes JSON-Format. Wenn die PV ein anderes Format schreibt, muss die EH-App damit umgehen können.

**Lösung:** Das Format in Phase 4a wird EH-kompatibel geschrieben. Die EH-App braucht nur minimale Anpassungen:
- `Client.fromJson()` toleriert bereits unbekannte Felder (json_annotation ignoriert sie)
- `_pvMeta` wird einfach als unbekanntes Feld ignoriert

**Aufwand:** 1 Stunde (Testen + ggf. Fallback-Defaults)

---

### Phase 5: Bi-direktionaler Sync (FLS-Verbrauch zurück)

**Ziel:** Die EH-App schreibt `verbrauchteStunden` zurück in die Cloud, die PV zeigt den Fortschritt.

#### 5a. EH-App: verbrauchteStunden zurückschreiben

Beim `syncToCloud()` wird der Klient mit aktuellem `verbrauchteStunden` hochgeladen.
Das passiert bereits! Die EH-App schreibt den kompletten Client zurück.

#### 5b. PV: FLS-Verbrauch anzeigen

Neues Widget: `FLSProgressCard` im Klienten-Detail:
- Ampel-Anzeige (grün/gelb/rot)
- Balkendiagramm: verbraucht / bewilligt
- Gesamtarbeitszeit (mit KLE-Faktor)
- Abrechnungsbetrag

Im Dashboard:
- KPI "FLS-Auslastung" statt dem hardcoded "87%"
- Alert-System für Klienten in Rot-Zone

**Aufwand:** 3-4 Stunden

---

### Phase 6: Mockup-Daten vollständig entfernen

**Ziel:** Keine hardcoded Daten mehr.

| Stelle | Aktion |
|--------|--------|
| `_generateSampleClients()` | Entfernen, leere Liste bei Fehler |
| Dashboard KPIs | Durch Provider-Daten ersetzen (Phase 3) |
| Dashboard Charts | Durch berechnete Daten ersetzen |
| Dashboard Activity Feed | Audit-Log + Notifications auslesen |
| Statusleiste "Letzte Sync" | `settings.lastSyncTime` anzeigen |
| Kapazitäts-History | Aus Arbeitszeiten berechnen |

**Aufwand:** 2-3 Stunden

---

### Phase 7: Technische Schulden beheben

| Problem | Lösung | Aufwand |
|---------|--------|---------|
| Manifest nicht persistent | `_loadLocalManifest()` aus Datei lesen | 1h |
| Triviale Checksum | SHA-256 verwenden (`crypto` package) | 30min |
| Certificate Pinning | Echte STRATO-Pins eintragen | 30min |
| Debug-MEK unsicher | Nur im kDebugMode, Warnung anzeigen | 15min |
| Doppeltes VacationRequest | `vacation.dart` löschen | 30min |
| Drift ungenutzt | Aus pubspec.yaml entfernen | 5min |

**Aufwand:** 3 Stunden

---

## 6. Prioritäts-Reihenfolge

```
Phase 1: Client-Model angleichen ──────────────── [BLOCKER]
    │
    ├── Phase 2: Client-Formular erweitern
    │
    ├── Phase 4a: ClientSyncAdapter (PV→EH)
    │       │
    │       └── Phase 4b: EH-App Sync testen
    │               │
    │               └── Phase 5: Bi-direktional
    │
    ├── Phase 3: Dashboard echte Daten
    │
    ├── Phase 6: Mockups entfernen
    │
    └── Phase 7: Tech Debt
```

**Kritischer Pfad:** Phase 1 → 4a → 4b → 5
**Parallelisierbar:** Phase 2, 3, 6, 7

---

## 7. Risiken & offene Fragen

1. **Verschlüsselungskompatibilität** - Beide Apps nutzen CryptoStorage mit AES-256-GCM, aber:
   - PV nutzt `crypto_storage.dart` (eigene Implementierung)
   - EH nutzt `crypto_storage.dart` (eigene Implementierung)
   - Format muss identisch sein (JSON-Envelope mit IV/Tag/Ciphertext)
   - **Test erforderlich:** PV verschlüsselt → EH entschlüsselt

2. **ID-Kollisionen** - PV generiert IDs als `client_{timestamp}`, EH als `{timestamp}`. Bei Sync könnten Duplikate entstehen.
   - **Lösung:** UUID verwenden (beide Seiten)

3. **Conflict Resolution** - Wenn ein Klient in PV UND EH gleichzeitig bearbeitet wird:
   - Aktuell: Last-Write-Wins (Timestamp)
   - Besser: PV hat Autorität über Stammdaten, EH über Verbrauchsdaten
   - **Klärung:** Welche Felder darf die EH-App überschreiben?

4. **Offline-Verhalten** - Was passiert wenn EH-Mitarbeiter offline Termine erstellt?
   - Aktuell: Lokal gespeichert, beim nächsten Sync hochgeladen
   - PV sieht die Daten erst nach Sync

5. **Team-Zuordnung** - EH-App hat `teamId` in Settings (global), PV hat `teamId` pro Client
   - EH-Mitarbeiter sieht nur Clients seines Teams ✓
   - Admin sieht alle via clients-index ✓
