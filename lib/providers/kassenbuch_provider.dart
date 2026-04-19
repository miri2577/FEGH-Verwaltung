import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/kassenbuch_eintrag.dart';
import '../services/kassenbuch_service.dart';

final kassenbuchServiceProvider =
    Provider<KassenbuchService>((ref) => KassenbuchService());

final kassenbuchForClientProvider = FutureProvider.family
    .autoDispose<List<KassenbuchEintrag>, String>((ref, clientId) async {
  return ref.watch(kassenbuchServiceProvider).loadForClient(clientId);
});

final kassenbuchSaldoProvider =
    FutureProvider.family.autoDispose<double, String>((ref, clientId) async {
  return ref.watch(kassenbuchServiceProvider).saldoForClient(clientId);
});

final kassenbuchActionProvider =
    StateNotifierProvider<KassenbuchActionNotifier, AsyncValue<void>>(
        (ref) => KassenbuchActionNotifier(ref));

class KassenbuchActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  KassenbuchActionNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> add(KassenbuchEintrag e) async {
    state = const AsyncValue.loading();
    final ok = await _ref.read(kassenbuchServiceProvider).addEintrag(e);
    state = const AsyncValue.data(null);
    _invalidate(e.clientId);
    return ok;
  }

  Future<bool> update(KassenbuchEintrag e) async {
    state = const AsyncValue.loading();
    final ok = await _ref.read(kassenbuchServiceProvider).updateEintrag(e);
    state = const AsyncValue.data(null);
    _invalidate(e.clientId);
    return ok;
  }

  Future<bool> confirm(String id, String clientId,
      {required String employeeId}) async {
    state = const AsyncValue.loading();
    final ok = await _ref
        .read(kassenbuchServiceProvider)
        .confirmEintrag(id, byEmployeeId: employeeId);
    state = const AsyncValue.data(null);
    _invalidate(clientId);
    return ok;
  }

  Future<bool> delete(String id, String clientId,
      {required String employeeId, String? reason}) async {
    state = const AsyncValue.loading();
    final ok = await _ref
        .read(kassenbuchServiceProvider)
        .deleteEintrag(id, byEmployeeId: employeeId, reason: reason);
    state = const AsyncValue.data(null);
    _invalidate(clientId);
    return ok;
  }

  void _invalidate(String clientId) {
    _ref.invalidate(kassenbuchForClientProvider(clientId));
    _ref.invalidate(kassenbuchSaldoProvider(clientId));
  }
}
