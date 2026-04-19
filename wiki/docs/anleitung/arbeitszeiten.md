# Arbeitszeiten

## Ueberblick

Die Arbeitszeit-Erfassung dokumentiert Ist-Zeiten pro Mitarbeiter und Tag, differenziert Taetigkeiten, berechnet Lohnstunden und erzeugt den monatlichen Zeitnachweis fuer Lohnbuchhaltung und Kontrollbehoerden.

!!! note "Berechtigung"
    Eigene Zeit erfassen: alle Mitarbeiter. Zeiten anderer einsehen/aendern: Teamleitung und Admin.

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
