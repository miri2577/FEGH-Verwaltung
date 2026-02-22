import 'package:flutter/foundation.dart';

enum NotificationType {
  info,
  success,
  warning,
  error,
  reminder,
  approval,
  system
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final String? actionLabel;
  final bool isRead;
  final bool isPersistent;
  final String? relatedEntityId;
  final String? relatedEntityType;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    required this.createdAt,
    this.expiresAt,
    this.data,
    this.actionUrl,
    this.actionLabel,
    this.isRead = false,
    this.isPersistent = true,
    this.relatedEntityId,
    this.relatedEntityType,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? createdAt,
    DateTime? expiresAt,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? actionLabel,
    bool? isRead,
    bool? isPersistent,
    String? relatedEntityId,
    String? relatedEntityType,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      actionLabel: actionLabel ?? this.actionLabel,
      isRead: isRead ?? this.isRead,
      isPersistent: isPersistent ?? this.isPersistent,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'data': data,
      'actionUrl': actionUrl,
      'actionLabel': actionLabel,
      'isRead': isRead,
      'isPersistent': isPersistent,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.info,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      data: json['data'],
      actionUrl: json['actionUrl'],
      actionLabel: json['actionLabel'],
      isRead: json['isRead'] ?? false,
      isPersistent: json['isPersistent'] ?? true,
      relatedEntityId: json['relatedEntityId'],
      relatedEntityType: json['relatedEntityType'],
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isActive => !isExpired;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AppNotification{id: $id, title: $title, type: $type, isRead: $isRead}';
  }
}

class NotificationSettings {
  final bool enableInAppNotifications;
  final bool enablePushNotifications;
  final bool enableEmailNotifications;
  final bool enableSoundNotifications;
  final Map<NotificationType, bool> typeSettings;
  final Map<NotificationPriority, bool> prioritySettings;
  final Duration autoHideDuration;
  final int maxNotificationsInHistory;

  const NotificationSettings({
    this.enableInAppNotifications = true,
    this.enablePushNotifications = false,
    this.enableEmailNotifications = false,
    this.enableSoundNotifications = true,
    this.typeSettings = const {
      NotificationType.info: true,
      NotificationType.success: true,
      NotificationType.warning: true,
      NotificationType.error: true,
      NotificationType.reminder: true,
      NotificationType.approval: true,
      NotificationType.system: true,
    },
    this.prioritySettings = const {
      NotificationPriority.low: true,
      NotificationPriority.normal: true,
      NotificationPriority.high: true,
      NotificationPriority.urgent: true,
    },
    this.autoHideDuration = const Duration(seconds: 5),
    this.maxNotificationsInHistory = 100,
  });

  NotificationSettings copyWith({
    bool? enableInAppNotifications,
    bool? enablePushNotifications,
    bool? enableEmailNotifications,
    bool? enableSoundNotifications,
    Map<NotificationType, bool>? typeSettings,
    Map<NotificationPriority, bool>? prioritySettings,
    Duration? autoHideDuration,
    int? maxNotificationsInHistory,
  }) {
    return NotificationSettings(
      enableInAppNotifications: enableInAppNotifications ?? this.enableInAppNotifications,
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      enableEmailNotifications: enableEmailNotifications ?? this.enableEmailNotifications,
      enableSoundNotifications: enableSoundNotifications ?? this.enableSoundNotifications,
      typeSettings: typeSettings ?? this.typeSettings,
      prioritySettings: prioritySettings ?? this.prioritySettings,
      autoHideDuration: autoHideDuration ?? this.autoHideDuration,
      maxNotificationsInHistory: maxNotificationsInHistory ?? this.maxNotificationsInHistory,
    );
  }

  bool shouldShowNotification(AppNotification notification) {
    return enableInAppNotifications &&
        (typeSettings[notification.type] ?? true) &&
        (prioritySettings[notification.priority] ?? true);
  }

  Map<String, dynamic> toJson() {
    return {
      'enableInAppNotifications': enableInAppNotifications,
      'enablePushNotifications': enablePushNotifications,
      'enableEmailNotifications': enableEmailNotifications,
      'enableSoundNotifications': enableSoundNotifications,
      'typeSettings': typeSettings.map((key, value) => MapEntry(key.toString().split('.').last, value)),
      'prioritySettings': prioritySettings.map((key, value) => MapEntry(key.toString().split('.').last, value)),
      'autoHideDurationMs': autoHideDuration.inMilliseconds,
      'maxNotificationsInHistory': maxNotificationsInHistory,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enableInAppNotifications: json['enableInAppNotifications'] ?? true,
      enablePushNotifications: json['enablePushNotifications'] ?? false,
      enableEmailNotifications: json['enableEmailNotifications'] ?? false,
      enableSoundNotifications: json['enableSoundNotifications'] ?? true,
      typeSettings: (json['typeSettings'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              NotificationType.values.firstWhere(
                (e) => e.toString().split('.').last == key,
                orElse: () => NotificationType.info,
              ),
              value as bool,
            ),
          ) ??
          const {
            NotificationType.info: true,
            NotificationType.success: true,
            NotificationType.warning: true,
            NotificationType.error: true,
            NotificationType.reminder: true,
            NotificationType.approval: true,
            NotificationType.system: true,
          },
      prioritySettings: (json['prioritySettings'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              NotificationPriority.values.firstWhere(
                (e) => e.toString().split('.').last == key,
                orElse: () => NotificationPriority.normal,
              ),
              value as bool,
            ),
          ) ??
          const {
            NotificationPriority.low: true,
            NotificationPriority.normal: true,
            NotificationPriority.high: true,
            NotificationPriority.urgent: true,
          },
      autoHideDuration: Duration(milliseconds: json['autoHideDurationMs'] ?? 5000),
      maxNotificationsInHistory: json['maxNotificationsInHistory'] ?? 100,
    );
  }
}