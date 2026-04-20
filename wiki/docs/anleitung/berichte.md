# Berichte

## Ueberblick

Das Berichte-Modul exportiert Daten aus der Verwaltungs-App in PDF, XLSX, CSV und XRechnung UBL. Jeder Bericht ist vorlagenbasiert (`fegh_pdf_kit`), signierbar und reproduzierbar aus gespeichertem Stand.

!!! note "Berechtigung"
    Berichte erstellen: alle Mitarbeiter (nur eigene Daten) oder Teamleitung (Team-Sicht) oder Admin (organisationsweit).

## Funktionsweise im Detail

### Das Problem, das wir loesen

Eine Einrichtung produziert im Jahr **Dutzende unterschiedliche
Berichte** an sechs verschiedene Zielgruppen:

- **Kostentraeger**: Quartalsberichte, Jahresberichte, Wirksamkeits-
  nachweise, Rechnungen.
- **Lohnbuchhaltung**: Monats-Zeitnachweise, Lohnsteuer-Monatsabschluss.
- **Finanzamt**: Jahresabschluss, USt-Voranmeldung.
- **Betriebsrat**: Ueberstunden-Uebersichten, Krankenquote.
- **Einrichtungsleitung**: Kennzahlen, Team-Auslastung, Budget-Stand.
- **Aufsichtsbehoerden** (LfDI, Heimaufsicht): anlassbezogen.

Jede Zielgruppe erwartet **unterschiedliches Format, unterschiedliche
Detail-Tiefe, unterschiedliche Rechtsgrundlagen**. Ohne strukturiertes
Berichts-Modul sitzt die Verwaltungskraft stundenlang an Copy-Paste
aus 5 Excel-Tabellen. Die Verwaltungs-App buendelt diese Berichte
als **Template-basierte Export-Pipeline**: einmal die Grundlage
pflegen, Bericht auf Knopfdruck in passendem Format.

### Konkretes Szenario: Der Monatsabschluss im April

**01. Mai, 08:00 Uhr — Admin Anja startet den Monatsabschluss fuer April.**

Sie arbeitet eine Checkliste ab:

1. **Zeitnachweise** fuer alle 25 Mitarbeiter als PDF → drucken,
   in die Mitarbeiter-Postfaecher zur Unterschrift.
2. **Team-CSV-Export** fuer Lohnbuchhalter: alle Schichten April,
   mit Lohn-Multipliern.
3. **Klienten-Monatsberichte**: pro aktivem Klient eine kurze PDF mit
   geleisteten FLS, Wirkungsmessungs-Snapshot, Abwesenheiten.
4. **Kassenbuch-Monatsauszuege**: pro Klient mit Kassenbuch, PDF,
   Signaturen inkludiert.
5. **Kapazitaets-Report** fuer sie selbst: Team-Auslastung April,
   Trend.
6. **XRechnungen**: Monatslauf starten fuer Sozialamt (siehe
   [Fachleistungsstunden im Doku-Wiki](https://miri2577.github.io/FEGH-Dokumentation/anleitung/fachleistungsstunden/)).

**Dauer**: in der Verwaltungs-App typisch 20 Minuten (Klicks +
PDF-Ansicht). Ohne App: ein halber Tag.

**02. Mai — Versand.**

- XRechnung XML → OZG-RE Portal hochladen, Status "Versendet".
- Zeitnachweise-PDFs → Mitarbeiter Rueckgabe nach Unterschrift →
  Archiv.
- CSV → Lohnbuchhaltung per beA.
- Klienten-Monatsberichte → optional an Sozialamt (nur wenn
  vertraglich vereinbart; nicht alle verlangen monatlich).

### Berichts-Typen im Ueberblick

| Bericht | Format | Zyklus | Zielgruppe |
|---------|--------|--------|------------|
| Zeitnachweis pro MA | PDF | Monat | Lohnbuchhaltung, Mitarbeiter |
| Team-CSV Arbeitszeit | CSV | Monat | Lohnbuchhaltung |
| Klient-Monatsbericht | PDF | Monat | intern + optional Kostentraeger |
| Kassenbuch-Monatsauszug | PDF | Monat | Klient, Betreuer, intern |
| Wochen-Aushang Dienstplan | PDF | Woche | Mitarbeiterraum |
| Kapazitaets-Report | PDF | Monat | Einrichtungsleitung |
| XRechnung | UBL-XML | Monat | Kostentraeger elektronisch |
| BtM-Bestandsliste | CSV/PDF | Quartal | interne Kontrolle |
| Jahresbilanz | PDF | Jahr | Leitung, Steuerberater |
| Wirksamkeitsbericht (Klient) | PDF | jaehrlich/bei Bedarf | Hilfeplan-Konferenz |

### PDF-Design-System

Alle PDFs nutzen den gemeinsamen **`fegh_pdf_kit`-Baukasten**:

- Einheitliche Farbpalette (primary/accent/warn/muted)
- Header-Baustein mit Logo + Titel + Aktenzeichen
- KPI-Kacheln fuer Kennzahlen
- Tabellenstil mit Zebra-Zeilen
- Roboto-Schrift (embedded, auch auf Behoerdenrechnern sichtbar)
- Fuss-/Kopfzeile einheitlich

Wenn die Einrichtung ihr Logo oder Farben anpassen will, wird das
in den PDF-Kit-Tokens **zentral** geaendert — nicht pro Bericht.

### Exportwege

Ein erzeugter Bericht wird **nicht automatisch** auf den Cloud-Speicher abgelegt
— die Entscheidung trifft der Mitarbeiter:

- **Download auf PC** (Default) — ins lokale Verzeichnis
- **Per Mail senden** (noch nicht aktiv) — geplantes Feature
- **In Cloud ablegen** — explizit auswaehlen; landet im Team-
  Ordner unter `reports/YYYY-MM/`

Fuer rechtssichere Archivierung empfiehlt sich ein separates DMS
(ecoDMS, Docuware) mit OCR.

### Rechtlicher Hintergrund

- **§14a UStG + ERechVBln** — elektronische Rechnung an Behoerden
  seit 2020 Pflicht.
- **HGB §257 + AO §147** — Aufbewahrungspflicht 10 Jahre fuer
  Rechnungen, 6 Jahre fuer sonstige Geschaeftsunterlagen.
- **§128 SGB IX** — Wirksamkeitsnachweis; Bericht pro Klient als
  Nachweis.
- **§21 SGB IX** — Teilhabeplanung; Klient-Monatsberichte sind
  Bestandteil der laufenden Teilhabeplanung.
- **Art. 30 DSGVO** — Verzeichnis der Verarbeitungstaetigkeiten;
  Berichte dokumentieren, welche personenbezogenen Daten wann
  verarbeitet wurden.

## Standard-Berichte

### Zeitnachweis (PDF)

Pro Mitarbeiter und Monat. Enthaelt Schichtdetails, Pausen, Ist/Soll-Stunden, Unterschriftszeile.

### Teamzeit-Nachweis (XLSX)

Pro Team und Monat — alle Mitarbeiter, eine Zeile je Schicht, mit Stundenlohn und Bruttobetrag. Fuer die Lohnbuchhaltung.

### Monatsbericht Klient (PDF)

Pro Klient und Monat. Enthaelt:

- Betreuungszeiten (aus Arbeitszeiterfassung, Typ `Betreuung`)
- Wirkungsmessung-Snapshot (aktueller Zielfortschritt)
- Abwesenheiten (Klient, z. B. Krankenhaus)
- Anzahl BtM-Gaben (wenn anwendbar)
- Kassenbuch-Monatsabschluss-Saldo (wenn anwendbar)

### Kassenbuch-Monatsauszug (PDF)

Pro Klient und Monat. Saldo Monatsanfang, Einzelbuchungen, Endsaldo, Unterschriften freigegebener Eintraege.

### XRechnung UBL (XML)

Pro Rechnung, fuer elektronische Rechnung an Bezirk/Sozialamt. Validiert gegen KoSIT-Schematron. Ausgabe als UBL 2.1 XML mit BT-Feldern und PEPPOL-BIS-3.0-Profil.

### Wochen-Aushang (PDF)

Pro Team und Woche. Matrix Mitarbeiter × Tage, zum Ausdrucken.

### Kapazitaets-Report (PDF)

Pro Team oder Bereich und Monat. Soll/Plan/Bedarf-Bilanz.

### Aushang Dienstplan (PDF)

Querformat, ideal zum Aushaengen in Mitarbeiterraeumen.

### BtM-Bestandsliste (CSV/PDF)

Alle BtM-Medikamente der Einrichtung mit aktuellem Bestand, letzter Gabe und Vernichtungsstand.

## Ausgabe-Formate

| Format | Geeignet fuer |
|--------|--------------|
| PDF | Druck, Archivierung, Unterschrift |
| XLSX | Weiterverarbeitung (Lohn, Buchhaltung) |
| CSV | Import in Drittsysteme |
| XRechnung UBL | Elektronische Rechnung gegenueber oeffentlichen Auftraggebern |
| iCal (.ics) | Kalender-Import (Outlook, Google, Apple) |

## Design-System

Alle PDFs nutzen das gemeinsame `fegh_pdf_kit` mit:

- FEGH-Farbpalette (primaer, accent, warn, muted, text)
- Roboto Regular + Bold
- Header mit Organisation, Berichtstitel, Aktenzeichen
- KPI-Kacheln fuer Kennzahlen
- Tabellen mit abwechselnder Zeilenfarbe
- Fussdaten mit Erstellungszeit und App-Name

## Archivierung

PDFs werden nicht automatisch auf den Cloud-Speicher abgelegt — Entscheidung des Sachbearbeiters, wohin exportiert wird. Fuer rechtssichere Archivierung empfiehlt sich ein externes DMS (z. B. ecoDMS, Docuware) mit OCR.
