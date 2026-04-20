import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_layout.dart';
import '../services/dashboard_layout_service.dart';

final dashboardLayoutServiceProvider =
    Provider<DashboardLayoutService>((ref) => DashboardLayoutService());

final dashboardLayoutProvider =
    StateNotifierProvider<DashboardLayoutNotifier, DashboardLayout>(
        (ref) => DashboardLayoutNotifier(ref));

class DashboardLayoutNotifier extends StateNotifier<DashboardLayout> {
  final Ref _ref;
  bool _loaded = false;

  DashboardLayoutNotifier(this._ref) : super(const DashboardLayout()) {
    _init();
  }

  Future<void> _init() async {
    state = await _ref.read(dashboardLayoutServiceProvider).load();
    _loaded = true;
  }

  bool get loaded => _loaded;

  Future<void> reorder(int oldIndex, int newIndex, List<String> knownIds) async {
    state = state.reorder(oldIndex, newIndex, knownIds);
    await _persist();
  }

  Future<void> toggleVisibility(String id) async {
    state = state.toggleVisibility(id);
    await _persist();
  }

  Future<void> reset() async {
    state = state.reset();
    await _ref.read(dashboardLayoutServiceProvider).reset();
  }

  Future<void> _persist() async {
    await _ref.read(dashboardLayoutServiceProvider).save(state);
  }
}
