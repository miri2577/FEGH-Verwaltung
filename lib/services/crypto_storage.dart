import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;

class EncryptedRecord {
  final int version;
  final String algorithm;
  final String nonce;
  final Map<String, dynamic> aad;
  final String ciphertext;
  final String tag;
  final WrappedDEK dekWrapped;

  EncryptedRecord({
    required this.version,
    required this.algorithm,
    required this.nonce,
    required this.aad,
    required this.ciphertext,
    required this.tag,
    required this.dekWrapped,
  });

  Map<String, dynamic> toJson() {
    return {
      'v': version,
      'alg': algorithm,
      'nonce': nonce,
      'aad': aad,
      'ciphertext': ciphertext,
      'tag': tag,
      'dekWrapped': dekWrapped.toJson(),
    };
  }

  factory EncryptedRecord.fromJson(Map<String, dynamic> json) {
    return EncryptedRecord(
      version: json['v'],
      algorithm: json['alg'],
      nonce: json['nonce'],
      aad: Map<String, dynamic>.from(json['aad']),
      ciphertext: json['ciphertext'],
      tag: json['tag'],
      dekWrapped: WrappedDEK.fromJson(json['dekWrapped']),
    );
  }
}

class WrappedDEK {
  final String algorithm;
  final String nonce;
  final String ciphertext;
  final String tag;

  WrappedDEK({
    required this.algorithm,
    required this.nonce,
    required this.ciphertext,
    required this.tag,
  });

  Map<String, dynamic> toJson() {
    return {
      'alg': algorithm,
      'nonce': nonce,
      'ciphertext': ciphertext,
      'tag': tag,
    };
  }

  factory WrappedDEK.fromJson(Map<String, dynamic> json) {
    return WrappedDEK(
      algorithm: json['alg'],
      nonce: json['nonce'],
      ciphertext: json['ciphertext'],
      tag: json['tag'],
    );
  }
}

class CryptoStorage {
  static const String _mekKey = 'personalverwaltung_mek';
  static const String _algorithm = 'AES-256-GCM';
  static const int _version = 1;

  final FlutterSecureStorage _secureStorage;
  final AesGcm _aes256Gcm;
  Uint8List? _mek;
  String? _externalPassphrase;
  Uint8List? _forcedMek;

  CryptoStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _aes256Gcm = AesGcm.with256bits();

  Future<void> initialize() async {
    await _loadOrCreateMEK();
  }

  Future<void> _loadOrCreateMEK() async {
    try {
      // Verwende forcierten MEK falls gesetzt (z. B. Team-Key)
      if (_forcedMek != null && _forcedMek!.length == 32) {
        _mek = _forcedMek;
        if (kDebugMode) print('✅ PV: Using forced MEK (team/org key)');
        return;
      }

      final mekBase64 = await _secureStorage.read(key: _mekKey);

      if (mekBase64 != null) {
        _mek = base64Decode(mekBase64);
        if (kDebugMode) {
          print('✅ Personalverwaltung: MEK loaded from secure storage');
        }
      } else {
        // Wenn externe Passphrase vorhanden: PBKDF2 ableiten
        if (_externalPassphrase != null && _externalPassphrase!.isNotEmpty) {
          _mek = await _deriveMekFromPassphrase(_externalPassphrase!);
          if (kDebugMode) print('✅ PV: MEK derived from external passphrase');
        } else {
          _mek = _generateRandomBytes(32); // 256-bit key
        }
        await _secureStorage.write(key: _mekKey, value: base64Encode(_mek!));
        if (kDebugMode) {
          print('✅ Personalverwaltung: New MEK generated and stored');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️  MEK operation failed: $e');
        print('🔧 Using development fallback (INSECURE!)');
        _mek = Uint8List.fromList(List.filled(32, 42)); // Development fallback
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
    // Persist salt alongside MEK
    final dir = Directory.systemTemp; // use system temp as fallback; for production use app support dir
    final saltFile = File('${dir.path}/pv_pbkdf2_salt');
    Uint8List salt;
    if (await saltFile.exists()) {
      salt = Uint8List.fromList(base64Decode(await saltFile.readAsString()));
    } else {
      salt = _generateRandomBytes(32);
      await saltFile.writeAsString(base64Encode(salt), flush: true);
    }
    // 100k pseudo-PBKDF2 (HMAC-SHA256 in loop) – konsistent zur Mobile-App
    List<int> result = utf8.encode('sync:$passphrase');
    for (int i = 0; i < 100000; i++) {
      final hmac = crypto.Hmac(crypto.sha256, salt);
      result = hmac.convert(result).bytes.toList();
    }
    return Uint8List.fromList(result.take(32).toList());
  }

  Future<String> encryptJson(String category, Map<String, dynamic> data) async {
    if (_mek == null) await initialize();

    // Generate Data Encryption Key (DEK)
    final dek = _generateRandomBytes(32);
    final dekNonce = _generateRandomBytes(12);

    // Prepare AAD (Additional Authenticated Data)
    final aad = {
      'category': category,
      'timestamp': DateTime.now().toIso8601String(),
      'version': _version,
    };

    final aadBytes = utf8.encode(json.encode(aad));

    // Encrypt data with DEK
    final dataBytes = utf8.encode(json.encode(data));
    final secretBox = await _aes256Gcm.encrypt(
      dataBytes,
      secretKey: SecretKey(dek),
      nonce: dekNonce,
      aad: aadBytes,
    );

    // Wrap DEK with MEK
    final mekNonce = _generateRandomBytes(12);
    final wrappedDek = await _aes256Gcm.encrypt(
      dek,
      secretKey: SecretKey(_mek!),
      nonce: mekNonce,
    );

    // Create encrypted record
    final encryptedRecord = EncryptedRecord(
      version: _version,
      algorithm: _algorithm,
      nonce: base64Encode(dekNonce),
      aad: aad,
      ciphertext: base64Encode(secretBox.cipherText),
      tag: base64Encode(secretBox.mac.bytes),
      dekWrapped: WrappedDEK(
        algorithm: _algorithm,
        nonce: base64Encode(mekNonce),
        ciphertext: base64Encode(wrappedDek.cipherText),
        tag: base64Encode(wrappedDek.mac.bytes),
      ),
    );

    return json.encode(encryptedRecord.toJson());
  }

  Future<Map<String, dynamic>?> decryptJson(String encryptedData) async {
    if (_mek == null) await initialize();

    try {
      final recordJson = json.decode(encryptedData) as Map<String, dynamic>;
      final record = EncryptedRecord.fromJson(recordJson);

      if (record.version != _version) {
        throw Exception('Unsupported encryption version: ${record.version}');
      }

      // Unwrap DEK
      final wrappedDekBox = SecretBox(
        base64Decode(record.dekWrapped.ciphertext),
        nonce: base64Decode(record.dekWrapped.nonce),
        mac: Mac(base64Decode(record.dekWrapped.tag)),
      );

      final dek = await _aes256Gcm.decrypt(
        wrappedDekBox,
        secretKey: SecretKey(_mek!),
      );

      // Decrypt data
      final dataBox = SecretBox(
        base64Decode(record.ciphertext),
        nonce: base64Decode(record.nonce),
        mac: Mac(base64Decode(record.tag)),
      );

      final aadBytes = utf8.encode(json.encode(record.aad));

      final decryptedBytes = await _aes256Gcm.decrypt(
        dataBox,
        secretKey: SecretKey(dek),
        aad: aadBytes,
      );

      final decryptedJson = utf8.decode(decryptedBytes);
      return json.decode(decryptedJson) as Map<String, dynamic>;

    } catch (e) {
      if (kDebugMode) {
        print('❌ Decryption failed: $e');
      }
      return null;
    }
  }

  Future<bool> rotateMEK() async {
    try {
      final oldMek = _mek;
      _mek = _generateRandomBytes(32);
      await _secureStorage.write(key: _mekKey, value: base64Encode(_mek!));

      if (kDebugMode) {
        print('✅ MEK rotated successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ MEK rotation failed: $e');
      }
      return false;
    }
  }

  Future<bool> deleteMEK() async {
    try {
      await _secureStorage.delete(key: _mekKey);
      _mek = null;
      if (kDebugMode) {
        print('✅ MEK deleted (crypto-erasure completed)');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ MEK deletion failed: $e');
      }
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
}
