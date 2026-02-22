import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/vacation_request.dart';
import '../models/app_settings.dart';
import '../services/local_storage_service.dart';
import '../services/hidrive_sync_service.dart';
import '../services/crypto_storage.dart';
import 'settings_provider.dart';
import 'employee_provider.dart';

final vacationRequestsProvider = StateNotifierProvider<VacationRequestsNotifier, AsyncValue<List<VacationRequest>>>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  final syncService = ref.watch(hiDriveSyncServiceProvider);
  final settings = ref.watch(appSettingsProvider);

  return VacationRequestsNotifier(localStorage, syncService, settings);
});

class VacationRequestsNotifier extends StateNotifier<AsyncValue<List<VacationRequest>>> {
  final LocalStorageService _localStorage;
  final HiDriveSyncService? _syncService;
  final AppSettings _settings;

  VacationRequestsNotifier(this._localStorage, this._syncService, this._settings)
      : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _loadVacationRequests();

      // Auto-sync on startup if enabled
      if (_settings.autoSyncOnStartup && _syncService != null) {
        await _syncFromCloud();
      }

      if (kDebugMode) {
        print('✅ Vacation provider initialized');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Vacation provider initialization failed: $e');
      }
    }
  }

  Future<void> _loadVacationRequests() async {
    try {
      final vacationRequests = await _localStorage.loadVacationRequests();
      state = AsyncValue.data(vacationRequests);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addVacationRequest(VacationRequest request) async {
    try {
      state = const AsyncValue.loading();

      final requestWithId = request.id.isEmpty
          ? request.copyWith(id: _localStorage.generateId())
          : request;

      final savedRequest = await _localStorage.saveVacationRequest(requestWithId);

      if (savedRequest != null) {
        // Sync to cloud if enabled
        if (_settings.autoSyncOnChanges && _syncService != null) {
          await _syncService!.saveRecord('vacation_request', savedRequest.toJson());
        }

        await _loadVacationRequests();

        if (kDebugMode) {
          print('✅ Vacation request added: ${savedRequest.id}');
        }
      } else {
        throw Exception('Failed to save vacation request');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to add vacation request: $e');
      }
    }
  }

  Future<void> updateVacationRequest(VacationRequest request) async {
    try {
      state = const AsyncValue.loading();

      final updatedRequest = await _localStorage.saveVacationRequest(request);

      if (updatedRequest != null) {
        // Sync to cloud if enabled
        if (_settings.autoSyncOnChanges && _syncService != null) {
          await _syncService!.saveRecord('vacation_request', updatedRequest.toJson());
        }

        await _loadVacationRequests();

        if (kDebugMode) {
          print('✅ Vacation request updated: ${updatedRequest.id}');
        }
      } else {
        throw Exception('Failed to update vacation request');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to update vacation request: $e');
      }
    }
  }

  Future<void> deleteVacationRequest(String requestId) async {
    try {
      state = const AsyncValue.loading();

      final success = await _localStorage.deleteVacationRequest(requestId);

      if (success) {
        // Remove from cloud if enabled
        if (_settings.autoSyncOnChanges && _syncService != null) {
          final records = await _syncService!.getRecordsByCategory('vacation_request');
          for (final recordId in records) {
            final record = await _syncService!.loadRecord(recordId);
            if (record != null && record['id'] == requestId) {
              await _syncService!.deleteRecord(recordId);
              break;
            }
          }
        }

        await _loadVacationRequests();

        if (kDebugMode) {
          print('✅ Vacation request deleted: $requestId');
        }
      } else {
        throw Exception('Failed to delete vacation request');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to delete vacation request: $e');
      }
    }
  }

  Future<void> approveVacationRequest(String requestId, String approvedById) async {
    try {
      final requests = await _localStorage.loadVacationRequests();
      final requestIndex = requests.indexWhere((r) => r.id == requestId);

      if (requestIndex >= 0) {
        final approvedRequest = requests[requestIndex].approve(approvedById);
        await updateVacationRequest(approvedRequest);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to approve vacation request: $e');
      }
    }
  }

  Future<void> rejectVacationRequest(String requestId, String rejectionReason) async {
    try {
      final requests = await _localStorage.loadVacationRequests();
      final requestIndex = requests.indexWhere((r) => r.id == requestId);

      if (requestIndex >= 0) {
        final rejectedRequest = requests[requestIndex].reject(rejectionReason);
        await updateVacationRequest(rejectedRequest);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to reject vacation request: $e');
      }
    }
  }

  Future<void> cancelVacationRequest(String requestId) async {
    try {
      final requests = await _localStorage.loadVacationRequests();
      final requestIndex = requests.indexWhere((r) => r.id == requestId);

      if (requestIndex >= 0) {
        final cancelledRequest = requests[requestIndex].cancel();
        await updateVacationRequest(cancelledRequest);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to cancel vacation request: $e');
      }
    }
  }

  Future<void> _syncFromCloud() async {
    if (_syncService == null) return;

    try {
      await _syncService!.syncFromRemote();

      // Load any new vacation requests from cloud
      final requestRecordIds = await _syncService!.getRecordsByCategory('vacation_request');
      final currentRequests = await _localStorage.loadVacationRequests();

      for (final recordId in requestRecordIds) {
        final record = await _syncService!.loadRecord(recordId);
        if (record != null) {
          final cloudRequest = VacationRequest.fromJson(record);

          // Check if request already exists locally
          final existsLocally = currentRequests.any((r) => r.id == cloudRequest.id);

          if (!existsLocally) {
            await _localStorage.saveVacationRequest(cloudRequest);
            if (kDebugMode) {
              print('⬇️ Synced vacation request from cloud: ${cloudRequest.id}');
            }
          }
        }
      }

      await _loadVacationRequests();
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

      final requests = await _localStorage.loadVacationRequests();

      for (final request in requests) {
        await _syncService!.saveRecord('vacation_request', request.toJson());
      }

      await _loadVacationRequests();

      if (kDebugMode) {
        print('✅ Synced ${requests.length} vacation requests to cloud');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to sync to cloud: $e');
      }
    }
  }

  Future<void> refresh() async {
    await _loadVacationRequests();
  }
}

// Convenience providers
final pendingVacationRequestsProvider = Provider<AsyncValue<List<VacationRequest>>>((ref) {
  final requests = ref.watch(vacationRequestsProvider);
  return requests.when(
    data: (requests) => AsyncValue.data(
      requests.where((r) => r.isPending).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final approvedVacationRequestsProvider = Provider<AsyncValue<List<VacationRequest>>>((ref) {
  final requests = ref.watch(vacationRequestsProvider);
  return requests.when(
    data: (requests) => AsyncValue.data(
      requests.where((r) => r.isApproved).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final activeVacationRequestsProvider = Provider<AsyncValue<List<VacationRequest>>>((ref) {
  final requests = ref.watch(vacationRequestsProvider);
  return requests.when(
    data: (requests) => AsyncValue.data(
      requests.where((r) => r.isActive).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final upcomingVacationRequestsProvider = Provider<AsyncValue<List<VacationRequest>>>((ref) {
  final requests = ref.watch(vacationRequestsProvider);
  return requests.when(
    data: (requests) => AsyncValue.data(
      requests.where((r) => r.isUpcoming).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final vacationRequestsByEmployeeProvider = Provider.family<AsyncValue<List<VacationRequest>>, String>((ref, employeeId) {
  final requests = ref.watch(vacationRequestsProvider);
  return requests.when(
    data: (requests) => AsyncValue.data(
      requests.where((r) => r.employeeId == employeeId).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final vacationRequestCountProvider = Provider<int>((ref) {
  final requests = ref.watch(vacationRequestsProvider);
  return requests.when(
    data: (requests) => requests.length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

final pendingApprovalCountProvider = Provider<int>((ref) {
  final pendingRequests = ref.watch(pendingVacationRequestsProvider);
  return pendingRequests.when(
    data: (requests) => requests.length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

final vacationRequestsByDateRangeProvider = Provider.family<AsyncValue<List<VacationRequest>>, ({DateTime start, DateTime end})>((ref, dateRange) {
  final requests = ref.watch(vacationRequestsProvider);
  return requests.when(
    data: (requests) {
      return AsyncValue.data(
        requests.where((r) {
          return r.isApproved &&
                 r.startDate.isBefore(dateRange.end.add(const Duration(days: 1))) &&
                 r.endDate.isAfter(dateRange.start.subtract(const Duration(days: 1)));
        }).toList(),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final employeeVacationDaysUsedProvider = Provider.family<int, String>((ref, employeeId) {
  final requests = ref.watch(vacationRequestsByEmployeeProvider(employeeId));
  return requests.when(
    data: (requests) {
      final currentYear = DateTime.now().year;
      return requests
          .where((r) => r.isApproved &&
                       r.type == VacationType.annual &&
                       r.startDate.year == currentYear)
          .fold<int>(0, (sum, request) => sum + request.workingDays);
    },
    loading: () => 0,
    error: (error, stack) => 0,
  );
});