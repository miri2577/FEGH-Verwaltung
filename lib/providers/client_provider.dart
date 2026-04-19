import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';
import '../services/local_storage_service.dart';
import 'employee_provider.dart';
import '../providers/cloud_provider.dart';
import '../services/audit_logger.dart';
import '../services/org_client_sync_service.dart';
import '../services/crypto_storage.dart';
import '../providers/settings_provider.dart';
import '../providers/policy_provider.dart';

class ClientNotifier extends Notifier<List<Client>> {
  late final LocalStorageService _storageService;

  @override
  List<Client> build() {
    _storageService = ref.read(localStorageServiceProvider);
    _loadClients();
    return [];
  }

  Future<void> _loadClients() async {
    try {
      final clientsData = await _storageService.getClients();
      state = clientsData.map((data) => Client.fromJson(data)).toList();
      print('✅ Clients loaded: ${state.length}');
    } catch (e) {
      print('❌ Error loading clients: $e');
      state = [];
    }
  }

  Future<void> addClient(Client client) async {
    try {
      final policy = ref.read(policyProvider);
      if (!policy.canCreateClient(teamId: client.teamId)) {
        print('🚫 Keine Berechtigung: Client anlegen');
        return;
      }
      final newClient = client.id.isEmpty
          ? Client.create(
              firstName: client.firstName,
              lastName: client.lastName,
              dateOfBirth: client.dateOfBirth,
              teamId: client.teamId,
              email: client.email,
              phone: client.phone,
              address: client.address,
              status: client.status,
              priority: client.priority,
              services: client.services,
              notes: client.notes,
              caseManager: client.caseManager,
              insuranceNumber: client.insuranceNumber,
              emergencyContact: client.emergencyContact,
              emergencyPhone: client.emergencyPhone,
              assignedEmployees: client.assignedEmployees,
              responsibleEmployeeId: client.responsibleEmployeeId,
              deputyEmployeeId: client.deputyEmployeeId,
              deputy2EmployeeId: client.deputy2EmployeeId,
              customFields: client.customFields,
              hilfeTyp: client.hilfeTyp,
              fachleistungsstunden: client.fachleistungsstunden,
              fachleistungsIntervall: client.fachleistungsIntervall,
              kostenuebernahme: client.kostenuebernahme,
              kostenuebernahmeVon: client.kostenuebernahmeVon,
              kostenuebernahmeBis: client.kostenuebernahmeBis,
              betreuungSeit: client.betreuungSeit,
              icfBereiche: client.icfBereiche,
              tibZiele: client.tibZiele,
              individuelleTibZiele: client.individuelleTibZiele,
              kalkulationsfaktorOverride: client.kalkulationsfaktorOverride,
              stundensatzOverride: client.stundensatzOverride,
              verbrauchteStunden: client.verbrauchteStunden,
            )
          : client.copyWith(updatedAt: DateTime.now());

      state = [...state, newClient];
      await _saveClients();
      print('✅ Client added: ${newClient.fullName}');
      await AuditLogger.log('client.add', context: {'id': newClient.id, 'teamId': newClient.teamId, 'name': newClient.fullName});

      // Cloud-Sync (team-scoped) – nur wenn aktiviert und teamId gesetzt
      await _maybeUploadClient(newClient);
    } catch (e) {
      print('❌ Error adding client: $e');
    }
  }

  Future<void> updateClient(Client updatedClient) async {
    try {
      final policy = ref.read(policyProvider);
      // Vorherigen Zustand ermitteln, um Team-Wechsel zu erkennen
      final prev = state.firstWhere((c) => c.id == updatedClient.id, orElse: () => updatedClient);
      if (!policy.canEditClient(teamId: updatedClient.teamId)) {
        print('🚫 Keine Berechtigung: Client bearbeiten');
        return;
      }
      final updated = updatedClient.copyWith(updatedAt: DateTime.now());
      state = state.map((client) {
        return client.id == updated.id ? updated : client;
      }).toList();

      await _saveClients();
      print('✅ Client updated: ${updated.fullName}');
      await AuditLogger.log('client.update', context: {'id': updated.id, 'teamId': updated.teamId, 'name': updated.fullName});

      // Wenn Team gewechselt wurde → Migration im Cloud-Speicher
      if ((prev.teamId ?? '') != (updated.teamId ?? '')) {
        if (!policy.canChangeClientTeam(fromTeamId: prev.teamId, toTeamId: updated.teamId)) {
          print('🚫 Keine Berechtigung: Client-Team wechseln');
          return;
        }
        await _maybeMigrateClient(prevTeamId: prev.teamId, client: updated);
      } else {
        await _maybeUploadClient(updated);
      }
    } catch (e) {
      print('❌ Error updating client: $e');
    }
  }

  Future<void> deleteClient(String clientId) async {
    try {
      final clientToDelete = state.firstWhere((c) => c.id == clientId);
      final policy = ref.read(policyProvider);
      if (!policy.canDeleteClient(teamId: clientToDelete.teamId)) {
        print('🚫 Keine Berechtigung: Client löschen');
        return;
      }
      state = state.where((client) => client.id != clientId).toList();
      await _saveClients();
      print('✅ Client deleted: ${clientToDelete.fullName}');
      await AuditLogger.log('client.delete', context: {'id': clientToDelete.id, 'teamId': clientToDelete.teamId, 'name': clientToDelete.fullName});

      await _maybeDeleteClient(clientToDelete);
    } catch (e) {
      print('❌ Error deleting client: $e');
    }
  }

  Future<void> _maybeMigrateClient({required String? prevTeamId, required Client client}) async {
    try {
      final settings = ref.read(appSettingsProvider);
      if (!settings.isCloudSyncReady) return;
      if (settings.organizationId == null || settings.organizationId!.isEmpty) return;
      final oldTeam = prevTeamId ?? '';
      final newTeam = client.teamId ?? '';
      if (oldTeam.isEmpty || newTeam.isEmpty || oldTeam == newTeam) {
        await _maybeUploadClient(client);
        return;
      }
      final webdav = ref.read(cloudClientProvider);
      final crypto = ref.read(cryptoStorageProvider);
      await crypto.initialize();
      final svc = OrgClientSyncService(
        client: webdav,
        crypto: crypto,
        orgBase: 'eingliederungshilfe/organizations/${settings.organizationId}',
      );
      final ok = await svc.migrateClientTeam(clientModel: client, oldTeamId: oldTeam, newTeamId: newTeam);
      print(ok
          ? '☁️ ✅ Client-Team migriert: ${client.fullName} ($oldTeam → $newTeam)'
          : '☁️ ❌ Migration fehlgeschlagen: ${client.fullName}');
    } catch (e) {
      print('☁️ ❌ Migration-Fehler: $e');
    }
  }

  Future<void> _maybeUploadClient(Client c) async {
    try {
      final settings = ref.read(appSettingsProvider);
      if (!settings.isCloudSyncReady) return;
      if (settings.organizationId == null || settings.organizationId!.isEmpty) return;
      if (c.teamId == null || c.teamId!.isEmpty) return;
      final client = ref.read(cloudClientProvider);
      final crypto = ref.read(cryptoStorageProvider);
      await crypto.initialize();
      final svc = OrgClientSyncService(
        client: client,
        crypto: crypto,
        orgBase: 'eingliederungshilfe/organizations/${settings.organizationId}',
      );
      final ok = await svc.uploadOrUpdateClient(c);
      if (ok) {
        print('☁️ ✅ Client in Cloud aktualisiert: ${c.fullName} (team=${c.teamId})');
      } else {
        print('☁️ ⚠️ Client nicht synchronisiert (fehlende Team/Org/Sync)');
      }
    } catch (e) {
      print('☁️ ❌ Client-Sync fehlgeschlagen: $e');
    }
  }

  Future<void> _maybeDeleteClient(Client c) async {
    try {
      final settings = ref.read(appSettingsProvider);
      if (!settings.isCloudSyncReady) return;
      if (settings.organizationId == null || settings.organizationId!.isEmpty) return;
      if (c.teamId == null || c.teamId!.isEmpty) return;
      final client = ref.read(cloudClientProvider);
      final crypto = ref.read(cryptoStorageProvider);
      await crypto.initialize();
      final svc = OrgClientSyncService(
        client: client,
        crypto: crypto,
        orgBase: 'eingliederungshilfe/organizations/${settings.organizationId}',
      );
      await svc.deleteClient(c);
      print('☁️ ✅ Client in Cloud gelöscht: ${c.fullName}');
    } catch (e) {
      print('☁️ ❌ Client-Delete-Sync fehlgeschlagen: $e');
    }
  }

  Future<void> archiveClient(String clientId) async {
    try {
      final clientIndex = state.indexWhere((c) => c.id == clientId);
      if (clientIndex != -1) {
        final updatedClient = state[clientIndex].copyWith(
          status: ClientStatus.archived,
          updatedAt: DateTime.now(),
        );

        state = List.from(state);
        state[clientIndex] = updatedClient;
        await _saveClients();
        print('✅ Client archived: ${updatedClient.fullName}');
      }
    } catch (e) {
      print('❌ Error archiving client: $e');
    }
  }

  Future<void> assignEmployeeToClient(String clientId, String employeeId) async {
    try {
      final clientIndex = state.indexWhere((c) => c.id == clientId);
      if (clientIndex != -1) {
        final client = state[clientIndex];
        final updatedEmployees = List<String>.from(client.assignedEmployees);

        if (!updatedEmployees.contains(employeeId)) {
          updatedEmployees.add(employeeId);

          final updatedClient = client.copyWith(
            assignedEmployees: updatedEmployees,
            updatedAt: DateTime.now(),
          );

          state = List.from(state);
          state[clientIndex] = updatedClient;
          await _saveClients();
          print('✅ Employee $employeeId assigned to client ${client.fullName}');
        }
      }
    } catch (e) {
      print('❌ Error assigning employee to client: $e');
    }
  }

  Future<void> removeEmployeeFromClient(String clientId, String employeeId) async {
    try {
      final clientIndex = state.indexWhere((c) => c.id == clientId);
      if (clientIndex != -1) {
        final client = state[clientIndex];
        final updatedEmployees = List<String>.from(client.assignedEmployees);
        updatedEmployees.remove(employeeId);

        final updatedClient = client.copyWith(
          assignedEmployees: updatedEmployees,
          updatedAt: DateTime.now(),
        );

        state = List.from(state);
        state[clientIndex] = updatedClient;
        await _saveClients();
        print('✅ Employee $employeeId removed from client ${client.fullName}');
      }
    } catch (e) {
      print('❌ Error removing employee from client: $e');
    }
  }

  Future<void> _saveClients() async {
    try {
      final clientsData = state.map((client) => client.toJson()).toList();
      await _storageService.saveClients(clientsData);
    } catch (e) {
      print('❌ Error saving clients: $e');
    }
  }

  String _generateId() {
    // Format muss mit EH-App kompatibel sein (nur Timestamp, kein Prefix)
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Getter für gefilterte Listen
  List<Client> get activeClients =>
      state.where((client) => client.status == ClientStatus.active).toList();

  List<Client> get pendingClients =>
      state.where((client) => client.status == ClientStatus.pending).toList();

  List<Client> get archivedClients =>
      state.where((client) => client.status == ClientStatus.archived).toList();

  List<Client> get urgentClients =>
      state.where((client) => client.priority == ClientPriority.urgent).toList();

  List<Client> getClientsByEmployee(String employeeId) =>
      state.where((client) => client.assignedEmployees.contains(employeeId)).toList();

  List<Client> getClientsByService(ServiceType service) =>
      state.where((client) => client.services.contains(service)).toList();

  Client? getClientById(String id) {
    try {
      return state.firstWhere((client) => client.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Client> searchClients(String query) {
    if (query.isEmpty) return state;

    final lowercaseQuery = query.toLowerCase();
    return state.where((client) {
      return client.firstName.toLowerCase().contains(lowercaseQuery) ||
          client.lastName.toLowerCase().contains(lowercaseQuery) ||
          client.fullName.toLowerCase().contains(lowercaseQuery) ||
          (client.email?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (client.phone?.contains(query) ?? false) ||
          (client.insuranceNumber?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  Map<ClientStatus, int> get statusStatistics {
    final stats = <ClientStatus, int>{
      ClientStatus.active: 0,
      ClientStatus.inactive: 0,
      ClientStatus.pending: 0,
      ClientStatus.archived: 0,
    };

    for (final client in state) {
      stats[client.status] = (stats[client.status] ?? 0) + 1;
    }

    return stats;
  }

  Map<ServiceType, int> get serviceStatistics {
    final stats = <ServiceType, int>{};

    for (final client in state) {
      for (final service in client.services) {
        stats[service] = (stats[service] ?? 0) + 1;
      }
    }

    return stats;
  }
}

// Provider Export
final clientProvider = NotifierProvider<ClientNotifier, List<Client>>(() {
  return ClientNotifier();
});

// Convenience providers
final activeClientsProvider = Provider<List<Client>>((ref) {
  return ref.watch(clientProvider.notifier).activeClients;
});

final pendingClientsProvider = Provider<List<Client>>((ref) {
  return ref.watch(clientProvider.notifier).pendingClients;
});

final urgentClientsProvider = Provider<List<Client>>((ref) {
  return ref.watch(clientProvider.notifier).urgentClients;
});

final clientStatisticsProvider = Provider<Map<ClientStatus, int>>((ref) {
  return ref.watch(clientProvider.notifier).statusStatistics;
});

final serviceStatisticsProvider = Provider<Map<ServiceType, int>>((ref) {
  return ref.watch(clientProvider.notifier).serviceStatistics;
});
