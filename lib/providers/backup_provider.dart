import 'dart:typed_data';

import 'package:fegh_backup/fegh_backup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/backup_restore_service.dart';

/// Auflistung der lokal vorhandenen Backups.
final localBackupsProvider =
    FutureProvider<List<BackupInfo>>((ref) async {
  return BackupRestoreService.listLocalBackups();
});

/// Aktionen rund um Backup/Restore. Der Notifier haelt nur den letzten
/// Ausfuehrungsstatus, die eigentlichen Listen kommen aus
/// [localBackupsProvider].
final backupActionProvider =
    StateNotifierProvider<BackupActionNotifier, AsyncValue<BackupActionState>>(
        (ref) => BackupActionNotifier(ref));

class BackupActionState {
  final String? message;
  final BackupInfo? lastCreated;
  final BackupMetadata? lastRestoredMetadata;
  final int? lastRestoredKeys;

  const BackupActionState({
    this.message,
    this.lastCreated,
    this.lastRestoredMetadata,
    this.lastRestoredKeys,
  });

  static const idle = BackupActionState();
}

class BackupActionNotifier extends StateNotifier<AsyncValue<BackupActionState>> {
  final Ref _ref;

  BackupActionNotifier(this._ref) : super(const AsyncValue.data(BackupActionState.idle));

  /// Erstellt ein Backup und refresht die Liste.
  Future<bool> createBackup(String password) async {
    state = const AsyncValue.loading();
    final res = await BackupRestoreService.createBackup(password: password);
    if (res.success && res.info != null) {
      state = AsyncValue.data(BackupActionState(
        message: 'Backup erstellt: ${res.info!.filename}',
        lastCreated: res.info,
      ));
      _ref.invalidate(localBackupsProvider);
      return true;
    }
    state = AsyncValue.error(res.error ?? 'Unbekannter Fehler', StackTrace.current);
    return false;
  }

  /// Spielt ein Backup ein.
  Future<bool> restoreBackup({
    required Uint8List bytes,
    required String password,
    bool overwrite = true,
  }) async {
    state = const AsyncValue.loading();
    final res = await BackupRestoreService.restoreBackup(
      bytes: bytes,
      password: password,
      overwrite: overwrite,
    );
    if (res.success) {
      state = AsyncValue.data(BackupActionState(
        message:
            'Wiederhergestellt: ${res.restoredKeys} Eintraege (uebersprungen: ${res.skippedKeys})',
        lastRestoredMetadata: res.metadata,
        lastRestoredKeys: res.restoredKeys,
      ));
      return true;
    }
    state = AsyncValue.error(res.error ?? 'Unbekannter Fehler', StackTrace.current);
    return false;
  }

  /// Loescht ein Backup lokal.
  Future<bool> deleteBackup(String filename) async {
    final ok = await BackupRestoreService.deleteBackup(filename);
    if (ok) _ref.invalidate(localBackupsProvider);
    return ok;
  }

  void clearMessage() {
    state = const AsyncValue.data(BackupActionState.idle);
  }
}
