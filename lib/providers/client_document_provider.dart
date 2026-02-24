import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/client_document.dart';

final clientDocumentsProvider =
    StateNotifierProvider<ClientDocumentsNotifier, AsyncValue<List<ClientDocument>>>((ref) {
  return ClientDocumentsNotifier();
});

final documentsByClientProvider =
    Provider.family<List<ClientDocument>, String>((ref, clientId) {
  final docs = ref.watch(clientDocumentsProvider);
  return docs.valueOrNull?.where((d) => d.clientId == clientId).toList() ?? [];
});

class ClientDocumentsNotifier extends StateNotifier<AsyncValue<List<ClientDocument>>> {
  ClientDocumentsNotifier() : super(const AsyncValue.loading()) {
    _initialize();
  }

  late Directory _docsDir;

  Future<void> _initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _docsDir = Directory(p.join(appDir.path, 'personalverwaltung', 'client_documents'));
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
        final docs = jsonList.map((j) => ClientDocument.fromJson(j as Map<String, dynamic>)).toList();
        state = AsyncValue.data(docs);
      } else {
        state = const AsyncValue.data(<ClientDocument>[]);
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

  Future<ClientDocument?> addDocument({
    required String clientId,
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

      final clientDir = Directory(p.join(_docsDir.path, clientId));
      if (!await clientDir.exists()) {
        await clientDir.create(recursive: true);
      }

      final destPath = p.join(clientDir.path, '${id}_$fileName');
      await sourceFile.copy(destPath);

      final doc = ClientDocument(
        id: id,
        clientId: clientId,
        name: name,
        fileName: fileName,
        category: category,
        filePath: destPath,
        uploadedAt: DateTime.now(),
        fileSize: fileSize,
      );

      final List<ClientDocument> docs = [...(state.valueOrNull ?? <ClientDocument>[]), doc];
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
