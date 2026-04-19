import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'cloud_webdav_client.dart';

class AuditScope {
  final List<String> teams;
  final DateTime? from;
  final DateTime? to;
  final String? reason;

  const AuditScope({this.teams = const [], this.from, this.to, this.reason});

  bool get isActive {
    final now = DateTime.now().toUtc();
    if (from != null && now.isBefore(from!)) return false;
    if (to != null && now.isAfter(to!)) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
        if (teams.isNotEmpty) 'teams': teams,
        if (from != null) 'from': from!.toUtc().toIso8601String(),
        if (to != null) 'to': to!.toUtc().toIso8601String(),
        if (reason != null) 'reason': reason,
      };

  factory AuditScope.fromJson(Map<String, dynamic> json) {
    return AuditScope(
      teams: (json['teams'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      from: json['from'] != null ? DateTime.tryParse(json['from'].toString())?.toUtc() : null,
      to: json['to'] != null ? DateTime.tryParse(json['to'].toString())?.toUtc() : null,
      reason: json['reason']?.toString(),
    );
  }
}

class RolesPolicyService {
  final CloudWebDavClient client;
  final String orgBase; // eingliederungshilfe/organizations/<org>

  Map<String, String> _userRoles = {}; // username/email -> role
  Map<String, List<String>> _userTeams = {}; // username/email -> teams
  Map<String, AuditScope> _auditScopes = {}; // username/email -> scope

  RolesPolicyService({required this.client, required this.orgBase});

  Future<bool> refresh() async {
    try {
      final path = '$orgBase/administration/users/roles.json';
      final res = await client.get(path);
      if (!res.success || res.data == null) {
        if (kDebugMode) debugPrint('[ROLES] roles.json not found');
        _userRoles = {};
        _userTeams = {};
        return false;
      }
      final jsonStr = utf8.decode(res.data!);
      final obj = jsonDecode(jsonStr) as Map<String, dynamic>;
      final users = (obj['users'] as List?) ?? const [];
      final roles = <String, String>{};
      final teams = <String, List<String>>{};
      for (final u in users) {
        if (u is Map<String, dynamic>) {
          final id = (u['id'] ?? '').toString().trim().toLowerCase();
          if (id.isEmpty) continue;
          final role = (u['role'] ?? '').toString();
          roles[id] = role;
          final t = (u['teams'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
          teams[id] = t;
          // optionaler Audit-Scope
          final scopeRaw = u['auditScope'];
          if (scopeRaw is Map<String, dynamic>) {
            _auditScopes[id] = AuditScope.fromJson(scopeRaw);
          }
        }
      }
      _userRoles = roles;
      _userTeams = teams;
      if (kDebugMode) debugPrint('[ROLES] loaded ${_userRoles.length} entries');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[ROLES] load error: $e');
      _userRoles = {};
      _userTeams = {};
      return false;
    }
  }

  String? getRoleFor(String? usernameOrEmail) {
    if (usernameOrEmail == null) return null;
    final key = usernameOrEmail.trim().toLowerCase();
    return _userRoles[key];
  }

  List<String> getTeamsFor(String? usernameOrEmail) {
    if (usernameOrEmail == null) return const [];
    final key = usernameOrEmail.trim().toLowerCase();
    return _userTeams[key] ?? const [];
  }

  /// Lädt die rohe roles.json als Map (ohne Caching), oder null wenn nicht vorhanden
  Future<Map<String, dynamic>?> loadRaw() async {
    try {
      final path = '$orgBase/administration/users/roles.json';
      final res = await client.get(path);
      if (!res.success || res.data == null) return null;
      final jsonStr = utf8.decode(res.data!);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('[ROLES] loadRaw error: $e');
      return null;
    }
  }

  /// Schreibt eine neue roles.json auf den Server (überschreibt bestehende)
  Future<bool> save(Map<String, dynamic> rolesObject) async {
    try {
      // Minimalvalidierung
      if (!rolesObject.containsKey('users') || rolesObject['users'] is! List) {
        throw ArgumentError('roles.json benötigt ein Feld "users" vom Typ Liste');
      }
      final path = '$orgBase/administration/users/roles.json';
      await client.mkcol('$orgBase/administration');
      await client.mkcol('$orgBase/administration/users');
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(rolesObject)));
      final res = await client.put(path, bytes);
      if (res.success) {
        // Nach Speichern Cache aktualisieren
        return await refresh();
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('[ROLES] save error: $e');
      return false;
    }
  }

  AuditScope? getAuditScopeFor(String? usernameOrEmail) {
    if (usernameOrEmail == null) return null;
    final key = usernameOrEmail.trim().toLowerCase();
    return _auditScopes[key];
  }

  /// Setzt oder aktualisiert den Audit-Scope für einen Auditor in roles.json
  Future<bool> setAuditorScope({
    required String userId,
    required AuditScope scope,
  }) async {
    try {
      final raw = await loadRaw() ?? {'users': <Map<String, dynamic>>[]};
      final users = List<Map<String, dynamic>>.from((raw['users'] as List?) ?? <Map<String, dynamic>>[]);
      final key = userId.trim().toLowerCase();
      final idx = users.indexWhere((u) => (u['id'] ?? '').toString().toLowerCase() == key);
      if (idx >= 0) {
        users[idx]['auditScope'] = scope.toJson();
      } else {
        users.add({'id': key, 'role': 'org_auditor', 'teams': <String>[], 'auditScope': scope.toJson()});
      }
      final ok = await save({'users': users});
      if (ok) _auditScopes[key] = scope;
      return ok;
    } catch (e) {
      if (kDebugMode) debugPrint('[ROLES] setAuditorScope error: $e');
      return false;
    }
  }

  /// Entfernt den Audit-Scope für einen Auditor in roles.json
  Future<bool> clearAuditorScope(String userId) async {
    try {
      final raw = await loadRaw() ?? {'users': <Map<String, dynamic>>[]};
      final users = List<Map<String, dynamic>>.from((raw['users'] as List?) ?? <Map<String, dynamic>>[]);
      final key = userId.trim().toLowerCase();
      final idx = users.indexWhere((u) => (u['id'] ?? '').toString().toLowerCase() == key);
      if (idx >= 0) {
        users[idx].remove('auditScope');
      }
      final ok = await save({'users': users});
      if (ok) _auditScopes.remove(key);
      return ok;
    } catch (e) {
      if (kDebugMode) debugPrint('[ROLES] clearAuditorScope error: $e');
      return false;
    }
  }
}
