# Urlaub und Abwesenheiten

## Ueberblick

Das Abwesenheiten-Modul verwaltet Urlaub, Krankheit, Fortbildung, Elternzeit und sonstige Nicht-Arbeitszeiten. Abwesenheiten sperren automatisch Schichten im Dienstplan und fliessen in die Kapazitaets- und Lohnberechnung ein.

!!! note "Berechtigung"
    Eigene Antraege stellen: alle Mitarbeiter. Genehmigen/ablehnen: Teamleitung. Globale Sichten: Admin.

## Abwesenheitstypen

| Typ | Beschreibung | Auf Urlaubskonto? |
|-----|-------------|--------------------|
| Urlaub | Regulaerer Jahresurlaub | Ja (Abbuchung) |
| Krankheit | Krankschreibung (AU) | Nein |
| Fortbildung | Dienstlich angeordnet | Nein (bezahlte Arbeitszeit) |
| Unbezahlter Urlaub | Sonder-Urlaub ohne Lohn | Nein |
| Elternzeit | Gesetzliche Elternzeit | Nein (langfristig) |
| Freistellung | Interne Freigabe | Individuell |
| Sonstige | Mit Pflicht-Begruendung | Individuell |

## Urlaubskonto

Jeder Mitarbeiter hat ein Urlaubskonto:

- **Jahresanspruch** aus Arbeitsvertrag (Default: 30 Tage bei Vollzeit, anteilig bei Teilzeit)
- **Resturlaub Vorjahr** — uebertragbar bis 31.03. des Folgejahrs
- **Verbrauchter Urlaub** — laufende Summe aus genehmigten Urlaubseintraegen
- **Verbleibend** — Anspruch − Verbrauch

## Workflow Urlaubsantrag

1. **Mitarbeiter** stellt Antrag mit Zeitraum und Begruendung (optional)
2. System prueft: Anspruch vorhanden? Konflikt mit bestehenden Schichten? Krankmeldung derselben Periode?
3. **Teamleitung** erhaelt Benachrichtigung, genehmigt oder lehnt ab
4. Bei Genehmigung: Schichten im Zeitraum werden storniert (oder zur Umplanung markiert), Urlaubskonto belastet
5. Bei Ablehnung: Grund wird im Antrag dokumentiert, Antrag bleibt fuer Historie

## Krankmeldung

Krankmeldungen sind sofort wirksam (keine Genehmigung noetig). Arbeitsunfaehigkeitsbescheinigung wird optional als Beleg hochgeladen (analog Beleg-Upload im Kassenbuch).

Krankmeldung ab Tag 1 pflicht, AU-Bescheinigung ab Tag 3 (§5 EFZG). Die App erinnert, wenn nach 3 Tagen noch kein Beleg hochgeladen ist.

## Dienstplan-Integration

Bei genehmigter Abwesenheit:

- **Betroffene Schichten** bekommen Status "abgesagt" mit Grund
- **Neuplanung** ist dringend: Dashboard zeigt betroffene Teams
- **iCal-Export** unterdrueckt abgesagte Schichten

## Uebersicht

Der Abwesenheits-Kalender zeigt alle Mitarbeiter eines Teams im Monats-/Jahresraster:

- Urlaub in gruen
- Krankheit in rot
- Fortbildung in blau
- Sonstiges in grau

Geeignet fuer Sichten "Wer ist diese Woche da?" und Exportierbar als Monats-PDF zur Teamsitzung.
