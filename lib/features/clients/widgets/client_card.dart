import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/client.dart';

class ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final bool canEdit;
  final bool canArchive;
  final bool canDelete;

  const ClientCard({
    super.key,
    required this.client,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onArchive,
    this.canEdit = true,
    this.canArchive = true,
    this.canDelete = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getPriorityColor(context),
                    child: Text(
                      _getInitials(client.fullName),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.fullName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Alter: ${client.age} Jahre',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              const SizedBox(height: 12),
              if (client.email != null)
                _buildInfoRow(Symbols.email, client.email!)
              else
                _buildInfoRow(Symbols.email, 'Keine E-Mail'),
              const SizedBox(height: 4),
              if (client.phone != null)
                _buildInfoRow(Symbols.phone, client.phone!)
              else
                _buildInfoRow(Symbols.phone, 'Keine Telefonnummer'),
              const SizedBox(height: 4),
              if (client.caseManager != null)
                _buildInfoRow(Symbols.person, client.caseManager!)
              else
                _buildInfoRow(Symbols.person, 'Kein Fallmanager'),
              const SizedBox(height: 8),
              // FLS-Info + HilfeTyp Badge
              if (client.fachleistungsstunden != null || client.hilfeTyp != null) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (client.hilfeTyp != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: client.hilfeTyp == 'eingliederungshilfe'
                              ? Colors.teal.shade100
                              : Colors.indigo.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          client.hilfeTypDisplay,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: client.hilfeTyp == 'eingliederungshilfe'
                                ? Colors.teal.shade800
                                : Colors.indigo.shade800,
                          ),
                        ),
                      ),
                    if (client.fachleistungsstunden != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${client.fachleistungsstunden} FLS / ${client.fachleistungsIntervallDisplay}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // FLS-Fortschrittsbalken
                if (client.fachleistungsstunden != null && client.fachleistungsstunden! > 0) ...[
                  Builder(builder: (context) {
                    final prozent = client.stundenverbrauchProzent.clamp(0.0, 100.0);
                    final barColor = prozent > 90
                        ? Colors.red
                        : prozent > 70
                            ? Colors.orange
                            : Colors.green;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${client.verbrauchteStunden.toStringAsFixed(0)} / ${client.fachleistungsstunden} Std.',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                            Text(
                              '${prozent.toStringAsFixed(0)}%',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: barColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        LinearProgressIndicator(
                          value: prozent / 100,
                          backgroundColor: barColor.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation(barColor),
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    );
                  }),
                ],
                const SizedBox(height: 8),
              ],
              // Services as chips
              if (client.services.isNotEmpty) ...[
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: client.services.take(2).map((service) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getServiceShortName(service),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.priorityDisplayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: _getPriorityColor(context),
                          ),
                        ),
                        Text(
                          '${client.assignedEmployees.length} Mitarbeiter',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: canEdit ? onEdit : null,
                        icon: const Icon(Symbols.edit, size: 18),
                        tooltip: 'Bearbeiten',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (client.status != ClientStatus.archived) ...[
                        IconButton(
                          onPressed: canArchive ? onArchive : null,
                          icon: const Icon(Symbols.archive, size: 18),
                          tooltip: 'Archivieren',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                            foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      IconButton(
                        onPressed: canDelete ? onDelete : null,
                        icon: const Icon(Symbols.delete, size: 18),
                        tooltip: 'Löschen',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.errorContainer,
                          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color foregroundColor;
    String label;

    switch (client.status) {
      case ClientStatus.active:
        backgroundColor = Colors.green.shade100;
        foregroundColor = Colors.green.shade800;
        label = 'Aktiv';
        break;
      case ClientStatus.inactive:
        backgroundColor = Colors.grey.shade100;
        foregroundColor = Colors.grey.shade800;
        label = 'Inaktiv';
        break;
      case ClientStatus.pending:
        backgroundColor = Colors.orange.shade100;
        foregroundColor = Colors.orange.shade800;
        label = 'Anstehend';
        break;
      case ClientStatus.archived:
        backgroundColor = Colors.purple.shade100;
        foregroundColor = Colors.purple.shade800;
        label = 'Archiviert';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(BuildContext context) {
    switch (client.priority) {
      case ClientPriority.low:
        return Colors.blue.shade600;
      case ClientPriority.medium:
        return Colors.orange.shade600;
      case ClientPriority.high:
        return Colors.red.shade600;
      case ClientPriority.urgent:
        return Colors.purple.shade600;
    }
  }

  String _getServiceShortName(ServiceType service) {
    switch (service) {
      case ServiceType.ambulant:
        return 'AMB';
      case ServiceType.stationaer:
        return 'STA';
      case ServiceType.beratung:
        return 'BER';
      case ServiceType.begleitung:
        return 'BEG';
      case ServiceType.wohnen:
        return 'WOH';
      case ServiceType.arbeit:
        return 'ARB';
      case ServiceType.freizeit:
        return 'FRZ';
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'KL';
  }
}
