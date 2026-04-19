import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/medication.dart';
import '../models/medication_administration.dart';
import '../services/medication_administration_service.dart';
import '../services/medication_service.dart';

// ── Services ────────────────────────────────────────────────────

final medicationServiceProvider =
    Provider<MedicationService>((ref) => MedicationService());

final medicationAdministrationServiceProvider =
    Provider<MedicationAdministrationService>((ref) =>
        MedicationAdministrationService(
            medications: ref.watch(medicationServiceProvider)));

// ── Plaene pro Klient ───────────────────────────────────────────

final medicationsForClientProvider = FutureProvider.family
    .autoDispose<List<Medication>, String>((ref, clientId) async {
  final svc = ref.watch(medicationServiceProvider);
  return svc.loadForClient(clientId);
});

final allActiveMedicationsProvider =
    FutureProvider.autoDispose<List<Medication>>((ref) async {
  return ref.watch(medicationServiceProvider).loadAllActive();
});

final medicationPlanActionProvider =
    StateNotifierProvider<MedicationPlanActionNotifier, AsyncValue<void>>(
        (ref) => MedicationPlanActionNotifier(ref));

class MedicationPlanActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  MedicationPlanActionNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> add(Medication m) async {
    state = const AsyncValue.loading();
    final ok = await _ref.read(medicationServiceProvider).addMedication(m);
    state = const AsyncValue.data(null);
    if (ok) _ref.invalidate(medicationsForClientProvider(m.clientId));
    _ref.invalidate(allActiveMedicationsProvider);
    return ok;
  }

  Future<bool> update(Medication m) async {
    state = const AsyncValue.loading();
    final ok = await _ref.read(medicationServiceProvider).updateMedication(m);
    state = const AsyncValue.data(null);
    if (ok) _ref.invalidate(medicationsForClientProvider(m.clientId));
    _ref.invalidate(allActiveMedicationsProvider);
    return ok;
  }

  Future<bool> deactivate(String id, String clientId) async {
    state = const AsyncValue.loading();
    final ok =
        await _ref.read(medicationServiceProvider).deactivateMedication(id);
    state = const AsyncValue.data(null);
    if (ok) _ref.invalidate(medicationsForClientProvider(clientId));
    _ref.invalidate(allActiveMedicationsProvider);
    return ok;
  }
}

// ── Slots (heutige Gaben) ───────────────────────────────────────

final todaysSlotsProvider = FutureProvider.autoDispose
    .family<List<AdministrationSlot>, DateTime>((ref, date) async {
  final svc = ref.watch(medicationAdministrationServiceProvider);
  return svc.openSlotsForDate(date);
});

final administrationActionProvider = StateNotifierProvider<
    AdministrationActionNotifier, AsyncValue<void>>(
  (ref) => AdministrationActionNotifier(ref),
);

class AdministrationActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  AdministrationActionNotifier(this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> administer(
    AdministrationSlot slot, {
    required String employeeId,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    final ok = await _ref
        .read(medicationAdministrationServiceProvider)
        .administer(slot, employeeId: employeeId, notes: notes);
    state = const AsyncValue.data(null);
    _invalidate(slot.scheduledAt);
    return ok;
  }

  Future<bool> refuse(
    AdministrationSlot slot, {
    required String employeeId,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    final ok = await _ref
        .read(medicationAdministrationServiceProvider)
        .markRefused(slot, employeeId: employeeId, reason: reason);
    state = const AsyncValue.data(null);
    _invalidate(slot.scheduledAt);
    return ok;
  }

  Future<bool> miss(
    AdministrationSlot slot, {
    required String employeeId,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    final ok = await _ref
        .read(medicationAdministrationServiceProvider)
        .markMissed(slot, employeeId: employeeId, reason: reason);
    state = const AsyncValue.data(null);
    _invalidate(slot.scheduledAt);
    return ok;
  }

  void _invalidate(DateTime at) {
    final day = DateTime(at.year, at.month, at.day);
    _ref.invalidate(todaysSlotsProvider(day));
  }
}
