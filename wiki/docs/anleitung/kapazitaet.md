# Kapazitaetsplanung

## Ueberblick

Die Kapazitaetsplanung bilanziert **Soll** (vertraglich verfuegbare Stunden) gegen **Ist** (geplante und geleistete Stunden) und stellt sicher, dass Teams ihren Leistungsumfang fuer die zugewiesenen Klienten erbringen koennen — ohne Ueberlast oder Unterauslastung.

!!! note "Berechtigung"
    Kapazitaet einsehen: Teamleitung (eigenes Team) und Admin (alle). Bearbeitung der Grundwerte: Admin.

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
