import 'package:fegh_cloud/fegh_cloud.dart' as cloud;
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

class WebDAVResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  WebDAVResult.success(this.data) : success = true, error = null, statusCode = null;
  WebDAVResult.failure(this.error, [this.statusCode]) : success = false, data = null;
}

class HiDriveConfig {
  static const String defaultBaseUrl = 'https://webdav.hidrive.strato.com/users';

  // TODO: Echte STRATO HiDrive TLS-Zertifikat-Pins eintragen.
  // Pins mit `openssl s_client -connect webdav.hidrive.strato.com:443` ermitteln.
  // Aktuell nicht implementiert — Pins werden noch nicht für Pinning genutzt.
  static List<String> get certificatePins => [];

  static String buildWebDAVUrl(String username, {String? subdirectory}) {
    final subdir = subdirectory != null ? '/$subdirectory' : '';
    return '$defaultBaseUrl/$username$subdir';
  }
}

class WebDAVResource {
  final String href;
  final String displayName;
  final DateTime? lastModified;
  final int? contentLength;
  final String contentType;
  final bool isCollection;

  WebDAVResource({
    required this.href,
    required this.displayName,
    this.lastModified,
    this.contentLength,
    required this.contentType,
    required this.isCollection,
  });

  factory WebDAVResource.fromXml(XmlElement element) {
    final href = element.findElements('d:href').first.innerText;
    final propstat = element.findElements('d:propstat').first;
    final prop = propstat.findElements('d:prop').first;

    final displayName = prop.findElements('d:displayname').isNotEmpty
        ? prop.findElements('d:displayname').first.innerText
        : href.split('/').last;

    final lastModifiedString = prop.findElements('d:getlastmodified').isNotEmpty
        ? prop.findElements('d:getlastmodified').first.innerText
        : null;

    final contentLengthString = prop.findElements('d:getcontentlength').isNotEmpty
        ? prop.findElements('d:getcontentlength').first.innerText
        : null;

    final contentType = prop.findElements('d:getcontenttype').isNotEmpty
        ? prop.findElements('d:getcontenttype').first.innerText
        : 'application/octet-stream';

    final isCollection = prop.findElements('d:resourcetype').isNotEmpty &&
        prop.findElements('d:resourcetype').first.findElements('d:collection').isNotEmpty;

    return WebDAVResource(
      href: href,
      displayName: displayName,
      lastModified: lastModifiedString != null
          ? DateTime.tryParse(lastModifiedString)
          : null,
      contentLength: contentLengthString != null
          ? int.tryParse(contentLengthString)
          : null,
      contentType: contentType,
      isCollection: isCollection,
    );
  }
}

class CloudWebDavClient {
  final String username;
  final String password;
  final String baseUrl;
  late final cloud.HidriveAdapter _adapter;

  CloudWebDavClient({
    required this.username,
    required this.password,
    String? customBaseUrl,
  }) : baseUrl = customBaseUrl ?? HiDriveConfig.buildWebDAVUrl(username) {
    _adapter = cloud.HidriveAdapter(
      username: username,
      password: password,
      baseUrlOverride: baseUrl,
    );
  }

  // propfind bleibt als detaillierte Abfrage bestehen; intern delegiert sie
  // an adapter.list und mappt auf die PV-Modellklasse WebDAVResource.
  Future<WebDAVResult<List<WebDAVResource>>> propfind(String path, {int depth = 1}) async {
    final result = await _adapter.list(path);
    if (!result.isSuccess) {
      return WebDAVResult.failure(
        result.error ?? 'PROPFIND fehlgeschlagen',
        result.statusCode,
      );
    }
    final resources = result.data!
        .map((e) => WebDAVResource(
              href: e.path,
              displayName: e.name,
              lastModified: e.lastModified,
              contentLength: e.size,
              contentType: e.isDirectory
                  ? 'httpd/unix-directory'
                  : 'application/octet-stream',
              isCollection: e.isDirectory,
            ))
        .toList();
    return WebDAVResult.success(resources);
  }

  Future<WebDAVResult<List<WebDAVResource>>> listDetailed(String path) async {
    return await propfind(path, depth: 1);
  }

  Future<WebDAVResult<List<String>>> list(String path) async {
    final res = await propfind(path, depth: 1);
    if (!res.success || res.data == null) {
      return WebDAVResult.failure(res.error, res.statusCode);
    }
    final names = res.data!
        .where((e) => !e.isCollection)
        .map((e) => e.displayName)
        .where((n) => n.isNotEmpty)
        .toList();
    return WebDAVResult.success(names);
  }

  Future<WebDAVResult<void>> put(String path, List<int> data) async {
    final sw = Stopwatch()..start();
    debugPrint('[WebDAV] PUT $path (${data.length}B)');
    final result = await _adapter.upload(path, Uint8List.fromList(data));
    if (result.isSuccess) {
      debugPrint('[WebDAV] PUT OK ${sw.elapsedMilliseconds}ms');
      return WebDAVResult.success(null);
    }
    debugPrint('[WebDAV] PUT FAIL ${result.error}');
    return WebDAVResult.failure(result.error, result.statusCode);
  }

  Future<WebDAVResult<List<int>>> get(String path) async {
    final sw = Stopwatch()..start();
    debugPrint('[WebDAV] GET $path');
    final result = await _adapter.download(path);
    if (result.isSuccess) {
      debugPrint('[WebDAV] GET OK ${result.data!.length}B ${sw.elapsedMilliseconds}ms');
      return WebDAVResult.success(result.data!);
    }
    if (result.statusCode == 404) {
      debugPrint('[WebDAV] GET 404 ${sw.elapsedMilliseconds}ms');
      return WebDAVResult.failure('File not found', 404);
    }
    debugPrint('[WebDAV] GET FAIL ${result.error}');
    return WebDAVResult.failure(result.error, result.statusCode);
  }

  Future<WebDAVResult<void>> delete(String path) async {
    final result = await _adapter.delete(path);
    if (result.isSuccess) return WebDAVResult.success(null);
    return WebDAVResult.failure(result.error, result.statusCode);
  }

  Future<WebDAVResult<void>> mkcol(String path) async {
    final result = await _adapter.createDirectory(path);
    if (result.isSuccess) return WebDAVResult.success(null);
    return WebDAVResult.failure(result.error, result.statusCode);
  }

  Future<WebDAVResult<bool>> exists(String path) async {
    final result = await _adapter.exists(path);
    if (result.isSuccess) return WebDAVResult.success(result.data!);
    return WebDAVResult.failure(result.error, result.statusCode);
  }

  void dispose() {
    _adapter.dispose();
  }
}
