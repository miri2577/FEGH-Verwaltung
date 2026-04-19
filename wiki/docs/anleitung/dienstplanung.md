# Dienstplanung

## Ueberblick

Die Dienstplanung verteilt Schichten auf Mitarbeiter innerhalb eines Teams und im Rahmen der gesetzlichen Arbeitszeit-Vorgaben. Sie ist das zentrale Werkzeug der Teamleitung und speist Zeitnachweis, Abrechnung und Kapazitaetsplanung.

!!! note "Berechtigung"
    Planen, aendern, loeschen: Teamleitung und Admin. Eigene Schichten einsehen: alle Mitarbeiter (in Verwaltung + Doku).

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
