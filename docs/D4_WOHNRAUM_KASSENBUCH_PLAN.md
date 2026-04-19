# D4: Wohnraum + Kassenbuch (MVP)

**Stand: 19.04.2026** — Plan, noch nicht implementiert.

## Warum

Fuer **besondere Wohnformen** (stationaere EGH, WfbM-Internate, therapeutische WG) sind zwei Verwaltungsaufgaben zentral:

1. **Wohnraum**: Mietverwaltung je Klient-Platz (Miete, Nebenkosten, Kaution, Vertragslaufzeit). Grundlage fuer Abrechnung mit dem Kostentraeger und fuer Existenzsicherungsleistungen nach §42a SGB XII.
2. **Kassenbuch**: Klient-gebundene Barkasse (Taschengeld, Haushaltsgeld, Freizeit, Gesundheit). Rechtliche Pflicht nach WTPG/Heimgesetz, dokumentarische Pflicht nach HGB §257 / AO §147 (Aufbewahrung 10/5 Jahre), jede Buchung unterschrieben oder audit-ierbar.

Beide Module sind **Greenfield** in der Verwaltung.

## Rechtlicher Rahmen (Kurz)

- **SGB IX** — EGH-Rahmen, §113 Assistenzleistungen, §42 Existenzsicherung (via SGB XII §§42, 42a)
- **SGB XII §42a** — Bedarf an Unterkunft und Heizung
- **WTPG / LWTG** — Landesrechtlicher Rahmen Wohnen mit Pflege und Teilhabe (NRW, BW, Hessen abweichend)
- **HGB §257, AO §147** — 10 Jahre Aufbewahrung Buchungen, 5 Jahre Quittungen
- **DSGVO Art. 5, 6, 32** — Zweckbindung, Rechtsgrundlage, TOM (Audit-Trail)
- **DSGVO Art. 9** — Kassenbuch indirekt: Ausgabe fuer Gesundheit/Medikament ist Gesundheitsdatum

## Scope

| Scope | Inhalt | Aufwand |
|-------|--------|---------|
| **A — MVP** | Wohnraum-Stammdaten + Kassenbuch-Eintraege mit Kategorie, Saldo pro Klient, PDF-Auszug | 4–5 d |
| **B — Medium** | A + Unterschriftspad (Canvas) + Monatsabschluss + Taschengeld-Quittung als PDF | +3 d |
| **C — Full** | B + Mietabrechnung mit Warm/Kalt + NK-Abrechnung + Beleg-Upload (Foto) | +5 d |

**Empfehlung: Scope A** umsetzen, B/C als Folge-Sprints.

## Datenmodell (Scope A)

### Wohnraum
```dart
class Wohnraum {
  final String id;
  final String? clientId;         // null = leerstehend
  final String bezeichnung;       // z.B. "Haus 1, Zimmer 3"
  final String? adresse;
  final double kaltmiete;         // EUR/Monat
  final double nebenkosten;       // EUR/Monat
  final double? kaution;
  final DateTime? mietbeginn;
  final DateTime? mietende;
  final String? vermieter;
  final String? vertragsnummer;
  final WohnraumStatus status;    // free, occupied, reserved, inactive
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum WohnraumStatus { free, occupied, reserved, inactive }
```

### KassenbuchEintrag
```dart
class KassenbuchEintrag {
  final String id;
  final String clientId;
  final DateTime datum;
  final double betrag;            // + Einzahlung, - Auszahlung
  final KassenbuchKategorie kategorie;
  final String beschreibung;
  final String? belegnummer;
  final String? erfasstVonEmployeeId;
  final bool confirmed;           // quittiert/signiert
  final DateTime createdAt;
}

enum KassenbuchKategorie {
  eingang,            // Eingang/Gutschrift
  taschengeld,
  haushaltsgeld,
  gesundheit,
  freizeit,
  bekleidung,
  verpflegung,
  sonstiges,
}
```

Persistenz: SharedPreferences-Keys `wohnraeume_v1` und `kassenbuch_eintraege_v1`. Cloud-Sync-Anbindung in D4.5.

## Services

### WohnraumService
```dart
class WohnraumService {
  Future<List<Wohnraum>> loadAll();
  Future<List<Wohnraum>> loadForClient(String clientId);
  Future<List<Wohnraum>> loadFree();
  Future<bool> addWohnraum(Wohnraum w);
  Future<bool> updateWohnraum(Wohnraum w);
  Future<bool> assignClient(String wohnraumId, String clientId);
  Future<bool> releaseClient(String wohnraumId);  // → status free
}
```

### KassenbuchService
```dart
class KassenbuchService {
  Future<List<KassenbuchEintrag>> loadForClient(String clientId);
  Future<double> saldoForClient(String clientId);
  Future<bool> addEintrag(KassenbuchEintrag e);
  Future<bool> updateEintrag(KassenbuchEintrag e);  // nur ungebuchte
  Future<bool> deleteEintrag(String id);            // nur ungebuchte, Audit

  /// Export monatlicher Auszug als PDF (via fegh_pdf_kit).
  Future<String> exportMonthlyStatement({
    required String clientId,
    required DateTime month,
  });
}
```

Alle Aktionen schreiben Audit-Events (`kassenbuch.entry.created`, `kassenbuch.entry.updated`, `kassenbuch.entry.deleted`, `wohnraum.created`, `wohnraum.assigned` etc.).

## Screens

### 1. WohnraumOverviewScreen (Admin-Nav „Personal/Planung")
- Tabelle aller Wohnraeume mit Status-Farbcodierung (free=grün, occupied=gelb, reserved=blau, inactive=grau)
- Filter nach Status + Freitext
- „Hinzufuegen"-Action → Form-Dialog
- Klick auf Zeile → Detail-Screen / Klient zuweisen

### 2. WohnraumFormDialog
- Bezeichnung, Adresse, Kaltmiete, Nebenkosten, Kaution, Vermieter, Vertragsnummer, Zeitraum
- Klient-Zuweisung separat (via Aktion „Zuweisen")

### 3. KassenbuchScreen (pro Klient)
- Saldo-Hero oben
- Liste der Eintraege, chronologisch absteigend, mit Kategorie-Chip und Betrag (rot bei negativ)
- „Eintrag erfassen"-Button → Form-Dialog
- „Export PDF" → Monatsauszug
- Filter: Monat + Kategorie

### 4. KassenbuchFormDialog
- Datum (default heute), Einzahlung/Auszahlung-Toggle, Betrag, Kategorie-Dropdown, Beschreibung, Belegnummer (optional)
- Bestaetigungsfeld (confirmed-Flag): „Buchung pruefen und freigeben"
- Hinweis: **Nach Freigabe nicht mehr editierbar** (Audit-Pflicht)

### 5. MyWorkScreen-Integration
Kassenbuch-Karte zeigt je Klient der letzten Schicht die letzte Buchung + Saldo. Snelle Buchung per Inline-Button.

## Integration (Navigation)

Neue NavEntries:
```dart
NavEntry(id: 'kassenbuch_staff', icon: Symbols.savings, label: 'Kassenbuch',
  section: NavSection.arbeit,
  builder: (_) => const KassenbuchClientPickerScreen(),
  visibleFor: _staffLike),
NavEntry(id: 'wohnraum', icon: Symbols.apartment, label: 'Wohnraum',
  section: NavSection.personal,
  builder: (_) => const WohnraumOverviewScreen(),
  visibleFor: _nonMember),
```

Klient-Profil: neuer Tab/Bereich „Kassenbuch" (admin/lead/auditor). Mitarbeiter: direkter Link aus MyWork.

## Rollen-Matrix

| Rolle | Wohnraum anlegen | Wohnraum zuweisen | Kassenbuch lesen | Kassenbuch buchen | Kassenbuch freigeben |
|-------|:-:|:-:|:-:|:-:|:-:|
| orgAdmin | ✓ | ✓ | ✓ | ✓ | ✓ |
| pvAdmin | ✓ | ✓ | ✓ | ✓ | ✓ |
| teamLead | – | ✓ (eigene Teams) | ✓ (eigene Teams) | ✓ | ✓ |
| teamMember | – | – | ✓ (zugewiesene Klienten) | ✓ | – |
| orgAuditor | – | – | ✓ (Scope-basiert) | – | – |

Freigabe (confirmed=true) ist **finaler Zustand** — danach kein Update/Delete moeglich, nur Storno-Eintrag.

## PDF-Export (Scope A)

Monatsauszug pro Klient:
- Kopf: Klient-Name, Monat, Erstellungszeitpunkt
- KPIs: Saldo-Start, Einzahlungen, Auszahlungen, Saldo-Ende
- Tabelle: Datum, Kategorie, Beschreibung, +/- Betrag, Saldo-fortlaufend
- Fuss: Unterschriftenzeile (Klient / Betreuer)

Bausteine aus `fegh_pdf_kit`.

## Audit-Events

| Event | Felder |
|-------|--------|
| `wohnraum.created` | `id`, `bezeichnung`, `kaltmiete` |
| `wohnraum.updated` | `id`, `changed` |
| `wohnraum.assigned` | `id`, `clientId` |
| `wohnraum.released` | `id`, `previousClient` |
| `kassenbuch.entry.created` | `clientId`, `entryId`, `kategorie`, `betrag`, `by` |
| `kassenbuch.entry.updated` | dto. |
| `kassenbuch.entry.deleted` | `clientId`, `entryId`, `by`, `reason` |
| `kassenbuch.entry.confirmed` | `clientId`, `entryId`, `by` |

## Abgrenzung (was NICHT in Scope A)

- **Canvas-Unterschrift** — Scope B
- **Monatsabschluss** (Saldo-Rollover) — Scope B
- **Warm/Kalt-Mietabrechnung** — Scope C
- **Nebenkostenabrechnung** — Scope C
- **Beleg-Upload** (Foto) — Scope C
- **Mehrwaehrungs-Support** — nein
- **Automatische Kassenbewegungen aus Medikation** — nein, explizit getrennt

## Umsetzungs-Reihenfolge

1. **Modelle** — 0,3 d
2. **Services mit Audit** — 0,5 d
3. **Provider (Riverpod)** — 0,3 d
4. **Kassenbuch-UI** (KassenbuchScreen, Form, ClientPicker) — 1 d
5. **Wohnraum-UI** (Overview, Form, Assign-Dialog) — 0,8 d
6. **PDF-Monatsauszug** — 0,5 d
7. **Integration** (Nav, Klient-Profil, MyWork) — 0,4 d
8. **Tests** (Saldo, Rollen-Gate, Audit-Events) — 0,4 d

**Summe: ~4–5 d**

## Risiken

| Risiko | Impact | Mitigation |
|--------|--------|-----------|
| Freigegebene Eintraege aus Versehen bearbeitbar | Compliance-Verstoss | Guard in Service + UI, keine Edit-Action, nur Storno |
| Saldo-Berechnung bei grossen Listen langsam | UX-Einbruch | im MVP ok (wenige hundert Eintraege), Caching in Provider spaeter |
| Belegnummer nicht durchgaengig | Pruefung schwierig | Pflichtfeld fuer Auszahlungen ≥ 50 EUR, sonst optional |
| Mischung Scope A mit BTM/Gesundheit | DSGVO Art. 9 | Kategorie „gesundheit" im UI mit Hinweis: Details nur in Notizen, nicht in Beschreibung |

## Offene Entscheidungen

1. **Wohnraum pro Klient oder pro Platz?** Empfehlung: **pro Platz**, Klient wird zugewiesen. So bleibt Historie bei Bewohner-Wechsel erhalten.
2. **Saldo in Echtzeit oder on-demand berechnen?** Empfehlung: on-demand (Service-Funktion), kein persistiertes Saldo-Feld im MVP.
3. **Storno oder Delete bei freigegebenen Eintraegen?** Empfehlung: **Storno**-Eintrag mit negativem Betrag + Verweis auf Original (spaeter; im MVP Delete blockieren).
