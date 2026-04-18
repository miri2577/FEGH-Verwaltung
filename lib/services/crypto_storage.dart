import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:fegh_crypto/fegh_crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Verwaltungs-CryptoStorage: MEK-Management + Delegation an `fegh_crypto`.
///
/// Wire-Format (EncryptedRecord) ist bit-identisch zur FEGH-Dokumentation.
/// Die konkrete AES-GCM + DEK-Wrapping-Logik liegt im Shared-Package
/// `fegh_crypto`, sodass beide Apps das gleiche Format lesen/schreiben.
class CryptoStorage {
  /// Muss mit Dokumentations-App uebereinstimmen (dort: storageKey = 'app_mek')
  static const String _mekKey = 'app_mek';

  final FlutterSecureStorage _secureStorage;
  final FeghCrypto _crypto;
  Uint8List? _mek;
  String? _externalPassphrase;
  Uint8List? _forcedMek;

  CryptoStorage({FlutterSecureStorage? secureStorage, FeghCrypto? cryptoImpl})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _crypto = cryptoImpl ?? FeghCrypto();

  Future<void> initialize() async {
    await _loadOrCreateMEK();
  }

  Future<void> _loadOrCreateMEK() async {
    try {
      if (_forcedMek != null && _forcedMek!.length == 32) {
        _mek = _forcedMek;
        if (kDebugMode) debugPrint('✅ PV: Using forced MEK (team/org key)');
        return;
      }

      final mekBase64 = await _secureStorage.read(key: _mekKey);
      if (mekBase64 != null) {
        _mek = base64Decode(mekBase64);
        if (kDebugMode) debugPrint('✅ PV: MEK loaded from secure storage');
      } else {
        if (_externalPassphrase != null && _externalPassphrase!.isNotEmpty) {
          _mek = await _deriveMekFromPassphrase(_externalPassphrase!);
          if (kDebugMode) debugPrint('✅ PV: MEK derived from external passphrase');
        } else {
          _mek = _generateRandomBytes(32);
        }
        await _secureStorage.write(key: _mekKey, value: base64Encode(_mek!));
        if (kDebugMode) debugPrint('✅ PV: New MEK generated and stored');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️  MEK operation failed: $e');
        debugPrint('🔧 Using development fallback (INSECURE!)');
        _mek = Uint8List.fromList(List.filled(32, 42));
      } else {
        throw Exception('Failed to initialize encryption: $e');
      }
    }
  }

  void setExternalPassphrase(String? pass) {
    _externalPassphrase = (pass != null && pass.isNotEmpty) ? pass : null;
  }

  void setExternalMEK(Uint8List? mek) {
    _forcedMek = mek;
  }

  Future<Uint8List> _deriveMekFromPassphrase(String passphrase) async {
    final dir = Directory.systemTemp;
    final saltFile = File('${dir.path}/pv_pbkdf2_salt');
    Uint8List salt;
    if (await saltFile.exists()) {
      salt = Uint8List.fromList(base64Decode(await saltFile.readAsString()));
    } else {
      salt = _generateRandomBytes(32);
      await saltFile.writeAsString(base64Encode(salt), flush: true);
    }
    List<int> result = utf8.encode('sync:$passphrase');
    for (int i = 0; i < 100000; i++) {
      final hmac = crypto.Hmac(crypto.sha256, salt);
      result = hmac.convert(result).bytes.toList();
    }
    return Uint8List.fromList(result.take(32).toList());
  }

  // ── High-Level API: JSON ⇄ verschluesselter String ──────────────

  /// Verschluesselt eine JSON-Map und liefert den serialisierten Record als String.
  Future<String> encryptJson(String category, Map<String, dynamic> data) async {
    if (_mek == null) await initialize();

    final aad = {
      'schema': category,
      'ts': DateTime.now().toUtc().toIso8601String(),
      'version': 1,
    };

    final record = await _crypto.encryptRecord(
      plaintext: utf8.encode(json.encode(data)),
      mek: _mek!,
      aad: aad,
    );
    return record.toJsonString();
  }

  /// Entschluesselt einen Record-String zurueck in die JSON-Map.
  Future<Map<String, dynamic>?> decryptJson(String encryptedData) async {
    if (_mek == null) await initialize();

    try {
      final record = EncryptedRecord.fromJsonString(encryptedData);
      if (record.version != 1) {
        throw Exception('Unsupported encryption version: ${record.version}');
      }
      final plain = await _crypto.decryptRecord(record: record, mek: _mek!);
      return json.decode(utf8.decode(plain)) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Decryption failed: $e');
      return null;
    }
  }

  // ── MEK-Lifecycle ────────────────────────────────────────────────

  Future<bool> rotateMEK() async {
    try {
      _mek = _generateRandomBytes(32);
      await _secureStorage.write(key: _mekKey, value: base64Encode(_mek!));
      if (kDebugMode) debugPrint('✅ MEK rotated successfully');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ MEK rotation failed: $e');
      return false;
    }
  }

  Future<bool> deleteMEK() async {
    try {
      await _secureStorage.delete(key: _mekKey);
      _mek = null;
      if (kDebugMode) debugPrint('✅ MEK deleted (crypto-erasure completed)');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ MEK deletion failed: $e');
      return false;
    }
  }

  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  bool get isInitialized => _mek != null;

  /// Aktueller MEK (nur fuer Admin/Backup-Flows).
  Uint8List? get mek => _mek;
}
