import 'dart:convert';

/// Layout-Konfiguration des Dashboards pro Benutzer (geraete-lokal).
///
/// - [orderedIds] : Reihenfolge aller Kachel-IDs (sichtbar + ausgeblendet).
/// - [hiddenIds]  : Menge der aktuell ausgeblendeten Kachel-IDs.
///
/// Kacheln, die noch nicht in [orderedIds] stehen (z. B. weil eine neue
/// Version der App eine neue Kachel bringt), werden beim Laden
/// automatisch hinten angehaengt und als sichtbar markiert.
class DashboardLayout {
  final List<String> orderedIds;
  final Set<String> hiddenIds;

  const DashboardLayout({
    this.orderedIds = const [],
    this.hiddenIds = const {},
  });

  bool isVisible(String id) => !hiddenIds.contains(id);

  /// Kacheln in Reihenfolge; ausgeblendete werden gefiltert.
  List<String> visibleIds(List<String> knownIds) {
    final ordered = [
      ...orderedIds.where(knownIds.contains),
      ...knownIds.where((id) => !orderedIds.contains(id)),
    ];
    return ordered.where((id) => !hiddenIds.contains(id)).toList();
  }

  /// Kacheln in Reihenfolge inkl. ausgeblendete (fuer Edit-Modus).
  List<String> allIds(List<String> knownIds) {
    return [
      ...orderedIds.where(knownIds.contains),
      ...knownIds.where((id) => !orderedIds.contains(id)),
    ];
  }

  DashboardLayout reorder(int oldIndex, int newIndex, List<String> knownIds) {
    final list = allIds(knownIds);
    if (oldIndex < 0 || oldIndex >= list.length) return this;
    final target =
        (newIndex > oldIndex ? newIndex - 1 : newIndex).clamp(0, list.length - 1);
    final id = list.removeAt(oldIndex);
    list.insert(target, id);
    return DashboardLayout(orderedIds: list, hiddenIds: hiddenIds);
  }

  DashboardLayout toggleVisibility(String id) {
    final hidden = {...hiddenIds};
    if (hidden.contains(id)) {
      hidden.remove(id);
    } else {
      hidden.add(id);
    }
    return DashboardLayout(orderedIds: orderedIds, hiddenIds: hidden);
  }

  DashboardLayout reset() => const DashboardLayout();

  String toJson() => jsonEncode({
        'orderedIds': orderedIds,
        'hiddenIds': hiddenIds.toList(),
      });

  factory DashboardLayout.fromJson(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return DashboardLayout(
        orderedIds: ((map['orderedIds'] as List?) ?? const [])
            .cast<String>(),
        hiddenIds: ((map['hiddenIds'] as List?) ?? const [])
            .cast<String>()
            .toSet(),
      );
    } catch (_) {
      return const DashboardLayout();
    }
  }
}
