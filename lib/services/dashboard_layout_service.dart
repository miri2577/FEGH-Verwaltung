import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_layout.dart';

/// Persistiert das Dashboard-Layout pro Geraet (SharedPreferences).
///
/// Das Layout ist nicht organisationsweit — jede Mitarbeiterin hat
/// ihr eigenes Dashboard-Setup. Deshalb keine Cloud-Synchronisierung.
class DashboardLayoutService {
  static const _key = 'dashboard_layout_v1';

  Future<DashboardLayout> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const DashboardLayout();
      return DashboardLayout.fromJson(raw);
    } catch (e) {
      if (kDebugMode) debugPrint('[DASH] load: $e');
      return const DashboardLayout();
    }
  }

  Future<bool> save(DashboardLayout layout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, layout.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[DASH] save: $e');
      return false;
    }
  }

  Future<bool> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[DASH] reset: $e');
      return false;
    }
  }
}
