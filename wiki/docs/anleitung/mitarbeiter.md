# Mitarbeiter verwalten

## Ueberblick

Das Mitarbeiter-Modul verwaltet Stammdaten, Arbeitsvertraege, Qualifikationen und Kontakt-Informationen aller in der Einrichtung taetigen Personen. Der Datensatz ist das Fundament fuer Dienstplan, Zeitnachweis und Kapazitaetsplanung.

!!! note "Berechtigung"
    Anlegen, bearbeiten, deaktivieren: Admin und Teamleitung. Lesen: alle Teammitglieder.

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
