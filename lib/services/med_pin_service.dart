import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Verwaltung einer Medikations-PIN pro Mitarbeiter.
///
/// Der PIN wird nie im Klartext gespeichert: PBKDF2-HMAC-SHA256 mit
/// 100k Iterationen und pro-Mitarbeiter-Salt. Speicherung im
/// FlutterSecureStorage (Windows DPAPI, Android Keystore, iOS Keychain).
///
/// Nutzt das Schema `"<saltHex>:<hashHex>"`.
class MedPinService {
  static const _prefix = 'med_pin_v1_';
  static const _iterations = 100000;
  static const _saltLen = 16;
  static const _keyLen = 32;

  final FlutterSecureStorage _storage;

  MedPinService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  String _key(String employeeId) => '$_prefix$employeeId';

  Future<bool> isSet(String employeeId) async {
    final v = await _storage.read(key: _key(employeeId));
    return v != null && v.isNotEmpty;
  }

  Future<void> setPin(String employeeId, String pin) async {
    final salt = _randomBytes(_saltLen);
    final hash = await _pbkdf2(pin, salt);
    await _storage.write(
      key: _key(employeeId),
      value: '${_hex(salt)}:${_hex(hash)}',
    );
  }

  Future<void> removePin(String employeeId) async {
    await _storage.delete(key: _key(employeeId));
  }

  /// Prueft den PIN. Gibt `true` zurueck, wenn er passt oder
  /// wenn fuer diesen Mitarbeiter gar kein PIN hinterlegt ist.
  Future<bool> verifyPin(String employeeId, String pin) async {
    final stored = await _storage.read(key: _key(employeeId));
    if (stored == null || stored.isEmpty) return true;
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final salt = _unhex(parts[0]);
    final expected = parts[1];
    final hash = await _pbkdf2(pin, salt);
    return _constantTimeEq(_hex(hash), expected);
  }

  Future<List<int>> _pbkdf2(String pin, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: _keyLen * 8,
    );
    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    return key.extractBytes();
  }

  List<int> _randomBytes(int n) {
    final r = Random.secure();
    return List<int>.generate(n, (_) => r.nextInt(256));
  }

  String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

  List<int> _unhex(String h) => List.generate(
        h.length ~/ 2,
        (i) => int.parse(h.substring(i * 2, i * 2 + 2), radix: 16),
      );

  bool _constantTimeEq(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
