import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/ui_customization.dart';

class SettingsService {
  static const String _settingsKey = 'personalverwaltung_settings';
  static const String _credentialsKey = 'personalverwaltung_credentials';
  static const String _devCredentialsPrefsKey = 'personalverwaltung_credentials_dev_fallback';

  final FlutterSecureStorage _secureStorage;
  late final SharedPreferences _prefs;
  AppSettings? _currentSettings;

  SettingsService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();

      if (kDebugMode) {
        print('✅ Settings service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize settings service: $e');
      }
      _currentSettings = AppSettings.defaultSettings();
    }
  }


  Future<void> _loadSettings() async {
    try {
      // Load non-sensitive settings from SharedPreferences
      final settingsJson = _prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsData = json.decode(settingsJson) as Map<String, dynamic>;

        // Load sensitive credentials separately from secure storage
        final credentials = await _loadCredentials();

        _currentSettings = AppSettings.fromJson({
          ...settingsData,
          ...credentials,
        });
      } else {
        _currentSettings = AppSettings.defaultSettings();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load settings: $e');
      }
      _currentSettings = AppSettings.defaultSettings();
    }
  }

  Future<Map<String, dynamic>> _loadCredentials() async {
    try {
      final credentialsJson = await _secureStorage.read(key: _credentialsKey);

      if (credentialsJson != null) {
        return json.decode(credentialsJson) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load credentials: $e');
      }
    }
    // DEV-Fallback aus SharedPreferences lesen
    try {
      final prefsJson = _prefs.getString(_devCredentialsPrefsKey);
      if (prefsJson != null && prefsJson.isNotEmpty) {
        if (kDebugMode) print('ℹ️ Using DEV fallback credentials from SharedPreferences');
        return json.decode(prefsJson) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  Future<bool> saveSettings(AppSettings settings) async {
    try {
      // Separate sensitive and non-sensitive data
      final settingsData = settings.toJson();
      final credentials = {
        'hidriveUsername': settingsData.remove('hidriveUsername'),
        'hidrivePassword': settingsData.remove('hidrivePassword'),
      };

      // Save non-sensitive settings to SharedPreferences
      await _prefs.setString(_settingsKey, json.encode(settingsData));

      // Save sensitive credentials to secure storage (mit DEV-Fallback)
      bool credSaved = false;
      try {
        await _secureStorage.write(
          key: _credentialsKey,
          value: json.encode(credentials),
        );
        credSaved = true;
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ SecureStorage write failed, using DEV fallback: $e');
        }
        await _prefs.setString(_devCredentialsPrefsKey, json.encode(credentials));
        credSaved = true;
      }

      _currentSettings = settings;

      if (kDebugMode) {
        print('✅ Settings saved successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save settings: $e');
      }
      return false;
    }
  }

  Future<bool> updateHiDriveCredentials(String username, String password) async {
    if (_currentSettings == null) return false;

    final updatedSettings = _currentSettings!.copyWith(
      hidriveUsername: username,
      hidrivePassword: password,
      updatedAt: DateTime.now(),
    );

    return await saveSettings(updatedSettings);
  }

  Future<bool> enableCloudSync(bool enabled) async {
    if (_currentSettings == null) return false;

    final updatedSettings = _currentSettings!.copyWith(
      enableCloudSync: enabled,
      updatedAt: DateTime.now(),
    );

    return await saveSettings(updatedSettings);
  }

  Future<bool> updateSyncSettings({
    bool? autoSyncOnStartup,
    bool? autoSyncOnChanges,
    int? syncIntervalMinutes,
  }) async {
    if (_currentSettings == null) return false;

    final updatedSettings = _currentSettings!.copyWith(
      autoSyncOnStartup: autoSyncOnStartup,
      autoSyncOnChanges: autoSyncOnChanges,
      syncIntervalMinutes: syncIntervalMinutes,
      updatedAt: DateTime.now(),
    );

    return await saveSettings(updatedSettings);
  }

  Future<bool> updateLastSyncTime(DateTime syncTime) async {
    if (_currentSettings == null) return false;

    final updatedSettings = _currentSettings!.copyWith(
      lastSyncTime: syncTime.toIso8601String(),
      updatedAt: DateTime.now(),
    );

    return await saveSettings(updatedSettings);
  }

  Future<bool> updateUISettings({
    String? language,
    String? dateFormat,
    String? timeFormat,
    bool? enableDarkMode,
    bool? enableNotifications,
  }) async {
    if (_currentSettings == null) return false;

    final updatedSettings = _currentSettings!.copyWith(
      language: language,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      enableDarkMode: enableDarkMode,
      enableNotifications: enableNotifications,
      updatedAt: DateTime.now(),
    );

    return await saveSettings(updatedSettings);
  }

  Future<bool> updateUICustomization(UICustomization uiCustomization) async {
    if (_currentSettings == null) return false;

    final updatedSettings = _currentSettings!.copyWith(
      uiCustomization: uiCustomization,
      updatedAt: DateTime.now(),
    );

    return await saveSettings(updatedSettings);
  }

  Future<bool> updateWindowSettings({
    double? windowWidth,
    double? windowHeight,
    bool? maximizeWindow,
  }) async {
    if (_currentSettings == null) return false;

    final updatedSettings = _currentSettings!.copyWith(
      windowWidth: windowWidth,
      windowHeight: windowHeight,
      maximizeWindow: maximizeWindow,
      updatedAt: DateTime.now(),
    );

    return await saveSettings(updatedSettings);
  }

  Future<bool> clearCredentials() async {
    try {
      await _secureStorage.delete(key: _credentialsKey);

      if (_currentSettings != null) {
        final updatedSettings = _currentSettings!.copyWith(
          hidriveUsername: null,
          hidrivePassword: null,
          enableCloudSync: false,
          updatedAt: DateTime.now(),
        );

        await saveSettings(updatedSettings);
      }

      if (kDebugMode) {
        print('✅ Credentials cleared');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear credentials: $e');
      }
      return false;
    }
  }

  Future<bool> resetSettings() async {
    try {
      await _prefs.remove(_settingsKey);
      await _secureStorage.delete(key: _credentialsKey);
      _currentSettings = AppSettings.defaultSettings();

      if (kDebugMode) {
        print('✅ Settings reset to defaults');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to reset settings: $e');
      }
      return false;
    }
  }

  // Getters
  AppSettings get settings => _currentSettings ?? AppSettings.defaultSettings();

  bool get hasHiDriveCredentials => settings.hasHiDriveCredentials;

  bool get isCloudSyncReady => settings.isCloudSyncReady;

  String? get hidriveUsername => settings.hidriveUsername;

  String? get hidrivePassword => settings.hidrivePassword;

  bool get cloudSyncEnabled => settings.enableCloudSync;

  bool get autoSyncOnStartup => settings.autoSyncOnStartup;

  bool get autoSyncOnChanges => settings.autoSyncOnChanges;

  int get syncIntervalMinutes => settings.syncIntervalMinutes;

  String? get lastSyncTime => settings.lastSyncTime;

  bool get enableNotifications => settings.enableNotifications;

  String get language => settings.language;

  String get dateFormat => settings.dateFormat;

  String get timeFormat => settings.timeFormat;

  bool get enableDarkMode => settings.enableDarkMode;

  double get windowWidth => settings.windowWidth;

  double get windowHeight => settings.windowHeight;

  bool get maximizeWindow => settings.maximizeWindow;

  bool get isInitialized => _currentSettings != null;
}
