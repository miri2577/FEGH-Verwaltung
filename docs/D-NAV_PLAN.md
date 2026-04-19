# D-Nav: Navigation-Rewrite mit Rollen-Weiche

**Stand: 19.04.2026** — Plan, noch nicht implementiert.

## Ausgangsproblem

Das aktuelle `MainLayout` nutzt eine `TabBar` mit **12 flachen Tabs** (Dashboard, Employees, Teams, Clients, Shifts, Timesheets, Vacation, ICF, Reports, Billing, Capacity, Settings). Das ist fuer eine stationaere Desktop-Admin-App nicht professionell:

- Material-Guidelines empfehlen bei Tabs max. 4–6 Eintraege. Ab 6 wird die Leiste scrollbar oder gequetscht.
- Es fehlt **Gruppierung**: Personal, Klienten, Planung, Finanzen, System sind in einem Topf.
- Die Verwaltung soll ab jetzt auch von **Mitarbeitern** stationaer genutzt werden — mit **anderer Tab-Auswahl** (z. B. „Meine Schichten", „Meine Klienten", „Medi-Gaben"). Eine TabBar mit 12 Tabs, die je nach Rolle 9 davon ausblendet, wirkt wie ein Provisorium.

## Ziel-Architektur

**NavigationRail** (Material 3 Desktop/Tablet-Idiom) links, **AppBar** oben fuer Kontext (Suche, User-Avatar, Notifications). Gruppen als Section-Header innerhalb der Rail, Eintraege rollen-gefiltert.

```
┌───────────────┬──────────────────────────────────────────┐
│ [User]  Q Suche         [🔔3] [⚙]                       │
├───────────────┼──────────────────────────────────────────┤
│ ARBEIT        │                                          │
│  🗓 Meine     │                                          │
│  👥 Meine Kl. │                                          │
│  💊 Gaben     │         Content Area                     │
│  💶 Kasse     │                                          │
│               │                                          │
│ KLIENTEN      │                                          │
│  📋 Liste     │                                          │
│  🎯 ICF       │                                          │
│               │                                          │
│ PERSONAL      │                                          │
│  👤 MA        │                                          │
│  🤝 Teams     │                                          │
│  🌴 Urlaub    │                                          │
│  📊 Kapazit.  │                                          │
│               │                                          │
│ PLANUNG       │                                          │
│  📅 Dienst.   │                                          │
│  ⏱ Zeitn.    │                                          │
│               │                                          │
│ FINANZEN      │                                          │
│  🧾 Rechn.    │                                          │
│  📈 Berichte  │                                          │
│               │                                          │
│ SYSTEM        │                                          │
│  ⚙ Einst.    │                                          │
│  💾 Backup    │                                          │
│  🛡 Admin     │                                          │
│  📜 Audit     │                                          │
└───────────────┴──────────────────────────────────────────┘
```

## Rollen-Sichtbarkeits-Matrix

Basis: die vorhandenen 5 Rollen aus `roles_policy_service.dart`.

| Sektion     | Eintrag          | `orgAdmin` | `pvAdmin` | `teamLead` | `teamMember` | `orgAuditor` |
|-------------|------------------|:---------:|:---------:|:---------:|:-----------:|:-----------:|
| ARBEIT      | Meine Schichten  |           |           |     ✓     |      ✓      |             |
|             | Meine Klienten   |           |           |     ✓     |      ✓      |             |
|             | Gaben (Medi)     |           |           |     ✓     |      ✓      |             |
|             | Kassenbuch-Eintrag |         |           |     ✓     |      ✓      |             |
| KLIENTEN    | Klienten-Liste   |     ✓     |     ✓     |     ✓     |      ✓      |      ✓      |
|             | ICF              |     ✓     |     ✓     |     ✓     |      ✓      |      ✓      |
| PERSONAL    | Mitarbeiter      |     ✓     |     ✓     |     ✓     |             |      ✓      |
|             | Teams            |     ✓     |     ✓     |     ✓     |             |      ✓      |
|             | Urlaub           |     ✓     |     ✓     |     ✓     |      ✓      |             |
|             | Kapazitaet       |     ✓     |     ✓     |     ✓     |             |      ✓      |
| PLANUNG     | Dienstplan       |     ✓     |     ✓     |     ✓     |             |      ✓      |
|             | Zeitnachweise    |     ✓     |     ✓     |     ✓     |      ✓      |      ✓      |
| FINANZEN    | Rechnungen       |     ✓     |     ✓     |           |             |      ✓      |
|             | Berichte         |     ✓     |     ✓     |     ✓     |             |      ✓      |
| SYSTEM      | Einstellungen    |     ✓     |     ✓     |     ✓     |      ✓      |      ✓      |
|             | Backup           |     ✓     |           |           |             |             |
|             | Admin-Konsole    |     ✓     |           |           |             |             |
|             | Audit-Log        |     ✓     |     ✓     |           |             |      ✓      |

`teamMember`-Rolle bekommt nur 7 Eintraege (Arbeit + eigene Klienten/ICF + eigene Zeitnachweise + Einstellungen). Admin sieht 18.

## Technische Bausteine

### 1. `NavigationRail` als `AdaptiveScaffold`
- Auf Desktop/Tablet: extended rail (mit Labels), permanent
- Auf Mobile: Drawer oder BottomNavigationBar (falls Mitarbeiter spaeter Smartphone nutzt)
- `flutter_adaptive_scaffold` oder `responsive_framework` (bereits in pubspec) als Helper

### 2. Navigation-Model als Datenstruktur
```dart
class NavEntry {
  final String id;
  final IconData icon;
  final String label;
  final Widget Function() build;
  final bool Function(RolesPolicy policy) visibleFor;
  final NavSection section;
}
enum NavSection { arbeit, klienten, personal, planung, finanzen, system }
```
Zentral an einer Stelle deklariert, UI filtert rollenabhaengig. Das macht neue Eintraege in Zukunft ein One-Liner.

### 3. Routing
- Aktuell: `_tabController.animateTo(index)` (direkter Index, nicht benannt).
- Neu: `Navigator.restorablePushNamed` oder `go_router`. Empfehlung: `go_router` wird jetzt Idiom in Flutter — aber bedeutet groesserer Umbau.
- Minimal-Invasiv: Named-Routes-Map (`Map<String, WidgetBuilder>`) und `Navigator.pushReplacementNamed`. Macht Deep-Links moeglich (`/klienten/42`), ohne go_router-Abhaengigkeit.

### 4. Mitarbeiter-Dashboard (neue Seite „Arbeit")
Bei Mitarbeiter-Rolle erster Screen nach Login:
- „Meine Schichten heute/morgen"
- „Noch offene Gaben"
- „Offene Kassenbuch-Eintraege"
- „Letzte Benachrichtigungen"

Kompakt, ein Scroll, Schnell-Buttons.

### 5. Auth-/Rollen-Gate vor Build
Beim App-Start liest ein `AppShell` die aktuelle Rolle (aus `roles_policy_service`), zeigt bei teamMember das Arbeits-Dashboard, bei Admin das klassische Dashboard. Rolle wird aus `SharedPreferences` gelesen (derzeit `isAdmin: bool`) oder frisch aus `administration/users/roles.json` synchronisiert.

## Migrations-Strategie

**Kein Big-Bang.** Schritte:

1. **NavEntry-Model + Registry** anlegen, alle bestehenden 12 Tabs als Entries abbilden, Rollen auf `orgAdmin` (alle Tabs sichtbar). Bestehende TabBar bleibt, aber wird aus dem Model gebaut.
2. **Rollen-Filter** einziehen — Admin sieht weiter 12, andere Rollen sehen Subset. Test: Teammember-Login zeigt 7 Tabs.
3. **NavigationRail als neuer Shell**, TabBar wird geloescht. Gruppen-Header ergaenzen, responsive-Breakpoints.
4. **Mitarbeiter-Dashboard** als neue Entry-Seite fuer `teamMember`.
5. **Neue Feature-Screens** (Medi-Gabe, Kassenbuch-Eintrag) kommen jetzt direkt in die Rail, mit korrekten Sichtbarkeits-Regeln.

Schritt 1+2 sind reine Refaktorierungen ohne UI-Sichtbarkeit fuer den User — Schritt 3 ist der sichtbare Umbau.

## Aufwand

| Schritt | Aufwand | Risiko |
|---------|---------|--------|
| NavEntry-Registry | 0,5 d | gering |
| Rollen-Filter | 0,5 d | gering |
| NavigationRail + AppBar | 1,5 d | mittel (Layout-Bugs) |
| Mitarbeiter-Dashboard | 1 d | gering |
| **Summe** | **3,5 d** | |

## Abgrenzung

- go_router bleibt **vorerst raus** — ein Named-Routes-Map reicht. go_router kann spaeter nachgezogen werden, ohne die Rail anzufassen.
- Deep-Links (`/klienten/42`) werden mit der Named-Routes-Map moeglich, aber nicht aktiv ausgerollt.
- Benachrichtigungs-Glocke in der AppBar: separater Task, kommt mit „Arbeits-Dashboard".

## Offene Entscheidungen (vor der Umsetzung bestaetigen)

1. **Rail permanent oder einklappbar?** Empfehlung: permanent extended (Labels immer sichtbar), max. 240 px breit. Bei < 1024 px Breite einklappbar.
2. **Sektions-Trenner**: grosse Texte (`ARBEIT`, `KLIENTEN`) oder nur dezente Divider? Empfehlung: kleine Caps-Texte, 11 px, outline-Farbe.
3. **Mitarbeiter-Dashboard als erster Tab?** Empfehlung: ja — `teamMember` landet direkt darin, Admin landet weiter im jetzigen Dashboard.
4. **Global Search in der AppBar?** Empfehlung: ja, Platzhalter jetzt, Implementierung spaeter.
