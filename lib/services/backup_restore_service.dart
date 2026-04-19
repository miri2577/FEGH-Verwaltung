import 'dart:io';

import 'package:fegh_backup/fegh_backup.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Erstellt und liest verschluesselte Full-Backups der Verwaltung.
///
/// Das Backup umfasst alle SharedPreferences-Keys, in denen die App
/// Nutzdaten ablegt (Employees, Teams, Shifts, Vacations, Clients,
/// Rechnungen, Timesheets, Notifications, Settings). Sensitive Daten
/// aus `flutter_secure_storage` (MEK, Cloud-Credentials) werden NICHT
/// gesichert — sie sind geraetegebunden und muessen nach einer
/// Wiederherstellung neu hinterlegt werden.
class BackupRestoreService {
  BackupRestoreService._();

  /// Liste der SharedPreferences-Keys, die im Backup enthalten sind.
  /// Jede neue persistierte Entitaet muss hier eingetragen werden.
  static const List<String> _backupKeys = [
    // LocalStorageService
    'employees.json',
    'teams.json',
    'shifts.json',
    'vacations.json',
    'clients.json',
    // BillingService
    'pv_rechnungen_v1',
    'pv_rechnung_empfaenger_v1',
    // TimeSheetService
    'timesheets',
    'timesheet_entries',
    // NotificationService
    'app_notifications',
    'notification_settings',
    // SettingsService (ohne Credentials)
    'personalverwaltung_settings',
  ];

  static const _appVersion = '0.3.0-beta.1';
  static const _dataVersion = '1.0.0';

  /// Standard-Ordner fuer Backups im Application-Support-Verzeichnis.
  static Future<Directory> backupDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory('${appDir.path}/backups');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  // ── Backup erstellen ─────────────────────────────────────────────

  /// Erstellt ein vollstaendiges, mit [password] verschluesseltes Backup.
  ///
  /// Gibt die [BackupInfo] (inkl. Dateipfad unter `path`) zurueck.
  static Future<BackupCreateResult> createBackup({
    required String password,
    String? customFilename,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{};
      for (final key in _backupKeys) {
        final value = prefs.getString(key);
        if (value != null) payload[key] = value;
      }

      final env = BackupEnvelope(
        metadata: BackupMetadata.create(
          deviceName: _deviceLabel(),
          appVersion: _appVersion,
          dataVersion: _dataVersion,
        ),
        payload: payload,
      );

      final bytes = await BackupCodec.encrypt(env.encodeJson(), password);
      final filename = customFilename ??
          'fegh-verwaltung-${DateTime.now().millisecondsSinceEpoch}.ehbackup';
      final dir = await backupDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      return BackupCreateResult.success(
        path: file.path,
        info: BackupInfo(
          id: env.metadata.backupId,
          filename: filename,
          createdAt: env.metadata.createdAt,
          deviceName: env.metadata.deviceName,
          isEncrypted: true,
          fileSizeBytes: bytes.length,
        ),
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[BACKUP] create failed: $e\n$st');
      return BackupCreateResult.failure('Backup fehlgeschlagen: $e');
    }
  }

  // ── Backup wiederherstellen ─────────────────────────────────────

  /// Entschluesselt [bytes] mit [password] und spielt die enthaltenen
  /// SharedPreferences-Keys zurueck. Vorhandene Werte werden
  /// ueberschrieben, nicht enthaltene Keys bleiben unberuehrt.
  static Future<BackupRestoreResult> restoreBackup({
    required Uint8List bytes,
    required String password,
    bool overwrite = true,
  }) async {
    try {
      final json = await BackupCodec.decrypt(bytes, password);
      final env = BackupEnvelope.decodeJson(json);
      final prefs = await SharedPreferences.getInstance();

      var restored = 0;
      var skipped = 0;
      for (final entry in env.payload.entries) {
        if (!_backupKeys.contains(entry.key)) {
          skipped++;
          continue;
        }
        if (!overwrite && prefs.getString(entry.key) != null) {
          skipped++;
          continue;
        }
        await prefs.setString(entry.key, entry.value as String);
        restored++;
      }

      return BackupRestoreResult.success(
        metadata: env.metadata,
        restoredKeys: restored,
        skippedKeys: skipped,
      );
    } on StateError catch (e) {
      // Falsches Passwort (aus BackupCodec)
      if (kDebugMode) debugPrint('[BACKUP] restore auth failed: $e');
      return BackupRestoreResult.failure(
        'Falsches Passwort oder Datei beschaedigt.',
      );
    } on FormatException catch (e) {
      return BackupRestoreResult.failure('Ungueltiges Dateiformat: ${e.message}');
    } catch (e, st) {
      if (kDebugMode) debugPrint('[BACKUP] restore failed: $e\n$st');
      return BackupRestoreResult.failure('Wiederherstellung fehlgeschlagen: $e');
    }
  }

  /// Liest und dekodiert nur die Metadaten eines Backups — praktisch
  /// zum Anzeigen vor der finalen Wiederherstellung.
  static Future<BackupMetadata?> peekMetadata({
    required Uint8List bytes,
    required String password,
  }) async {
    try {
      final json = await BackupCodec.decrypt(bytes, password);
      return BackupEnvelope.decodeJson(json).metadata;
    } catch (_) {
      return null;
    }
  }

  // ── Lokale Backup-Liste ──────────────────────────────────────────

  /// Listet alle `.ehbackup`-Dateien im Standard-Backup-Ordner
  /// (ohne sie zu entschluesseln — Liste basiert auf Datei-Stats).
  static Future<List<BackupInfo>> listLocalBackups() async {
    try {
      final dir = await backupDirectory();
      final files = dir.listSync().whereType<File>().where((f) {
        return f.path.toLowerCase().endsWith('.ehbackup');
      }).toList();

      final infos = <BackupInfo>[];
      for (final file in files) {
        final stat = file.statSync();
        final filename = file.uri.pathSegments.last;
        infos.add(BackupInfo(
          id: filename.replaceAll(RegExp(r'[^0-9]'), ''),
          filename: filename,
          createdAt: stat.modified,
          deviceName: 'Unbekannt',
          isEncrypted: true,
          fileSizeBytes: stat.size,
        ));
      }
      infos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return infos;
    } catch (e) {
      if (kDebugMode) debugPrint('[BACKUP] list failed: $e');
      return [];
    }
  }

  /// Loescht ein Backup lokal.
  static Future<bool> deleteBackup(String filename) async {
    try {
      final dir = await backupDirectory();
      final file = File('${dir.path}/$filename');
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[BACKUP] delete failed: $e');
    }
    return false;
  }

  // ── Recovery-Phrase ──────────────────────────────────────────────

  /// Erzeugt eine neue 12-Wort Recovery-Phrase und verschluesselt damit
  /// [masterEncryptionKey]. Das Ergebnis ([encryptedMek]) kann in der
  /// App persistiert und der Phrase separat aufbewahrt werden.
  static Future<({String phrase, String encryptedMek})>
      generateRecoveryPhraseForMek(Uint8List masterEncryptionKey) async {
    final phrase = RecoveryService.generateRecoveryKey();
    final encryptedMek =
        await RecoveryService.encryptMekWithRecoveryKey(masterEncryptionKey, phrase);
    return (phrase: phrase, encryptedMek: encryptedMek);
  }

  // ── intern ───────────────────────────────────────────────────────

  static String _deviceLabel() {
    if (kIsWeb) return 'Web';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }
}

// ─────────────────────────────────────────────────────────────────────
// Result-Typen
// ─────────────────────────────────────────────────────────────────────

class BackupCreateResult {
  final bool success;
  final String? error;
  final String? path;
  final BackupInfo? info;

  const BackupCreateResult._({
    required this.success,
    this.error,
    this.path,
    this.info,
  });

  factory BackupCreateResult.success({
    required String path,
    required BackupInfo info,
  }) =>
      BackupCreateResult._(success: true, path: path, info: info);

  factory BackupCreateResult.failure(String error) =>
      BackupCreateResult._(success: false, error: error);
}

class BackupRestoreResult {
  final bool success;
  final String? error;
  final BackupMetadata? metadata;
  final int restoredKeys;
  final int skippedKeys;

  const BackupRestoreResult._({
    required this.success,
    this.error,
    this.metadata,
    this.restoredKeys = 0,
    this.skippedKeys = 0,
  });

  factory BackupRestoreResult.success({
    required BackupMetadata metadata,
    required int restoredKeys,
    required int skippedKeys,
  }) =>
      BackupRestoreResult._(
        success: true,
        metadata: metadata,
        restoredKeys: restoredKeys,
        skippedKeys: skippedKeys,
      );

  factory BackupRestoreResult.failure(String error) =>
      BackupRestoreResult._(success: false, error: error);

  /// JSON (nicht verwendet — enthalten fuer Debug-Logging).
  Map<String, dynamic> toJson() => {
        'success': success,
        if (error != null) 'error': error,
        'restoredKeys': restoredKeys,
        'skippedKeys': skippedKeys,
      };
}

