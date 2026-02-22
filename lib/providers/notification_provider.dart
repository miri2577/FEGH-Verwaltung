import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

// Notification Service Provider
final notificationServiceProvider = ChangeNotifierProvider<NotificationService>((ref) {
  final service = NotificationService();
  service.initialize();
  return service;
});

// All notifications
final notificationsProvider = Provider<List<AppNotification>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.notifications;
});

// Unread notifications
final unreadNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.unreadNotifications;
});

// Active notifications (not expired)
final activeNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.activeNotifications;
});

// Unread count
final unreadNotificationCountProvider = Provider<int>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.unreadCount;
});

// Notification settings
final notificationSettingsProvider = Provider<NotificationSettings>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.settings;
});

// Filtered notifications by type
final notificationsByTypeProvider = Provider.family<List<AppNotification>, NotificationType>((ref, type) {
  final service = ref.watch(notificationServiceProvider);
  return service.getNotificationsByType(type);
});

// Filtered notifications by priority
final notificationsByPriorityProvider = Provider.family<List<AppNotification>, NotificationPriority>((ref, priority) {
  final service = ref.watch(notificationServiceProvider);
  return service.getNotificationsByPriority(priority);
});

// Notifications stream provider
final notificationStreamProvider = StreamProvider<AppNotification>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.notificationStream;
});

// Notification actions
class NotificationActions {
  final NotificationService _service;

  NotificationActions(this._service);

  // Basic notification methods
  Future<String> showSuccess(String title, String message, {String? actionUrl, String? actionLabel}) {
    return _service.showSuccess(title, message, actionUrl: actionUrl, actionLabel: actionLabel);
  }

  Future<String> showError(String title, String message, {String? actionUrl, String? actionLabel}) {
    return _service.showError(title, message, actionUrl: actionUrl, actionLabel: actionLabel);
  }

  Future<String> showWarning(String title, String message, {String? actionUrl, String? actionLabel}) {
    return _service.showWarning(title, message, actionUrl: actionUrl, actionLabel: actionLabel);
  }

  Future<String> showInfo(String title, String message, {String? actionUrl, String? actionLabel}) {
    return _service.showInfo(title, message, actionUrl: actionUrl, actionLabel: actionLabel);
  }

  Future<String> showReminder(String title, String message, {DateTime? expiresAt, String? relatedEntityId}) {
    return _service.showReminder(title, message, expiresAt: expiresAt, relatedEntityId: relatedEntityId);
  }

  // Entity-specific notifications
  Future<void> notifyTimesheetSubmitted(String employeeName, String timesheetId) {
    return _service.notifyTimesheetSubmitted(employeeName, timesheetId);
  }

  Future<void> notifyTimesheetApproved(String employeeName, String timesheetId) {
    return _service.notifyTimesheetApproved(employeeName, timesheetId);
  }

  Future<void> notifyTimesheetRejected(String employeeName, String timesheetId, String reason) {
    return _service.notifyTimesheetRejected(employeeName, timesheetId, reason);
  }

  Future<void> notifyNewEmployee(String employeeName, String employeeId) {
    return _service.notifyNewEmployee(employeeName, employeeId);
  }

  Future<void> notifyShiftReminder(String employeeName, DateTime shiftStart, String shiftId) {
    return _service.notifyShiftReminder(employeeName, shiftStart, shiftId);
  }

  Future<void> notifySystemMaintenance(DateTime maintenanceStart, Duration duration) {
    return _service.notifySystemMaintenance(maintenanceStart, duration);
  }

  // Notification management
  Future<void> markAsRead(String notificationId) {
    return _service.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() {
    return _service.markAllAsRead();
  }

  Future<void> removeNotification(String notificationId) {
    return _service.removeNotification(notificationId);
  }

  Future<void> clearAllNotifications() {
    return _service.clearAllNotifications();
  }

  Future<void> clearReadNotifications() {
    return _service.clearReadNotifications();
  }

  // Settings
  Future<void> updateSettings(NotificationSettings settings) {
    return _service.updateSettings(settings);
  }

  // Search
  List<AppNotification> searchNotifications(String query) {
    return _service.searchNotifications(query);
  }

  List<AppNotification> getNotificationsByEntity(String entityType, String entityId) {
    return _service.getNotificationsByEntity(entityType, entityId);
  }
}

// Notification actions provider
final notificationActionsProvider = Provider<NotificationActions>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationActions(service);
});

// Notification statistics
class NotificationStats {
  final int total;
  final int unread;
  final int byType;
  final int byPriority;

  const NotificationStats({
    required this.total,
    required this.unread,
    required this.byType,
    required this.byPriority,
  });
}

final notificationStatsProvider = Provider<Map<String, int>>((ref) {
  final notifications = ref.watch(notificationsProvider);

  final stats = <String, int>{
    'total': notifications.length,
    'unread': notifications.where((n) => !n.isRead).length,
    'active': notifications.where((n) => n.isActive).length,
    'expired': notifications.where((n) => n.isExpired).length,
  };

  // Count by type
  for (final type in NotificationType.values) {
    stats['type_${type.toString().split('.').last}'] =
        notifications.where((n) => n.type == type).length;
  }

  // Count by priority
  for (final priority in NotificationPriority.values) {
    stats['priority_${priority.toString().split('.').last}'] =
        notifications.where((n) => n.priority == priority).length;
  }

  return stats;
});