# Dashboard und KPIs

Das Dashboard ist die Startseite fuer Admins und Team-Leitungen. Es buendelt operative KPIs in Karten-Form.

## Funktionsweise im Detail

### Das Problem, das wir loesen

Eine Einrichtungsleitung hat frueh morgens typisch **drei Fragen**:

1. Was brennt heute? (akute Themen, Krankmeldungen, fehlende
   Mitarbeiter)
2. Was muss in diesem Monat erledigt werden? (Rechnungen,
   Berichte, Urlaubsfreigaben)
3. Wo droht etwas in 2-4 Wochen? (Auslaufende Bewilligungen,
   Jahresurlaub, Teamkonflikte)

Ohne Dashboard muss sie das aus **fuenf verschiedenen Modulen**
zusammensuchen (Dienstplan, Urlaub, Rechnungen, Klienten,
Kapazitaetsplanung). Das dauert 20 Minuten — jeden Morgen. Mit
Dashboard dauert es 90 Sekunden: eine einzige Seite mit
Klickbaren Kacheln, jede verlinkt direkt zum Handlungsort.

### Konkretes Szenario: Anjas Montag-Morgen-Routine

**07:50 Uhr — Anja kommt ins Buero, oeffnet die App.**

Das Dashboard zeigt auf einen Blick:

**Heute-Sektion**:

- 🔴 **1 Ueberfaelliger Zeitnachweis** (Mia, eingereicht seit 4 Tagen)
- 🟡 **2 offene Urlaubsantraege** (Clara fuer Mai, Bjoern fuer Juni)
- 🟢 **24 geplante Schichten heute**, 0 akute Ausfaelle
- 🟡 **3 offene Medikationsgaben team-weit**

**Finanzen**:

- 🔴 **2 Rechnungen faellig seit > 30 Tagen** (Sozialamt Koeln)
- 🟢 Umsatz April: 82.000 EUR (Ziel: 80.000 EUR)

**Klienten**:

- 🟡 **1 Klient mit auslaufender Bewilligung** (Frau L., Bewilligung
  endet 30. April — noch 5 Wochen)
- 🔴 **3 Klienten ohne DSGVO-Einwilligung** (Neuaufnahmen seit Maerz)

**Anjas Priorisierung in den naechsten 15 Minuten:**

1. Mias Zeitnachweis genehmigen (1 Klick → Zeitnachweis-Screen)
2. Clara + Bjoern Urlaub ansehen, genehmigen / Rueckfragen
3. Sozialamt Koeln anmahnen (Rechnungen gehen auf die zweite
   Mahnstufe)
4. Frau L.: Fortsetzungsantrag einreichen
5. Drei fehlende DSGVO-Einwilligungen → Kollegin Lara bitten,
   morgen mit den Klienten ein Gespraech zu fuehren

Um 08:05 ist Anja fertig mit der Morgenroutine. Handlungsfaehig
fuer den Tag.

### Dashboard-Karten im Ueberblick

Jede Karte hat:

- **Ueberschrift** (Kontext der Kennzahl)
- **Hauptzahl** in grosser Schrift (Soll/Ist, Prozent, Stueck)
- **Farbige Ampel**:
  - 🟢 OK (im Soll)
  - 🟡 Achtung (Grenzbereich, nicht akut)
  - 🔴 Handlung erforderlich
  - ⚪ Keine Daten (noch nichts eingegeben)
- **Klickziel** (fuehrt zum passenden Detail-Modul)

Die **Ampel-Schwellen** sind konfigurierbar pro Karte
(Einstellungen → Dashboard). Standard z. B.:

- Zeitnachweis „rot" ab 3 Tagen offen
- Auslaufende Bewilligungen: rot ≤ 2 Wochen, gelb ≤ 8 Wochen
- Budget-Auslastung: gruen 70-95 %, gelb 95-105 %, rot ≥ 110 %

### Rollen-abhaengige Sicht

Jede Rolle sieht nur ihre relevanten Karten:

- **orgAdmin**: alles
- **pvAdmin**: alles ausser MEK/Rotation
- **teamLead**: Heute + eigenes Team + Klienten des Teams (keine
  Finanzen)
- **teamMember**: nur eigene Schichten, Zeitnachweise, PRN-Gaben
- **orgAuditor**: Read-only Finanzen + Audit

Das haelt das Dashboard relevant. Eine Teamleitung sehe keine
zehn Admin-Karten, die sie nicht beruehren darf.

### Rechtlicher Hintergrund

- **Art. 5 Abs. 1 lit. c DSGVO** (Datenminimierung) — jede Rolle
  sieht nur relevante KPIs.
- **§4 ArbZG** — Pflicht zur Uebersicht ueber Arbeitszeit-
  Konflikte; das Dashboard macht sie sofort sichtbar.
- **BSI IT-Grundschutz ORP.1** — Organisatorische Strukturen;
  Dashboard unterstuetzt Fuehrungskraft bei der Wahrnehmung von
  Aufsichtspflichten.

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
