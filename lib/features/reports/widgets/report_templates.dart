import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/report_config.dart';
import '../../../providers/policy_provider.dart';

class ReportTemplates extends ConsumerWidget {
  final String selectedCategory;
  final Function(ReportTemplate) onTemplateSelected;

  const ReportTemplates({
    super.key,
    required this.selectedCategory,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = _getTemplates();
    final filteredTemplates = selectedCategory == 'all'
        ? templates
        : templates.where((t) => t.category == selectedCategory).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.library_books,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Report Vorlagen',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: ref.read(policyProvider).canManageReportTemplates() ? () => _createCustomTemplate(context) : null,
                icon: const Icon(Symbols.add, size: 18),
                label: const Text('Neue Vorlage'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Wählen Sie eine vorgefertigte Vorlage oder erstellen Sie eine neue',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Template Categories
          _buildCategoryTabs(context, templates),
          const SizedBox(height: 24),

          // Template Grid
          Expanded(
            child: filteredTemplates.isEmpty
                ? _buildEmptyState(context)
                : _buildTemplateGrid(context, filteredTemplates, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context, List<ReportTemplate> templates) {
    final categories = templates.map((t) => t.category).toSet().toList();
    categories.sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip(context, 'all', 'Alle (${templates.length})', selectedCategory == 'all'),
          const SizedBox(width: 8),
          ...categories.map((category) {
            final count = templates.where((t) => t.category == category).length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCategoryChip(
                context,
                category,
                '${_getCategoryLabel(category)} ($count)',
                selectedCategory == category,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String category, String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          // TODO: Implement category selection
        }
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.library_books,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Vorlagen in dieser Kategorie',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstellen Sie eine neue Vorlage oder wählen Sie eine andere Kategorie',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _createCustomTemplate(context),
            icon: const Icon(Symbols.add),
            label: const Text('Neue Vorlage erstellen'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateGrid(BuildContext context, List<ReportTemplate> templates, WidgetRef ref) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(context, template, ref);
      },
    );
  }

  Widget _buildTemplateCard(BuildContext context, ReportTemplate template, WidgetRef ref) {
    final canUse = ref.read(policyProvider).canUseReportTemplates();
    final canManage = ref.read(policyProvider).canManageReportTemplates();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: canUse ? () => onTemplateSelected(template) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and actions
            Container(
              padding: const EdgeInsets.all(16),
              color: _getCategoryColor(template.category).withOpacity(0.1),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(template.category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(template.category),
                      size: 20,
                      color: _getCategoryColor(template.category),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      if (canUse)
                        const PopupMenuItem(
                          value: 'use',
                          child: Row(
                            children: [
                              Icon(Symbols.play_arrow, size: 18),
                              SizedBox(width: 8),
                              Text('Verwenden'),
                            ],
                          ),
                        ),
                      if (canManage)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Symbols.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Bearbeiten'),
                            ],
                          ),
                        ),
                      if (canManage)
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Symbols.content_copy, size: 18),
                              SizedBox(width: 8),
                              Text('Duplizieren'),
                            ],
                          ),
                        ),
                      const PopupMenuDivider(),
                      if (canManage)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Symbols.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Löschen', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                    onSelected: (value) => _handleTemplateAction(context, value, template),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        template.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Template Features
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: template.features.take(3).map((feature) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          feature,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      )).toList(),
                    ),

                    const SizedBox(height: 12),

                    // Footer with metadata
                    Row(
                      children: [
                        Icon(
                          template.isCustom ? Symbols.person : Symbols.verified,
                          size: 14,
                          color: template.isCustom
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            template.isCustom ? 'Benutzerdefiniert' : 'Standard',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(template.lastUsed),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ReportTemplate> _getTemplates() {
    return [
      ReportTemplate(
        id: '1',
        name: 'Monatlicher Zeitnachweis',
        description: 'Detaillierte Übersicht über alle Arbeitsstunden und Überstunden pro Mitarbeiter für einen Monat.',
        category: 'timesheet',
        features: ['Arbeitsstunden', 'Überstunden', 'Pausenzeiten', 'Feiertage'],
        format: ReportFormat.pdf,
        lastUsed: DateTime.now().subtract(const Duration(days: 2)),
        isCustom: false,
      ),
      ReportTemplate(
        id: '2',
        name: 'Wöchentlicher Schichtbericht',
        description: 'Übersicht über geplante und tatsächlich gearbeitete Schichten.',
        category: 'shifts',
        features: ['Schichtplanung', 'Abwesenheiten', 'Vertretungen', 'Auslastung'],
        format: ReportFormat.excel,
        lastUsed: DateTime.now().subtract(const Duration(days: 5)),
        isCustom: false,
      ),
      ReportTemplate(
        id: '3',
        name: 'Mitarbeiter Leistungsanalyse',
        description: 'Umfassende Analyse der Mitarbeiterleistung mit KPIs und Trends.',
        category: 'performance',
        features: ['KPIs', 'Trends', 'Vergleiche', 'Bewertungen'],
        format: ReportFormat.pdf,
        lastUsed: DateTime.now().subtract(const Duration(days: 10)),
        isCustom: false,
      ),
      ReportTemplate(
        id: '4',
        name: 'Kapazitätsplanung Q1',
        description: 'Quartalsweise Kapazitätsanalyse mit Prognosen und Empfehlungen.',
        category: 'capacity',
        features: ['Auslastung', 'Prognosen', 'Empfehlungen', 'Grafiken'],
        format: ReportFormat.pdf,
        lastUsed: DateTime.now().subtract(const Duration(days: 15)),
        isCustom: false,
      ),
      ReportTemplate(
        id: '5',
        name: 'Anwesenheitsstatistik',
        description: 'Detaillierte Anwesenheitsauswertung mit Fehlzeiten und Urlaubstagen.',
        category: 'attendance',
        features: ['Anwesenheit', 'Fehlzeiten', 'Urlaub', 'Krankheit'],
        format: ReportFormat.excel,
        lastUsed: DateTime.now().subtract(const Duration(days: 7)),
        isCustom: false,
      ),
      ReportTemplate(
        id: '6',
        name: 'Lohnabrechnung Export',
        description: 'Export-Format für Lohnabrechnungssoftware mit allen relevanten Daten.',
        category: 'payroll',
        features: ['Bruttolohn', 'Überstunden', 'Zulagen', 'Abzüge'],
        format: ReportFormat.csv,
        lastUsed: DateTime.now().subtract(const Duration(days: 30)),
        isCustom: false,
      ),
      ReportTemplate(
        id: '7',
        name: 'Custom Dashboard Report',
        description: 'Benutzerdefinierter Report mit ausgewählten Metriken.',
        category: 'custom',
        features: ['Flexibel', 'Interaktiv', 'Anpassbar', 'Multi-Format'],
        format: ReportFormat.pdf,
        lastUsed: DateTime.now().subtract(const Duration(days: 1)),
        isCustom: true,
      ),
    ];
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'timesheet':
        return 'Zeiterfassung';
      case 'employee':
        return 'Mitarbeiter';
      case 'shifts':
        return 'Schichten';
      case 'capacity':
        return 'Kapazität';
      case 'performance':
        return 'Leistung';
      case 'attendance':
        return 'Anwesenheit';
      case 'payroll':
        return 'Lohnabrechnung';
      case 'custom':
        return 'Benutzerdefiniert';
      default:
        return category;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'timesheet':
        return Symbols.schedule;
      case 'employee':
        return Symbols.people;
      case 'shifts':
        return Symbols.work;
      case 'capacity':
        return Symbols.analytics;
      case 'performance':
        return Symbols.trending_up;
      case 'attendance':
        return Symbols.fact_check;
      case 'payroll':
        return Symbols.euro;
      case 'custom':
        return Symbols.tune;
      default:
        return Symbols.description;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'timesheet':
        return Colors.blue;
      case 'employee':
        return Colors.green;
      case 'shifts':
        return Colors.orange;
      case 'capacity':
        return Colors.purple;
      case 'performance':
        return Colors.red;
      case 'attendance':
        return Colors.teal;
      case 'payroll':
        return Colors.indigo;
      case 'custom':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Nie';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Heute';
    } else if (difference.inDays == 1) {
      return 'Gestern';
    } else if (difference.inDays < 7) {
      return 'vor ${difference.inDays}d';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  void _createCustomTemplate(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Symbols.add),
            SizedBox(width: 12),
            Text('Neue Vorlage erstellen'),
          ],
        ),
        content: const Text('Template-Editor wird implementiert.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template-Editor wird geöffnet')),
              );
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  void _handleTemplateAction(BuildContext context, String action, ReportTemplate template) {
    switch (action) {
      case 'use':
        onTemplateSelected(template);
        break;
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${template.name} wird bearbeitet...')),
        );
        break;
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${template.name} wird dupliziert...')),
        );
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Vorlage löschen'),
            content: Text('Möchten Sie "${template.name}" wirklich löschen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${template.name} wurde gelöscht')),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Löschen'),
              ),
            ],
          ),
        );
        break;
    }
  }
}

class ReportTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> features;
  final ReportFormat format;
  final DateTime? lastUsed;
  final bool isCustom;

  const ReportTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.features,
    required this.format,
    this.lastUsed,
    this.isCustom = false,
  });
}
