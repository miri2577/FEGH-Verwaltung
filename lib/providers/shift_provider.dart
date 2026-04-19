import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/shift.dart';
import '../models/app_settings.dart';
import '../services/local_storage_service.dart';
import '../services/hidrive_sync_service.dart';
import '../services/crypto_storage.dart';
import '../services/shift_conflict_checker.dart';
import 'settings_provider.dart';
import 'employee_provider.dart';

final shiftsProvider = StateNotifierProvider<ShiftsNotifier, AsyncValue<List<Shift>>>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  final syncService = ref.watch(hiDriveSyncServiceProvider);
  final settings = ref.watch(appSettingsProvider);

  return ShiftsNotifier(localStorage, syncService, settings);
});

class ShiftsNotifier extends StateNotifier<AsyncValue<List<Shift>>> {
  final LocalStorageService _localStorage;
  final HiDriveSyncService? _syncService;
  final AppSettings _settings;

  ShiftsNotifier(this._localStorage, this._syncService, this._settings)
      : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _loadShifts();

      // Auto-sync on startup if enabled
      if (_settings.autoSyncOnStartup && _syncService != null) {
        await _syncFromCloud();
      }

      if (kDebugMode) {
        print('✅ Shift provider initialized');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Shift provider initialization failed: $e');
      }
    }
  }

  Future<void> _loadShifts() async {
    try {
      final shifts = await _localStorage.loadShifts();
      state = AsyncValue.data(shifts);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addShift(Shift shift) async {
    try {
      state = const AsyncValue.loading();

      final shiftWithId = shift.id.isEmpty
          ? shift.copyWith(id: _localStorage.generateId())
          : shift;

      final savedShift = await _localStorage.saveShift(shiftWithId);

      if (savedShift != null) {
        // Sync to cloud if enabled
        if (_settings.autoSyncOnChanges && _syncService != null) {
          await _syncService!.saveRecord('shift', savedShift.toJson());
        }

        await _loadShifts();

        if (kDebugMode) {
          print('✅ Shift added: ${savedShift.id}');
        }
      } else {
        throw Exception('Failed to save shift');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to add shift: $e');
      }
    }
  }

  Future<void> updateShift(Shift shift) async {
    try {
      state = const AsyncValue.loading();

      final updatedShift = await _localStorage.saveShift(shift);

      if (updatedShift != null) {
        // Sync to cloud if enabled
        if (_settings.autoSyncOnChanges && _syncService != null) {
          await _syncService!.saveRecord('shift', updatedShift.toJson());
        }

        await _loadShifts();

        if (kDebugMode) {
          print('✅ Shift updated: ${updatedShift.id}');
        }
      } else {
        throw Exception('Failed to update shift');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to update shift: $e');
      }
    }
  }

  Future<void> deleteShift(String shiftId) async {
    try {
      state = const AsyncValue.loading();

      final success = await _localStorage.deleteShift(shiftId);

      if (success) {
        // Remove from cloud if enabled
        if (_settings.autoSyncOnChanges && _syncService != null) {
          final records = await _syncService!.getRecordsByCategory('shift');
          for (final recordId in records) {
            final record = await _syncService!.loadRecord(recordId);
            if (record != null && record['id'] == shiftId) {
              await _syncService!.deleteRecord(recordId);
              break;
            }
          }
        }

        await _loadShifts();

        if (kDebugMode) {
          print('✅ Shift deleted: $shiftId');
        }
      } else {
        throw Exception('Failed to delete shift');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to delete shift: $e');
      }
    }
  }

  Future<void> startShift(String shiftId) async {
    try {
      final shifts = await _localStorage.loadShifts();
      final shiftIndex = shifts.indexWhere((s) => s.id == shiftId);

      if (shiftIndex >= 0) {
        final updatedShift = shifts[shiftIndex].startShift();
        await updateShift(updatedShift);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to start shift: $e');
      }
    }
  }

  Future<void> endShift(String shiftId) async {
    try {
      final shifts = await _localStorage.loadShifts();
      final shiftIndex = shifts.indexWhere((s) => s.id == shiftId);

      if (shiftIndex >= 0) {
        final updatedShift = shifts[shiftIndex].endShift();
        await updateShift(updatedShift);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to end shift: $e');
      }
    }
  }

  Future<void> cancelShift(String shiftId) async {
    try {
      final shifts = await _localStorage.loadShifts();
      final shiftIndex = shifts.indexWhere((s) => s.id == shiftId);

      if (shiftIndex >= 0) {
        final updatedShift = shifts[shiftIndex].cancelShift();
        await updateShift(updatedShift);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to cancel shift: $e');
      }
    }
  }

  Future<void> _syncFromCloud() async {
    if (_syncService == null) return;

    try {
      await _syncService!.syncFromRemote();

      // Load any new shifts from cloud
      final shiftRecordIds = await _syncService!.getRecordsByCategory('shift');
      final currentShifts = await _localStorage.loadShifts();

      for (final recordId in shiftRecordIds) {
        final record = await _syncService!.loadRecord(recordId);
        if (record != null) {
          final cloudShift = Shift.fromJson(record);

          // Check if shift already exists locally
          final existsLocally = currentShifts.any((s) => s.id == cloudShift.id);

          if (!existsLocally) {
            await _localStorage.saveShift(cloudShift);
            if (kDebugMode) {
              print('⬇️ Synced shift from cloud: ${cloudShift.id}');
            }
          }
        }
      }

      await _loadShifts();
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

      final shifts = await _localStorage.loadShifts();

      for (final shift in shifts) {
        await _syncService!.saveRecord('shift', shift.toJson());
      }

      await _loadShifts();

      if (kDebugMode) {
        print('✅ Synced ${shifts.length} shifts to cloud');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) {
        print('❌ Failed to sync to cloud: $e');
      }
    }
  }

  Future<void> refresh() async {
    await _loadShifts();
  }

  /// Prueft eine geplante Schicht gegen den aktuellen State.
  /// Kann synchron aus UI-Code aufgerufen werden.
  List<ShiftConflict> validateShift(Shift shift) {
    final list = state.asData?.value ?? const <Shift>[];
    return ShiftConflictChecker.check(shift, list);
  }
}

// Convenience providers
final todaysShiftsProvider = Provider<AsyncValue<List<Shift>>>((ref) {
  final shifts = ref.watch(shiftsProvider);
  return shifts.when(
    data: (shifts) => AsyncValue.data(
      shifts.where((s) => s.isToday).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final upcomingShiftsProvider = Provider<AsyncValue<List<Shift>>>((ref) {
  final shifts = ref.watch(shiftsProvider);
  return shifts.when(
    data: (shifts) => AsyncValue.data(
      shifts.where((s) => s.isUpcoming).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final activeShiftsProvider = Provider<AsyncValue<List<Shift>>>((ref) {
  final shifts = ref.watch(shiftsProvider);
  return shifts.when(
    data: (shifts) => AsyncValue.data(
      shifts.where((s) => s.isInProgress).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final overdueShiftsProvider = Provider<AsyncValue<List<Shift>>>((ref) {
  final shifts = ref.watch(shiftsProvider);
  return shifts.when(
    data: (shifts) => AsyncValue.data(
      shifts.where((s) => s.isOverdue).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final shiftsByEmployeeProvider = Provider.family<AsyncValue<List<Shift>>, String>((ref, employeeId) {
  final shifts = ref.watch(shiftsProvider);
  return shifts.when(
    data: (shifts) => AsyncValue.data(
      shifts.where((s) => s.employeeId == employeeId).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final shiftsByTeamProvider = Provider.family<AsyncValue<List<Shift>>, String>((ref, teamId) {
  final shifts = ref.watch(shiftsProvider);
  return shifts.when(
    data: (shifts) => AsyncValue.data(
      shifts.where((s) => s.teamId == teamId).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final shiftCountProvider = Provider<int>((ref) {
  final shifts = ref.watch(shiftsProvider);
  return shifts.when(
    data: (shifts) => shifts.length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

final shiftsByDateProvider = Provider.family<AsyncValue<List<Shift>>, DateTime>((ref, date) {
  final shifts = ref.watch(shiftsProvider);
  return shifts.when(
    data: (shifts) {
      final targetDate = DateTime(date.year, date.month, date.day);
      return AsyncValue.data(
        shifts.where((s) {
          final shiftDate = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
          return shiftDate == targetDate;
        }).toList(),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});