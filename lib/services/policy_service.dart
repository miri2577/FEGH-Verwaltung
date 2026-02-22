import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/roles_policy_provider.dart';

enum UserRole { orgAdmin, orgAuditor, teamLead, teamMember, pvAdmin }

class PolicyService {
  final Ref ref;
  PolicyService(this.ref);

  UserRole get role {
    final s = ref.read(appSettingsProvider);
    // Prefer Org‑Policy mapping (roles.json)
    final policy = ref.read(rolesPolicyProvider);
    final mapped = policy.getRoleFor(s.hidriveUsername);
    final roleStr = (mapped ?? s.userRole ?? '').toLowerCase();
    switch (roleStr) {
      case 'org_admin':
      case 'orgadmin':
        return UserRole.orgAdmin;
      case 'org_auditor':
      case 'orgauditor':
        return UserRole.orgAuditor;
      case 'team_lead':
      case 'teamlead':
        return UserRole.teamLead;
      case 'pv_admin':
      case 'pvadmin':
        return UserRole.pvAdmin;
      default:
        return UserRole.teamMember;
    }
  }

  bool get _isAdmin => role == UserRole.orgAdmin || role == UserRole.pvAdmin;
  bool get _isAuditor => role == UserRole.orgAuditor;
  bool get _isLead => role == UserRole.teamLead;

  List<String> _myTeams() {
    final s = ref.read(appSettingsProvider);
    final policy = ref.read(rolesPolicyProvider);
    return policy.getTeamsFor(s.hidriveUsername);
  }

  bool _isLeadOfTeam(String? teamId) {
    if (!_isLead) return false;
    if (teamId == null || teamId.isEmpty) return false;
    return _myTeams().contains(teamId);
  }

  // Team‑Lead nur innerhalb eigener Teams
  bool canCreateClient({String? teamId}) => _isAdmin || _isLeadOfTeam(teamId);
  bool canEditClient({String? teamId}) => _isAdmin || _isLeadOfTeam(teamId);
  bool canDeleteClient({String? teamId}) => _isAdmin;
  bool canChangeClientTeam({String? fromTeamId, String? toTeamId}) => _isAdmin;
  bool canManageTeams() => _isAdmin;
  bool canRebuildIndexes() => _isAdmin;
  bool canRotateKeys() => _isAdmin;
  bool canViewAdminTools() => _isAdmin || _isAuditor;

  // Dokumentation (ICF/TIB): nur Team‑Leads (optional Auditor per Policy erweiterbar)
  bool canViewDocumentation() {
    // Admin bewusst ausgeschlossen; Auditor via Scope oder Settings-Schalter
    if (_isLead) return true;
    if (_isAuditor) {
      final s = ref.read(appSettingsProvider);
      if (s.auditorCanViewDocs) return true; // globaler Schalter (Admin entscheidet)
      final policy = ref.read(rolesPolicyProvider);
      final scope = policy.getAuditScopeFor(s.hidriveUsername);
      return scope?.isActive == true;
    }
    return false;
  }

  // Team‑sensitiver Doku‑Zugriff: true nur, wenn Rolle und Scope (Team/Zeitraum) passen
  bool canViewDocumentationForTeam(String? teamId, {DateTime? when}) {
    final ts = when?.toUtc() ?? DateTime.now().toUtc();
    // Team‑Lead: nur eigene Teams
    if (_isLead) {
      return _isLeadOfTeam(teamId);
    }
    // Auditor: nur mit aktivem Scope und (falls Teams angegeben) passendem Team
    if (_isAuditor) {
      final s = ref.read(appSettingsProvider);
      final policy = ref.read(rolesPolicyProvider);
      final scope = policy.getAuditScopeFor(s.hidriveUsername);
      if (scope == null || !scope.isActive) return false;
      final inTime = (scope.from == null || !ts.isBefore(scope.from!)) && (scope.to == null || !ts.isAfter(scope.to!));
      final inTeam = (teamId == null || teamId.isEmpty || scope.teams.isEmpty || scope.teams.contains(teamId));
      return inTime && inTeam;
    }
    // Admins & Members: kein Zugriff
    return false;
  }

  // Reports / Export
  bool canViewReports() => true; // alle dürfen lesen
  bool canUseReportTemplates() => _isAdmin || _isLead; // Templates anwenden
  bool canManageReportTemplates() => _isAdmin; // erstellen/bearbeiten/löschen
  bool canExportData() => _isAdmin || _isLead; // Datenexport
}
