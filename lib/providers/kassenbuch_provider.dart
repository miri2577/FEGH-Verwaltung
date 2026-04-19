import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/kassenbuch_eintrag.dart';
import '../models/kassenbuch_monatsabschluss.dart';
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

/// Map: originalEntryId → stornoEntryId (pro Klient).
final kassenbuchStornoMapProvider = FutureProvider.family
    .autoDispose<Map<String, String>, String>((ref, clientId) async {
  return ref.watch(kassenbuchServiceProvider).stornoMapForClient(clientId);
});

/// Map: "YYYY-MM" → KassenbuchMonatsabschluss (pro Klient).
final kassenbuchAbschluesseProvider = FutureProvider.family
    .autoDispose<Map<String, KassenbuchMonatsabschluss>, String>(
        (ref, clientId) async {
  return ref.watch(kassenbuchServiceProvider).abschluesseForClient(clientId);
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

  Future<KassenbuchMonatsabschluss?> closeMonth(
    String clientId,
    DateTime month, {
    required String employeeId,
    String? signaturePngB64,
  }) async {
    state = const AsyncValue.loading();
    final a = await _ref.read(kassenbuchServiceProvider).closeMonth(
          clientId,
          month,
          byEmployeeId: employeeId,
          signaturePngB64: signaturePngB64,
        );
    state = const AsyncValue.data(null);
    _invalidate(clientId);
    return a;
  }

  Future<String?> storno(String originalId, String clientId,
      {required String employeeId,
      required String reason,
      String? signaturePngB64}) async {
    state = const AsyncValue.loading();
    final id = await _ref.read(kassenbuchServiceProvider).stornoEintrag(
          originalId,
          byEmployeeId: employeeId,
          reason: reason,
          signaturePngB64: signaturePngB64,
        );
    state = const AsyncValue.data(null);
    _invalidate(clientId);
    return id;
  }

  void _invalidate(String clientId) {
    _ref.invalidate(kassenbuchForClientProvider(clientId));
    _ref.invalidate(kassenbuchSaldoProvider(clientId));
    _ref.invalidate(kassenbuchStornoMapProvider(clientId));
    _ref.invalidate(kassenbuchAbschluesseProvider(clientId));
  }
}
