import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/employee.dart';
import '../models/team.dart';
import '../models/shift.dart';
import '../models/vacation_request.dart';

class LocalStorageService {
  static const String _dataDirectory = 'personalverwaltung_data';
  static const String _employeesFile = 'employees.json';
  static const String _teamsFile = 'teams.json';
  static const String _shiftsFile = 'shifts.json';
  static const String _vacationsFile = 'vacations.json';
  static const String _clientsFile = 'clients.json';

  final Uuid _uuid = const Uuid();
  Directory? _dataDir;

  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _dataDir = Directory(path.join(appDir.path, _dataDirectory));

      if (!await _dataDir!.exists()) {
        await _dataDir!.create(recursive: true);
        if (kDebugMode) {
          print('✅ Created data directory: ${_dataDir!.path}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize local storage: $e');
      }
      rethrow;
    }
  }

  // Employee Management
  Future<List<Employee>> loadEmployees() async {
    try {
      final file = File(path.join(_dataDir!.path, _employeesFile));
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((json) => Employee.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load employees: $e');
      }
      return [];
    }
  }

  Future<bool> saveEmployees(List<Employee> employees) async {
    try {
      final file = File(path.join(_dataDir!.path, _employeesFile));
      final jsonList = employees.map((e) => e.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));

      if (kDebugMode) {
        print('✅ Saved ${employees.length} employees');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save employees: $e');
      }
      return false;
    }
  }

  Future<Employee?> saveEmployee(Employee employee) async {
    final employees = await loadEmployees();
    final index = employees.indexWhere((e) => e.id == employee.id);

    final updatedEmployee = employee.copyWith(updatedAt: DateTime.now());

    if (index >= 0) {
      employees[index] = updatedEmployee;
    } else {
      employees.add(updatedEmployee);
    }

    final success = await saveEmployees(employees);
    return success ? updatedEmployee : null;
  }

  Future<bool> deleteEmployee(String employeeId) async {
    final employees = await loadEmployees();
    final initialLength = employees.length;
    employees.removeWhere((e) => e.id == employeeId);

    if (employees.length < initialLength) {
      return await saveEmployees(employees);
    }
    return false;
  }

  Future<Employee?> getEmployeeById(String employeeId) async {
    final employees = await loadEmployees();
    try {
      return employees.firstWhere((e) => e.id == employeeId);
    } catch (e) {
      return null;
    }
  }

  // Team Management
  Future<List<Team>> loadTeams() async {
    try {
      final file = File(path.join(_dataDir!.path, _teamsFile));
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((json) => Team.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load teams: $e');
      }
      return [];
    }
  }

  Future<bool> saveTeams(List<Team> teams) async {
    try {
      final file = File(path.join(_dataDir!.path, _teamsFile));
      final jsonList = teams.map((t) => t.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));

      if (kDebugMode) {
        print('✅ Saved ${teams.length} teams');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save teams: $e');
      }
      return false;
    }
  }

  Future<Team?> saveTeam(Team team) async {
    final teams = await loadTeams();
    final index = teams.indexWhere((t) => t.id == team.id);

    final updatedTeam = team.copyWith(updatedAt: DateTime.now());

    if (index >= 0) {
      teams[index] = updatedTeam;
    } else {
      teams.add(updatedTeam);
    }

    final success = await saveTeams(teams);
    return success ? updatedTeam : null;
  }

  Future<bool> deleteTeam(String teamId) async {
    final teams = await loadTeams();
    final initialLength = teams.length;
    teams.removeWhere((t) => t.id == teamId);

    if (teams.length < initialLength) {
      return await saveTeams(teams);
    }
    return false;
  }

  // Shift Management
  Future<List<Shift>> loadShifts() async {
    try {
      final file = File(path.join(_dataDir!.path, _shiftsFile));
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((json) => Shift.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load shifts: $e');
      }
      return [];
    }
  }

  Future<bool> saveShifts(List<Shift> shifts) async {
    try {
      final file = File(path.join(_dataDir!.path, _shiftsFile));
      final jsonList = shifts.map((s) => s.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));

      if (kDebugMode) {
        print('✅ Saved ${shifts.length} shifts');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save shifts: $e');
      }
      return false;
    }
  }

  Future<Shift?> saveShift(Shift shift) async {
    final shifts = await loadShifts();
    final index = shifts.indexWhere((s) => s.id == shift.id);

    final updatedShift = shift.copyWith(updatedAt: DateTime.now());

    if (index >= 0) {
      shifts[index] = updatedShift;
    } else {
      shifts.add(updatedShift);
    }

    final success = await saveShifts(shifts);
    return success ? updatedShift : null;
  }

  Future<bool> deleteShift(String shiftId) async {
    final shifts = await loadShifts();
    final initialLength = shifts.length;
    shifts.removeWhere((s) => s.id == shiftId);

    if (shifts.length < initialLength) {
      return await saveShifts(shifts);
    }
    return false;
  }

  // Vacation Management
  Future<List<VacationRequest>> loadVacationRequests() async {
    try {
      final file = File(path.join(_dataDir!.path, _vacationsFile));
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((json) => VacationRequest.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load vacation requests: $e');
      }
      return [];
    }
  }

  Future<bool> saveVacationRequests(List<VacationRequest> requests) async {
    try {
      final file = File(path.join(_dataDir!.path, _vacationsFile));
      final jsonList = requests.map((v) => v.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));

      if (kDebugMode) {
        print('✅ Saved ${requests.length} vacation requests');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save vacation requests: $e');
      }
      return false;
    }
  }

  Future<VacationRequest?> saveVacationRequest(VacationRequest request) async {
    final requests = await loadVacationRequests();
    final index = requests.indexWhere((v) => v.id == request.id);

    final updatedRequest = request.copyWith(updatedAt: DateTime.now().toIso8601String());

    if (index >= 0) {
      requests[index] = updatedRequest;
    } else {
      requests.add(updatedRequest);
    }

    final success = await saveVacationRequests(requests);
    return success ? updatedRequest : null;
  }

  Future<bool> deleteVacationRequest(String requestId) async {
    final requests = await loadVacationRequests();
    final initialLength = requests.length;
    requests.removeWhere((r) => r.id == requestId);

    if (requests.length < initialLength) {
      return await saveVacationRequests(requests);
    }
    return false;
  }


  // Utility Methods
  Future<List<Shift>> getShiftsForEmployee(String employeeId, {DateTime? startDate, DateTime? endDate}) async {
    final shifts = await loadShifts();
    return shifts.where((shift) {
      if (shift.employeeId != employeeId) return false;

      if (startDate != null && shift.startTime.isBefore(startDate)) return false;
      if (endDate != null && shift.endTime.isAfter(endDate)) return false;

      return true;
    }).toList();
  }

  Future<List<Shift>> getTodaysShifts() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final shifts = await loadShifts();
    return shifts.where((shift) {
      final shiftDate = DateTime(shift.startTime.year, shift.startTime.month, shift.startTime.day);
      return shiftDate.isAtSameMomentAs(today);
    }).toList();
  }

  Future<List<VacationRequest>> getVacationRequestsForEmployee(String employeeId) async {
    final requests = await loadVacationRequests();
    return requests.where((request) => request.employeeId == employeeId).toList();
  }

  String generateId() => _uuid.v4();

  String get dataDirectoryPath => _dataDir?.path ?? '';

  bool get isInitialized => _dataDir != null;

  // Clients
  Future<List<Map<String, dynamic>>> getClients() async {
    try {
      final file = File(path.join(_dataDir!.path, _clientsFile));
      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load clients: $e');
      }
      return [];
    }
  }

  Future<bool> saveClients(List<Map<String, dynamic>> clients) async {
    try {
      final file = File(path.join(_dataDir!.path, _clientsFile));
      await file.writeAsString(json.encode(clients));

      if (kDebugMode) {
        print('✅ Saved ${clients.length} clients');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save clients: $e');
      }
      return false;
    }
  }
}