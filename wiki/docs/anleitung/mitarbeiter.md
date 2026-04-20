# Mitarbeiter verwalten

## Ueberblick

Das Mitarbeiter-Modul verwaltet Stammdaten, Arbeitsvertraege, Qualifikationen und Kontakt-Informationen aller in der Einrichtung taetigen Personen. Der Datensatz ist das Fundament fuer Dienstplan, Zeitnachweis und Kapazitaetsplanung.

!!! note "Berechtigung"
    Anlegen, bearbeiten, deaktivieren: Admin und Teamleitung. Lesen: alle Teammitglieder.

## Funktionsweise im Detail

### Das Problem, das wir loesen

Der Mitarbeiter-Datensatz ist das zentrale **Identitaets- und Rechte-
Objekt** der ganzen App. Alle anderen Module referenzieren ihn:

- **Medikation** pruefe, ob dieser Mitarbeiter Zeuge einer BtM-Gabe
  sein darf
- **Kassenbuch** prueft, wer freigegeben hat
- **Dienstplan** plant Schichten gegen Wochenarbeitszeit und
  Qualifikation
- **Berichte** zeigen, wer eine Rechnung erstellt hat
- **Audit-Log** schreibt die Mitarbeiter-ID zu jedem Event

Ohne strukturierten Mitarbeiter-Datensatz waere jedes dieser Module
auf Freitext-Namen angewiesen — und bei Namensgleichheit oder
Heirat sofort inkonsistent. Die App nutzt **stabile Mitarbeiter-IDs**
und bezieht alle anderen Daten (Rolle, Team-Mitgliedschaft,
Wochensoll) auf diese ID.

### Konkretes Szenario: Neueinstellung und Offboarding

**01. Maerz — Admin Anja stellt Sven als Sozialarbeiter ein.**

1. `Mitarbeiter → Neu`
2. Stammdaten: Sven Weber, geboren 1992, eingestellt 01.03.2026,
   40 h/Woche, 45,00 EUR/h.
3. Bereich: **Eingliederungshilfe**
4. Notfallkontakt: "Tanja Weber, 0162-..." (Pflichtfeld fuer
   Arbeitsschutz).
5. Team-Mitgliedschaft: WG Hauptstrasse (als Mitglied, nicht
   Teamleitung).
6. Qualifikations-Flags: Fuehrerschein Kl. B (ja), BtM-Einweisung
   (noch nicht — wird nach Schulung gesetzt).

**02. Maerz — Anja generiert den Provisioning-QR-Code.**

1. `Mitarbeiter → Sven → Einladen`
2. System erzeugt verschluesselten Token (enthaelt HiDrive-Zugang,
   Team-Key, Rolle) + 6-stellige PIN.
3. QR wird als Bildschirm + PDF angezeigt.
4. Anja gibt Sven PIN und QR getrennt (PIN muendlich, QR per beA).

**03. Maerz — Sven installiert Doku-App, scannt QR, PIN eingeben.**

Sein Geraet ist sofort einsatzfaehig — ohne dass er je HiDrive-
Credentials gesehen hat. Beim ersten Login schreibt das System:
`auth.login method=provisioning userId=sven@…`

**10. Maerz — Sven hat BtM-Einweisung absolviert.**

Anja setzt das Flag `BtM-Einweisung: ja`. Ab sofort darf Sven im
Medikationsmodul bei BtM-Gaben als Zeuge quittieren.

**Oktober — Sven kuendigt, letzter Arbeitstag 31. Oktober.**

1. 29. Oktober: Anja setzt seinen Status auf `Inaktiv` mit Datum
   01. November.
2. Was automatisch passiert:
   - Ab 01.11.: Sven kann nicht mehr in die App einloggen
     (Rollen-Check blockiert).
   - HiDrive-App-Passwort wird nicht rotiert (andere Mitarbeiter
     nutzen es weiter); statt dessen wird Svens Team-Mitgliedschaft
     entfernt → er hat keinen Team-Key mehr lokal.
   - Alle **historischen Eintraege** (Gaben, Kassenbuch-Buchungen,
     Rechnungen, Audit-Events) **bleiben** mit seiner Mitarbeiter-ID
     referenziert. Das ist Absicht: Pruefer muessen rekonstruieren
     koennen, wer im April BtM verabreicht hat — auch wenn Sven
     laengst weg ist.

### Stabile IDs statt Namen

Beim Anlegen bekommt jeder Mitarbeiter eine UUID. Diese ID wandert
als `employeeId` in alle Audit-Events, Schichten, Gaben, Kassen-
buchungen. Die App zeigt dem Menschen den **aktuellen Namen** an —
bei Heirat oder Namensaenderung aktualisiert die App automatisch
die Anzeige, ohne die ID zu aendern.

Bedeutung: Wenn Sven zum 01. Januar von Weber auf Mueller-Weber
wechselt, zeigt der Audit-Log-Viewer fuer den Eintrag vom
15. Februar `Sven Weber`, fuer den Eintrag vom 01. Maerz
`Sven Mueller-Weber` — obwohl in beiden Faellen dieselbe ID
hinterlegt ist. Das ist GoBD-konform und DSGVO-konform.

### Rechtlicher Hintergrund

- **§26 BDSG + Art. 88 DSGVO** — Beschaeftigtendatenschutz. Nur
  zweckgebundene Felder sind erlaubt; private Details (z. B.
  Hobby, politische Ansicht) sind unzulaessig.
- **§17 Arbeitsschutzgesetz** — Notfallkontakt und medizinisch
  relevante Hinweise duerfen erfasst werden; Pflichtfeld in dieser
  App.
- **§16 ArbZG** — Aufzeichnungspflicht fuer Arbeitszeit. Der
  Mitarbeiterdatensatz ist Primaerschluessel der Zeiterfassung.
- **§87 BetrVG** — Betriebsrat-Mitbestimmung bei Einfuehrung
  personenbezogener Ueberwachung; die Mitarbeiter-Registrierung
  selbst faellt nicht darunter, die Audit-Verknuepfung schon.

## Stammdatenfelder

| Feld | Beschreibung |
|------|-------------|
| Name | Vor- und Nachname |
| Rolle | Pflegefachkraft, Heilerziehungspfleger:in, Verwaltung, Leitung, etc. |
| Bereich | Eingliederungshilfe, Familienhilfe, Jugendhilfe, Sozialhilfe, Betreuung |
| E-Mail | Primaer-ID fuer Login und Chat |
| Telefon | Dienst- und Privat-Nummer |
| Adresse | Meldeadresse |
| Geburtsdatum | Fuer Vertragspruefungen und Altersjubilaeum |
| Einstellungsdatum | Beginn des Arbeitsverhaeltnisses |
| Wochenarbeitszeit | Vertragliche Sollzeit in Stunden |
| Stundensatz | Default fuer Dienstplan (kann pro Schicht ueberschrieben werden) |
| Notfallkontakt | Name + Telefon fuer Ernstfall |
| Bundesland-Qualifikation | Fachliche Freigabe fuer spezifische Bedarfsinstrumente (siehe [Bundeslaender](bundeslaender.md)) |

## Teams

Ein Mitarbeiter kann Mitglied mehrerer Teams sein. Zuweisung ueber den Teams-Screen. Teamleitung eines Teams erbt Leserechte auf alle Klienten-Akten dieses Teams.

## Status

- **Aktiv** — arbeitet regulaer, erscheint im Dienstplan
- **Urlaub** — laeuft weiter, aber Dienstplan markiert die Zeit gesperrt
- **Krank** — wie Urlaub, mit separatem Attest-Hinweis
- **Inaktiv** — ausgeschieden, Historie bleibt

Ein inaktiver Mitarbeiter kann keine Quittungen mehr leisten (Medikation, Kassenbuch), bisherige Eintraege bleiben aber im Audit mit Mitarbeiter-ID.

## Onboarding via Einladungscode

Statt Mitarbeiter von Hand pro Geraet einzurichten, erzeugt der Admin einen **Provisioning-Token**:

1. In der Einladungs-Ansicht Mitarbeiter auswaehlen
2. Rolle und Teamzuweisung bestaetigen
3. Token mit PIN geschuetzt als QR-Code anzeigen
4. Mitarbeiter scannt am neuen Geraet, gibt PIN ein, Profil wird automatisch eingerichtet (HiDrive-Zugang, Team-Key, Rolle)

Siehe [Mitarbeiter einladen](../admin/einladung.md) fuer den Admin-Pfad.

## Integration

- **Dienstplan**: Mitarbeiter werden Schichten zugewiesen
- **Medikation**: Mitarbeiter quittieren Gaben und bestaetigen sich als Zeuge
- **Kassenbuch**: Mitarbeiter buchen Ein-/Auszahlungen fuer Klienten
- **Chat**: Mitarbeiter sind Mitglied in Team- und Klienten-Raeumen
