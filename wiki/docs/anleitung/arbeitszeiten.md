# Arbeitszeiten

## Ueberblick

Die Arbeitszeit-Erfassung dokumentiert Ist-Zeiten pro Mitarbeiter und Tag, differenziert Taetigkeiten, berechnet Lohnstunden und erzeugt den monatlichen Zeitnachweis fuer Lohnbuchhaltung und Kontrollbehoerden.

!!! note "Berechtigung"
    Eigene Zeit erfassen: alle Mitarbeiter. Zeiten anderer einsehen/aendern: Teamleitung und Admin.

## Funktionsweise im Detail

### Das Problem, das wir loesen

In der Verwaltung sitzt am Monatsende Anja und muss drei Fragen
fuer 25 Mitarbeiter beantworten:

1. **Wie viele Stunden hat jeder gearbeitet?** (Lohn)
2. **Wie viele davon sind dem Klienten zuzuordnen?** (FLS-Rechnung)
3. **Gab es ArbZG-Konflikte?** (Compliance)

Ohne digitale Zeiterfassung sind das drei Excel-Listen, die
haendisch aus drei unterschiedlichen Quellen befuellt werden
(Stempeluhr, Terminkalender, Bauchgefuehl). Die App verbindet die
drei Sichten: eine Ist-Zeit-Erfassung, drei Ausgabe-Reports — ohne
Redundanz.

### Konkretes Szenario: Monatsabschluss Maerz fuer Team "Hauptstrasse"

**01. April, 09:00 Uhr — Anja oeffnet `Arbeitszeiten → Monatsbericht`.**

Sie waehlt Maerz 2026 und Team Hauptstrasse (5 Mitarbeiter).

Das Dashboard zeigt pro Mitarbeiter:

| Mitarbeiter | Soll | Ist | Saldo | FLS | Ueber 10h-Tage | Ruhezeit < 11h |
|-------------|------|-----|-------|-----|----------------|----------------|
| Mia (40 h) | 176 h | 182 h | +6 h | 155 h | 0 | 0 |
| Bjoern (40 h) | 176 h | 168 h | -8 h | 142 h | 1 | 1 |
| Clara (30 h) | 132 h | 135 h | +3 h | 112 h | 0 | 0 |
| Daniel (40 h) | 176 h | 180 h | +4 h | 151 h | 2 | 0 |
| Emma (20 h) | 88 h | 88 h | 0 h | 76 h | 0 | 0 |

**Auffaelligkeiten:**

- **Bjoern: 8 h Minus** — er war eine Woche krank ohne AU (Grippe,
  nach 2 Tagen wieder fit), hat die Arbeitszeit einfach kuerzer
  gebucht. Anja klaert das im Gespraech.
- **Bjoern: 1x Ruhezeit < 11h** — der Konflikt-Check hat am 14.
  Maerz geschlagen: Bjoern war abends 22:00 fertig, am naechsten
  Morgen 07:00 wieder da (= 9 h Ruhezeit, §5 ArbZG-Verstoss).
  Muss dokumentiert werden.
- **Daniel: 2x ueber 10h** — zwei lange Nachtdienste im Maerz,
  beide innerhalb der 10 h-Ausnahme-Regel (§3 Abs. 2 mit
  Ausgleich), aber Anja notiert es fuer den Jahreszyklus.

**09:30 Uhr — Anja generiert Einzelnachweise.**

Fuer jeden Mitarbeiter:

- `Arbeitszeiten → Mitarbeiter waehlen → Zeitnachweis PDF`
- PDF enthaelt: Mitarbeiter-Stammdaten, Woche fuer Woche
  tabellarisch, Summen pro Taetigkeitstyp, ArbZG-Konflikte mit
  Hinweis, Soll/Ist/Saldo, Unterschriftszeilen (Mitarbeiter +
  Leitung).
- Anja druckt 5 PDFs, legt sie den Mitarbeitern zur Unterschrift in
  die Faecher.

**10:00 Uhr — Lohnabrechnung vorbereiten.**

`Arbeitszeiten → Team-CSV-Export`:

- Eine CSV-Zeile pro Schicht + pro manuellem Zeit-Eintrag
- Spalten: Mitarbeiter-ID, Datum, Start, Ende, Dauer, Pause,
  Schicht-Typ, Lohn-Multiplier, Stundenlohn, Summe
- Anja schickt die CSV an den Lohnsachbearbeiter des Traegers —
  der importiert sie in DATEV (oder wartet auf den geplanten
  DATEV-Export-Button).

**10:15 Uhr — FLS-Monatslauf fuer Abrechnung.**

Die Arbeitszeit-Eintraege mit Taetigkeit "Betreuung", "Dokumentation"
oder "Buero (mit Fallbezug)" fliessen automatisch in die
FLS-Rechnungen — siehe
[Fachleistungsstunden](../anleitung/fachleistungsstunden.md) in der
Doku-App. Der Monatslauf dort nutzt dieselben Zeit-Eintraege.

### Die drei Sichten — eine Datenbasis

| Sicht | Quelle | Zweck |
|-------|--------|-------|
| **Lohn** | alle Ist-Zeiten | Stundensumme × Stundenlohn × Multiplier |
| **FLS** | Ist-Zeiten mit abrechenbarer Taetigkeit + Klient | Traeger-Rechnung |
| **Compliance** | ArbZG-Verstoesse | §16 ArbZG-Aufzeichnungspflicht |

Der gleiche Datensatz erzeugt alle drei Sichten — ein Eintrag muss
nur einmal gepflegt werden, Redundanzen sind unmoeglich.

### Import aus Stempeluhr

Einrichtungen mit biometrischer Stempeluhr koennen die Exportdaten
per CSV importieren. Format:

```
userId,tag,start,ende,pause_min
sven@org,2026-03-15,07:55,16:30,30
```

Nach Import prueft die App gegen bestehende Eintraege, um Doppel-
eintragungen zu vermeiden. Neue Eintraege bekommen automatisch
Taetigkeit "Betreuung" als Default — der Mitarbeiter kann das
spaeter pro Eintrag korrigieren.

### Rechtlicher Hintergrund

- **§16 ArbZG** — Aufzeichnungspflicht, Aufbewahrung 2 Jahre.
- **§41 ff. SGB III** — sozialversicherungsrechtliche Nachweis-
  pflichten (Krankengeld, Kurzarbeitergeld).
- **EuGH C-55/18** — objektive, verlaessliche Zeiterfassung aller
  Mitarbeiter verpflichtend; App erfuellt das mit granularer
  Erfassung + Historie.
- **§87 BetrVG** — Betriebsrats-Mitbestimmung bei Einfuehrung,
  Aenderung und Anwendung technischer Einrichtungen zur
  Ueberwachung (Zeiterfassung zaehlt dazu).
- **DSGVO Art. 5/6 + §26 BDSG** — Verarbeitung zu Arbeitsvertrags-
  zwecken zulaessig; Zweckbindung an Lohnabrechnung + ArbZG-
  Compliance, keine Leistungsvergleiche ohne Mitbestimmung.

## Erfassungsquellen

Ist-Zeiten entstehen auf drei Wegen:

1. **Schichten starten/beenden** — aus dem Dienstplan, mit Einstempelung bei tatsaechlicher Ankunft
2. **Manuelle Eintraege** — Taetigkeitsbasiert ohne Schicht (z. B. "Buerotag")
3. **Import** — CSV aus Fremdsystemen (z. B. Stempeluhr)

## Taetigkeitstypen

| Typ | Beschreibung |
|-----|-------------|
| Betreuung | Direkte Arbeit am Klienten |
| Buero | Verwaltung, Dokumentation |
| Fahrt | Fahrtzeit zwischen Standorten |
| Dokumentation | Akten-/Berichte-Arbeit |
| Verwaltung | Organisationsaufgaben |
| Fortbildung | Schulungen |
| Teamsitzung | Besprechungen |
| Sonstige | Alles andere, mit Pflicht-Beschreibung |

Die Typen wirken NICHT auf den Lohn (der kommt aus dem Schicht-Typ), aber sie fliessen in die Fachleistungsstunden-Zaehlung.

## Regeln

- Startzeit < Endzeit (gleicher Tag oder max. 24h)
- Pause wird separat abgezogen
- Ueberlappende Eintraege pro Mitarbeiter werden als Warnung markiert
- ArbZG-Konflikte (>10h Schicht, <11h Ruhezeit) erscheinen im Dashboard

## Exporte

### Einzelner Zeitnachweis (PDF)

Pro Mitarbeiter und Monat — fertig fuer Unterschrift und Personalakte.

### Teamweite CSV

Fuer die Lohnbuchhaltung — alle Schichten eines Monats aller Teammitglieder mit Ist-Zeit, Pause, Soll-Zeit, Differenz, Stundenlohn, Summe.

### DATEV-Export (geplant)

In Vorbereitung — Anbindung an externe Lohnprogramme via CSV-Spezifikation.

## Dashboard

Das Zeit-Dashboard zeigt pro Mitarbeiter und Monat:

- **Soll-Stunden** aus Wochenarbeitszeit * Arbeitstage
- **Ist-Stunden** aus Erfassung
- **Saldo** (Positiv = Plusstunden, Negativ = Minusstunden)
- **Ueberstunden** (Zuschlaege aus Dienstplan-Typ)

## Integration

- **Dienstplan** erzeugt Standard-Schicht, die bei Start/Ende zum Zeit-Eintrag wird
- **Fachleistungsstunden** zieht "Betreuung"-Zeiten heran (siehe [Fachleistungsstunden](fachleistungsstunden.md))
- **Kapazitaetsplanung** bilanziert Soll vs. Ist team- und bereichsweit
