import 'package:fegh_billing/fegh_billing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/billing_service.dart';

final billingServiceProvider = Provider<BillingService>((ref) {
  return BillingService();
});

final rechnungenProvider =
    StateNotifierProvider<RechnungenNotifier, AsyncValue<List<Rechnung>>>((ref) {
  return RechnungenNotifier(ref.watch(billingServiceProvider));
});

class RechnungenNotifier extends StateNotifier<AsyncValue<List<Rechnung>>> {
  final BillingService _svc;

  RechnungenNotifier(this._svc) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _svc.loadRechnungen();
      list.sort((a, b) => b.rechnungsdatum.compareTo(a.rechnungsdatum));
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> add(Rechnung r) async {
    final ok = await _svc.addRechnung(r);
    if (ok) await load();
    return ok;
  }

  Future<bool> update(Rechnung r) async {
    final ok = await _svc.updateRechnung(r);
    if (ok) await load();
    return ok;
  }

  Future<bool> delete(String id) async {
    final ok = await _svc.deleteRechnung(id);
    if (ok) await load();
    return ok;
  }
}

final empfaengerProvider = StateNotifierProvider<EmpfaengerNotifier,
    AsyncValue<List<RechnungEmpfaenger>>>((ref) {
  return EmpfaengerNotifier(ref.watch(billingServiceProvider));
});

class EmpfaengerNotifier
    extends StateNotifier<AsyncValue<List<RechnungEmpfaenger>>> {
  final BillingService _svc;

  EmpfaengerNotifier(this._svc) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _svc.loadEmpfaenger();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> add(RechnungEmpfaenger e) async {
    final ok = await _svc.addEmpfaenger(e);
    if (ok) await load();
    return ok;
  }

  Future<bool> update(RechnungEmpfaenger e) async {
    final ok = await _svc.updateEmpfaenger(e);
    if (ok) await load();
    return ok;
  }

  Future<bool> delete(String id) async {
    final ok = await _svc.deleteEmpfaenger(id);
    if (ok) await load();
    return ok;
  }
}
