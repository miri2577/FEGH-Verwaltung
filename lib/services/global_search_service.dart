import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';

import 'package:fegh_billing/fegh_billing.dart' show Rechnung;

import '../models/client.dart';

/// Globale Suchergebnisse aus allen Entitaets-Typen.
class SearchResult {
  final String id;
  final String title;
  final String? subtitle;
  final SearchResultType type;
  final IconData icon;

  const SearchResult({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    required this.icon,
  });
}

enum SearchResultType {
  client,
  employee,
  team,
  shift,
  rechnung,
}

extension SearchResultTypeLabel on SearchResultType {
  String get label {
    switch (this) {
      case SearchResultType.client:
        return 'Klient';
      case SearchResultType.employee:
        return 'Mitarbeiter';
      case SearchResultType.team:
        return 'Team';
      case SearchResultType.shift:
        return 'Schicht';
      case SearchResultType.rechnung:
        return 'Rechnung';
    }
  }

  /// Ziel-Tab in der AppShell.
  String get navigationTarget {
    switch (this) {
      case SearchResultType.client:
        return 'clients';
      case SearchResultType.employee:
        return 'employees';
      case SearchResultType.team:
        return 'teams';
      case SearchResultType.shift:
        return 'shifts';
      case SearchResultType.rechnung:
        return 'rechnungen';
    }
  }
}

/// Reine Funktions-Bibliothek fuer die globale Suche — kein State.
///
/// Die Services laden die Rohdaten via ihrer Provider; dieser Service
/// vergleicht sie gegen einen Such-Query und liefert geordnete
/// Ergebnisse. Matching: case-insensitive substring, Score nach
/// Feld (title > subtitle > id).
class GlobalSearchService {
  const GlobalSearchService();

  /// Fuehrt die Suche gegen alle bekannten Entitaets-Listen aus.
  /// Leerer Query → leere Liste.
  List<SearchResult> search({
    required String query,
    List<Client> clients = const [],
    List<Employee> employees = const [],
    List<Team> teams = const [],
    List<Shift> shifts = const [],
    List<Rechnung> rechnungen = const [],
    int limit = 40,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final scored = <_ScoredResult>[];

    for (final c in clients) {
      final score = _scoreClient(c, q);
      if (score > 0) {
        scored.add(_ScoredResult(
          score: score,
          result: SearchResult(
            id: c.id,
            title: c.fullName,
            subtitle: [
              if (c.klientenId != null && c.klientenId!.isNotEmpty)
                'ID ${c.klientenId}',
              if (c.status != ClientStatus.active) c.statusDisplayName,
              if (c.teamId != null) 'Team ${c.teamId}',
            ].join(' • '),
            type: SearchResultType.client,
            icon: Symbols.person,
          ),
        ));
      }
    }

    for (final e in employees) {
      final score = _scoreEmployee(e, q);
      if (score > 0) {
        scored.add(_ScoredResult(
          score: score,
          result: SearchResult(
            id: e.id,
            title: e.fullName,
            subtitle: [
              if (e.email.isNotEmpty) e.email,
              if (e.position.isNotEmpty) e.position,
            ].join(' • '),
            type: SearchResultType.employee,
            icon: Symbols.badge,
          ),
        ));
      }
    }

    for (final t in teams) {
      final score = _scoreTeam(t, q);
      if (score > 0) {
        scored.add(_ScoredResult(
          score: score,
          result: SearchResult(
            id: t.id,
            title: t.name,
            subtitle: [
              if (t.location != null) t.location!,
              '${t.memberIds.length} Mitglieder',
              '${t.clientIds.length} Klienten',
            ].join(' • '),
            type: SearchResultType.team,
            icon: Symbols.groups,
          ),
        ));
      }
    }

    for (final s in shifts) {
      final score = _scoreShift(s, q);
      if (score > 0) {
        scored.add(_ScoredResult(
          score: score,
          result: SearchResult(
            id: s.id,
            title: '${s.startTime.day}.${s.startTime.month}.${s.startTime.year} '
                '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')} – '
                '${s.endTime.hour.toString().padLeft(2, '0')}:${s.endTime.minute.toString().padLeft(2, '0')}',
            subtitle: [
              s.type.displayName,
              if (s.location != null) s.location!,
              s.status.displayName,
            ].join(' • '),
            type: SearchResultType.shift,
            icon: Symbols.schedule,
          ),
        ));
      }
    }

    for (final r in rechnungen) {
      final score = _scoreRechnung(r, q);
      if (score > 0) {
        scored.add(_ScoredResult(
          score: score,
          result: SearchResult(
            id: r.id,
            title: r.rechnungsnummer,
            subtitle: [
              r.rechnungsdatum.toIso8601String().split('T').first,
              if (r.bemerkung != null && r.bemerkung!.isNotEmpty)
                r.bemerkung!,
            ].join(' • '),
            type: SearchResultType.rechnung,
            icon: Symbols.receipt_long,
          ),
        ));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((s) => s.result).toList();
  }

  // ── Scoring ──────────────────────────────────────────────────

  int _scoreClient(Client c, String q) {
    var score = 0;
    if (c.fullName.toLowerCase().contains(q)) score += 100;
    if ((c.klientenId ?? '').toLowerCase().contains(q)) score += 80;
    if ((c.email ?? '').toLowerCase().contains(q)) score += 40;
    if ((c.phone ?? '').toLowerCase().contains(q)) score += 30;
    if ((c.address ?? '').toLowerCase().contains(q)) score += 20;
    return score;
  }

  int _scoreEmployee(Employee e, String q) {
    var score = 0;
    if (e.fullName.toLowerCase().contains(q)) score += 100;
    if (e.email.toLowerCase().contains(q)) score += 80;
    if (e.position.toLowerCase().contains(q)) score += 30;
    return score;
  }

  int _scoreTeam(Team t, String q) {
    var score = 0;
    if (t.name.toLowerCase().contains(q)) score += 100;
    if (t.description.toLowerCase().contains(q)) score += 40;
    if ((t.location ?? '').toLowerCase().contains(q)) score += 30;
    return score;
  }

  int _scoreShift(Shift s, String q) {
    var score = 0;
    if ((s.description ?? '').toLowerCase().contains(q)) score += 60;
    if ((s.location ?? '').toLowerCase().contains(q)) score += 40;
    if (s.employeeId.toLowerCase().contains(q)) score += 20;
    if ((s.notes ?? '').toLowerCase().contains(q)) score += 20;
    return score;
  }

  int _scoreRechnung(Rechnung r, String q) {
    var score = 0;
    if (r.rechnungsnummer.toLowerCase().contains(q)) score += 100;
    if ((r.bemerkung ?? '').toLowerCase().contains(q)) score += 40;
    if ((r.bestellnummer ?? '').toLowerCase().contains(q)) score += 40;
    return score;
  }
}

class _ScoredResult {
  final int score;
  final SearchResult result;
  const _ScoredResult({required this.score, required this.result});
}
