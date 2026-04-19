import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/team.dart';
import '../models/app_settings.dart';
import '../services/local_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/crypto_storage.dart';
import 'settings_provider.dart';
import 'employee_provider.dart';
import 'policy_provider.dart';

final teamsProvider = StateNotifierProvider<TeamsNotifier, AsyncValue<List<Team>>>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  final syncService = ref.watch(cloudSyncServiceProvider);
  final settings = ref.watch(appSettingsProvider);

  return TeamsNotifier(localStorage, syncService, settings, ref);
});

class TeamsNotifier extends StateNotifier<AsyncValue<List<Team>>> {
  final LocalStorageService _localStorage;
  final CloudSyncService? _syncService;
  final AppSettings _settings;
  final Ref? _ref;

  TeamsNotifier(this._localStorage, this._syncService, this._settings, [this._ref])
      : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _loadTeams();

      // Auto-sync on startup if enabled
      if (_settings.autoSyncOnStartup && _syncService != null) {
        await _syncFromCloud();
      }

      if (kDebugMode) {
        print('✅ Team provider initialized');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Team provider initialization failed: $e');
      }
    }
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await _localStorage.loadTeams();
      state = AsyncValue.data(teams);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addTeam(Team team) async {
    try {
      // RBAC: Nur Admin‑Rollen dürfen Teams verwalten
      final policy = _ref?.read(policyProvider);
      if (policy != null && !policy.canManageTeams()) {
        throw Exception('Keine Berechtigung, Teams zu erstellen');
      }
      state = const AsyncValue.loading();

      final teamWithId = team.id.isEmpty
          ? team.copyWith(id: _localStorage.generateId())
          : team;

      final savedTeam = await _localStorage.saveTeam(teamWithId);

      if (savedTeam != null) {
        if (_settings.autoSyncOnChanges && _syncService != null) {
          await _syncService!.saveRecord('team', savedTeam.toJson());
        }

        await _loadTeams();

        if (kDebugMode) {
          print('✅ Team added: ${savedTeam.name}');
        }
      } else {
        throw Exception('Failed to save team');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to add team: $e');
      }
    }
  }

  Future<void> updateTeam(Team team) async {
    try {
      final policy = _ref?.read(policyProvider);
      if (policy != null && !policy.canManageTeams()) {
        throw Exception('Keine Berechtigung, Teams zu bearbeiten');
      }
      state = const AsyncValue.loading();

      final updatedTeam = await _localStorage.saveTeam(team);

      if (updatedTeam != null) {
        if (_settings.autoSyncOnChanges && _syncService != null) {
          await _syncService!.saveRecord('team', updatedTeam.toJson());
        }

        await _loadTeams();

        if (kDebugMode) {
          print('✅ Team updated: ${updatedTeam.name}');
        }
      } else {
        throw Exception('Failed to update team');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to update team: $e');
      }
    }
  }

  Future<void> deleteTeam(String teamId) async {
    try {
      final policy = _ref?.read(policyProvider);
      if (policy != null && !policy.canManageTeams()) {
        throw Exception('Keine Berechtigung, Teams zu löschen');
      }
      state = const AsyncValue.loading();

      final success = await _localStorage.deleteTeam(teamId);

      if (success) {
        if (_settings.autoSyncOnChanges && _syncService != null) {
          final records = await _syncService!.getRecordsByCategory('team');
          for (final recordId in records) {
            final record = await _syncService!.loadRecord(recordId);
            if (record != null && record['id'] == teamId) {
              await _syncService!.deleteRecord(recordId);
              break;
            }
          }
        }

        await _loadTeams();

        if (kDebugMode) {
          print('✅ Team deleted: $teamId');
        }
      } else {
        throw Exception('Failed to delete team');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to delete team: $e');
      }
    }
  }

  Future<void> addMemberToTeam(String teamId, String employeeId) async {
    try {
      final teams = await _localStorage.loadTeams();
      final teamIndex = teams.indexWhere((t) => t.id == teamId);

      if (teamIndex >= 0) {
        final updatedTeam = teams[teamIndex].addMember(employeeId);
        await updateTeam(updatedTeam);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to add member to team: $e');
      }
    }
  }

  Future<void> removeMemberFromTeam(String teamId, String employeeId) async {
    try {
      final teams = await _localStorage.loadTeams();
      final teamIndex = teams.indexWhere((t) => t.id == teamId);

      if (teamIndex >= 0) {
        final updatedTeam = teams[teamIndex].removeMember(employeeId);
        await updateTeam(updatedTeam);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to remove member from team: $e');
      }
    }
  }

  Future<void> _syncFromCloud() async {
    if (_syncService == null) return;

    try {
      await _syncService!.syncFromRemote();

      // Load any new teams from cloud
      final teamRecordIds = await _syncService!.getRecordsByCategory('team');
      final currentTeams = await _localStorage.loadTeams();

      for (final recordId in teamRecordIds) {
        final record = await _syncService!.loadRecord(recordId);
        if (record != null) {
          final cloudTeam = Team.fromJson(record);

          // Check if team already exists locally
          final existsLocally = currentTeams.any((t) => t.id == cloudTeam.id);

          if (!existsLocally) {
            await _localStorage.saveTeam(cloudTeam);
            if (kDebugMode) {
              print('⬇️ Synced team from cloud: ${cloudTeam.name}');
            }
          }
        }
      }

      await _loadTeams();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to sync from cloud: $e');
      }
    }
  }

  Future<void> syncToCloud() async {
    if (_syncService == null) return;

    try {
      state = const AsyncValue.loading();

      final teams = await _localStorage.loadTeams();

      for (final team in teams) {
        await _syncService!.saveRecord('team', team.toJson());
      }

      await _loadTeams();

      if (kDebugMode) {
        print('✅ Synced ${teams.length} teams to cloud');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to sync to cloud: $e');
      }
    }
  }

  Future<void> refresh() async {
    await _loadTeams();
  }
}

// Convenience providers
final activeTeamsProvider = Provider<AsyncValue<List<Team>>>((ref) {
  final teams = ref.watch(teamsProvider);
  return teams.when(
    data: (teams) => AsyncValue.data(
      teams.where((t) => t.status == TeamStatus.active).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final teamByIdProvider = Provider.family<Team?, String>((ref, teamId) {
  final teams = ref.watch(teamsProvider);
  return teams.when(
    data: (teams) {
      try {
        return teams.firstWhere((t) => t.id == teamId);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (error, stack) => null,
  );
});

final teamCountProvider = Provider<int>((ref) {
  final teams = ref.watch(teamsProvider);
  return teams.when(
    data: (teams) => teams.length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

final activeTeamCountProvider = Provider<int>((ref) {
  final activeTeams = ref.watch(activeTeamsProvider);
  return activeTeams.when(
    data: (teams) => teams.length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

final teamsByDepartmentProvider = Provider<Map<String, List<Team>>>((ref) {
  final teams = ref.watch(teamsProvider);
  return teams.when(
    data: (teams) {
      final Map<String, List<Team>> groupedTeams = {};
      for (final team in teams) {
        final department = team.department ?? 'Ohne Abteilung';
        if (!groupedTeams.containsKey(department)) {
          groupedTeams[department] = [];
        }
        groupedTeams[department]!.add(team);
      }
      return groupedTeams;
    },
    loading: () => <String, List<Team>>{},
    error: (error, stack) => <String, List<Team>>{},
  );
});
