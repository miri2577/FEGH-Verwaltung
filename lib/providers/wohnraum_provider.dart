import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wohnraum.dart';
import '../services/wohnraum_service.dart';

final wohnraumServiceProvider =
    Provider<WohnraumService>((ref) => WohnraumService());

final allWohnraeumeProvider =
    FutureProvider.autoDispose<List<Wohnraum>>((ref) async {
  return ref.watch(wohnraumServiceProvider).loadActive();
});

final wohnraeumeForClientProvider = FutureProvider.family
    .autoDispose<List<Wohnraum>, String>((ref, clientId) async {
  return ref.watch(wohnraumServiceProvider).loadForClient(clientId);
});

final wohnraumActionProvider =
    StateNotifierProvider<WohnraumActionNotifier, AsyncValue<void>>(
        (ref) => WohnraumActionNotifier(ref));

class WohnraumActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  WohnraumActionNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> add(Wohnraum w) async {
    state = const AsyncValue.loading();
    final ok = await _ref.read(wohnraumServiceProvider).addWohnraum(w);
    state = const AsyncValue.data(null);
    _invalidate();
    return ok;
  }

  Future<bool> update(Wohnraum w) async {
    state = const AsyncValue.loading();
    final ok = await _ref.read(wohnraumServiceProvider).updateWohnraum(w);
    state = const AsyncValue.data(null);
    _invalidate();
    return ok;
  }

  Future<bool> assignClient(String wohnraumId, String clientId) async {
    state = const AsyncValue.loading();
    final ok = await _ref
        .read(wohnraumServiceProvider)
        .assignClient(wohnraumId, clientId);
    state = const AsyncValue.data(null);
    _invalidate(clientId: clientId);
    return ok;
  }

  Future<bool> releaseClient(String wohnraumId) async {
    state = const AsyncValue.loading();
    final ok =
        await _ref.read(wohnraumServiceProvider).releaseClient(wohnraumId);
    state = const AsyncValue.data(null);
    _invalidate();
    return ok;
  }

  Future<bool> deactivate(String wohnraumId) async {
    state = const AsyncValue.loading();
    final ok =
        await _ref.read(wohnraumServiceProvider).deactivate(wohnraumId);
    state = const AsyncValue.data(null);
    _invalidate();
    return ok;
  }

  void _invalidate({String? clientId}) {
    _ref.invalidate(allWohnraeumeProvider);
    if (clientId != null) {
      _ref.invalidate(wohnraeumeForClientProvider(clientId));
    }
  }
}
