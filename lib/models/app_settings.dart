import 'package:flutter/foundation.dart';
import 'ui_customization.dart';

class AppSettings {
  final String? hidriveUsername;
  final String? hidrivePassword;
  final String? userRole; // org_admin, org_auditor, team_lead, team_member, pv_admin
  final bool enableCloudSync;
  final bool autoSyncOnStartup;
  final bool autoSyncOnChanges;
  final int syncIntervalMinutes;
  final String? lastSyncTime;
  final String? organizationId;
  final String? rootSubdirectory; // optionaler Root-Unterordner (z. B. "Gemeinsam/Eingliederungshilfe")
  final bool enableNotifications;
  final bool auditorCanViewDocs;
  final String language;
  final String dateFormat;
  final String timeFormat;
  final bool enableDarkMode;
  final double windowWidth;
  final double windowHeight;
  final bool maximizeWindow;
  final UICustomization uiCustomization;
  final DateTime updatedAt;

  AppSettings({
    this.hidriveUsername,
    this.hidrivePassword,
    this.userRole,
    this.enableCloudSync = false,
    this.autoSyncOnStartup = true,
    this.autoSyncOnChanges = true,
    this.syncIntervalMinutes = 15,
    this.lastSyncTime,
    this.organizationId,
    this.rootSubdirectory,
    this.enableNotifications = true,
    this.auditorCanViewDocs = false,
    this.language = 'de',
    this.dateFormat = 'dd.MM.yyyy',
    this.timeFormat = 'HH:mm',
    this.enableDarkMode = false,
    this.windowWidth = 1400,
    this.windowHeight = 900,
    this.maximizeWindow = false,
    this.uiCustomization = const UICustomization(),
    required this.updatedAt,
  });

  bool get hasHiDriveCredentials =>
      hidriveUsername?.isNotEmpty == true && hidrivePassword?.isNotEmpty == true;

  bool get isCloudSyncReady => hasHiDriveCredentials && enableCloudSync;

  Map<String, dynamic> toJson() {
    return {
      'hidriveUsername': hidriveUsername,
      'hidrivePassword': hidrivePassword,
      'userRole': userRole,
      'enableCloudSync': enableCloudSync,
      'autoSyncOnStartup': autoSyncOnStartup,
      'autoSyncOnChanges': autoSyncOnChanges,
      'syncIntervalMinutes': syncIntervalMinutes,
      'lastSyncTime': lastSyncTime,
      'organizationId': organizationId,
      'rootSubdirectory': rootSubdirectory,
      'enableNotifications': enableNotifications,
      'auditorCanViewDocs': auditorCanViewDocs,
      'language': language,
      'dateFormat': dateFormat,
      'timeFormat': timeFormat,
      'enableDarkMode': enableDarkMode,
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'maximizeWindow': maximizeWindow,
      'uiCustomization': uiCustomization.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      hidriveUsername: json['hidriveUsername'],
      hidrivePassword: json['hidrivePassword'],
      userRole: json['userRole'],
      enableCloudSync: json['enableCloudSync'] ?? false,
      autoSyncOnStartup: json['autoSyncOnStartup'] ?? true,
      autoSyncOnChanges: json['autoSyncOnChanges'] ?? true,
      syncIntervalMinutes: json['syncIntervalMinutes'] ?? 15,
      lastSyncTime: json['lastSyncTime'],
      organizationId: json['organizationId'],
      rootSubdirectory: json['rootSubdirectory'],
      enableNotifications: json['enableNotifications'] ?? true,
      auditorCanViewDocs: json['auditorCanViewDocs'] ?? false,
      language: json['language'] ?? 'de',
      dateFormat: json['dateFormat'] ?? 'dd.MM.yyyy',
      timeFormat: json['timeFormat'] ?? 'HH:mm',
      enableDarkMode: json['enableDarkMode'] ?? false,
      windowWidth: json['windowWidth']?.toDouble() ?? 1400,
      windowHeight: json['windowHeight']?.toDouble() ?? 900,
      maximizeWindow: json['maximizeWindow'] ?? false,
      uiCustomization: json['uiCustomization'] != null
          ? UICustomization.fromJson(json['uiCustomization'] as Map<String, dynamic>)
          : const UICustomization(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  factory AppSettings.defaultSettings() {
    return AppSettings(
      userRole: 'org_admin',
      updatedAt: DateTime.now(),
    );
  }

  AppSettings copyWith({
    String? hidriveUsername,
    String? hidrivePassword,
    String? userRole,
    bool? enableCloudSync,
    bool? autoSyncOnStartup,
    bool? autoSyncOnChanges,
    int? syncIntervalMinutes,
    String? lastSyncTime,
    String? organizationId,
    String? rootSubdirectory,
    bool? enableNotifications,
    bool? auditorCanViewDocs,
    String? language,
    String? dateFormat,
    String? timeFormat,
    bool? enableDarkMode,
    double? windowWidth,
    double? windowHeight,
    bool? maximizeWindow,
    UICustomization? uiCustomization,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      hidriveUsername: hidriveUsername ?? this.hidriveUsername,
      hidrivePassword: hidrivePassword ?? this.hidrivePassword,
      userRole: userRole ?? this.userRole,
      enableCloudSync: enableCloudSync ?? this.enableCloudSync,
      autoSyncOnStartup: autoSyncOnStartup ?? this.autoSyncOnStartup,
      autoSyncOnChanges: autoSyncOnChanges ?? this.autoSyncOnChanges,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      organizationId: organizationId ?? this.organizationId,
      rootSubdirectory: rootSubdirectory ?? this.rootSubdirectory,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      auditorCanViewDocs: auditorCanViewDocs ?? this.auditorCanViewDocs,
      language: language ?? this.language,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      enableDarkMode: enableDarkMode ?? this.enableDarkMode,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      maximizeWindow: maximizeWindow ?? this.maximizeWindow,
      uiCustomization: uiCustomization ?? this.uiCustomization,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() => 'AppSettings(hidriveUser: $hidriveUsername, cloudSync: $enableCloudSync)';
}
