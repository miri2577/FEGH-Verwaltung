import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/employee.dart';
import '../../../models/employee_document.dart';
import '../../../providers/employee_document_provider.dart';

class EmployeeDocumentsCard extends ConsumerWidget {
  final Employee employee;

  const EmployeeDocumentsCard({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentsByEmployeeProvider(employee.id));

    final categories = {
      'Personalakte': (Symbols.badge, Colors.blue),
      'Schulungen & Zertifikate': (Symbols.school, Colors.green),
      'Urlaubsanträge': (Symbols.beach_access, Colors.orange),
      'Sonstige Dokumente': (Symbols.description, Colors.purple),
    };

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
                  onPressed: () => _showUploadDialog(context, ref),
                  icon: const Icon(Symbols.upload_file, size: 18),
                  label: const Text('Hinzufügen'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...categories.entries.map((entry) {
              final categoryDocs = documents.where((d) => d.category == entry.key).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildDocumentCategory(
                  context,
                  ref,
                  entry.key,
                  categoryDocs,
                  entry.value.$1,
                  entry.value.$2,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCategory(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<EmployeeDocument> documents,
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
          ...documents.map((doc) => _buildDocumentItem(context, ref, doc, color)),
      ],
    );
  }

  Widget _buildDocumentItem(BuildContext context, WidgetRef ref, EmployeeDocument document, Color categoryColor) {
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
                    const Text(' \u2022 '),
                    Text(
                      _formatUploadDate(document.uploadedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (document.fileSize > 0) ...[
                      const Text(' \u2022 '),
                      Text(
                        document.formattedSize,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Symbols.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('L\u00f6schen', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) => _handleDocumentAction(context, ref, value, document),
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

  void _showUploadDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedCategory = 'Personalakte';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Symbols.upload_file),
              SizedBox(width: 12),
              Text('Dokument hinzuf\u00fcgen'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Dokumentname',
                    border: OutlineInputBorder(),
                    hintText: 'z.B. Arbeitsvertrag',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategorie',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Personalakte', child: Text('Personalakte')),
                    DropdownMenuItem(value: 'Schulungen & Zertifikate', child: Text('Schulungen & Zertifikate')),
                    DropdownMenuItem(value: 'Urlaubsantr\u00e4ge', child: Text('Urlaubsantr\u00e4ge')),
                    DropdownMenuItem(value: 'Sonstige Dokumente', child: Text('Sonstige Dokumente')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCategory = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles();
                if (result != null && result.files.single.path != null) {
                  final filePath = result.files.single.path!;
                  final docName = nameController.text.trim().isEmpty
                      ? result.files.single.name
                      : nameController.text.trim();

                  final doc = await ref.read(employeeDocumentsProvider.notifier).addDocument(
                    employeeId: employee.id,
                    name: docName,
                    category: selectedCategory,
                    sourceFilePath: filePath,
                  );

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(doc != null
                            ? 'Dokument "$docName" wurde hinzugef\u00fcgt'
                            : 'Fehler beim Hochladen'),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Symbols.upload_file),
              label: const Text('Datei ausw\u00e4hlen & hochladen'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDocumentAction(BuildContext context, WidgetRef ref, String action, EmployeeDocument document) {
    switch (action) {
      case 'view':
        _openDocument(context, document);
        break;
      case 'delete':
        _showDeleteConfirmation(context, ref, document);
        break;
    }
  }

  void _openDocument(BuildContext context, EmployeeDocument document) async {
    final file = File(document.filePath);
    if (await file.exists()) {
      final uri = Uri.file(document.filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datei konnte nicht ge\u00f6ffnet werden')),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datei nicht gefunden')),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, EmployeeDocument document) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Symbols.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Dokument l\u00f6schen'),
          ],
        ),
        content: Text('M\u00f6chten Sie "${document.name}" wirklich l\u00f6schen? Diese Aktion kann nicht r\u00fcckg\u00e4ngig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await ref.read(employeeDocumentsProvider.notifier).deleteDocument(document.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '"${document.name}" wurde gel\u00f6scht'
                        : 'Fehler beim L\u00f6schen'),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('L\u00f6schen'),
          ),
        ],
      ),
    );
  }
}
