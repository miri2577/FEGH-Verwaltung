# Kapazitaetsplanung

## Ueberblick

Die Kapazitaetsplanung bilanziert **Soll** (vertraglich verfuegbare Stunden) gegen **Ist** (geplante und geleistete Stunden) und stellt sicher, dass Teams ihren Leistungsumfang fuer die zugewiesenen Klienten erbringen koennen — ohne Ueberlast oder Unterauslastung.

!!! note "Berechtigung"
    Kapazitaet einsehen: Teamleitung (eigenes Team) und Admin (alle). Bearbeitung der Grundwerte: Admin.

## Funktionsweise im Detail

### Das Problem, das wir loesen

Eingliederungshilfe funktioniert nur, wenn **Bewilligungen und
Arbeitskraft** zueinander passen. Ueber-/Unter-Deckung kostet:

- **Ueber-Deckung** (mehr FLS bewilligt als Kapazitaet): Wartelisten
  fuer Klienten, verlorene Bewilligungen, Image-Schaden.
- **Unter-Deckung** (mehr Stunden gearbeitet als bezahlt): Lohnkosten
  ohne Refinanzierung — die Einrichtung legt Geld drauf.

Ohne Kapazitaetsplanung bemerkt eine Einrichtung das erst beim
Jahresabschluss der Buchhalterin. Zu spaet. Das Kapazitaets-
Dashboard macht die Bilanz **zu jedem Zeitpunkt** sichtbar und
zeigt 3 Monate in die Zukunft: welche Wochen drohen rot, welche
Klienten brauchen eine Bedarfsfortschreibung.

### Konkretes Szenario: Jahresplanungs-Meeting im Dezember

**05. Dezember 2026 — Admin Anja bereitet die Jahresplanung fuer 2027 vor.**

Sie oeffnet `Kapazitaet → 2027 Ueberblick`:

- **Soll-Stunden 2027** (alle 25 Mitarbeiter, 40h-Schnitt): 52.000 h
- **Abzug Urlaub/Krank-Schnitt** (14%): -7.280 h → 44.720 h Netto
- **Bereits bewilligte FLS** aus Klient-Akten 2027: 38.500 h

Differenz: **+6.220 h freie Kapazitaet** = 12 % Puffer.

Die **Kennzahlen pro Team**:

| Team | Soll 2027 | Ist-Klienten-Bedarf | Prozent |
|------|-----------|----------------------|---------|
| Hauptstrasse | 10.400 h | 10.800 h | **104 %** ⚠ |
| Gruenstrasse | 8.300 h | 7.200 h | 87 % |
| Mobil | 12.500 h | 10.500 h | 84 % |
| Tagesstruktur | 13.500 h | 10.000 h | 74 % |

**Befund**:
- Hauptstrasse ist **ueberbucht**. Zwei Klienten koennen im
  Jahresverlauf nicht voll versorgt werden.
- Tagesstruktur hat **Luft** — 3.500 h nicht verteilt.

**Entscheidung im Meeting**:

1. **Umverteilung**: Klient 1 aus Hauptstrasse, der perspektivisch
   in die Tagesstruktur passt, wird im zweiten Quartal 2027 verlegt.
2. **Neueinstellung**: 1 Halbtagskraft fuer Hauptstrasse (20 h/Woche
   = 1.040 h/Jahr) — deckt die verbleibende Ueberschreitung.
3. **Akquise**: Tagesstruktur-Team hat Luft fuer 3 neue Klienten;
   Sozialarbeiterin nimmt Kontakt zum Bezirksamt auf, die haben eine
   Warteliste.

### Das 3-Monats-Rollende-Dashboard

Die praktikabelste Sicht ist nicht das Jahr, sondern die
**naechsten drei Monate**. Das Dashboard aktualisiert sich
wochenweise:

- **Woche 1-12**: konkret geplant via Dienstplan + Urlaubsantraege
- **Woche 13-26**: Soll-Kapazitaet gegen offene Bewilligungen
- **Woche 27+**: nur noch Grobplan, ohne Detail

Wochen mit **Fehldeckung > 10 %** werden rot markiert — die
Teamleitung weiss, dass sie handeln muss (Zusatzschichten,
Umverteilung, Tausch-Anfragen).

### Eskalationsoptionen

Bei Fehldeckung hat die Teamleitung typisch vier Hebel:

1. **Zusatzschichten anbieten** — Springer oder Teilzeitkraefte
   fragen (Tausch-Anfrage-Workflow kann hier missbraucht werden:
   jemand bietet Mehrarbeit an, Lead nimmt an).
2. **Umverteilung Klient** — in ein anderes Team, wenn dort
   Kapazitaet und fachlich passend.
3. **Externe Unterstuetzung** — Zeitarbeit oder freie Kraefte
   einkaufen, wenn die Einrichtung das bilanziell darstellen kann.
4. **Bedarfskorrektur** — mit Kostentraeger ueber weniger FLS
   verhandeln, wenn der Klient gesundheitlich besser dasteht.
   Realistisch nur mit neuem Bescheid, dauert Monate.

Alle Entscheidungen werden im Audit-Log vermerkt (als Management-
Entscheidungen), damit bei spaeteren Nachfragen nachvollziehbar ist,
warum gehandelt wurde.

### Rechtlicher Hintergrund

- **§125 SGB IX** — Verguetungsvereinbarung zwischen Traeger und
  Leistungserbringer. Kapazitaetsplanung stellt sicher, dass
  vereinbarte Leistungen erbracht werden koennen.
- **§17 Abs. 2 ArbSchG** — Sichere Arbeitsbedingungen;
  Ueberlastung einzelner Mitarbeiter ist Arbeitsschutzverstoss.
- **EU-Arbeitszeitrichtlinie 2003/88/EG** — Rahmen fuer ArbZG;
  48-h-Wochen-Durchschnitt im 6-Monats-Fenster.
- **HGB §289** — Lagebericht bei groesseren Einrichtungen;
  Kapazitaetsausnutzung ist berichtspflichtig.

## Kern-Kennzahlen

| Kennzahl | Berechnung |
|----------|-----------|
| Soll-Stunden Monat | Summe der Wochenarbeitszeiten aller aktiven Mitarbeiter × Arbeitswochen |
| Abwesenheits-Soll | Soll-Stunden abzueglich Urlaub/Krankheit/Fortbildung |
| Plan-Stunden | Summe aller geplanten Schichten des Monats |
| Ist-Stunden | Summe erfasster Zeit-Eintraege |
| Klienten-FLS-Bedarf | Summe der FLS pro Klient (siehe [Fachleistungsstunden im Doku-Wiki](https://miri2577.github.io/FEGH-Dokumentation/anleitung/fachleistungsstunden/)) |
| Fehldeckung | Bedarf − Plan |

## Dashboard-Kacheln

- **Team-Auslastung**: Prozent `Plan/Abwesenheits-Soll`. Ideal 90–105 %.
- **Bereichsauslastung**: Analog, aber nach Bereich (Eingliederungshilfe, Familienhilfe, …)
- **Fehldeckung**: Rote Balken, wenn `Bedarf > Plan`
- **Ueberlast**: Rote Balken, wenn `Plan > Abwesenheits-Soll × 1.10`

## Planung auf 3 Monate

Der Planungshorizont ist 3 Monate. Fuer jeden Monat:

1. Urlaubsantraege und Krankmeldungen flossen in `Abwesenheits-Soll`
2. Dienstplan-Bulks erzeugen die `Plan-Stunden`
3. FLS aus den Klienten-Plaenen ergeben den `Bedarf`
4. Dashboard markiert Wochen mit Deckungsluecken

## Eskalation

Bei Fehldeckung hat die Teamleitung Optionen:

- **Zusatzschichten** — Mitarbeiter mit Verfuegbarkeit fragen (Tausch-Anfrage-Workflow)
- **Umverteilung** — Klienten in anderes Team, wenn Kapazitaet dort
- **Externe Unterstuetzung** — Zeitarbeit oder freie Kraefte (separat zu buchen)
- **Bedarfskorrektur** — mit Leistungstraeger Rahmen anpassen

Alle Massnahmen werden im Audit-Log protokolliert.

## Reports

**Monatsbericht Kapazitaet** zeigt den ganzen Monat-Plan-Durchfluss mit farblich markierten Hotspots — Grundlage fuer Rueckmeldungen an Kostentraeger und interne Retrospektiven.
