import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/notification.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    final isExpired = notification.isExpired;

    return Card(
      elevation: isRead ? 1 : 3,
      color: isRead
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Type Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTypeColor(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(notification.type),
                      size: 20,
                      color: _getTypeColor(notification.type),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and Priority
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                  color: isExpired
                                      ? Theme.of(context).colorScheme.outline
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (notification.priority != NotificationPriority.normal)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(notification.priority),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getPriorityLabel(notification.priority),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getPriorityTextColor(notification.priority),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          _formatTimestamp(notification.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Unread indicator
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),

                  // Actions
                  PopupMenuButton<String>(
                    icon: Icon(
                      Symbols.more_vert,
                      size: 20,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    itemBuilder: (context) => [
                      if (!isRead)
                        PopupMenuItem(
                          value: 'mark_read',
                          child: Row(
                            children: [
                              const Icon(Symbols.mark_email_read, size: 16),
                              const SizedBox(width: 8),
                              const Text('Als gelesen markieren'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Symbols.delete,
                              size: 16,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Löschen',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'mark_read':
                          onMarkAsRead?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Message
              Text(
                notification.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isExpired
                      ? Theme.of(context).colorScheme.outline
                      : null,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Action Button
              if (notification.actionUrl != null && notification.actionLabel != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Symbols.open_in_new, size: 16),
                      label: Text(notification.actionLabel!),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ],

              // Expiry Warning
              if (isExpired) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Symbols.schedule,
                        size: 12,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Abgelaufen',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return Symbols.info;
      case NotificationType.success:
        return Symbols.check_circle;
      case NotificationType.warning:
        return Symbols.warning;
      case NotificationType.error:
        return Symbols.error;
      case NotificationType.reminder:
        return Symbols.schedule;
      case NotificationType.approval:
        return Symbols.approval;
      case NotificationType.system:
        return Symbols.settings;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.reminder:
        return Colors.purple;
      case NotificationType.approval:
        return Colors.amber;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'NIEDRIG';
      case NotificationPriority.normal:
        return 'NORMAL';
      case NotificationPriority.high:
        return 'HOCH';
      case NotificationPriority.urgent:
        return 'DRINGEND';
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  Color _getPriorityTextColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
      case NotificationPriority.normal:
      case NotificationPriority.high:
      case NotificationPriority.urgent:
        return Colors.white;
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Gerade eben';
    } else if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes} Min';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours} Std';
    } else if (difference.inDays < 7) {
      return 'vor ${difference.inDays} Tag${difference.inDays == 1 ? '' : 'en'}';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }
}