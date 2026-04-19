import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shift.dart';
import '../models/shift_swap_request.dart';
import '../services/shift_swap_service.dart';
import 'shift_provider.dart';
import 'team_provider.dart';

final shiftSwapServiceProvider =
    Provider<ShiftSwapService>((ref) => ShiftSwapService());

/// Alle Tausch-Anfragen, neueste zuerst.
final allShiftSwapsProvider =
    FutureProvider.autoDispose<List<ShiftSwapRequest>>((ref) async {
  return ref.watch(shiftSwapServiceProvider).loadAll();
});

/// Eigene Anfragen des Mitarbeiters.
final myShiftSwapsProvider = FutureProvider.family
    .autoDispose<List<ShiftSwapRequest>, String>((ref, employeeId) async {
  return ref.watch(shiftSwapServiceProvider).loadForRequester(employeeId);
});

/// Offene Anfragen, die [employeeId] annehmen koennte.
final openSwapsForMeProvider = FutureProvider.family
    .autoDispose<List<ShiftSwapRequest>, String>((ref, employeeId) async {
  final teams = ref.watch(teamsProvider).valueOrNull ?? const [];
  final myTeamIds = teams
      .where((t) =>
          t.memberIds.contains(employeeId) || t.teamLeaderId == employeeId)
      .map((t) => t.id)
      .toSet();
  return ref.watch(shiftSwapServiceProvider).loadOpenForRecipient(
        employeeId,
        myTeamIds: myTeamIds,
      );
});

/// Anfragen in `accepted`-Zustand — Teamleitung muss entscheiden.
final swapsPendingLeadDecisionProvider = FutureProvider.family
    .autoDispose<List<ShiftSwapRequest>, String>((ref, leadEmployeeId) async {
  final teams = ref.watch(teamsProvider).valueOrNull ?? const [];
  final myLeadTeamIds = teams
      .where((t) => t.teamLeaderId == leadEmployeeId)
      .map((t) => t.id)
      .toSet();
  if (myLeadTeamIds.isEmpty) return const [];
  return ref.watch(shiftSwapServiceProvider).loadForLeadReview(myLeadTeamIds);
});

final shiftSwapActionProvider =
    StateNotifierProvider<ShiftSwapActionNotifier, AsyncValue<void>>(
        (ref) => ShiftSwapActionNotifier(ref));

class ShiftSwapActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ShiftSwapActionNotifier(this._ref)
      : super(const AsyncValue.data(null));

  Future<String?> createRequest({
    required Shift shift,
    required String requesterEmployeeId,
    String? offeredToEmployeeId,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    final id = await _ref.read(shiftSwapServiceProvider).createRequest(
          shift: shift,
          requesterEmployeeId: requesterEmployeeId,
          offeredToEmployeeId: offeredToEmployeeId,
          reason: reason,
        );
    state = const AsyncValue.data(null);
    _invalidate();
    return id;
  }

  Future<bool> cancel(String requestId, String byEmployeeId) async {
    state = const AsyncValue.loading();
    final ok = await _ref
        .read(shiftSwapServiceProvider)
        .cancel(requestId, byEmployeeId);
    state = const AsyncValue.data(null);
    _invalidate();
    return ok;
  }

  Future<bool> accept(
      String requestId, String acceptingEmployeeId) async {
    state = const AsyncValue.loading();
    final ok = await _ref
        .read(shiftSwapServiceProvider)
        .accept(requestId, acceptingEmployeeId);
    state = const AsyncValue.data(null);
    _invalidate();
    return ok;
  }

  Future<bool> decline(String requestId, String byEmployeeId,
      {String? reason}) async {
    state = const AsyncValue.loading();
    final ok = await _ref.read(shiftSwapServiceProvider).decline(
          requestId,
          byEmployeeId,
          reason: reason,
        );
    state = const AsyncValue.data(null);
    _invalidate();
    return ok;
  }

  /// Teamleitung genehmigt — updated die Schicht und den Swap-Status.
  Future<bool> approveByLead(
    String requestId,
    String leadEmployeeId, {
    String? note,
  }) async {
    state = const AsyncValue.loading();
    final svc = _ref.read(shiftSwapServiceProvider);
    final updated = await svc.approveByLead(requestId, leadEmployeeId,
        note: note);
    if (updated == null) {
      state = const AsyncValue.data(null);
      return false;
    }
    // Schicht umbuchen: acceptingEmployeeId wird neuer Inhaber.
    final shifts = _ref.read(shiftsProvider).valueOrNull ?? const [];
    final shift = shifts.cast<Shift?>().firstWhere(
          (s) => s != null && s.id == updated.shiftId,
          orElse: () => null,
        );
    if (shift != null && updated.acceptingEmployeeId != null) {
      await _ref.read(shiftsProvider.notifier).updateShift(
            shift.copyWith(employeeId: updated.acceptingEmployeeId),
          );
    }
    state = const AsyncValue.data(null);
    _invalidate();
    return true;
  }

  Future<bool> rejectByLead(
    String requestId,
    String leadEmployeeId, {
    String? note,
  }) async {
    state = const AsyncValue.loading();
    final ok = await _ref
        .read(shiftSwapServiceProvider)
        .rejectByLead(requestId, leadEmployeeId, note: note);
    state = const AsyncValue.data(null);
    _invalidate();
    return ok;
  }

  void _invalidate() {
    _ref.invalidate(allShiftSwapsProvider);
    // Family provider sind per-argument — sie werden beim naechsten Watch
    // neu aufgebaut, da sie `autoDispose` sind. Deshalb kein explicit
    // invalidate noetig.
  }
}
