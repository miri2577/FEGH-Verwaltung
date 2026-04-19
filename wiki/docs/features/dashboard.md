# Dashboard und KPIs

Das Dashboard ist die Startseite fuer Admins und Team-Leitungen. Es buendelt operative KPIs in Karten-Form.

## Inhalte

### Heute-Sektion
- Schichten heute (geplant / aktiv / abgeschlossen)
- Offene Urlaubsantraege
- Ueberfaellige Zeitnachweise (eingereicht, aber nicht genehmigt)
- Offene Medikationsgaben team-weit

### Personal
- Gesamtzahl Mitarbeiter (aktiv / inaktiv)
- Teams und Durchschnittsgroessen
- Kapazitaets-Auslastung in Prozent

### Finanzen (nur Admin)
- Offene Rechnungen (Status: entwurf / versendet / bezahlt)
- Umsatz dieses Monats
- Faellige Rechnungen

### Klienten
- Aktive Klienten, Neuzugaenge im Monat
- Klienten ohne Einwilligung (Warnung)
- Klienten mit auslaufender Bewilligung

## Navigation

Tap auf eine Karte fuehrt direkt zur zugehoerigen Detail-Ansicht:

- „Schichten heute" → Dienstplan gefiltert auf heute
- „Offene Medikationsgaben" → MedicationAdministrationScreen
- „Offene Rechnungen" → Rechnungen-Liste gefiltert

## Rollenabhaengigkeit

- `orgAdmin` / `pvAdmin`: volles Dashboard mit allen KPIs
- `teamLead`: KPIs der eigenen Teams
- `teamMember`: Dashboard nicht sichtbar — direkt auf *Meine Arbeit* geleitet
- `orgAuditor`: Dashboard mit Zahlen, aber ohne Detail-Deeplinks zu editierbaren Bereichen

## Geplant

- Benutzerdefinierte KPI-Kacheln (per Drag-Drop)
- Export Dashboard als PDF-Snapshot
- Zeitreihen-Grafiken fuer Umsatz, Auslastung
