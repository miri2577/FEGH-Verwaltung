import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AuditLogger {
  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    final f = File('${dir.path}/audit.log');
    if (!(await f.exists())) await f.create(recursive: true);
    return f;
  }

  static Future<void> log(String action, {Map<String, dynamic>? context}) async {
    try {
      final f = await _file();
      final line = jsonEncode({
        'ts': DateTime.now().toUtc().toIso8601String(),
        'action': action,
        'ctx': context ?? {},
      });
      await f.writeAsString(line + '\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  static Future<List<String>> tail({int lines = 200}) async {
    try {
      final f = await _file();
      final content = await f.readAsLines();
      if (content.length <= lines) return content;
      return content.sublist(content.length - lines);
    } catch (_) {
      return [];
    }
  }
}

