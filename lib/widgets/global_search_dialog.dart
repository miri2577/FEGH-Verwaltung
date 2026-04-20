import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../providers/client_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/shift_provider.dart';
import '../providers/team_provider.dart';
import '../services/audit_logger.dart';
import '../services/global_search_service.dart';

/// Globale Suche ueber alle Entitaets-Typen.
///
/// Tastatur-Shortcut `Ctrl+F` oder Klick auf das Such-Icon in der
/// AppBar. Dialog schliesst sich bei Escape oder Klick ausserhalb.
/// Enter auf einem Ergebnis navigiert zum Tab.
class GlobalSearchDialog extends ConsumerStatefulWidget {
  /// Callback beim Auswaehlen eines Ergebnisses — die AppShell
  /// wechselt dann den Tab und markiert das Element.
  final void Function(SearchResult result) onSelect;

  const GlobalSearchDialog({super.key, required this.onSelect});

  /// Zeigt den Dialog und gibt optional das ausgewaehlte Ergebnis zurueck.
  static Future<SearchResult?> show(
    BuildContext context, {
    void Function(SearchResult)? onSelect,
  }) {
    return showDialog<SearchResult>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => GlobalSearchDialog(
        onSelect: (r) {
          onSelect?.call(r);
          Navigator.of(ctx).pop(r);
        },
      ),
    );
  }

  @override
  ConsumerState<GlobalSearchDialog> createState() =>
      _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<GlobalSearchDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _service = const GlobalSearchService();
  Timer? _debounce;
  String _query = '';
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _query = v;
          _highlightedIndex = 0;
        });
      }
    });
  }

  List<SearchResult> _runSearch() {
    if (_query.trim().isEmpty) return const [];
    final clients = ref.read(clientProvider);
    final employees = ref.read(employeesProvider).valueOrNull ?? const [];
    final teams = ref.read(teamsProvider).valueOrNull ?? const [];
    final shifts = ref.read(shiftsProvider).valueOrNull ?? const [];
    return _service.search(
      query: _query,
      clients: clients,
      employees: employees,
      teams: teams,
      shifts: shifts,
    );
  }

  void _handleKey(KeyEvent event, List<SearchResult> results) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _highlightedIndex =
          (_highlightedIndex + 1).clamp(0, results.length - 1));
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(
          () => _highlightedIndex = (_highlightedIndex - 1).clamp(0, results.length - 1));
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (results.isNotEmpty && _highlightedIndex < results.length) {
        _select(results[_highlightedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  void _select(SearchResult r) {
    AuditLogger.log('search.result_selected', context: {
      'type': r.type.name,
      'id': r.id,
      'query': _query,
    });
    widget.onSelect(r);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _runSearch();
    final grouped = <SearchResultType, List<SearchResult>>{};
    for (final r in results) {
      grouped.putIfAbsent(r.type, () => []).add(r);
    }

    return Dialog(
      alignment: const Alignment(0, -0.5),
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (e) => _handleKey(e, results),
        child: SizedBox(
          width: 640,
          height: 520,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  onChanged: _onQueryChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Symbols.search),
                    hintText:
                        'Klienten, Mitarbeiter, Teams, Schichten, Rechnungen …',
                    border: const OutlineInputBorder(),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Symbols.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _query.trim().isEmpty
                    ? _hint(theme)
                    : results.isEmpty
                        ? _empty(theme)
                        : _resultList(theme, grouped, results),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Text('${results.length} Treffer',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        )),
                    const Spacer(),
                    Text('↑↓ navigieren · Enter oeffnen · Esc schliessen',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hint(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.search, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('Tippe um zu suchen',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 6),
            Text(
                'Durchsucht Klienten, Mitarbeiter, Teams, Schichten und Rechnungen',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                )),
          ],
        ),
      ),
    );
  }

  Widget _empty(ThemeData theme) {
    return Center(
      child: Text('Keine Treffer fuer "$_query"',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          )),
    );
  }

  Widget _resultList(
    ThemeData theme,
    Map<SearchResultType, List<SearchResult>> grouped,
    List<SearchResult> flat,
  ) {
    final tiles = <Widget>[];
    var flatIndex = 0;
    for (final type in SearchResultType.values) {
      final list = grouped[type];
      if (list == null || list.isEmpty) continue;
      tiles.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          type.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
            letterSpacing: 0.5,
          ),
        ),
      ));
      for (final r in list) {
        final isHighlighted = flatIndex == _highlightedIndex;
        tiles.add(Container(
          color: isHighlighted ? theme.colorScheme.primaryContainer : null,
          child: ListTile(
            leading: Icon(r.icon),
            title: Text(r.title),
            subtitle: r.subtitle == null ? null : Text(r.subtitle!),
            onTap: () => _select(r),
            dense: true,
          ),
        ));
        flatIndex++;
      }
    }
    return ListView(children: tiles);
  }
}
