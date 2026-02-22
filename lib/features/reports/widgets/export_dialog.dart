import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/report_config.dart';
import '../../../providers/reports_provider.dart';
import '../../../providers/policy_provider.dart';
import '../../../services/audit_logger.dart';
import 'package:file_picker/file_picker.dart';

class ExportDialog extends ConsumerStatefulWidget {
  final ReportConfig reportConfig;

  const ExportDialog({
    super.key,
    required this.reportConfig,
  });

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  ReportFormat _selectedFormat = ReportFormat.pdf;
  bool _includeCharts = true;
  bool _includeSummary = true;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Symbols.download,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('Report exportieren'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report: ${widget.reportConfig.name}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // Format Selection
            Text(
              'Export-Format',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ReportFormat.values.map((format) {
                final isSelected = _selectedFormat == format;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getFormatIcon(format),
                        size: 18,
                        color: isSelected ? Colors.white : null,
                      ),
                      const SizedBox(width: 8),
                      Text(format.label),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFormat = format;
                      });
                    }
                  },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Export Options
            Text(
              'Export-Optionen',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            CheckboxListTile(
              title: const Text('Diagramme einschließen'),
              subtitle: const Text('Fügt Grafiken und Visualisierungen hinzu'),
              value: _includeCharts,
              onChanged: (value) {
                setState(() {
                  _includeCharts = value ?? true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),

            CheckboxListTile(
              title: const Text('Zusammenfassung einschließen'),
              subtitle: const Text('Fügt KPIs und Statistiken hinzu'),
              value: _includeSummary,
              onChanged: (value) {
                setState(() {
                  _includeSummary = value ?? true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: _isExporting ? null : _exportReport,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Symbols.download),
          label: Text(_isExporting ? 'Exportiere...' : 'Exportieren'),
        ),
      ],
    );
  }

  IconData _getFormatIcon(ReportFormat format) {
    switch (format) {
      case ReportFormat.pdf:
        return Symbols.picture_as_pdf;
      case ReportFormat.excel:
        return Symbols.table_chart;
      case ReportFormat.csv:
        return Symbols.text_snippet;
      case ReportFormat.json:
        return Symbols.data_object;
    }
  }

  Future<void> _exportReport() async {
    // RBAC: Export nur mit Berechtigung
    try {
      final policy = ref.read(policyProvider);
      if (!policy.canExportData()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keine Berechtigung für Export')));
        }
        return;
      }
    } catch (_) {}
    setState(() {
      _isExporting = true;
    });

    try {
      // File picker for save location
      final extension = _getFileExtension(_selectedFormat);
      final fileName = '${widget.reportConfig.name}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Report speichern',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [extension],
      );

      if (path != null) {
        // Simulate export process
        final reportsService = ref.read(reportsServiceProvider);
        final success = await reportsService.exportReport(
          widget.reportConfig.id,
          _selectedFormat,
          path,
        );

        if (success) {
          await AuditLogger.log('export.report', context: {
            'reportId': widget.reportConfig.id,
            'format': _selectedFormat.name,
            'path': path,
            'includeCharts': _includeCharts,
            'includeSummary': _includeSummary,
          });
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Symbols.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Export erfolgreich'),
                          Text(
                            'Gespeichert unter: $path',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Öffnen',
                  textColor: Colors.white,
                  onPressed: () {
                    // TODO: Open file
                  },
                ),
              ),
            );
          }
        } else {
          _showErrorSnackBar('Export fehlgeschlagen. Bitte versuchen Sie es erneut.');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Fehler beim Export: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Symbols.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _getFileExtension(ReportFormat format) {
    switch (format) {
      case ReportFormat.pdf:
        return 'pdf';
      case ReportFormat.excel:
        return 'xlsx';
      case ReportFormat.csv:
        return 'csv';
      case ReportFormat.json:
        return 'json';
    }
  }
}

class QuickExportButton extends ConsumerWidget {
  final ReportConfig reportConfig;
  final ReportFormat format;

  const QuickExportButton({
    super.key,
    required this.reportConfig,
    required this.format,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Als ${format.label} exportieren',
      child: OutlinedButton.icon(
        onPressed: () => _quickExport(context, ref),
        icon: Icon(_getFormatIcon(format), size: 18),
        label: Text(format.label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  IconData _getFormatIcon(ReportFormat format) {
    switch (format) {
      case ReportFormat.pdf:
        return Symbols.picture_as_pdf;
      case ReportFormat.excel:
        return Symbols.table_chart;
      case ReportFormat.csv:
        return Symbols.text_snippet;
      case ReportFormat.json:
        return Symbols.data_object;
    }
  }

  Future<void> _quickExport(BuildContext context, WidgetRef ref) async {
    try {
      final extension = _getFileExtension(format);
      final fileName = '${reportConfig.name}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Report speichern',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [extension],
      );

      if (path != null) {
        final reportsService = ref.read(reportsServiceProvider);
        final success = await reportsService.exportReport(
          reportConfig.id,
          format,
          path,
        );

        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report erfolgreich als ${format.label} exportiert'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export-Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFileExtension(ReportFormat format) {
    switch (format) {
      case ReportFormat.pdf:
        return 'pdf';
      case ReportFormat.excel:
        return 'xlsx';
      case ReportFormat.csv:
        return 'csv';
      case ReportFormat.json:
        return 'json';
    }
  }
}
