import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrlOverride = baseUrl;

  static const _accessTokenKey = 'mova_access_token';
  static const _refreshTokenKey = 'mova_refresh_token';

  static ApiClient _instance = ApiClient();

  static ApiClient get instance => _instance;

  @visibleForTesting
  static void overrideInstanceForTesting(ApiClient client) {
    _instance = client;
  }

  final http.Client _client;
  final String? _baseUrlOverride;

  Uri get _baseUri {
    const configuredUrl = String.fromEnvironment('MOVA_API_BASE_URL');
    final baseUrl = (_baseUrlOverride ?? configuredUrl).trim();
    if (baseUrl.isEmpty) {
      throw const ApiException(
        0,
        'Backend URL is not configured. Launch with '
        '--dart-define=MOVA_API_BASE_URL=<API base URL>.',
      );
    }
    final normalizedUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(normalizedUrl);
  }

  Future<String?> get accessToken async =>
      (await SharedPreferences.getInstance()).getString(_accessTokenKey);

  Future<String?> get refreshToken async =>
      (await SharedPreferences.getInstance()).getString(_refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_accessTokenKey, accessToken);
    await preferences.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> clearTokens() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
  }

  Future<dynamic> get(
    String path, {
    Map<String, String> query = const {},
    bool authenticated = true,
  }) => _request('GET', path, query: query, authenticated: authenticated);

  Future<dynamic> post(
    String path, {
    Object? body,
    bool authenticated = true,
    Map<String, String> headers = const {},
  }) => _request(
    'POST',
    path,
    body: body,
    authenticated: authenticated,
    extraHeaders: headers,
  );

  Future<dynamic> patch(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => _request('PATCH', path, body: body, authenticated: authenticated);

  Future<dynamic> delete(String path, {bool authenticated = true}) =>
      _request('DELETE', path, authenticated: authenticated);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String> query = const {},
    Object? body,
    bool authenticated = true,
    Map<String, String> extraHeaders = const {},
    bool allowRefresh = true,
  }) async {
    final uri = _baseUri
        .resolve(path)
        .replace(queryParameters: query.isEmpty ? null : query);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      ...extraHeaders,
    };
    if (authenticated) {
      final token = await accessToken;
      if (token == null || token.isEmpty) {
        throw const ApiException(401, 'Please sign in to continue.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    final streamedResponse = await _client
        .send(request)
        .timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = response.body.isEmpty ? null : _decodeBody(response.body);
    if (response.statusCode == 401 &&
        authenticated &&
        allowRefresh &&
        path != 'auth/refresh' &&
        await _refreshAccessToken()) {
      return _request(
        method,
        path,
        query: query,
        body: body,
        authenticated: authenticated,
        extraHeaders: extraHeaders,
        allowRefresh: false,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        _errorMessage(decoded, response.statusCode),
      );
    }
    return decoded;
  }

  Future<bool> _refreshAccessToken() async {
    final token = await refreshToken;
    if (token == null || token.isEmpty) return false;
    try {
      final response = await _request(
        'POST',
        'auth/refresh',
        body: {'refreshToken': token},
        authenticated: false,
        allowRefresh: false,
      );
      if (response is! Map) return false;
      final data = response['data'] is Map ? response['data'] as Map : response;
      final tokens = data['tokens'] ?? response['tokens'];
      final tokenResponse = tokens is Map ? tokens : data;
      final access =
          (tokenResponse['accessToken'] ?? tokenResponse['access_token'])
              ?.toString();
      final refresh =
          (tokenResponse['refreshToken'] ?? tokenResponse['refresh_token'])
              ?.toString();
      if (access == null ||
          access.isEmpty ||
          refresh == null ||
          refresh.isEmpty) {
        return false;
      }
      await saveTokens(accessToken: access, refreshToken: refresh);
      return true;
    } on ApiException {
      await clearTokens();
      return false;
    }
  }

  dynamic _decodeBody(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  String _errorMessage(dynamic body, int statusCode) {
    if (body is Map<String, dynamic>) {
      final message = body['message'] ?? body['error'];
      if (message is List) return message.join('\n');
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    return 'Request failed ($statusCode). Please try again.';
  }
}
