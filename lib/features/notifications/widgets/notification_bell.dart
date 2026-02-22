import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../providers/notification_provider.dart';
import 'notification_center.dart';

class NotificationBell extends ConsumerWidget {
  final double? iconSize;
  final Color? iconColor;

  const NotificationBell({
    super.key,
    this.iconSize,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Symbols.notifications,
            size: iconSize ?? 24,
            color: iconColor ?? Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => _showNotificationCenter(context),
          tooltip: 'Benachrichtigungen',
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationCenter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NotificationCenter(),
    );
  }
}