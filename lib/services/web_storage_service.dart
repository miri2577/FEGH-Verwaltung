import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/employee.dart';
import '../models/team.dart';
import '../models/shift.dart';
import '../models/vacation_request.dart';

/// Web-kompatibler Storage-Service der SharedPreferences nutzt statt Dateisystem
class WebStorageService {
  static const String _employeesKey = 'pv_employees';
  static const String _teamsKey = 'pv_teams';
  static const String _shiftsKey = 'pv_shifts';
  static const String _vacationsKey = 'pv_vacations';
  static const String _clientsKey = 'pv_clients';

  final Uuid _uuid = const Uuid();
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (kDebugMode) print('✅ Web storage initialized');
  }

  // Employee Management
  Future<List<Employee>> loadEmployees() async {
    try {
      final content = _prefs.getString(_employeesKey);
      if (content == null || content.isEmpty) return [];
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((j) => Employee.fromJson(j)).toList();
    } catch (e) {
      if (kDebugMode) print('❌ Failed to load employees: $e');
      return [];
    }
  }

  Future<bool> saveEmployees(List<Employee> employees) async {
    try {
      final jsonList = employees.map((e) => e.toJson()).toList();
      await _prefs.setString(_employeesKey, json.encode(jsonList));
      if (kDebugMode) print('✅ Saved ${employees.length} employees');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Failed to save employees: $e');
      return false;
    }
  }

  Future<Employee?> saveEmployee(Employee employee) async {
    final employees = await loadEmployees();
    final index = employees.indexWhere((e) => e.id == employee.id);
    final updated = employee.copyWith(updatedAt: DateTime.now());
    if (index >= 0) { employees[index] = updated; } else { employees.add(updated); }
    final success = await saveEmployees(employees);
    return success ? updated : null;
  }

  Future<bool> deleteEmployee(String employeeId) async {
    final employees = await loadEmployees();
    final len = employees.length;
    employees.removeWhere((e) => e.id == employeeId);
    return employees.length < len ? await saveEmployees(employees) : false;
  }

  Future<Employee?> getEmployeeById(String employeeId) async {
    final employees = await loadEmployees();
    try { return employees.firstWhere((e) => e.id == employeeId); } catch (_) { return null; }
  }

  // Team Management
  Future<List<Team>> loadTeams() async {
    try {
      final content = _prefs.getString(_teamsKey);
      if (content == null || content.isEmpty) return [];
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((j) => Team.fromJson(j)).toList();
    } catch (e) {
      if (kDebugMode) print('❌ Failed to load teams: $e');
      return [];
    }
  }

  Future<bool> saveTeams(List<Team> teams) async {
    try {
      final jsonList = teams.map((t) => t.toJson()).toList();
      await _prefs.setString(_teamsKey, json.encode(jsonList));
      return true;
    } catch (e) { return false; }
  }

  Future<Team?> saveTeam(Team team) async {
    final teams = await loadTeams();
    final index = teams.indexWhere((t) => t.id == team.id);
    final updated = team.copyWith(updatedAt: DateTime.now());
    if (index >= 0) { teams[index] = updated; } else { teams.add(updated); }
    final success = await saveTeams(teams);
    return success ? updated : null;
  }

  Future<bool> deleteTeam(String teamId) async {
    final teams = await loadTeams();
    final len = teams.length;
    teams.removeWhere((t) => t.id == teamId);
    return teams.length < len ? await saveTeams(teams) : false;
  }

  // Shift Management
  Future<List<Shift>> loadShifts() async {
    try {
      final content = _prefs.getString(_shiftsKey);
      if (content == null || content.isEmpty) return [];
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((j) => Shift.fromJson(j)).toList();
    } catch (e) { return []; }
  }

  Future<bool> saveShifts(List<Shift> shifts) async {
    try {
      final jsonList = shifts.map((s) => s.toJson()).toList();
      await _prefs.setString(_shiftsKey, json.encode(jsonList));
      return true;
    } catch (e) { return false; }
  }

  Future<Shift?> saveShift(Shift shift) async {
    final shifts = await loadShifts();
    final index = shifts.indexWhere((s) => s.id == shift.id);
    final updated = shift.copyWith(updatedAt: DateTime.now());
    if (index >= 0) { shifts[index] = updated; } else { shifts.add(updated); }
    final success = await saveShifts(shifts);
    return success ? updated : null;
  }

  Future<bool> deleteShift(String shiftId) async {
    final shifts = await loadShifts();
    final len = shifts.length;
    shifts.removeWhere((s) => s.id == shiftId);
    return shifts.length < len ? await saveShifts(shifts) : false;
  }

  // Vacation Management
  Future<List<VacationRequest>> loadVacationRequests() async {
    try {
      final content = _prefs.getString(_vacationsKey);
      if (content == null || content.isEmpty) return [];
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((j) => VacationRequest.fromJson(j)).toList();
    } catch (e) { return []; }
  }

  Future<bool> saveVacationRequests(List<VacationRequest> requests) async {
    try {
      final jsonList = requests.map((v) => v.toJson()).toList();
      await _prefs.setString(_vacationsKey, json.encode(jsonList));
      return true;
    } catch (e) { return false; }
  }

  Future<VacationRequest?> saveVacationRequest(VacationRequest request) async {
    final requests = await loadVacationRequests();
    final index = requests.indexWhere((v) => v.id == request.id);
    final updated = request.copyWith(updatedAt: DateTime.now().toIso8601String());
    if (index >= 0) { requests[index] = updated; } else { requests.add(updated); }
    final success = await saveVacationRequests(requests);
    return success ? updated : null;
  }

  Future<bool> deleteVacationRequest(String requestId) async {
    final requests = await loadVacationRequests();
    final len = requests.length;
    requests.removeWhere((r) => r.id == requestId);
    return requests.length < len ? await saveVacationRequests(requests) : false;
  }

  // Clients
  Future<List<Map<String, dynamic>>> getClients() async {
    try {
      final content = _prefs.getString(_clientsKey);
      if (content == null || content.isEmpty) return [];
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) { return []; }
  }

  Future<bool> saveClients(List<Map<String, dynamic>> clients) async {
    try {
      await _prefs.setString(_clientsKey, json.encode(clients));
      return true;
    } catch (e) { return false; }
  }

  // Utility
  Future<List<Shift>> getShiftsForEmployee(String employeeId, {DateTime? startDate, DateTime? endDate}) async {
    final shifts = await loadShifts();
    return shifts.where((s) {
      if (s.employeeId != employeeId) return false;
      if (startDate != null && s.startTime.isBefore(startDate)) return false;
      if (endDate != null && s.endTime.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  Future<List<Shift>> getTodaysShifts() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final shifts = await loadShifts();
    return shifts.where((s) {
      final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      return d.isAtSameMomentAs(today);
    }).toList();
  }

  Future<List<VacationRequest>> getVacationRequestsForEmployee(String employeeId) async {
    final requests = await loadVacationRequests();
    return requests.where((r) => r.employeeId == employeeId).toList();
  }

  String generateId() => _uuid.v4();
  String get dataDirectoryPath => 'web-localStorage';
  bool get isInitialized => true;
}
