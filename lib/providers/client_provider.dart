import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';
import '../services/local_storage_service.dart';
import 'employee_provider.dart';
import '../providers/hidrive_provider.dart';
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
      final newClient = client.copyWith(
        id: client.id.isEmpty ? _generateId() : client.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

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
      final webdav = ref.read(hidriveClientProvider);
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
      final client = ref.read(hidriveClientProvider);
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
      final client = ref.read(hidriveClientProvider);
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

  List<Client> _generateSampleClients() {
    final now = DateTime.now();
    return [
      Client(
        id: 'client_001',
        firstName: 'Max',
        lastName: 'Mustermann',
        email: 'max.mustermann@email.com',
        phone: '+49 30 123456789',
        address: 'Musterstraße 1, 10115 Berlin',
        dateOfBirth: DateTime(1985, 3, 15),
        status: ClientStatus.active,
        priority: ClientPriority.medium,
        services: [ServiceType.ambulant, ServiceType.beratung],
        notes: 'Regelmäßige Termine, sehr kooperativ',
        caseManager: 'Sarah Weber',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 5)),
        insuranceNumber: 'M123456789',
        emergencyContact: 'Anna Mustermann',
        emergencyPhone: '+49 30 987654321',
        assignedEmployees: ['emp_001', 'emp_003'],
        fachleistungsstunden: 120,
        fachleistungsIntervall: 'monatlich',
        hilfeTyp: 'eingliederungshilfe',
        kostenuebernahme: 'Bezirksamt Mitte',
        kostenuebernahmeVon: DateTime(2025, 1, 1),
        kostenuebernahmeBis: DateTime(2025, 12, 31),
        betreuungSeit: DateTime(2023, 6, 1),
        verbrauchteStunden: 45.5,
      ),
      Client(
        id: 'client_002',
        firstName: 'Anna',
        lastName: 'Schmidt',
        email: 'anna.schmidt@email.com',
        phone: '+49 30 234567890',
        address: 'Beispielweg 5, 10117 Berlin',
        dateOfBirth: DateTime(1992, 8, 22),
        status: ClientStatus.active,
        priority: ClientPriority.high,
        services: [ServiceType.stationaer, ServiceType.wohnen],
        notes: 'Benötigt intensive Betreuung',
        caseManager: 'Thomas Müller',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 1)),
        insuranceNumber: 'A987654321',
        emergencyContact: 'Peter Schmidt',
        emergencyPhone: '+49 30 876543210',
        assignedEmployees: ['emp_002', 'emp_004'],
        fachleistungsstunden: 80,
        fachleistungsIntervall: 'monatlich',
        hilfeTyp: 'familienhilfe',
        kostenuebernahme: 'Jugendamt Charlottenburg',
        kostenuebernahmeVon: DateTime(2025, 3, 1),
        kostenuebernahmeBis: DateTime(2026, 2, 28),
        betreuungSeit: DateTime(2024, 1, 15),
        verbrauchteStunden: 72.0,
        stundensatzOverride: 58.50,
      ),
      Client(
        id: 'client_003',
        firstName: 'Peter',
        lastName: 'Weber',
        email: 'peter.weber@email.com',
        phone: '+49 30 345678901',
        address: 'Teststraße 12, 10119 Berlin',
        dateOfBirth: DateTime(1978, 12, 5),
        status: ClientStatus.pending,
        priority: ClientPriority.urgent,
        services: [ServiceType.begleitung, ServiceType.arbeit],
        notes: 'Neue Aufnahme, Erstgespräch steht aus',
        caseManager: 'Maria Hoffmann',
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        insuranceNumber: 'P456789123',
        emergencyContact: 'Lisa Weber',
        emergencyPhone: '+49 30 765432109',
        assignedEmployees: ['emp_001'],
        fachleistungsstunden: 160,
        fachleistungsIntervall: 'jaehrlich',
        hilfeTyp: 'eingliederungshilfe',
        betreuungSeit: DateTime(2026, 2, 1),
      ),
      Client(
        id: 'client_004',
        firstName: 'Julia',
        lastName: 'Hoffmann',
        email: 'julia.hoffmann@email.com',
        phone: '+49 30 456789012',
        address: 'Probeallee 8, 10121 Berlin',
        dateOfBirth: DateTime(1995, 6, 18),
        status: ClientStatus.active,
        priority: ClientPriority.low,
        services: [ServiceType.freizeit, ServiceType.beratung],
        notes: 'Teilnahme an Freizeitgruppen',
        caseManager: 'David Klein',
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 3)),
        insuranceNumber: 'J321654987',
        emergencyContact: 'Robert Hoffmann',
        emergencyPhone: '+49 30 654321098',
        assignedEmployees: ['emp_005'],
        fachleistungsstunden: 40,
        fachleistungsIntervall: 'woechentlich',
        hilfeTyp: 'eingliederungshilfe',
        kostenuebernahme: 'Sozialamt Neukölln',
        kostenuebernahmeVon: DateTime(2025, 6, 1),
        kostenuebernahmeBis: DateTime(2026, 5, 31),
        betreuungSeit: DateTime(2024, 9, 1),
        verbrauchteStunden: 12.0,
        kalkulationsfaktorOverride: 1.5,
      ),
    ];
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
