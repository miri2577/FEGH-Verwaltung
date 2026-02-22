import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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

class HiDriveWebDAVClient {
  final String username;
  final String password;
  final String baseUrl;
  late final http.Client _client;

  HiDriveWebDAVClient({
    required this.username,
    required this.password,
    String? customBaseUrl,
  }) : baseUrl = customBaseUrl ?? HiDriveConfig.buildWebDAVUrl(username) {
    _client = http.Client();
  }

  Map<String, String> get _headers {
    final credentials = base64Encode(utf8.encode('$username:$password'));
    return {
      'Authorization': 'Basic $credentials',
      'User-Agent': 'PersonalverwaltungApp/1.0.0',
      'Accept': '*/*',
    };
  }

  Future<WebDAVResult<List<WebDAVResource>>> propfind(String path, {int depth = 1}) async {
    try {
      final url = '$baseUrl/$path'.replaceAll('//', '/').replaceFirst(':/', '://');

      final propfindBody = '''<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:displayname/>
    <d:getcontentlength/>
    <d:getcontenttype/>
    <d:getlastmodified/>
    <d:resourcetype/>
  </d:prop>
</d:propfind>''';

      final response = await _client.send(http.Request('PROPFIND', Uri.parse(url))
        ..headers.addAll(_headers)
        ..headers['Content-Type'] = 'application/xml'
        ..headers['Depth'] = depth.toString()
        ..body = propfindBody);

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 207) { // Multi-Status
        final document = XmlDocument.parse(responseBody);
        final responses = document.findAllElements('d:response');

        final resources = responses.map((element) => WebDAVResource.fromXml(element)).toList();
        return WebDAVResult.success(resources);
      } else {
        return WebDAVResult.failure(
          'PROPFIND failed: ${response.reasonPhrase}',
          response.statusCode,
        );
      }
    } catch (e) {
      return WebDAVResult.failure('PROPFIND error: $e');
    }
  }

  // Convenience: list children with details (filters out the queried folder itself)
  Future<WebDAVResult<List<WebDAVResource>>> listDetailed(String path) async {
    final res = await propfind(path, depth: 1);
    if (!res.success || res.data == null) return WebDAVResult.failure(res.error, res.statusCode);
    final items = List<WebDAVResource>.from(res.data!);
    // Most PROPFIND responses include the directory itself as the first item.
    if (items.isNotEmpty) items.removeAt(0);
    return WebDAVResult.success(items);
  }

  // Convenience: list plain file names (non-collections) in a directory
  Future<WebDAVResult<List<String>>> list(String path) async {
    final res = await listDetailed(path);
    if (!res.success || res.data == null) return WebDAVResult.failure(res.error, res.statusCode);
    final names = res.data!
        .where((e) => !e.isCollection)
        .map((e) => e.displayName)
        .where((name) => name.isNotEmpty)
        .toList();
    return WebDAVResult.success(names);
  }

  Future<WebDAVResult<void>> put(String path, List<int> data) async {
    try {
      final url = '$baseUrl/$path'.replaceAll('//', '/').replaceFirst(':/', '://');
      final sw = Stopwatch()..start();
      debugPrint('[WebDAV] PUT $url (${data.length}B)');

      final response = await _client
          .put(
        Uri.parse(url),
        headers: {
          ..._headers,
          'Content-Type': 'application/octet-stream',
          'Content-Length': data.length.toString(),
        },
        body: data,
      )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 201 || response.statusCode == 204) {
        debugPrint('[WebDAV] PUT OK ${sw.elapsedMilliseconds}ms');
        return WebDAVResult.success(null);
      } else {
        debugPrint('[WebDAV] PUT FAIL ${response.statusCode} ${response.reasonPhrase} ${sw.elapsedMilliseconds}ms');
        return WebDAVResult.failure(
          'PUT failed: ${response.reasonPhrase}',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('[WebDAV] PUT error: $e');
      return WebDAVResult.failure('PUT error: $e');
    }
  }

  Future<WebDAVResult<List<int>>> get(String path) async {
    try {
      final url = '$baseUrl/$path'.replaceAll('//', '/').replaceFirst(':/', '://');
      final sw = Stopwatch()..start();
      debugPrint('[WebDAV] GET $url');

      final response = await _client
          .get(
        Uri.parse(url),
        headers: _headers,
      )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        debugPrint('[WebDAV] GET OK ${response.bodyBytes.length}B ${sw.elapsedMilliseconds}ms');
        return WebDAVResult.success(response.bodyBytes);
      } else if (response.statusCode == 404) {
        debugPrint('[WebDAV] GET 404 ${sw.elapsedMilliseconds}ms');
        return WebDAVResult.failure('File not found', response.statusCode);
      } else {
        debugPrint('[WebDAV] GET FAIL ${response.statusCode} ${response.reasonPhrase} ${sw.elapsedMilliseconds}ms');
        return WebDAVResult.failure(
          'GET failed: ${response.reasonPhrase}',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('[WebDAV] GET error: $e');
      return WebDAVResult.failure('GET error: $e');
    }
  }

  Future<WebDAVResult<void>> delete(String path) async {
    try {
      final url = '$baseUrl/$path'.replaceAll('//', '/').replaceFirst(':/', '://');

      final response = await _client.delete(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 204 || response.statusCode == 404) {
        return WebDAVResult.success(null);
      } else {
        return WebDAVResult.failure(
          'DELETE failed: ${response.reasonPhrase}',
          response.statusCode,
        );
      }
    } catch (e) {
      return WebDAVResult.failure('DELETE error: $e');
    }
  }

  Future<WebDAVResult<void>> mkcol(String path) async {
    try {
      final url = '$baseUrl/$path'.replaceAll('//', '/').replaceFirst(':/', '://');

      final response = await _client.send(http.Request('MKCOL', Uri.parse(url))
        ..headers.addAll(_headers));

      final statusCode = response.statusCode;
      if (statusCode == 201 || statusCode == 405) { // 405 means already exists
        return WebDAVResult.success(null);
      } else {
        return WebDAVResult.failure(
          'MKCOL failed: ${response.reasonPhrase}',
          statusCode,
        );
      }
    } catch (e) {
      return WebDAVResult.failure('MKCOL error: $e');
    }
  }

  Future<WebDAVResult<bool>> exists(String path) async {
    final result = await propfind(path, depth: 0);
    if (result.success) {
      return WebDAVResult.success(true);
    } else if (result.statusCode == 404) {
      return WebDAVResult.success(false);
    } else {
      return WebDAVResult.failure(result.error);
    }
  }

  void dispose() {
    _client.close();
  }
}
