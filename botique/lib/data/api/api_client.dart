import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../models/product.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({required this.baseUrl, this._token, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? _token;

  /// Invoked when a request is rejected with 401 so the app can clear the
  /// expired session. Set by the auth layer; must never retry in a loop.
  void Function()? onUnauthorized;

  void setToken(String? token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _authHeaders => {
        'accept': 'application/json',
        if (_token != null && _token!.isNotEmpty) 'authorization': 'Bearer $_token',
      };

  Map<String, String> get _headers => {..._authHeaders, 'content-type': 'application/json'};

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: {
        for (final e in query.entries)
          e.key: e.value is List ? (e.value as List).join(',') : e.value.toString(),
      });
    }
    return uri;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _client.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query}) =>
      _send(() => _client.post(_uri(path, query), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> patch(String path, {Object? body, Map<String, dynamic>? query}) =>
      _send(() => _client.patch(_uri(path, query), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) =>
      _send(() => _client.delete(_uri(path, query), headers: _headers));

  /// Uploads image files as multipart/form-data. Returns the `data` payload.
  Future<dynamic> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    List<UploadImage> images = const [],
  }) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(_authHeaders)
      ..fields.addAll(fields);
    for (final image in images) {
      request.files.add(http.MultipartFile.fromBytes(
        'images',
        image.bytes,
        filename: image.filename,
        contentType: MediaType.parse(image.mimeType),
      ));
    }
    return _send(() async => http.Response.fromStream(await _client.send(request)));
  }

  /// Resolves backend-relative asset URLs (e.g. `/images/abc.png`) against the
  /// API base URL while leaving absolute URLs untouched.
  String resolveImageUrl(String url) {
    if (url.isEmpty || url.startsWith('http://') || url.startsWith('https://')) return url;
    return url.startsWith('/') ? '$baseUrl$url' : '$baseUrl/$url';
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request();
    } on TimeoutException {
      throw const ApiException(statusCode: 0, code: 'TIMEOUT', message: 'The server took too long to respond.');
    } on http.ClientException catch (e) {
      throw ApiException(statusCode: 0, code: 'NETWORK', message: e.message);
    }

    Object? decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded['success'] == true) {
        return decoded['data'];
      }
      return decoded;
    }

    if (decoded is Map<String, dynamic> && decoded['success'] == false) {
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        final exception = ApiException(
          statusCode: response.statusCode,
          code: (error['code'] as String?) ?? 'ERROR',
          message: (error['message'] as String?) ?? 'Something went wrong',
          details: error['details'],
        );
        if (exception.statusCode == 401) {
          onUnauthorized?.call();
        }
        throw exception;
      }
    }
    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }
    throw ApiException(
      statusCode: response.statusCode,
      code: 'HTTP_${response.statusCode}',
      message: 'Request failed with status ${response.statusCode}',
    );
  }
}