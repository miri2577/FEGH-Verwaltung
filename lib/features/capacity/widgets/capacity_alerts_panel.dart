import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../providers/capacity_provider.dart';

class CapacityAlertsPanel extends ConsumerWidget {
  const CapacityAlertsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(capacityAlertsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.notifications,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kapazitäts-Warnungen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            alertsAsync.when(
              data: (alerts) => alerts.isEmpty
                  ? _buildNoAlertsState(context)
                  : Column(
                      children: alerts.map((alert) => _buildAlertItem(context, alert)).toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAlertsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Keine kritischen Warnungen',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(BuildContext context, String alert) {
    final AlertInfo alertInfo = _parseAlert(alert);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alertInfo.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: alertInfo.color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              alertInfo.icon,
              color: alertInfo.color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getAlertAction(alert),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _handleAlertAction(context, alert),
              icon: Icon(
                Symbols.arrow_forward,
                size: 16,
                color: alertInfo.color,
              ),
              tooltip: 'Details anzeigen',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.error,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Fehler beim Laden der Warnungen',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  AlertInfo _parseAlert(String alert) {
    if (alert.contains('kritisch')) {
      return AlertInfo(Colors.red, Symbols.error);
    } else if (alert.contains('unterbesetzt') || alert.contains('Überstunden')) {
      return AlertInfo(Colors.orange, Symbols.warning);
    } else if (alert.contains('Verfügbarkeit')) {
      return AlertInfo(Colors.blue, Symbols.info);
    } else {
      return AlertInfo(Colors.grey, Symbols.notifications);
    }
  }

  String _getAlertAction(String alert) {
    if (alert.contains('kritisch')) {
      return 'Sofortige Maßnahmen erforderlich';
    } else if (alert.contains('unterbesetzt')) {
      return 'Personalplanung überprüfen';
    } else if (alert.contains('Überstunden')) {
      return 'Arbeitszeiten optimieren';
    } else if (alert.contains('Verfügbarkeit')) {
      return 'Mitarbeiterverteilung prüfen';
    } else {
      return 'Details in Teamübersicht verfügbar';
    }
  }

  void _handleAlertAction(BuildContext context, String alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warnung Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert),
            const SizedBox(height: 16),
            Text(
              'Empfohlene Maßnahmen:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(_getDetailedRecommendations(alert)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigieren Sie zur Schichtplanung, um Maßnahmen zu ergreifen'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Maßnahmen'),
          ),
        ],
      ),
    );
  }

  String _getDetailedRecommendations(String alert) {
    if (alert.contains('kritisch')) {
      return '• Sofortige Personalakquise einleiten\n'
             '• Überstunden genehmigen\n'
             '• Externe Dienstleister kontaktieren\n'
             '• Arbeitsbelastung umverteilen';
    } else if (alert.contains('unterbesetzt')) {
      return '• Personalbedarfsplanung überprüfen\n'
             '• Schichtpläne optimieren\n'
             '• Urlaubssperren erwägen\n'
             '• Querverteilung zwischen Teams prüfen';
    } else if (alert.contains('Überstunden')) {
      return '• Arbeitszeiten analysieren\n'
             '• Effizienz-Maßnahmen implementieren\n'
             '• Zusätzliches Personal einstellen\n'
             '• Workload-Verteilung optimieren';
    } else {
      return '• Weitere Details in der Teamübersicht\n'
             '• Regelmäßige Kapazitätsprüfung\n'
             '• Präventive Maßnahmen einleiten';
    }
  }
}

class AlertInfo {
  final Color color;
  final IconData icon;

  AlertInfo(this.color, this.icon);
}