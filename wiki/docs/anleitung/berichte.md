# Berichte

## Ueberblick

Das Berichte-Modul exportiert Daten aus der Verwaltungs-App in PDF, XLSX, CSV und XRechnung UBL. Jeder Bericht ist vorlagenbasiert (`fegh_pdf_kit`), signierbar und reproduzierbar aus gespeichertem Stand.

!!! note "Berechtigung"
    Berichte erstellen: alle Mitarbeiter (nur eigene Daten) oder Teamleitung (Team-Sicht) oder Admin (organisationsweit).

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

PDFs werden nicht automatisch auf HiDrive abgelegt — Entscheidung des Sachbearbeiters, wohin exportiert wird. Fuer rechtssichere Archivierung empfiehlt sich ein externes DMS (z. B. ecoDMS, Docuware) mit OCR.
