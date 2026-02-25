import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/ui_customization.dart';
import '../services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return AppSettingsNotifier(settingsService);
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsService _settingsService;

  AppSettingsNotifier(this._settingsService) : super(AppSettings.defaultSettings()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _settingsService.initialize();
      state = _settingsService.settings;
      if (kDebugMode) {
        print('✅ Settings provider initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Settings provider initialization failed: $e');
      }
    }
  }

  Future<bool> updateHiDriveCredentials(String username, String password) async {
    final success = await _settingsService.updateHiDriveCredentials(username, password);
    if (success) {
      state = _settingsService.settings;
    }
    return success;
  }

  Future<bool> enableCloudSync(bool enabled) async {
    final success = await _settingsService.enableCloudSync(enabled);
    if (success) {
      state = _settingsService.settings;
    }
    return success;
  }

  Future<bool> updateSyncSettings({
    bool? autoSyncOnStartup,
    bool? autoSyncOnChanges,
    int? syncIntervalMinutes,
  }) async {
    final success = await _settingsService.updateSyncSettings(
      autoSyncOnStartup: autoSyncOnStartup,
      autoSyncOnChanges: autoSyncOnChanges,
      syncIntervalMinutes: syncIntervalMinutes,
    );
    if (success) {
      state = _settingsService.settings;
    }
    return success;
  }

  Future<bool> updateLastSyncTime(DateTime syncTime) async {
    final success = await _settingsService.updateLastSyncTime(syncTime);
    if (success) {
      state = _settingsService.settings;
    }
    return success;
  }

  Future<bool> updateUISettings({
    String? language,
    String? dateFormat,
    String? timeFormat,
    bool? enableDarkMode,
    bool? enableNotifications,
  }) async {
    final success = await _settingsService.updateUISettings(
      language: language,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      enableDarkMode: enableDarkMode,
      enableNotifications: enableNotifications,
    );
    if (success) {
      state = _settingsService.settings;
    }
    return success;
  }

  Future<bool> updateUICustomization(UICustomization uiCustomization) async {
    final success = await _settingsService.updateUICustomization(uiCustomization);
    if (success) {
      state = _settingsService.settings;
    }
    return success;
  }

  Future<bool> updateWindowSettings({
    double? windowWidth,
    double? windowHeight,
    bool? maximizeWindow,
  }) async {
    final success = await _settingsService.updateWindowSettings(
      windowWidth: windowWidth,
      windowHeight: windowHeight,
      maximizeWindow: maximizeWindow,
    );
    if (success) {
      state = _settingsService.settings;
    }
    return success;
  }

  Future<bool> clearCredentials() async {
    final success = await _settingsService.clearCredentials();
    if (success) {
      state = _settingsService.settings;
    }
    return success;
  }

  Future<bool> resetSettings() async {
    final success = await _settingsService.resetSettings();
    if (success) {
      state = _settingsService.settings;
    }
    return success;
  }
}

// Convenience providers for specific settings
final hidriveCredentialsProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.hasHiDriveCredentials;
});

final cloudSyncEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.enableCloudSync;
});

final cloudSyncReadyProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.isCloudSyncReady;
});

final darkModeProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.enableDarkMode;
});

final uiCustomizationProvider = Provider<UICustomization>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.uiCustomization;
});