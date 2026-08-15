import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  ApiClient({required this.baseUrl, String? userId, String? role, http.Client? client})
      : _userId = userId,
        _role = role,
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? _userId;
  String? _role;

  void setPrincipal({String? userId, String? role}) {
    _userId = userId;
    _role = role;
  }

  void clearPrincipal() {
    _userId = null;
    _role = null;
  }

  Map<String, String> get _headers => {
        'accept': 'application/json',
        'content-type': 'application/json',
        'x-user-id': ?_userId,
        'x-user-role': ?_role,
      };

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
        throw ApiException(
          statusCode: response.statusCode,
          code: (error['code'] as String?) ?? 'ERROR',
          message: (error['message'] as String?) ?? 'Something went wrong',
          details: error['details'],
        );
      }
    }
    throw ApiException(
      statusCode: response.statusCode,
      code: 'HTTP_${response.statusCode}',
      message: 'Request failed with status ${response.statusCode}',
    );
  }
}