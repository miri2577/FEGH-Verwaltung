import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/timesheet.dart';

class TimesheetService {
  static const String _timesheetsKey = 'timesheets';
  static const String _timesheetEntriesKey = 'timesheet_entries';
  final FlutterSecureStorage _storage;

  TimesheetService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // Timesheet CRUD Operations
  Future<List<Timesheet>> getAllTimesheets() async {
    try {
      final timesheetsJson = await _storage.read(key: _timesheetsKey);
      if (timesheetsJson == null || timesheetsJson.isEmpty) {
        print('📝 No timesheets found in storage');
        return [];
      }

      final List<dynamic> timesheetsList = json.decode(timesheetsJson);
      final timesheets = timesheetsList.map((json) => Timesheet.fromJson(json)).toList();

      print('📝 Loaded ${timesheets.length} timesheets');
      return timesheets;
    } catch (e) {
      print('❌ Error loading timesheets: $e');
      return [];
    }
  }

  Future<List<TimesheetEntry>> getAllTimesheetEntries() async {
    try {
      final entriesJson = await _storage.read(key: _timesheetEntriesKey);
      if (entriesJson == null || entriesJson.isEmpty) {
        print('📝 No timesheet entries found in storage');
        return [];
      }

      final List<dynamic> entriesList = json.decode(entriesJson);
      final entries = entriesList.map((json) => TimesheetEntry.fromJson(json)).toList();

      print('📝 Loaded ${entries.length} timesheet entries');
      return entries;
    } catch (e) {
      print('❌ Error loading timesheet entries: $e');
      return [];
    }
  }

  Future<List<Timesheet>> getTimesheetsByEmployee(String employeeId) async {
    final allTimesheets = await getAllTimesheets();
    return allTimesheets.where((t) => t.employeeId == employeeId).toList();
  }

  Future<List<Timesheet>> getTimesheetsByStatus(TimesheetStatus status) async {
    final allTimesheets = await getAllTimesheets();
    return allTimesheets.where((t) => t.status == status).toList();
  }

  Future<List<Timesheet>> getTimesheetsByDateRange(DateTime start, DateTime end) async {
    final allTimesheets = await getAllTimesheets();
    return allTimesheets.where((t) {
      return t.startDate.isBefore(end) && t.endDate.isAfter(start);
    }).toList();
  }

  Future<Timesheet?> getTimesheetById(String id) async {
    final allTimesheets = await getAllTimesheets();
    try {
      return allTimesheets.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveTimesheet(Timesheet timesheet) async {
    try {
      final allTimesheets = await getAllTimesheets();
      final index = allTimesheets.indexWhere((t) => t.id == timesheet.id);

      if (index >= 0) {
        allTimesheets[index] = timesheet;
      } else {
        allTimesheets.add(timesheet);
      }

      final timesheetsJson = json.encode(allTimesheets.map((t) => t.toJson()).toList());
      await _storage.write(key: _timesheetsKey, value: timesheetsJson);

      print('✅ Timesheet saved: ${timesheet.id}');
      return true;
    } catch (e) {
      print('❌ Error saving timesheet: $e');
      return false;
    }
  }

  Future<bool> deleteTimesheet(String id) async {
    try {
      final allTimesheets = await getAllTimesheets();
      allTimesheets.removeWhere((t) => t.id == id);

      // Also delete associated entries
      final allEntries = await getAllTimesheetEntries();
      allEntries.removeWhere((e) => e.timesheetId == id);

      final timesheetsJson = json.encode(allTimesheets.map((t) => t.toJson()).toList());
      await _storage.write(key: _timesheetsKey, value: timesheetsJson);

      final entriesJson = json.encode(allEntries.map((e) => e.toJson()).toList());
      await _storage.write(key: _timesheetEntriesKey, value: entriesJson);

      print('✅ Timesheet deleted: $id');
      return true;
    } catch (e) {
      print('❌ Error deleting timesheet: $e');
      return false;
    }
  }

  // Timesheet Entry Operations
  Future<List<TimesheetEntry>> getEntriesByTimesheet(String timesheetId) async {
    final allEntries = await getAllTimesheetEntries();
    return allEntries.where((e) => e.timesheetId == timesheetId).toList();
  }

  Future<bool> saveTimesheetEntry(TimesheetEntry entry) async {
    try {
      final allEntries = await getAllTimesheetEntries();
      final index = allEntries.indexWhere((e) => e.id == entry.id);

      if (index >= 0) {
        allEntries[index] = entry;
      } else {
        allEntries.add(entry);
      }

      final entriesJson = json.encode(allEntries.map((e) => e.toJson()).toList());
      await _storage.write(key: _timesheetEntriesKey, value: entriesJson);

      print('✅ Timesheet entry saved: ${entry.id}');
      return true;
    } catch (e) {
      print('❌ Error saving timesheet entry: $e');
      return false;
    }
  }

  Future<bool> deleteTimesheetEntry(String entryId) async {
    try {
      final allEntries = await getAllTimesheetEntries();
      allEntries.removeWhere((e) => e.id == entryId);

      final entriesJson = json.encode(allEntries.map((e) => e.toJson()).toList());
      await _storage.write(key: _timesheetEntriesKey, value: entriesJson);

      print('✅ Timesheet entry deleted: $entryId');
      return true;
    } catch (e) {
      print('❌ Error deleting timesheet entry: $e');
      return false;
    }
  }

  // Status Operations
  Future<bool> submitTimesheet(String timesheetId, String submittedBy) async {
    final timesheet = await getTimesheetById(timesheetId);
    if (timesheet == null) return false;

    final updatedTimesheet = timesheet.copyWith(
      status: TimesheetStatus.submitted,
      submittedBy: submittedBy,
      submittedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await saveTimesheet(updatedTimesheet);
  }

  Future<bool> approveTimesheet(String timesheetId, String approvedBy) async {
    final timesheet = await getTimesheetById(timesheetId);
    if (timesheet == null) return false;

    final updatedTimesheet = timesheet.copyWith(
      status: TimesheetStatus.approved,
      approvedBy: approvedBy,
      approvedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await saveTimesheet(updatedTimesheet);
  }

  Future<bool> rejectTimesheet(String timesheetId, String rejectionReason) async {
    final timesheet = await getTimesheetById(timesheetId);
    if (timesheet == null) return false;

    final updatedTimesheet = timesheet.copyWith(
      status: TimesheetStatus.rejected,
      rejectionReason: rejectionReason,
      updatedAt: DateTime.now(),
    );

    return await saveTimesheet(updatedTimesheet);
  }

  Future<bool> finalizeTimesheet(String timesheetId) async {
    final timesheet = await getTimesheetById(timesheetId);
    if (timesheet == null) return false;

    final updatedTimesheet = timesheet.copyWith(
      status: TimesheetStatus.finalized,
      updatedAt: DateTime.now(),
    );

    return await saveTimesheet(updatedTimesheet);
  }

  // Analytics
  Future<Map<String, double>> getTimesheetSummary(String timesheetId) async {
    final entries = await getEntriesByTimesheet(timesheetId);

    double totalHours = 0.0;
    double regularHours = 0.0;
    double overtimeHours = 0.0;
    double totalPay = 0.0;

    for (final entry in entries) {
      totalHours += entry.totalHours;
      totalPay += entry.calculatedPay;

      if (entry.type == TimesheetEntryType.regular) {
        regularHours += entry.totalHours;
      } else if (entry.type == TimesheetEntryType.overtime) {
        overtimeHours += entry.totalHours;
      }
    }

    return {
      'totalHours': totalHours,
      'regularHours': regularHours,
      'overtimeHours': overtimeHours,
      'totalPay': totalPay,
    };
  }

  Future<Map<String, double>> getEmployeeTimesheetSummary(String employeeId, DateTime startDate, DateTime endDate) async {
    final timesheets = await getTimesheetsByEmployee(employeeId);
    final relevantTimesheets = timesheets.where((t) {
      return t.startDate.isBefore(endDate) && t.endDate.isAfter(startDate);
    }).toList();

    double totalHours = 0.0;
    double totalPay = 0.0;
    int totalTimesheets = relevantTimesheets.length;

    for (final timesheet in relevantTimesheets) {
      totalHours += timesheet.calculatedTotalHours;
      totalPay += timesheet.calculatedTotalPay;
    }

    return {
      'totalHours': totalHours,
      'totalPay': totalPay,
      'totalTimesheets': totalTimesheets.toDouble(),
      'averageHoursPerWeek': totalTimesheets > 0 ? totalHours / totalTimesheets : 0.0,
    };
  }

  // Utility Functions
  String generateTimesheetId() {
    return 'timesheet_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String generateTimesheetEntryId() {
    return 'entry_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  Future<bool> importTimesheets(List<Timesheet> timesheets) async {
    try {
      for (final timesheet in timesheets) {
        await saveTimesheet(timesheet);
      }
      print('✅ Imported ${timesheets.length} timesheets');
      return true;
    } catch (e) {
      print('❌ Error importing timesheets: $e');
      return false;
    }
  }

  Future<bool> clearAllData() async {
    try {
      await _storage.delete(key: _timesheetsKey);
      await _storage.delete(key: _timesheetEntriesKey);
      print('✅ All timesheet data cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing timesheet data: $e');
      return false;
    }
  }
}