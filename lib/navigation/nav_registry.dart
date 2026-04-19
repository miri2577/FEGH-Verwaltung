import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../features/billing/billing_screen.dart';
import '../features/capacity/capacity_screen.dart';
import '../features/clients/clients_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/employees/employees_screen.dart';
import '../features/icf/icf_screen.dart';
import '../features/my_work/my_work_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shifts/shifts_screen.dart';
import '../features/teams/teams_screen.dart';
import '../features/timesheets/timesheets_screen.dart';
import '../features/vacation/vacation_screen.dart';
import '../services/policy_service.dart';

/// Gruppen der Navigation. Reihenfolge = Sortierung in der Rail.
enum NavSection {
  arbeit,
  klienten,
  personal,
  planung,
  finanzen,
  system,
}

extension NavSectionLabel on NavSection {
  String get label {
    switch (this) {
      case NavSection.arbeit:
        return 'ARBEIT';
      case NavSection.klienten:
        return 'KLIENTEN';
      case NavSection.personal:
        return 'PERSONAL';
      case NavSection.planung:
        return 'PLANUNG';
      case NavSection.finanzen:
        return 'FINANZEN';
      case NavSection.system:
        return 'SYSTEM';
    }
  }
}

/// Ein Navigations-Eintrag. `visibleFor` steuert, welche Rollen ihn
/// in der Rail sehen.
class NavEntry {
  final String id;
  final IconData icon;
  final String label;
  final NavSection section;
  final WidgetBuilder builder;
  final bool Function(UserRole role) visibleFor;

  const NavEntry({
    required this.id,
    required this.icon,
    required this.label,
    required this.section,
    required this.builder,
    required this.visibleFor,
  });
}

// ── Rollen-Praedikate ─────────────────────────────────────────────

bool _all(UserRole r) => true;

bool _staffLike(UserRole r) =>
    r == UserRole.teamLead || r == UserRole.teamMember;

bool _nonMember(UserRole r) => r != UserRole.teamMember;

bool _leadOrAbove(UserRole r) =>
    r == UserRole.orgAdmin || r == UserRole.pvAdmin || r == UserRole.teamLead;

bool _auditorOrAdmin(UserRole r) =>
    r == UserRole.orgAdmin ||
    r == UserRole.pvAdmin ||
    r == UserRole.orgAuditor;

// ── Registry ──────────────────────────────────────────────────────

/// Die vollstaendige Navigation. Reihenfolge = Reihenfolge pro Sektion.
final List<NavEntry> navRegistry = <NavEntry>[
  // ARBEIT — nur fuer Staff (Member + Lead)
  NavEntry(
    id: 'my_work',
    icon: Symbols.work,
    label: 'Meine Arbeit',
    section: NavSection.arbeit,
    builder: (_) => const MyWorkScreen(),
    visibleFor: _staffLike,
  ),

  // KLIENTEN
  NavEntry(
    id: 'clients',
    icon: Symbols.people,
    label: 'Klienten',
    section: NavSection.klienten,
    builder: (_) => const ClientsScreen(),
    visibleFor: _all,
  ),
  NavEntry(
    id: 'icf',
    icon: Symbols.health_and_safety,
    label: 'ICF/TIB',
    section: NavSection.klienten,
    builder: (_) => const ICFScreen(),
    visibleFor: _all,
  ),

  // PERSONAL
  NavEntry(
    id: 'dashboard',
    icon: Symbols.dashboard,
    label: 'Dashboard',
    section: NavSection.personal,
    builder: (_) => const DashboardScreen(),
    visibleFor: _nonMember,
  ),
  NavEntry(
    id: 'employees',
    icon: Symbols.group,
    label: 'Mitarbeiter',
    section: NavSection.personal,
    builder: (_) => const EmployeesScreen(),
    visibleFor: _nonMember,
  ),
  NavEntry(
    id: 'teams',
    icon: Symbols.corporate_fare,
    label: 'Teams',
    section: NavSection.personal,
    builder: (_) => const TeamsScreen(),
    visibleFor: _nonMember,
  ),
  NavEntry(
    id: 'vacation',
    icon: Symbols.beach_access,
    label: 'Urlaub',
    section: NavSection.personal,
    builder: (_) => const VacationScreen(),
    visibleFor: _all,
  ),
  NavEntry(
    id: 'capacity',
    icon: Symbols.analytics,
    label: 'Kapazitaet',
    section: NavSection.personal,
    builder: (_) => const CapacityScreen(),
    visibleFor: _nonMember,
  ),

  // PLANUNG
  NavEntry(
    id: 'shifts',
    icon: Symbols.schedule,
    label: 'Dienstplan',
    section: NavSection.planung,
    builder: (_) => const ShiftsScreen(),
    visibleFor: _leadOrAbove,
  ),
  NavEntry(
    id: 'timesheets',
    icon: Symbols.assignment,
    label: 'Zeitnachweise',
    section: NavSection.planung,
    builder: (_) => const TimesheetsScreen(),
    visibleFor: _all,
  ),

  // FINANZEN
  NavEntry(
    id: 'billing',
    icon: Symbols.receipt_long,
    label: 'Rechnungen',
    section: NavSection.finanzen,
    builder: (_) => const BillingScreen(),
    visibleFor: _auditorOrAdmin,
  ),
  NavEntry(
    id: 'reports',
    icon: Symbols.assessment,
    label: 'Berichte',
    section: NavSection.finanzen,
    builder: (_) => const ReportsScreen(),
    visibleFor: _nonMember,
  ),

  // SYSTEM
  NavEntry(
    id: 'settings',
    icon: Symbols.settings,
    label: 'Einstellungen',
    section: NavSection.system,
    builder: (_) => const SettingsScreen(),
    visibleFor: _all,
  ),
];

/// Filtert die Registry nach aktiver Rolle und gruppiert sie nach
/// Sektion in der Reihenfolge von [NavSection].
Map<NavSection, List<NavEntry>> visibleEntriesGrouped(UserRole role) {
  final result = <NavSection, List<NavEntry>>{};
  for (final e in navRegistry) {
    if (!e.visibleFor(role)) continue;
    result.putIfAbsent(e.section, () => []).add(e);
  }
  return result;
}

/// Liefert den Default-Eintrag (erstes Item in der ersten sichtbaren
/// Sektion) oder `null`, falls nichts sichtbar ist.
NavEntry? defaultEntryFor(UserRole role) {
  for (final section in NavSection.values) {
    for (final e in navRegistry) {
      if (e.section == section && e.visibleFor(role)) return e;
    }
  }
  return null;
}
