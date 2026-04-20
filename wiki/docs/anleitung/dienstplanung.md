# Dienstplanung

## Ueberblick

Die Dienstplanung verteilt Schichten auf Mitarbeiter innerhalb eines Teams und im Rahmen der gesetzlichen Arbeitszeit-Vorgaben. Sie ist das zentrale Werkzeug der Teamleitung und speist Zeitnachweis, Abrechnung und Kapazitaetsplanung.

!!! note "Berechtigung"
    Planen, aendern, loeschen: Teamleitung und Admin. Eigene Schichten einsehen: alle Mitarbeiter (in Verwaltung + Doku).

## Funktionsweise im Detail

### Das Problem, das wir loesen

Dienstplanung in einer Betreuungseinrichtung ist kein Kalender-
Tetris. Sie verbindet **vier parallele Welten**, die jede fuer sich
schon kompliziert sind:

1. **Arbeitsrecht** (ArbZG §§3/5): maximal 10 h pro Tag, mindestens
   11 h Ruhezeit zwischen Schichten, 48 h Wochenhoechst.
2. **Bedarfsdeckung**: jede Wohngruppe braucht pro Schicht mindestens
   eine Fachkraft — fehlt jemand, droht Versorgungsluecke und
   Haftung gegenueber Klienten.
3. **Lohnkosten**: Zuschlaege fuer Nacht/Wochenende/Feiertag koennen
   den Plan teuer machen. Wer am 01. Mai Tagschicht hat, kostet
   doppelt soviel wie ein Donnerstag-Mittagsdienst.
4. **Mitarbeiter-Zufriedenheit**: wer dauernd Last-Minute-Aenderungen
   bekommt, kuendigt. Fair verteilte Wochenenden und realistische
   Urlaubsplanung halten das Team zusammen.

Ohne strukturierte Dienstplanung hieng e das an einer einzelnen
Teamleitung, die den Wochenplan in Excel fuehrt und per Gruppen-
WhatsApp teilt. Folge: ArbZG-Verstoesse fallen erst bei der
Pruefung auf, Tausche werden nicht dokumentiert, Konflikte
entstehen.

FEGH macht die Planung zum strukturierten Prozess mit automatischer
Konflikt-Pruefung, Tausch-Workflow und Historie.

### Konkretes Szenario: Eine Woche im Leben von Teamleitung Paula

**Montag, 10. Februar — Wochenplanung fuer KW 8.**

Paula oeffnet `Dienstplan → Bulk-Anlage`:

- Muster: Fruehdienst Mo-Fr, Mitarbeiterin Mia.
- Zeit: 06:00-14:00, Typ: Regulaer, Standort: WG Hauptstrasse.
- Konflikt-Check laeuft automatisch gegen bestehende Schichten:
  - Mia hat am 12. Februar bereits eine Nachtschicht (Mi 22:00-06:00)
    im Dienstplan. Die **Ruhezeit** zwischen 06:00 Do und dem neuen
    Fruehdienst Do 06:00 waere **0 h** — §5 ArbZG verlangt 11 h.
  - Konflikt-Check: **BLOCKIEREND** (rot, Liste der Verstoesse).
- Paula klickt Mia aus Do raus, waehlt Bjoern als Ersatz.
- Nochmal pruefen: diesmal nur Warnungen (Bjoern kommt auf 48 h
  Wochenstunden — Grenze nach §3). Paula bestaetigt mit "Trotzdem
  speichern".
- 4 Schichten angelegt (Mo-Mi + Fr fuer Mia, Do fuer Bjoern).

**Mittwoch, 12. Februar, 14:30 — Mia wird krank.**

Sie markiert ihre Fr-Schicht als `abgesagt` mit Grund
"Krankmeldung, AU folgt". System benachrichtigt Paula.

Paula hat zwei Optionen:
1. **Neuplanung**: selbst Ersatz suchen
2. **Tausch-Anfrage**: Ersatzschicht ins Team "ausschreiben"

Weil das 48-h-Wochen-Limit fuer Bjoern gilt, ist Tausch der bessere
Weg — vielleicht springt jemand ein, der diese Woche noch Kapazitaet
hat.

**14:40 — Paula startet die Tausch-Anfrage stellvertretend fuer Mia:**

- Shift-Detail → "Tausch anbieten"
- Angebot offen fuer das Team (keine konkrete Empfaengerin)
- Grund: "Krankmeldung Mia, Ersatz gesucht fuer Fr 06-14"
- System schreibt `ShiftSwapRequest` im Status `pending`.

**15:15 — Kollegin Clara nimmt an.**

Clara war heute bei Familie besuchend, sieht die Anfrage im
`Tausch-Anfragen`-Screen → Tab "Fuer mich" → klickt "Annehmen".
System:
- Status `pending` → `accepted`
- `acceptingEmployeeId = clara`
- Sichtbar fuer Paula im Tab "Leitungs-Freigabe"

**15:20 — Paula genehmigt.**

- Klickt "Genehmigen" mit Notiz "Danke fuer das Einspringen"
- System:
  - Status → `approved`
  - `Shift.employeeId` wird von Mia auf Clara umgebucht
  - Audit-Event `shift.swap.approved` mit allen IDs
  - Clara erhaelt neue Schicht im Doku-App-Kalender ("Meine Schichten")

**Donnerstag, 13. Februar, 09:00 — Zeitueberschneidung.**

Paula bemerkt, dass Bjoern am Do 12:00-20:00 geplant ist, aber eine
Fortbildung 14:00-16:00 auf seinem Kalender steht, die er auch
teilnehmen will. Sie oeffnet den Plan, **zieht per Drag-Drop** die
Schicht von 12:00-20:00 auf 18:00-02:00 (Nachtdienst):

- System prueft Konflikte: 11 h Ruhezeit nach dem neuen Start OK,
  keine Ueberlappung mit anderen Schichten.
- Warn-Dialog: "Nachtdienst hat 1,25x Zuschlag — 8 h × 23 EUR × 1,25
  = 230 EUR statt 184 EUR. Trotzdem verschieben?"
- Paula bestaetigt. Schicht ist jetzt Nachtdienst, Lohn-Multiplier
  greift automatisch. SnackBar zeigt "Rueckgaengig"-Button fuer 5 s.

**Freitag, 14. Februar, 16:00 — Wochenaushang.**

Paula klickt `Wochen-Aushang (PDF)`:

- PDF-Querformat, KW 8 auf einer Seite
- Mitarbeiter vertikal, Tage Mo-So horizontal
- Schichten als farbige Kacheln nach Typ
- Header mit Team-Name + Woche

Sie druckt ihn aus, haengt ihn ans schwarze Brett. Parallel gibt
sie allen Mitarbeitern den **iCal-Export**: `iCal-Export` klicken →
`.ics`-Datei herunterladen → ueber beA an alle. Jeder importiert
das in Outlook/Apple-Kalender/Google-Kalender und sieht seine
Schichten integriert mit privaten Terminen.

### Lohn-Multiplier und Zuschlaege

Die Schicht-Typen wirken auf den Lohn:

| Typ | Multiplier | Wirkung bei 23 EUR/h × 8 h |
|-----|------------|----------------------------|
| Regulaer | 1,00 | 184 EUR |
| Ueberstunden | 1,50 | 276 EUR |
| Wochenende | 1,25 | 230 EUR |
| Nacht | 1,25 | 230 EUR |
| Feiertag | 2,00 | 368 EUR |

Wichtig: der Multiplier greift auf **tatsaechlich geleistete**
Stunden, nicht auf geplante. Wenn Mia plane 8 h startet aber nach
6 h geht (z. B. Krankheit mitten in der Schicht), wird nur der
tatsaechlich geleistete Anteil mit Multiplier berechnet.

### Konflikt-Check — was geprueft wird

Die `ShiftConflictChecker`-Klasse prueft jede neue oder verschobene
Schicht gegen:

| Regel | Paragraph | Severity |
|-------|-----------|----------|
| Doppelbelegung (Ueberlappung beim selben MA) | – | BLOCKIEREND |
| > 10 h Tagesarbeit | §3 ArbZG | BLOCKIEREND |
| < 11 h Ruhezeit zwischen Schichten | §5 ArbZG | BLOCKIEREND |
| > 48 h / Woche (Rolling 7 Tage) | §3 ArbZG Abs. 2 | WARNUNG |

Die App trennt harte Verstoesse (blockieren) von weichen (warnen,
Benutzer kann trotzdem speichern). Wochenlimit ist als Warnung
implementiert, weil es im 6-Monats-Durchschnitt erfuellt werden
darf (§3 ArbZG Abs. 2) — die App kennt aber nur die eine Woche.

### iCal-Export: was drin ist und was nicht

Der Export folgt **RFC 5545**:

- UTF-8 ICS-Datei
- Pro Schicht ein `VEVENT` mit DTSTART/DTEND in UTC (`...Z`)
- UID = `<shiftId>@fegh`
- SUMMARY: "Dienst <Typ> — <Mitarbeitername>"
- DESCRIPTION: Team, Pause, Notiz (newlines escaped)
- LOCATION: Standort (falls gesetzt)
- STATUS: CONFIRMED / CANCELLED / TENTATIVE
- Abgesagte Schichten werden **nicht** exportiert (wuerde nur verwirren)

### Rechtlicher Hintergrund

- **§3 ArbZG** — 8 h werktaeglich, max. 10 h, im Schnitt 48 h/Woche.
- **§5 ArbZG** — 11 h Ruhezeit zwischen Schichten.
- **§4 ArbZG** — Pausen ab 6 h Arbeit.
- **§16 ArbZG** — Aufzeichnungspflicht (2 Jahre); Dienstplan-Historie
  deckt das ab.
- **§87 BetrVG** — Mitbestimmung bei Dienstplan; Betriebsrat kann
  Bulk-Anlagen und Aenderungen nach Mitbestimmungsvereinbarung
  einsehen.
- **EuGH C-55/18** (2019) — objektive und verlaessliche
  Arbeitszeiterfassung Pflicht; Dienstplanung als Soll-Vorgabe
  reicht nicht, Ist-Zeit muss zusaetzlich dokumentiert sein.

## Schicht-Felder

| Feld | Beschreibung |
|------|-------------|
| Mitarbeiter | Wer uebernimmt die Schicht |
| Team | Kontext (ein Mitarbeiter kann in mehreren Teams sein) |
| Startzeit / Endzeit | Geplante Dauer |
| Typ | Regulaer, Ueberstunden, Feiertag, Nacht, Wochenende — beeinflusst den Lohn-Multiplikator |
| Status | Geplant, Laufend, Abgeschlossen, Abgesagt, Nicht erschienen |
| Standort | Optional (z. B. "WG Hauptstrasse") |
| Beschreibung | Kurzer Zweck ("Fruehdienst", "Nachtbereitschaft") |
| Pause | Minuten, werden von Istzeit abgezogen |
| Stundenlohn | Default aus Mitarbeiter-Profil, pro Schicht ueberschreibbar |

## Lohn-Multiplikatoren

| Typ | Faktor | Bedeutung |
|-----|--------|-----------|
| Regulaer | 1.00 | Normale Werktag-Schicht |
| Ueberstunden | 1.50 | Zuschlagsfaehige Mehrarbeit |
| Nacht | 1.25 | 22:00 – 06:00 |
| Wochenende | 1.25 | Samstag ab 00:00 bis Sonntag 24:00 |
| Feiertag | 2.00 | Gesetzliche Feiertage nach Bundesland |

Die Multiplikatoren wirken nur auf die **tatsaechlich geleisteten** Stunden (Ist-Zeit minus Pause), nicht auf die Planung.

## Planung

### Einzelschicht

**Neue Schicht** oeffnet den Schichtdialog mit Konflikt-Pruefung. Beim Speichern wird gegen bestehende Schichten desselben Mitarbeiters geprueft (Ueberlappung, ArbZG-§3/§5-Regeln).

### Bulk-Anlage

**Bulk-Anlage** erzeugt mehrere Schichten aus einem Muster (z. B. "Fruehdienst Mo-Fr fuer 4 Wochen"). Vor dem Speichern laeuft der Konflikt-Check ueber den gesamten Bulk-Satz:

- **Blockierend**: Ueberlappung oder ArbZG-Verletzung → Abbruch mit Liste
- **Warnung**: Enger Rhythmus (z. B. >10h Dienst am Stueck) → Bestaetigen erforderlich

### iCal-Export

Jeder Dienstplan kann als **`.ics`-Datei** heruntergeladen werden (Button "iCal-Export"). Import in Outlook, Apple Kalender, Google Calendar, Thunderbird. Abgesagte Schichten werden nicht exportiert.

## Aushang

Der **Wochen-Aushang** erzeugt eine PDF-Querformat-Ansicht aller Schichten eines Teams fuer eine Woche — zum Ausdrucken und Aushaengen. Darstellung: Mitarbeiter vertikal, Tage horizontal, Schichten als farbige Zellen nach Status/Typ.

## ArbZG-Konflikte

Die Konflikt-Pruefung erkennt:

- **§3 ArbZG**: > 10h werktaegliche Arbeitszeit ohne Ausgleich
- **§5 ArbZG**: < 11h Ruhezeit zwischen zwei Schichten
- **Doppelbelegung**: Mitarbeiter in derselben Zeit schon verplant
- **Bereichs-Mismatch**: Mitarbeiter ohne Qualifikation fuer Klienten-Bundesland

## Mitarbeiter-Sicht (Doku)

Die Doku-App zeigt Mitarbeitenden ihre eigenen Schichten als Read-only-Liste im Screen **Meine Schichten**. Quittung (Start/Ende) erfolgt ueber die Zeiterfassung in der Doku; der Status-Sync fliesst zurueck in die Verwaltung.

## Integration

- **Zeitnachweis** uebernimmt Ist-Zeiten der Schicht
- **Kapazitaetsplanung** bilanziert geplante Stunden vs. Budget
- **Wirkungsmessung** nutzt Schichtkontext fuer "Fachleistungsstunden bei Klient"
