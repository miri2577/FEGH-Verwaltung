# Fix 2026-02-25: Farbgebung Mitarbeiter-Profilansicht Tabs

## Problem

In der Mitarbeiter-Profilansicht (`EmployeeProfileScreen`) waren die Tab-Labels und Icons ("Profil", "Statistiken", "Zeiten", "Dokumente", "Kalender") auf dem blauen AppBar-Hintergrund schlecht lesbar. Die Standard-Farbgebung von Material 3 hat dunkle Tab-Farben gesetzt, die auf dem blauen Header kaum sichtbar waren.

## Loesung

**Datei:** `lib/features/employees/employee_profile_screen.dart`

Explizite Farbwerte fuer die TabBar gesetzt:

- `labelColor`: `onPrimary` (weiss) fuer den aktiven Tab
- `unselectedLabelColor`: `onPrimary` mit 70% Opacity fuer inaktive Tabs
- `indicatorColor`: `onPrimary` (weiss) fuer den Indikator-Strich

Die Farben passen sich automatisch an das Theme an (nutzen `colorScheme.onPrimary` statt hardcodierter Werte).
