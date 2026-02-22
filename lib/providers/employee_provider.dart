import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/employee.dart';
import '../models/app_settings.dart';
import '../services/local_storage_service.dart';
import '../services/hidrive_sync_service.dart';
import '../services/crypto_storage.dart';
import '../services/hidrive_webdav_client.dart';
import 'settings_provider.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final cryptoStorageProvider = Provider<CryptoStorage>((ref) {
  return CryptoStorage();
});

final hiDriveSyncServiceProvider = Provider<HiDriveSyncService?>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final cryptoStorage = ref.watch(cryptoStorageProvider);

  if (!settings.isCloudSyncReady) return null;

  final sub = (settings.rootSubdirectory != null && settings.rootSubdirectory!.trim().isNotEmpty)
      ? settings.rootSubdirectory!.trim()
      : null;
  final customBase = HiDriveConfig.buildWebDAVUrl(settings.hidriveUsername ?? '', subdirectory: sub);
  final client = HiDriveWebDAVClient(
    username: settings.hidriveUsername ?? '',
    password: settings.hidrivePassword ?? '',
    customBaseUrl: customBase,
  );
  final base = 'eingliederungshilfe/organizations/${settings.organizationId ?? 'default'}/administration';
  final svc = HiDriveSyncService(client: client, cryptoStorage: cryptoStorage, basePath: base);
  svc.initialize();
  return svc;
});

final employeesProvider = StateNotifierProvider<EmployeesNotifier, AsyncValue<List<Employee>>>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  final syncService = ref.watch(hiDriveSyncServiceProvider);
  final settings = ref.watch(appSettingsProvider);

  return EmployeesNotifier(localStorage, syncService, settings);
});

class EmployeesNotifier extends StateNotifier<AsyncValue<List<Employee>>> {
  final LocalStorageService _localStorage;
  final HiDriveSyncService? _syncService;
  final AppSettings _settings;

  EmployeesNotifier(this._localStorage, this._syncService, this._settings)
      : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _localStorage.initialize();
      await _loadEmployees();

      // Auto-sync on startup if enabled
      if (_settings.autoSyncOnStartup && _syncService != null) {
        await _syncFromCloud();
      }

      if (kDebugMode) {
        print('✅ Employee provider initialized');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Employee provider initialization failed: $e');
      }
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _localStorage.loadEmployees();
      state = AsyncValue.data(employees);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addEmployee(Employee employee) async {
    try {
      state = const AsyncValue.loading();

      // Generate ID if not provided
      final employeeWithId = employee.id.isEmpty
          ? employee.copyWith(id: _localStorage.generateId())
          : employee;

      final savedEmployee = await _localStorage.saveEmployee(employeeWithId);

      if (savedEmployee != null) {
        // Sync to cloud if enabled
        if (_settings.autoSyncOnChanges && _syncService != null) {
          await _syncService!.saveRecord('employee', savedEmployee.toJson());
        }

        await _loadEmployees();

        if (kDebugMode) {
          print('✅ Employee added: ${savedEmployee.fullName}');
        }
      } else {
        throw Exception('Failed to save employee');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to add employee: $e');
      }
    }
  }

  Future<void> updateEmployee(Employee employee) async {
    try {
      state = const AsyncValue.loading();

      final updatedEmployee = await _localStorage.saveEmployee(employee);

      if (updatedEmployee != null) {
        // Sync to cloud if enabled
        if (_settings.autoSyncOnChanges && _syncService != null) {
          await _syncService!.saveRecord('employee', updatedEmployee.toJson());
        }

        await _loadEmployees();

        if (kDebugMode) {
          print('✅ Employee updated: ${updatedEmployee.fullName}');
        }
      } else {
        throw Exception('Failed to update employee');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to update employee: $e');
      }
    }
  }

  Future<void> deleteEmployee(String employeeId) async {
    try {
      state = const AsyncValue.loading();

      final success = await _localStorage.deleteEmployee(employeeId);

      if (success) {
        // Remove from cloud if enabled
        if (_settings.autoSyncOnChanges && _syncService != null) {
          final records = await _syncService!.getRecordsByCategory('employee');
          for (final recordId in records) {
            final record = await _syncService!.loadRecord(recordId);
            if (record != null && record['id'] == employeeId) {
              await _syncService!.deleteRecord(recordId);
              break;
            }
          }
        }

        await _loadEmployees();

        if (kDebugMode) {
          print('✅ Employee deleted: $employeeId');
        }
      } else {
        throw Exception('Failed to delete employee');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to delete employee: $e');
      }
    }
  }

  Future<void> _syncFromCloud() async {
    if (_syncService == null) return;

    try {
      await _syncService!.syncFromRemote();

      // Load any new employees from cloud
      final employeeRecordIds = await _syncService!.getRecordsByCategory('employee');
      final currentEmployees = await _localStorage.loadEmployees();

      for (final recordId in employeeRecordIds) {
        final record = await _syncService!.loadRecord(recordId);
        if (record != null) {
          final cloudEmployee = Employee.fromJson(record);

          // Check if employee already exists locally
          final existsLocally = currentEmployees.any((e) => e.id == cloudEmployee.id);

          if (!existsLocally) {
            await _localStorage.saveEmployee(cloudEmployee);
            if (kDebugMode) {
              print('⬇️ Synced employee from cloud: ${cloudEmployee.fullName}');
            }
          }
        }
      }

      await _loadEmployees();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to sync from cloud: $e');
      }
    }
  }

  // Öffentliche Methode für Admin-Sync Button
  Future<void> syncFromCloud() => _syncFromCloud();

  Future<void> syncToCloud() async {
    if (_syncService == null) return;

    try {
      state = const AsyncValue.loading();

      final employees = await _localStorage.loadEmployees();

      for (final employee in employees) {
        await _syncService!.saveRecord('employee', employee.toJson());
      }

      await _loadEmployees();

      if (kDebugMode) {
        print('✅ Synced ${employees.length} employees to cloud');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to sync to cloud: $e');
      }
    }
  }

  Future<void> refresh() async {
    await _loadEmployees();
  }
}

// Convenience providers
final activeEmployeesProvider = Provider<AsyncValue<List<Employee>>>((ref) {
  final employees = ref.watch(employeesProvider);
  return employees.when(
    data: (employees) => AsyncValue.data(
      employees.where((e) => e.status == EmployeeStatus.active).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final employeeByIdProvider = Provider.family<Employee?, String>((ref, employeeId) {
  final employees = ref.watch(employeesProvider);
  return employees.when(
    data: (employees) {
      try {
        return employees.firstWhere((e) => e.id == employeeId);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (error, stack) => null,
  );
});

final employeeCountProvider = Provider<int>((ref) {
  final employees = ref.watch(employeesProvider);
  return employees.when(
    data: (employees) => employees.length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

final activeEmployeeCountProvider = Provider<int>((ref) {
  final activeEmployees = ref.watch(activeEmployeesProvider);
  return activeEmployees.when(
    data: (employees) => employees.length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
});
