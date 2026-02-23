import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/employee_document.dart';

final employeeDocumentsProvider =
    StateNotifierProvider<EmployeeDocumentsNotifier, AsyncValue<List<EmployeeDocument>>>((ref) {
  return EmployeeDocumentsNotifier();
});

final documentsByEmployeeProvider =
    Provider.family<List<EmployeeDocument>, String>((ref, employeeId) {
  final docs = ref.watch(employeeDocumentsProvider);
  return docs.valueOrNull?.where((d) => d.employeeId == employeeId).toList() ?? [];
});

class EmployeeDocumentsNotifier extends StateNotifier<AsyncValue<List<EmployeeDocument>>> {
  EmployeeDocumentsNotifier() : super(const AsyncValue.loading()) {
    _initialize();
  }

  late Directory _docsDir;

  Future<void> _initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _docsDir = Directory(p.join(appDir.path, 'personalverwaltung', 'employee_documents'));
      if (!await _docsDir.exists()) {
        await _docsDir.create(recursive: true);
      }
      await _loadDocuments();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<File> get _indexFile async {
    return File(p.join(_docsDir.path, 'index.json'));
  }

  Future<void> _loadDocuments() async {
    try {
      final file = await _indexFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        final docs = jsonList.map((j) => EmployeeDocument.fromJson(j as Map<String, dynamic>)).toList();
        state = AsyncValue.data(docs);
      } else {
        state = const AsyncValue.data(<EmployeeDocument>[]);
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> _saveIndex() async {
    final docs = state.valueOrNull ?? [];
    final file = await _indexFile;
    await file.writeAsString(json.encode(docs.map((d) => d.toJson()).toList()));
  }

  Future<EmployeeDocument?> addDocument({
    required String employeeId,
    required String name,
    required String category,
    required String sourceFilePath,
  }) async {
    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) return null;

      final fileName = p.basename(sourceFilePath);
      final fileSize = await sourceFile.length();
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final employeeDir = Directory(p.join(_docsDir.path, employeeId));
      if (!await employeeDir.exists()) {
        await employeeDir.create(recursive: true);
      }

      final destPath = p.join(employeeDir.path, '${id}_$fileName');
      await sourceFile.copy(destPath);

      final doc = EmployeeDocument(
        id: id,
        employeeId: employeeId,
        name: name,
        fileName: fileName,
        category: category,
        filePath: destPath,
        uploadedAt: DateTime.now(),
        fileSize: fileSize,
      );

      final List<EmployeeDocument> docs = [...(state.valueOrNull ?? <EmployeeDocument>[]), doc];
      state = AsyncValue.data(docs);
      await _saveIndex();
      return doc;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteDocument(String documentId) async {
    try {
      final docs = state.valueOrNull ?? [];
      final doc = docs.where((d) => d.id == documentId).firstOrNull;
      if (doc == null) return false;

      final file = File(doc.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      final updatedDocs = docs.where((d) => d.id != documentId).toList();
      state = AsyncValue.data(updatedDocs);
      await _saveIndex();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadDocuments();
  }
}
