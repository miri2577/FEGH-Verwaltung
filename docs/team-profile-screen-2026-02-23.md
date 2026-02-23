# Feature: Team-Profilseite

**Datum:** 23.02.2026
**Status:** Implementiert, Build erfolgreich

---

## Übersicht

Neue Team-Profilseite analog zur bestehenden Mitarbeiter-Profilseite. Wird per Klick auf ein Team in der Team-Liste (Grid oder Tabelle) geöffnet.

---

## Neue Datei

| Datei | Beschreibung |
|-------|-------------|
| `lib/features/teams/team_profile_screen.dart` | Vollständige Team-Profilseite mit 5 Tabs |

## Geänderte Datei

| Datei | Änderung |
|-------|----------|
| `lib/features/teams/widgets/team_list_view.dart` | `_showTeamDetails()` navigiert zum `TeamProfileScreen` statt AlertDialog |

---

## 5 Tabs

### 1. Übersicht
- **Team-Info-Card**: Icon, Name, Beschreibung, Status-Badge, Abteilung, Mitgliederzahl, Teamleiter-Avatar
- **Details-Card**: Team-ID, Abteilung, Standort, Budget, Erstellt/Aktualisiert, Notizen
- **Quick-Stats-Row**: Aktive Mitglieder, Wochenkapazität (Soll-Stunden), Durchschnittslohn, Budget

### 2. Mitglieder
- Liste aller Team-Mitglieder mit Avatar, Name, Position, Status, Stunden/Woche
- Teamleiter-Badge (gelb hervorgehoben)
- Klick auf Mitglied öffnet dessen Employee-Profil
- Button zum Entfernen von Mitgliedern (RBAC-geschützt)
- Button "Verwalten" öffnet Team-Formular zum Hinzufügen/Entfernen

### 3. Statistiken
- **Team-Leistung**: Gesamtstunden, Überstunden, Anwesenheit, Stunden/Mitarbeiter (aktueller Monat)
- **Urlaubsübersicht**: Aktuell im Urlaub, offene Anträge, genehmigte Tage
- **Mitarbeiter-Vergleich**: Fortschrittsbalken pro Mitarbeiter (Ist vs. Soll-Stunden im Monat)

### 4. Schichten
- Liste aller Team-Schichten (aktueller Monat + Zukunft)
- Farbcodierte Status-Badges (Geplant/Aktiv/Erledigt/Abgesagt/Nicht erschienen)
- PDF-Export des Schichtplans (Landscape-Format, Tabelle)

### 5. Kalender
- Syncfusion SfCalendar mit Tag/Woche/Monat-Ansichten
- Zeigt Schichten + Urlaube aller Mitglieder aggregiert
- Mitarbeitername im Termin-Subject für Unterscheidbarkeit
- Farbcodierte Legende (Schicht/Überstunden/Urlaub/Krank)
- Agenda-Ansicht im Monatskalender

---

## Features

- **PDF-Export**: Team-Profil als PDF (Name, Details, Mitglieder-Tabelle, Notizen)
- **PDF-Druck**: Nativer Druckdialog
- **Status-Verwaltung**: Aktivieren/Pausieren über Popup-Menü
- **RBAC**: Bearbeiten/Entfernen nur mit `canManageTeams()`-Berechtigung
- **Navigation**: Mitglieder anklickbar → öffnet Employee-Profil

---

## Verwendete Provider

| Provider | Verwendung |
|----------|-----------|
| `teamByIdProvider` | Team-Daten laden |
| `employeesProvider` | Mitglieder-Details |
| `timesheetsByEmployeeProvider` | Stunden/Überstunden pro Mitglied |
| `shiftsByEmployeeProvider` | Schichten pro Mitglied |
| `shiftsByTeamProvider` | Team-Schichten |
| `vacationRequestsByEmployeeProvider` | Urlaubsdaten pro Mitglied |
| `policyProvider` | RBAC-Prüfung |
| `teamsProvider.notifier` | Team aktualisieren, Mitglieder entfernen |
