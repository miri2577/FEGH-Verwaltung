import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/notification.dart';

class NotificationService extends ChangeNotifier {
  static const String _notificationsKey = 'app_notifications';
  static const String _settingsKey = 'notification_settings';

  final _uuid = const Uuid();
  final List<AppNotification> _notifications = [];
  final StreamController<AppNotification> _notificationStream = StreamController<AppNotification>.broadcast();

  NotificationSettings _settings = const NotificationSettings();
  SharedPreferences? _prefs;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<AppNotification> get unreadNotifications => _notifications.where((n) => !n.isRead).toList();
  List<AppNotification> get activeNotifications => _notifications.where((n) => n.isActive).toList();
  int get unreadCount => unreadNotifications.length;
  NotificationSettings get settings => _settings;
  Stream<AppNotification> get notificationStream => _notificationStream.stream;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadNotifications();
    await _loadSettings();
    _cleanupExpiredNotifications();

    // Cleanup timer - remove expired notifications every hour
    Timer.periodic(const Duration(hours: 1), (_) => _cleanupExpiredNotifications());
  }

  // Core notification methods
  Future<String> showNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    NotificationPriority priority = NotificationPriority.normal,
    Duration? expiresIn,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? actionLabel,
    bool isPersistent = true,
    String? relatedEntityId,
    String? relatedEntityType,
  }) async {
    final notification = AppNotification(
      id: _uuid.v4(),
      title: title,
      message: message,
      type: type,
      priority: priority,
      createdAt: DateTime.now(),
      expiresAt: expiresIn != null ? DateTime.now().add(expiresIn) : null,
      data: data,
      actionUrl: actionUrl,
      actionLabel: actionLabel,
      isPersistent: isPersistent,
      relatedEntityId: relatedEntityId,
      relatedEntityType: relatedEntityType,
    );

    return await _addNotification(notification);
  }

  // Convenience methods for different notification types
  Future<String> showSuccess(String title, String message, {String? actionUrl, String? actionLabel}) {
    return showNotification(
      title: title,
      message: message,
      type: NotificationType.success,
      actionUrl: actionUrl,
      actionLabel: actionLabel,
    );
  }

  Future<String> showError(String title, String message, {String? actionUrl, String? actionLabel}) {
    return showNotification(
      title: title,
      message: message,
      type: NotificationType.error,
      priority: NotificationPriority.high,
      actionUrl: actionUrl,
      actionLabel: actionLabel,
    );
  }

  Future<String> showWarning(String title, String message, {String? actionUrl, String? actionLabel}) {
    return showNotification(
      title: title,
      message: message,
      type: NotificationType.warning,
      priority: NotificationPriority.normal,
      actionUrl: actionUrl,
      actionLabel: actionLabel,
    );
  }

  Future<String> showInfo(String title, String message, {String? actionUrl, String? actionLabel}) {
    return showNotification(
      title: title,
      message: message,
      type: NotificationType.info,
      actionUrl: actionUrl,
      actionLabel: actionLabel,
    );
  }

  Future<String> showReminder(String title, String message, {DateTime? expiresAt, String? relatedEntityId}) {
    return showNotification(
      title: title,
      message: message,
      type: NotificationType.reminder,
      priority: NotificationPriority.normal,
      expiresIn: expiresAt?.difference(DateTime.now()),
      relatedEntityId: relatedEntityId,
    );
  }

  Future<String> showApprovalRequired(String title, String message, {String? relatedEntityId, String? actionUrl}) {
    return showNotification(
      title: title,
      message: message,
      type: NotificationType.approval,
      priority: NotificationPriority.high,
      relatedEntityId: relatedEntityId,
      actionUrl: actionUrl,
      actionLabel: 'Genehmigen',
    );
  }

  // Entity-specific notification methods
  Future<void> notifyTimesheetSubmitted(String employeeName, String timesheetId) {
    return showApprovalRequired(
      'Zeitnachweis eingereicht',
      '$employeeName hat einen Zeitnachweis zur Genehmigung eingereicht.',
      relatedEntityId: timesheetId,
      actionUrl: '/timesheets/$timesheetId',
    );
  }

  Future<void> notifyTimesheetApproved(String employeeName, String timesheetId) {
    return showSuccess(
      'Zeitnachweis genehmigt',
      'Der Zeitnachweis von $employeeName wurde genehmigt.',
      actionUrl: '/timesheets/$timesheetId',
      actionLabel: 'Details anzeigen',
    );
  }

  Future<void> notifyTimesheetRejected(String employeeName, String timesheetId, String reason) {
    return showWarning(
      'Zeitnachweis abgelehnt',
      'Der Zeitnachweis von $employeeName wurde abgelehnt. Grund: $reason',
      actionUrl: '/timesheets/$timesheetId',
      actionLabel: 'Details anzeigen',
    );
  }

  Future<void> notifyNewEmployee(String employeeName, String employeeId) {
    return showInfo(
      'Neuer Mitarbeiter',
      '$employeeName wurde als neuer Mitarbeiter hinzugefügt.',
      actionUrl: '/employees/$employeeId',
      actionLabel: 'Profil anzeigen',
    );
  }

  Future<void> notifyShiftReminder(String employeeName, DateTime shiftStart, String shiftId) {
    final timeUntilShift = shiftStart.difference(DateTime.now());
    final message = timeUntilShift.inHours > 0
        ? 'Schicht beginnt in ${timeUntilShift.inHours} Stunden'
        : 'Schicht beginnt in ${timeUntilShift.inMinutes} Minuten';

    return showReminder(
      'Schicht-Erinnerung für $employeeName',
      message,
      expiresAt: shiftStart,
      relatedEntityId: shiftId,
    );
  }

  Future<void> notifySystemMaintenance(DateTime maintenanceStart, Duration duration) {
    return showNotification(
      title: 'Geplante Wartungsarbeiten',
      message: 'Das System wird am ${maintenanceStart.day}.${maintenanceStart.month} für ${duration.inHours} Stunden gewartet.',
      type: NotificationType.system,
      priority: NotificationPriority.high,
      expiresIn: Duration(hours: 24),
    );
  }

  // Notification management
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> removeNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearReadNotifications() async {
    _notifications.removeWhere((n) => n.isRead);
    await _saveNotifications();
    notifyListeners();
  }

  // Settings management
  Future<void> updateSettings(NotificationSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  // Search and filter
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  List<AppNotification> getNotificationsByPriority(NotificationPriority priority) {
    return _notifications.where((n) => n.priority == priority).toList();
  }

  List<AppNotification> getNotificationsByEntity(String entityType, String entityId) {
    return _notifications.where((n) =>
      n.relatedEntityType == entityType && n.relatedEntityId == entityId
    ).toList();
  }

  List<AppNotification> searchNotifications(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _notifications.where((n) =>
      n.title.toLowerCase().contains(lowercaseQuery) ||
      n.message.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Private methods
  Future<String> _addNotification(AppNotification notification) async {
    if (!_settings.shouldShowNotification(notification)) {
      return notification.id;
    }

    _notifications.insert(0, notification);
    _notificationStream.add(notification);

    // Limit notifications history
    if (_notifications.length > _settings.maxNotificationsInHistory) {
      _notifications.removeRange(_settings.maxNotificationsInHistory, _notifications.length);
    }

    if (notification.isPersistent) {
      await _saveNotifications();
    }

    notifyListeners();
    return notification.id;
  }

  Future<void> _loadNotifications() async {
    if (_prefs == null) return;

    final notificationsJson = _prefs!.getString(_notificationsKey);
    if (notificationsJson != null) {
      try {
        final List<dynamic> notificationsList = jsonDecode(notificationsJson);
        _notifications.clear();
        _notifications.addAll(
          notificationsList.map((json) => AppNotification.fromJson(json)).toList(),
        );
      } catch (e) {
        print('Error loading notifications: $e');
      }
    }
  }

  Future<void> _saveNotifications() async {
    if (_prefs == null) return;

    try {
      final persistentNotifications = _notifications.where((n) => n.isPersistent).toList();
      final notificationsJson = jsonEncode(
        persistentNotifications.map((n) => n.toJson()).toList(),
      );
      await _prefs!.setString(_notificationsKey, notificationsJson);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    final settingsJson = _prefs!.getString(_settingsKey);
    if (settingsJson != null) {
      try {
        final settingsMap = jsonDecode(settingsJson);
        _settings = NotificationSettings.fromJson(settingsMap);
      } catch (e) {
        print('Error loading notification settings: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_prefs == null) return;

    try {
      final settingsJson = jsonEncode(_settings.toJson());
      await _prefs!.setString(_settingsKey, settingsJson);
    } catch (e) {
      print('Error saving notification settings: $e');
    }
  }

  void _cleanupExpiredNotifications() {
    final now = DateTime.now();
    final beforeCount = _notifications.length;

    _notifications.removeWhere((n) => n.isExpired);

    if (_notifications.length != beforeCount) {
      _saveNotifications();
      notifyListeners();
      print('Cleaned up ${beforeCount - _notifications.length} expired notifications');
    }
  }

  @override
  void dispose() {
    _notificationStream.close();
    super.dispose();
  }
}