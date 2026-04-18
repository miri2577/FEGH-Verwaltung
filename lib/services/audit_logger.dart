import 'package:fegh_compliance/fegh_compliance.dart' as shared;

/// Verwaltungs-Fassade fuer den gemeinsamen AuditLogger.
///
/// Die Legacy-API der Verwaltung (static `log` und `tail`) wird hier
/// 1:1 erhalten, intern delegiert alles an den Shared-Logger
/// `fegh_compliance.AuditLogger` (Singleton).
///
/// Damit loggen beide Apps (Doku + Verwaltung) in die gleiche
/// JSON-Lines-Datei im Application-Support-Verzeichnis, mit
/// identischem Schema (ts, action, userId, ctx).
class AuditLogger {
  /// Schreibt einen Audit-Eintrag. Default-userId `system` fuer
  /// Verwaltungs-Aufrufe ohne expliziten User.
  static Future<void> log(String action, {Map<String, dynamic>? context}) {
    return shared.AuditLogger.logStatic(action, context: context);
  }

  /// Liefert die letzten [lines] Eintraege als JSON-Strings.
  static Future<List<String>> tail({int lines = 200}) {
    return shared.AuditLogger.tail(lines: lines);
  }
}
