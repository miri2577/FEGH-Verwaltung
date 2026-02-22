import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timesheet.dart';
import '../services/timesheet_service.dart';

// Service Provider
final timesheetServiceProvider = Provider<TimesheetService>((ref) {
  return TimesheetService();
});

// Timesheet Notifier
class TimesheetsNotifier extends StateNotifier<AsyncValue<List<Timesheet>>> {
  final TimesheetService _service;

  TimesheetsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadTimesheets();
  }

  Future<void> loadTimesheets() async {
    state = const AsyncValue.loading();
    try {
      final timesheets = await _service.getAllTimesheets();
      state = AsyncValue.data(timesheets);
      print('✅ Timesheets loaded: ${timesheets.length}');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      print('❌ Error loading timesheets: $error');
    }
  }

  Future<void> refresh() async {
    await loadTimesheets();
  }

  Future<void> addTimesheet(Timesheet timesheet) async {
    final success = await _service.saveTimesheet(timesheet);
    if (success) {
      await loadTimesheets();
      print('✅ Timesheet added: ${timesheet.id}');
    } else {
      print('❌ Failed to add timesheet');
      throw Exception('Failed to add timesheet');
    }
  }

  Future<void> updateTimesheet(Timesheet timesheet) async {
    final success = await _service.saveTimesheet(timesheet);
    if (success) {
      await loadTimesheets();
      print('✅ Timesheet updated: ${timesheet.id}');
    } else {
      print('❌ Failed to update timesheet');
      throw Exception('Failed to update timesheet');
    }
  }

  Future<void> deleteTimesheet(String timesheetId) async {
    final success = await _service.deleteTimesheet(timesheetId);
    if (success) {
      await loadTimesheets();
      print('✅ Timesheet deleted: $timesheetId');
    } else {
      print('❌ Failed to delete timesheet');
      throw Exception('Failed to delete timesheet');
    }
  }

  Future<void> submitTimesheet(String timesheetId, String submittedBy) async {
    final success = await _service.submitTimesheet(timesheetId, submittedBy);
    if (success) {
      await loadTimesheets();
      print('✅ Timesheet submitted: $timesheetId');
    } else {
      print('❌ Failed to submit timesheet');
      throw Exception('Failed to submit timesheet');
    }
  }

  Future<void> approveTimesheet(String timesheetId, String approvedBy) async {
    final success = await _service.approveTimesheet(timesheetId, approvedBy);
    if (success) {
      await loadTimesheets();
      print('✅ Timesheet approved: $timesheetId');
    } else {
      print('❌ Failed to approve timesheet');
      throw Exception('Failed to approve timesheet');
    }
  }

  Future<void> rejectTimesheet(String timesheetId, String rejectionReason) async {
    final success = await _service.rejectTimesheet(timesheetId, rejectionReason);
    if (success) {
      await loadTimesheets();
      print('✅ Timesheet rejected: $timesheetId');
    } else {
      print('❌ Failed to reject timesheet');
      throw Exception('Failed to reject timesheet');
    }
  }

  Future<void> finalizeTimesheet(String timesheetId) async {
    final success = await _service.finalizeTimesheet(timesheetId);
    if (success) {
      await loadTimesheets();
      print('✅ Timesheet finalized: $timesheetId');
    } else {
      print('❌ Failed to finalize timesheet');
      throw Exception('Failed to finalize timesheet');
    }
  }
}

// Timesheet Entry Notifier
class TimesheetEntriesNotifier extends StateNotifier<AsyncValue<List<TimesheetEntry>>> {
  final TimesheetService _service;

  TimesheetEntriesNotifier(this._service) : super(const AsyncValue.loading()) {
    loadEntries();
  }

  Future<void> loadEntries() async {
    state = const AsyncValue.loading();
    try {
      final entries = await _service.getAllTimesheetEntries();
      state = AsyncValue.data(entries);
      print('✅ Timesheet entries loaded: ${entries.length}');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      print('❌ Error loading timesheet entries: $error');
    }
  }

  Future<void> addEntry(TimesheetEntry entry) async {
    final success = await _service.saveTimesheetEntry(entry);
    if (success) {
      await loadEntries();
      print('✅ Timesheet entry added: ${entry.id}');
    } else {
      print('❌ Failed to add timesheet entry');
      throw Exception('Failed to add timesheet entry');
    }
  }

  Future<void> updateEntry(TimesheetEntry entry) async {
    final success = await _service.saveTimesheetEntry(entry);
    if (success) {
      await loadEntries();
      print('✅ Timesheet entry updated: ${entry.id}');
    } else {
      print('❌ Failed to update timesheet entry');
      throw Exception('Failed to update timesheet entry');
    }
  }

  Future<void> deleteEntry(String entryId) async {
    final success = await _service.deleteTimesheetEntry(entryId);
    if (success) {
      await loadEntries();
      print('✅ Timesheet entry deleted: $entryId');
    } else {
      print('❌ Failed to delete timesheet entry');
      throw Exception('Failed to delete timesheet entry');
    }
  }
}

// Main Providers
final timesheetsProvider = StateNotifierProvider<TimesheetsNotifier, AsyncValue<List<Timesheet>>>((ref) {
  final service = ref.watch(timesheetServiceProvider);
  return TimesheetsNotifier(service);
});

final timesheetEntriesProvider = StateNotifierProvider<TimesheetEntriesNotifier, AsyncValue<List<TimesheetEntry>>>((ref) {
  final service = ref.watch(timesheetServiceProvider);
  return TimesheetEntriesNotifier(service);
});

// Filtered Providers
final timesheetsByEmployeeProvider = Provider.family<AsyncValue<List<Timesheet>>, String>((ref, employeeId) {
  final timesheetsAsync = ref.watch(timesheetsProvider);
  return timesheetsAsync.when(
    data: (timesheets) => AsyncValue.data(
      timesheets.where((t) => t.employeeId == employeeId).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

final timesheetsByStatusProvider = Provider.family<AsyncValue<List<Timesheet>>, TimesheetStatus>((ref, status) {
  final timesheetsAsync = ref.watch(timesheetsProvider);
  return timesheetsAsync.when(
    data: (timesheets) => AsyncValue.data(
      timesheets.where((t) => t.status == status).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

final entriesByTimesheetProvider = Provider.family<AsyncValue<List<TimesheetEntry>>, String>((ref, timesheetId) {
  final entriesAsync = ref.watch(timesheetEntriesProvider);
  return entriesAsync.when(
    data: (entries) => AsyncValue.data(
      entries.where((e) => e.timesheetId == timesheetId).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Count Providers
final timesheetCountProvider = Provider<int>((ref) {
  final timesheetsAsync = ref.watch(timesheetsProvider);
  return timesheetsAsync.when(
    data: (timesheets) => timesheets.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final pendingTimesheetsCountProvider = Provider<int>((ref) {
  final timesheetsAsync = ref.watch(timesheetsProvider);
  return timesheetsAsync.when(
    data: (timesheets) => timesheets.where((t) => t.status == TimesheetStatus.submitted).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final draftTimesheetsCountProvider = Provider<int>((ref) {
  final timesheetsAsync = ref.watch(timesheetsProvider);
  return timesheetsAsync.when(
    data: (timesheets) => timesheets.where((t) => t.status == TimesheetStatus.draft).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final currentWeekTimesheetsProvider = Provider<AsyncValue<List<Timesheet>>>((ref) {
  final timesheetsAsync = ref.watch(timesheetsProvider);
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  return timesheetsAsync.when(
    data: (timesheets) => AsyncValue.data(
      timesheets.where((t) {
        return t.startDate.isBefore(endOfWeek) && t.endDate.isAfter(startOfWeek);
      }).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Analytics Providers
final timesheetAnalyticsProvider = Provider.family<AsyncValue<Map<String, double>>, String>((ref, timesheetId) {
  return ref.watch(timesheetServiceProvider).getTimesheetSummary(timesheetId).then(
    (summary) => AsyncValue.data(summary),
  ) as AsyncValue<Map<String, double>>;
});

// Individual timesheet provider
final timesheetByIdProvider = Provider.family<AsyncValue<Timesheet?>, String>((ref, timesheetId) {
  final timesheetsAsync = ref.watch(timesheetsProvider);
  return timesheetsAsync.when(
    data: (timesheets) {
      try {
        final timesheet = timesheets.firstWhere((t) => t.id == timesheetId);
        return AsyncValue.data(timesheet);
      } catch (e) {
        return const AsyncValue.data(null);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Combined Provider for Dashboard
final timesheetDashboardProvider = Provider<Map<String, dynamic>>((ref) {
  final timesheetsAsync = ref.watch(timesheetsProvider);

  return timesheetsAsync.when(
    data: (timesheets) {
      final draft = timesheets.where((t) => t.status == TimesheetStatus.draft).length;
      final submitted = timesheets.where((t) => t.status == TimesheetStatus.submitted).length;
      final approved = timesheets.where((t) => t.status == TimesheetStatus.approved).length;
      final rejected = timesheets.where((t) => t.status == TimesheetStatus.rejected).length;
      final finalized = timesheets.where((t) => t.status == TimesheetStatus.finalized).length;

      final totalHours = timesheets.fold(0.0, (sum, t) => sum + t.calculatedTotalHours);
      final totalPay = timesheets.fold(0.0, (sum, t) => sum + t.calculatedTotalPay);

      return {
        'total': timesheets.length,
        'draft': draft,
        'submitted': submitted,
        'approved': approved,
        'rejected': rejected,
        'finalized': finalized,
        'totalHours': totalHours,
        'totalPay': totalPay,
      };
    },
    loading: () => <String, dynamic>{},
    error: (_, __) => <String, dynamic>{},
  );
});