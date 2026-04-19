# D3: Medikationsmodul (MVP)

**Stand: 19.04.2026** — Plan, noch nicht implementiert.

## Warum

Die FEGH-Verwaltung wird ab jetzt auch stationaer und im Mehrbenutzer-Betrieb genutzt. Mitarbeiter:innen brauchen eine gefuehrte Verabreichung: „Welche Medikamente muss ich heute welchem Klienten geben?" mit sauberer Doku (wer, wann, was). Admin/Teamleitung pflegen die Medikationsplaene. Ohne dieses Modul ist die App in Wohnheimen/TS-Einrichtungen nicht einsatzfaehig.

## Rechtlicher Rahmen (Kurz)

- **AMG** (Arzneimittelgesetz) — Grundregelwerk
- **§§ 132, 63 SGB V** — Delegation aerztlicher Leistungen
- **WTPG / Heimgesetz** — Dokumentationspflichten
- **Art. 9 DSGVO** — Gesundheitsdaten, hoechste Schutzstufe
- **Art. 32 DSGVO** — technische und organisatorische Massnahmen (Signatur, Audit)
- **BtMG** (Betaeubungsmittel) — gesonderte Dokumentation mit zusaetzlichen Pflichten. **Nicht im MVP** (siehe Abgrenzung).

## Scope — drei Varianten

| Scope | Inhalt | Aufwand |
|-------|--------|---------|
| **A — MVP** | Medikationsplan pro Klient + Verabreichungs-Quittung, keine Bestandsfuehrung, kein BTM | 2–3 d |
| **B — Medium** | A + Bedarfsmedikation (PRN) + BTM-Kennzeichnung (ohne Bestand) | +2 d |
| **C — Full** | B + Bestand pro Einrichtung + Verfallsdaten + Rezept-Upload + Nachbestellung | +5 d |

**Empfehlung: Scope A** — stellt den Alltagsbetrieb sicher (Plan + Gabe). B und C sind iterative Erweiterungen.

## Datenmodell (Scope A)

### Medication (Plan-Eintrag)
```dart
class Medication {
  final String id;
  final String clientId;
  final String name;             // z.B. "Sertralin 50 mg"
  final String dosage;           // z.B. "1 Tablette"
  final MedicationSchedule schedule;   // Morgen/Mittag/Abend/Nacht Flags
  final DateTime validFrom;
  final DateTime? validUntil;
  final String? prescribedBy;    // Arztname / Praxis
  final String? notes;
  final bool requiresBtmLog;     // immer false im MVP
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class MedicationSchedule {
  final bool morning;    // z. B. 08:00
  final bool noon;       // 12:00
  final bool evening;    // 18:00
  final bool night;      // 22:00
}
```

### MedicationAdministration (Gabe-Quittung)
```dart
class MedicationAdministration {
  final String id;
  final String medicationId;
  final String clientId;
  final DateTime scheduledAt;          // geplanter Zeitpunkt
  final DateTime? administeredAt;      // tatsaechlich gegeben
  final String? administeredByEmployeeId;
  final AdministrationStatus status;   // given | refused | missed
  final String? reason;                // optional: Grund bei refused/missed
  final String? notes;
  final DateTime createdAt;            // Quittungs-Erstellung
}

enum AdministrationStatus { pending, given, refused, missed }
```

Persistenz: SharedPreferences, Keys `medications_v1` und `medication_administrations_v1`. Cloud-Sync nachziehen, sobald Settings den Key unterstuetzen.

## Services

### MedicationService
```dart
class MedicationService {
  Future<List<Medication>> loadForClient(String clientId);
  Future<List<Medication>> loadAllActive();
  Future<bool> addMedication(Medication m);
  Future<bool> updateMedication(Medication m);
  Future<bool> deactivateMedication(String id);  // soft delete, Plan bleibt historisch
}
```

### MedicationAdministrationService
```dart
class MedicationAdministrationService {
  /// Erzeugt aus den Plaenen die offenen Gaben fuer [date] und gibt
  /// sie zurueck. Falls schon Quittungen existieren, werden sie
  /// aufgeloest (given/refused/missed).
  Future<List<AdministrationSlot>> openSlotsForDate(DateTime date);

  Future<bool> administer(AdministrationSlot slot, {
    required String employeeId,
    String? notes,
  });
  Future<bool> markRefused(AdministrationSlot slot, {required String reason, required String employeeId});
  Future<bool> markMissed(AdministrationSlot slot, {required String reason, required String employeeId});

  Future<List<MedicationAdministration>> historyForClient(String clientId, {int days = 30});
}

class AdministrationSlot {
  final Medication medication;
  final DateTime scheduledAt;
  final MedicationAdministration? existing;  // null = noch offen
}
```

Jede `administer`/`markX`-Aktion schreibt einen Audit-Eintrag (`AuditLogger.log('medication.given', ...)`) inkl. Klient-ID, Mitarbeiter-ID, Timestamp.

## Screens

### 1. MedicationPlanScreen (Admin/Lead-Sicht)
- Aufruf aus Klient-Profil („Medikationsplan verwalten")
- Liste der aktiven Medikamente des Klienten
- Hinzufuegen-/Bearbeiten-Dialog mit Feldern: Name, Dosis, MMAN-Checkboxen, Gueltigkeit von/bis, Arzt, Notizen
- „Deaktivieren"-Action (soft delete)
- Historische Eintraege einklappbar

### 2. MedicationAdministrationScreen (Mitarbeiter-Hauptansicht)
- Tab „Meine Gaben heute" — offene Slots sortiert nach Zeit
- Pro Slot: Klient-Name, Medikament, Dosis, geplante Zeit, Aktionen (Gegeben / Verweigert / Verpasst)
- Bei „Gegeben": Button → Quittungs-Dialog (PIN/Passwort-Bestaetigung, Notizfeld optional). Signatur ist text-basiert (Mitarbeiter-ID + Timestamp + Audit).
- Bei „Verweigert/Verpasst": Grund-Pflichtfeld.
- Bestaetigte Gaben verbleiben in der Liste (ausgegraut), damit nichts verloren geht.

### 3. MedicationHistoryScreen (optional, aus Klient-Profil)
- Chronologische Liste der letzten Gaben, filterbar nach Medikament/Status

## Integration

### Navigation (D-Nav)
Neuer Eintrag in Section `ARBEIT`:
```dart
NavEntry(id: 'meds', icon: Symbols.medication, label: 'Medikation',
  section: NavSection.arbeit,
  builder: (_) => const MedicationAdministrationScreen(),
  visibleFor: _staffLike),
```
Fuer Admin ein separater Plan-Eintrag in Section `KLIENTEN`:
```dart
NavEntry(id: 'medication_plans', icon: Symbols.pill, label: 'Medikationsplaene',
  section: NavSection.klienten, builder: (_) => const MedicationPlanOverviewScreen(),
  visibleFor: _nonMember),
```

### MyWorkScreen
Die Placeholder-Karte „Offene Medikationsgaben" wird durch eine echte Liste ersetzt (erste 5 offenen Slots fuer den angemeldeten Mitarbeiter heute).

### Klient-Profil
Neuer Button „Medikationsplan" in der Klient-Detailansicht (nur fuer admin/lead sichtbar, liest `policy.canEditClient`).

## Rollen-Matrix

| Rolle         | Plan lesen | Plan bearbeiten | Gabe ausfuehren | Historie lesen |
|---------------|:-:|:-:|:-:|:-:|
| orgAdmin      | ✓ | ✓ | — | ✓ |
| pvAdmin       | ✓ | ✓ | — | ✓ |
| teamLead      | ✓ (eigene Teams) | ✓ (eigene Teams) | ✓ | ✓ |
| teamMember    | ✓ (lesend) | — | ✓ | ✓ (eigene Gaben) |
| orgAuditor    | ✓ (lesend) | — | — | ✓ |

Admins koennen selbst nicht verabreichen — wenn sie's doch sollen, wird die Aktion in Audit mit Sonderkennzeichen festgehalten. Im MVP: Admin-Accounts sehen die Gabe-Aktionen nicht; Audit-Konfig bleibt restriktiv.

## Signatur-Mechanik (MVP)

- Mitarbeiter bestaetigt Gabe durch **PIN-Eingabe** (6-stellig, im Profil hinterlegt).
- PIN wird lokal mit PBKDF2/HMAC-SHA-256 gehasht verglichen (nicht gespeichert im Klartext).
- AuditLogger protokolliert: `medication.given`, `clientId`, `medicationId`, `employeeId`, `timestamp`, `hashOfPin` (zur Pruefung).

Variante fuer spaeter: echte Canvas-Unterschrift (`signature` Package).

## Audit-Events

| Event | Felder |
|-------|--------|
| `medication.plan.created` | `clientId`, `medicationId`, `by` |
| `medication.plan.updated` | dto. + `changed` |
| `medication.plan.deactivated` | dto. |
| `medication.given` | `clientId`, `medicationId`, `by`, `scheduledAt`, `administeredAt` |
| `medication.refused` | + `reason` |
| `medication.missed` | + `reason` |

Alle Events fliessen in `fegh_compliance.AuditLogger` (bereits integriert).

## Abgrenzung (was NICHT in Scope A)

- **BTM-Dokumentation**: BtMG verlangt doppelte Kontrolle, Bestand, Vernichtungsprotokoll. Eigenes Modul in B/C.
- **Bestandsfuehrung**: Verfallsdaten, Nachbestellung, Rezept-Upload — Scope C.
- **Bedarfsmedikation (PRN)**: ungeplante Gabe — Scope B.
- **Arzt-Anbindung**: Rezept-Import/-Export, HL7/FHIR — perspektivisch, nicht in D3.
- **Unterschrift via Canvas**: spaetere Iteration, MVP nutzt PIN.
- **Mehrstufige Freigabe (4-Augen-Prinzip)**: Scope B/C.

## Umsetzungs-Reihenfolge

1. **Datenmodelle** (Medication, MedicationSchedule, MedicationAdministration, AdministrationStatus, AdministrationSlot) — 0,3 d
2. **Services** (MedicationService, MedicationAdministrationService mit Audit) — 0,5 d
3. **Provider** (Riverpod) — 0,2 d
4. **MedicationPlanScreen** + Form-Dialog — 0,6 d
5. **MedicationAdministrationScreen** + Quittungs-Dialog mit PIN — 0,8 d
6. **Integration MyWork + Klient-Profil + Navigation** — 0,4 d
7. **Unit-Tests** (Schedule-Ableitung, Slot-Generierung, Audit) — 0,3 d

**Summe: ~3 d**

## Risiken

| Risiko | Impact | Mitigation |
|--------|--------|-----------|
| PIN-Mechanik zu einfach | Signatur nicht rechtssicher | Hinweis im UI: „Fuer hoechste Anforderungen Canvas-Signatur in Scope B". Audit-Log doppelt absichern. |
| Missverstaendnis bzgl. BTM | Gesetzesverstoss | Grosser Hinweis auf Plan-Dialog: „Dieses Modul dokumentiert nur Nicht-BTM. Fuer BTM sep. Heft." |
| Mitarbeiter vergisst Quittung | Doku-Luecke | Statusbar in MyWork zeigt Zahl offener Gaben rot, wenn &gt; 0 nach der geplanten Zeit. |
| Datensicherheit | Gesundheitsdaten-Leak | Cloud-Sync verschluesselt (fegh_crypto), AuditLogger protokolliert Zugriffe. |

## Offene Entscheidungen vor Umsetzungsstart

1. **Feste oder konfigurierbare MMAN-Zeiten?** Empfehlung: fest (08:00/12:00/18:00/22:00) im MVP, konfigurierbar in Scope B.
2. **PIN-Laenge?** Empfehlung: 6 Ziffern.
3. **Gabe-Quittung auch rueckdatiert erlaubt?** Empfehlung: max. 12 h zurueck, danach nur noch „Verpasst" erfassbar.
