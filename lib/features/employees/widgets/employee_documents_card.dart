import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/employee.dart';

class EmployeeDocumentsCard extends StatelessWidget {
  final Employee employee;

  const EmployeeDocumentsCard({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.folder,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Dokumente & Unterlagen',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showUploadDialog(context),
                  icon: const Icon(Symbols.upload_file, size: 18),
                  label: const Text('Hinzufügen'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Document Categories
            _buildDocumentCategory(
              context,
              'Personalakte',
              [
                _DocumentItem('Arbeitsvertrag', 'contract.pdf', DateTime.now().subtract(const Duration(days: 30))),
                _DocumentItem('Lebenslauf', 'cv.pdf', DateTime.now().subtract(const Duration(days: 45))),
                _DocumentItem('Zeugnisse', 'certificates.pdf', DateTime.now().subtract(const Duration(days: 60))),
              ],
              Symbols.badge,
              Colors.blue,
            ),

            const SizedBox(height: 20),

            _buildDocumentCategory(
              context,
              'Schulungen & Zertifikate',
              [
                _DocumentItem('Arbeitssicherheit', 'safety_training.pdf', DateTime.now().subtract(const Duration(days: 90))),
                _DocumentItem('Erste Hilfe Kurs', 'first_aid.pdf', DateTime.now().subtract(const Duration(days: 200))),
              ],
              Symbols.school,
              Colors.green,
            ),

            const SizedBox(height: 20),

            _buildDocumentCategory(
              context,
              'Urlaubsanträge',
              [
                _DocumentItem('Sommerurlaub 2024', 'vacation_2024_summer.pdf', DateTime.now().subtract(const Duration(days: 10))),
                _DocumentItem('Weihnachtsurlaub 2023', 'vacation_2023_christmas.pdf', DateTime.now().subtract(const Duration(days: 300))),
              ],
              Symbols.beach_access,
              Colors.orange,
            ),

            const SizedBox(height: 20),

            _buildDocumentCategory(
              context,
              'Sonstige Dokumente',
              [
                _DocumentItem('Führungszeugnis', 'background_check.pdf', DateTime.now().subtract(const Duration(days: 365))),
              ],
              Symbols.description,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCategory(
    BuildContext context,
    String title,
    List<_DocumentItem> documents,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                '${documents.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (documents.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Symbols.folder_open,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Keine Dokumente in dieser Kategorie',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ...documents.map((doc) => _buildDocumentItem(context, doc, color)),
      ],
    );
  }

  Widget _buildDocumentItem(BuildContext context, _DocumentItem document, Color categoryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getFileTypeIcon(document.fileName),
              size: 20,
              color: categoryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      document.fileName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Text(' • '),
                    Text(
                      _formatUploadDate(document.uploadDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Symbols.visibility, size: 18),
                    SizedBox(width: 8),
                    Text('Anzeigen'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Symbols.download, size: 18),
                    SizedBox(width: 8),
                    Text('Herunterladen'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Symbols.share, size: 18),
                    SizedBox(width: 8),
                    Text('Teilen'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
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
            onSelected: (value) => _handleDocumentAction(context, value, document),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Symbols.more_vert,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileTypeIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Symbols.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Symbols.description;
      case 'xls':
      case 'xlsx':
        return Symbols.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Symbols.image;
      default:
        return Symbols.draft;
    }
  }

  String _formatUploadDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Heute';
    } else if (difference.inDays == 1) {
      return 'Gestern';
    } else if (difference.inDays < 7) {
      return 'vor ${difference.inDays} Tagen';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'vor $weeks Woche${weeks > 1 ? 'n' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'vor $months Monat${months > 1 ? 'en' : ''}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'vor $years Jahr${years > 1 ? 'en' : ''}';
    }
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Symbols.upload_file),
            SizedBox(width: 12),
            Text('Dokument hinzufügen'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Wählen Sie eine Datei zum Hochladen aus:'),
            SizedBox(height: 16),
            // TODO: Implement file picker
            Text('Datei-Auswahl wird implementiert'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upload-Funktion wird implementiert')),
              );
            },
            child: const Text('Hochladen'),
          ),
        ],
      ),
    );
  }

  void _handleDocumentAction(BuildContext context, String action, _DocumentItem document) {
    switch (action) {
      case 'view':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${document.name} wird angezeigt')),
        );
        break;
      case 'download':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${document.name} wird heruntergeladen')),
        );
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${document.name} wird geteilt')),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(context, document);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, _DocumentItem document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Symbols.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Dokument löschen'),
          ],
        ),
        content: Text('Möchten Sie "${document.name}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${document.name} wurde gelöscht')),
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
  }
}

class _DocumentItem {
  final String name;
  final String fileName;
  final DateTime uploadDate;

  _DocumentItem(this.name, this.fileName, this.uploadDate);
}