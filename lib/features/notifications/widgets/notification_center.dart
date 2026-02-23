import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/notification.dart';
import '../../../providers/notification_provider.dart';
import 'notification_card.dart';

class NotificationCenter extends ConsumerStatefulWidget {
  const NotificationCenter({super.key});

  @override
  ConsumerState<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends ConsumerState<NotificationCenter> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  NotificationType? _filterType;
  NotificationPriority? _filterPriority;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unreadNotifications = ref.watch(unreadNotificationsProvider);
    final actions = ref.watch(notificationActionsProvider);
    final stats = ref.watch(notificationStatsProvider);

    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Symbols.notifications,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Benachrichtigungen',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Actions
                  if (unreadNotifications.isNotEmpty) ...[
                    TextButton.icon(
                      onPressed: () => actions.markAllAsRead(),
                      icon: const Icon(Symbols.mark_email_read, size: 18),
                      label: const Text('Alle als gelesen'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    onPressed: () => _showSettings(context),
                    icon: const Icon(Symbols.settings),
                    tooltip: 'Einstellungen',
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Symbols.close),
                    tooltip: 'Schließen',
                  ),
                ],
              ),
            ),

            // Search and Filter
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Benachrichtigungen durchsuchen...',
                      prefixIcon: const Icon(Symbols.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              icon: const Icon(Symbols.clear),
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Filter Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<NotificationType?>(
                          value: _filterType,
                          decoration: const InputDecoration(
                            labelText: 'Typ',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<NotificationType?>(
                              value: null,
                              child: Text('Alle Typen'),
                            ),
                            ...NotificationType.values.map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(_getTypeLabel(type)),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterType = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<NotificationPriority?>(
                          value: _filterPriority,
                          decoration: const InputDecoration(
                            labelText: 'Priorität',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<NotificationPriority?>(
                              value: null,
                              child: Text('Alle Prioritäten'),
                            ),
                            ...NotificationPriority.values.map((priority) => DropdownMenuItem(
                              value: priority,
                              child: Text(_getPriorityLabel(priority)),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterPriority = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Symbols.inbox, size: 18),
                      const SizedBox(width: 8),
                      Text('Alle (${stats['total'] ?? 0})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Symbols.mark_as_unread, size: 18),
                      const SizedBox(width: 8),
                      Text('Ungelesen (${stats['unread'] ?? 0})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Symbols.schedule, size: 18),
                      const SizedBox(width: 8),
                      Text('Aktiv (${stats['active'] ?? 0})'),
                    ],
                  ),
                ),
              ],
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotificationList(_getFilteredNotifications(notifications)),
                  _buildNotificationList(_getFilteredNotifications(unreadNotifications)),
                  _buildNotificationList(_getFilteredNotifications(ref.watch(activeNotificationsProvider))),
                ],
              ),
            ),

            // Footer with actions
            if (notifications.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showClearDialog(context, actions),
                      icon: const Icon(Symbols.delete_sweep, size: 18),
                      label: const Text('Gelesene löschen'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showClearAllDialog(context, actions),
                      icon: const Icon(Symbols.clear_all, size: 18),
                      label: const Text('Alle löschen'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${notifications.length} Benachrichtigungen',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.notifications_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Benachrichtigungen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Keine Benachrichtigungen entsprechen Ihrer Suche'
                  : 'Sie haben keine Benachrichtigungen',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return NotificationCard(
          notification: notifications[index],
          onTap: () => _handleNotificationTap(notifications[index]),
          onMarkAsRead: () => ref.read(notificationActionsProvider).markAsRead(notifications[index].id),
          onDelete: () => ref.read(notificationActionsProvider).removeNotification(notifications[index].id),
        );
      },
    );
  }

  List<AppNotification> _getFilteredNotifications(List<AppNotification> notifications) {
    var filtered = notifications;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((n) =>
        n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        n.message.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Filter by type
    if (_filterType != null) {
      filtered = filtered.where((n) => n.type == _filterType).toList();
    }

    // Filter by priority
    if (_filterPriority != null) {
      filtered = filtered.where((n) => n.priority == _filterPriority).toList();
    }

    return filtered;
  }

  void _handleNotificationTap(AppNotification notification) {
    final actions = ref.read(notificationActionsProvider);

    // Mark as read if not already
    if (!notification.isRead) {
      actions.markAsRead(notification.id);
    }

    // Handle action URL if present
    if (notification.actionUrl != null) {
      final url = notification.actionUrl!;
      if (url.startsWith('/employees/')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation zu: Mitarbeiter ${url.split('/').last}')),
        );
      } else if (url.startsWith('/timesheets/')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation zu: Zeitnachweis ${url.split('/').last}')),
        );
      } else if (url.startsWith('/vacation/')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation zu: Urlaubsantrag ${url.split('/').last}')),
        );
      } else if (url.startsWith('/shifts/')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation zu: Schicht ${url.split('/').last}')),
        );
      }
    }
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Symbols.settings),
            SizedBox(width: 12),
            Text('Benachrichtigungseinstellungen'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Urlaubsanträge'),
                subtitle: const Text('Benachrichtigung bei neuen Anträgen'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Zeitnachweise'),
                subtitle: const Text('Benachrichtigung bei Statusänderungen'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Schichtplanung'),
                subtitle: const Text('Benachrichtigung bei Schichtänderungen'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('System'),
                subtitle: const Text('Systemmeldungen und Warnungen'),
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, NotificationActions actions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gelesene Benachrichtigungen löschen'),
        content: const Text('Möchten Sie alle gelesenen Benachrichtigungen dauerhaft löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              actions.clearReadNotifications();
              Navigator.of(context).pop();
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, NotificationActions actions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle Benachrichtigungen löschen'),
        content: const Text('Möchten Sie wirklich ALLE Benachrichtigungen dauerhaft löschen? Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              actions.clearAllNotifications();
              Navigator.of(context).pop();
            },
            child: const Text('Alle löschen'),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return 'Information';
      case NotificationType.success:
        return 'Erfolg';
      case NotificationType.warning:
        return 'Warnung';
      case NotificationType.error:
        return 'Fehler';
      case NotificationType.reminder:
        return 'Erinnerung';
      case NotificationType.approval:
        return 'Genehmigung';
      case NotificationType.system:
        return 'System';
    }
  }

  String _getPriorityLabel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Niedrig';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'Hoch';
      case NotificationPriority.urgent:
        return 'Dringend';
    }
  }
}