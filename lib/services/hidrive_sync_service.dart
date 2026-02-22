import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'hidrive_webdav_client.dart';
import 'crypto_storage.dart';

class SyncManifest {
  final Map<String, ManifestEntry> entries;
  final DateTime lastSync;
  final String version;

  SyncManifest({
    required this.entries,
    required this.lastSync,
    this.version = '1.0',
  });

  Map<String, dynamic> toJson() {
    return {
      'entries': entries.map((k, v) => MapEntry(k, v.toJson())),
      'lastSync': lastSync.toIso8601String(),
      'version': version,
    };
  }

  factory SyncManifest.fromJson(Map<String, dynamic> json) {
    return SyncManifest(
      entries: (json['entries'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, ManifestEntry.fromJson(v)),
      ),
      lastSync: DateTime.parse(json['lastSync']),
      version: json['version'] ?? '1.0',
    );
  }

  SyncManifest copyWith({
    Map<String, ManifestEntry>? entries,
    DateTime? lastSync,
    String? version,
  }) {
    return SyncManifest(
      entries: entries ?? this.entries,
      lastSync: lastSync ?? this.lastSync,
      version: version ?? this.version,
    );
  }
}

class ManifestEntry {
  final String uuid;
  final String category;
  final DateTime created;
  final DateTime modified;
  final int size;
  final String checksum;

  ManifestEntry({
    required this.uuid,
    required this.category,
    required this.created,
    required this.modified,
    required this.size,
    required this.checksum,
  });

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'category': category,
      'created': created.toIso8601String(),
      'modified': modified.toIso8601String(),
      'size': size,
      'checksum': checksum,
    };
  }

  factory ManifestEntry.fromJson(Map<String, dynamic> json) {
    return ManifestEntry(
      uuid: json['uuid'],
      category: json['category'],
      created: DateTime.parse(json['created']),
      modified: DateTime.parse(json['modified']),
      size: json['size'],
      checksum: json['checksum'],
    );
  }
}

class HiDriveSyncService {
  final String _syncFolder; // e.g., eingliederungshilfe/organizations/<org>/administration
  static const String _manifestFile = 'manifest.json.enc';

  final HiDriveWebDAVClient _client;
  final CryptoStorage _cryptoStorage;
  final Uuid _uuid = const Uuid();

  SyncManifest? _localManifest;
  SyncManifest? _remoteManifest;

  HiDriveSyncService({
    required HiDriveWebDAVClient client,
    required CryptoStorage cryptoStorage,
    String? basePath,
  })  : _client = client,
        _cryptoStorage = cryptoStorage,
        _syncFolder = basePath ?? 'personalverwaltung_encrypted';

  Future<bool> initialize() async {
    try {
      // Ensure sync folder exists
      final folderResult = await _client.exists(_syncFolder);
      if (folderResult.success && !folderResult.data!) {
        await _client.mkcol(_syncFolder);
        if (kDebugMode) {
          print('✅ Created sync folder: $_syncFolder');
        }
      }

      // Load local manifest
      await _loadLocalManifest();

      // Load remote manifest
      await _loadRemoteManifest();

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize HiDrive sync: $e');
      }
      return false;
    }
  }

  Future<String?> saveRecord(String category, Map<String, dynamic> data) async {
    try {
      final uuid = _uuid.v4();
      final encryptedData = await _cryptoStorage.encryptJson(category, data);
      final dataBytes = utf8.encode(encryptedData);

      // Upload to HiDrive
      final filePath = '$_syncFolder/$uuid.bin';
      final uploadResult = await _client.put(filePath, dataBytes);

      if (uploadResult.success) {
        // Update local manifest
        final entry = ManifestEntry(
          uuid: uuid,
          category: category,
          created: DateTime.now(),
          modified: DateTime.now(),
          size: dataBytes.length,
          checksum: _calculateChecksum(dataBytes),
        );

        _localManifest = (_localManifest ?? _createEmptyManifest()).copyWith(
          entries: {
            ...(_localManifest?.entries ?? {}),
            uuid: entry,
          },
          lastSync: DateTime.now(),
        );

        // Save updated manifest
        await _saveLocalManifest();
        await _uploadManifest();

        if (kDebugMode) {
          print('✅ Saved $category record: $uuid');
        }
        return uuid;
      } else {
        if (kDebugMode) {
          print('❌ Failed to upload record: ${uploadResult.error}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving record: $e');
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> loadRecord(String uuid) async {
    try {
      final filePath = '$_syncFolder/$uuid.bin';
      final downloadResult = await _client.get(filePath);

      if (downloadResult.success) {
        final encryptedData = utf8.decode(downloadResult.data!);
        return await _cryptoStorage.decryptJson(encryptedData);
      } else {
        if (kDebugMode) {
          print('❌ Failed to download record $uuid: ${downloadResult.error}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading record $uuid: $e');
      }
      return null;
    }
  }

  Future<bool> deleteRecord(String uuid) async {
    try {
      final filePath = '$_syncFolder/$uuid.bin';
      final deleteResult = await _client.delete(filePath);

      if (deleteResult.success) {
        // Update local manifest
        final updatedEntries = Map<String, ManifestEntry>.from(
          _localManifest?.entries ?? {},
        );
        updatedEntries.remove(uuid);

        _localManifest = (_localManifest ?? _createEmptyManifest()).copyWith(
          entries: updatedEntries,
          lastSync: DateTime.now(),
        );

        await _saveLocalManifest();
        await _uploadManifest();

        if (kDebugMode) {
          print('✅ Deleted record: $uuid');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Failed to delete record $uuid: ${deleteResult.error}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting record $uuid: $e');
      }
      return false;
    }
  }

  Future<List<String>> getRecordsByCategory(String category) async {
    final manifest = _localManifest ?? _createEmptyManifest();
    return manifest.entries.values
        .where((entry) => entry.category == category)
        .map((entry) => entry.uuid)
        .toList();
  }

  Future<bool> syncFromRemote() async {
    try {
      await _loadRemoteManifest();

      if (_remoteManifest == null) {
        if (kDebugMode) {
          print('ℹ️  No remote manifest found');
        }
        return true;
      }

      final localManifest = _localManifest ?? _createEmptyManifest();
      int downloadedCount = 0;

      // Download missing records
      for (final entry in _remoteManifest!.entries.values) {
        if (!localManifest.entries.containsKey(entry.uuid)) {
          final data = await loadRecord(entry.uuid);
          if (data != null) {
            downloadedCount++;
            if (kDebugMode) {
              print('⬇️  Downloaded record: ${entry.uuid} (${entry.category})');
            }
          }
        }
      }

      // Update local manifest
      _localManifest = localManifest.copyWith(
        entries: {
          ...localManifest.entries,
          ..._remoteManifest!.entries,
        },
        lastSync: DateTime.now(),
      );

      await _saveLocalManifest();

      if (kDebugMode) {
        print('✅ Sync completed: $downloadedCount records downloaded');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sync from remote failed: $e');
      }
      return false;
    }
  }

  Future<bool> syncToRemote() async {
    try {
      await _loadRemoteManifest();

      final localManifest = _localManifest ?? _createEmptyManifest();
      final remoteManifest = _remoteManifest ?? _createEmptyManifest();
      int uploadedCount = 0;

      // Upload missing records
      for (final entry in localManifest.entries.values) {
        if (!remoteManifest.entries.containsKey(entry.uuid)) {
          // Record exists locally but not remotely, upload it
          final data = await loadRecord(entry.uuid);
          if (data != null) {
            uploadedCount++;
            if (kDebugMode) {
              print('⬆️  Uploaded record: ${entry.uuid} (${entry.category})');
            }
          }
        }
      }

      await _uploadManifest();

      if (kDebugMode) {
        print('✅ Upload completed: $uploadedCount records uploaded');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sync to remote failed: $e');
      }
      return false;
    }
  }

  Future<File> _localManifestFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/sync_manifest.json');
  }

  Future<void> _loadLocalManifest() async {
    try {
      final file = await _localManifestFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _localManifest = SyncManifest.fromJson(json);
        if (kDebugMode) {
          print('✅ Local manifest loaded: ${_localManifest!.entries.length} entries');
        }
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to load local manifest: $e');
      }
    }
    _localManifest = _createEmptyManifest();
  }

  Future<void> _saveLocalManifest() async {
    try {
      final file = await _localManifestFile();
      final content = jsonEncode(_localManifest?.toJson() ?? _createEmptyManifest().toJson());
      await file.writeAsString(content, flush: true);
      if (kDebugMode) {
        print('💾 Local manifest saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save local manifest: $e');
      }
    }
  }

  Future<void> _loadRemoteManifest() async {
    try {
      final manifestPath = '$_syncFolder/$_manifestFile';
      final downloadResult = await _client.get(manifestPath);

      if (downloadResult.success) {
        final encryptedData = utf8.decode(downloadResult.data!);
        final manifestData = await _cryptoStorage.decryptJson(encryptedData);

        if (manifestData != null) {
          _remoteManifest = SyncManifest.fromJson(manifestData);
          if (kDebugMode) {
            print('✅ Remote manifest loaded: ${_remoteManifest!.entries.length} entries');
          }
        }
      } else if (downloadResult.statusCode == 404) {
        if (kDebugMode) {
          print('ℹ️  No remote manifest found (first sync)');
        }
        _remoteManifest = null;
      } else {
        if (kDebugMode) {
          print('❌ Failed to load remote manifest: ${downloadResult.error}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading remote manifest: $e');
      }
    }
  }

  Future<void> _uploadManifest() async {
    try {
      final manifest = _localManifest ?? _createEmptyManifest();
      final encryptedData = await _cryptoStorage.encryptJson('manifest', manifest.toJson());
      final dataBytes = utf8.encode(encryptedData);

      final manifestPath = '$_syncFolder/$_manifestFile';
      final uploadResult = await _client.put(manifestPath, dataBytes);

      if (uploadResult.success) {
        if (kDebugMode) {
          print('✅ Manifest uploaded');
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to upload manifest: ${uploadResult.error}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading manifest: $e');
      }
    }
  }

  SyncManifest _createEmptyManifest() {
    return SyncManifest(
      entries: {},
      lastSync: DateTime.now(),
    );
  }

  String _calculateChecksum(Uint8List data) {
    return crypto.sha256.convert(data).toString();
  }

  SyncManifest? get localManifest => _localManifest;
  SyncManifest? get remoteManifest => _remoteManifest;

  int get localRecordCount => _localManifest?.entries.length ?? 0;
  int get remoteRecordCount => _remoteManifest?.entries.length ?? 0;

  DateTime? get lastSyncTime => _localManifest?.lastSync;
}
