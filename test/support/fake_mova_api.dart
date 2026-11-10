import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mova/data/sample_data.dart';
import 'package:mova/services/api_client.dart';

class FakeMovaApi {
  final Map<String, _FakeUser> _users = {};
  int _nextId = 1;

  FakeMovaApi() {
    addUser(
      email: 'admin@mova.test',
      password: 'password123',
      name: 'MOVA Admin',
      role: 'admin',
    );
  }

  late final http.Client client = MockClient(_handle);

  String addUser({
    required String email,
    required String password,
    required String name,
    String role = 'passenger',
    String phone = '',
    String identificationNumber = '',
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final user = _FakeUser(
      id: _nextId++,
      email: normalizedEmail,
      password: password,
      name: name,
      role: role,
      phone: phone,
      identificationNumber: identificationNumber,
    );
    _users[normalizedEmail] = user;
    return _accessToken(user);
  }

  void install() {
    ApiClient.overrideInstanceForTesting(
      ApiClient(client: client, baseUrl: 'https://mova.test/api/v1'),
    );
  }

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path.replaceFirst('/api/v1', '');
    final body = request.body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(request.body) as Map);

    if (request.method == 'POST' && path == '/auth/register') {
      final email = body['email']?.toString().trim().toLowerCase() ?? '';
      if (_users.containsKey(email)) {
        return _json({
          'message': 'An account with this email already exists.',
        }, 409);
      }
      addUser(
        email: email,
        password: body['password']?.toString() ?? '',
        name: body['name']?.toString() ?? '',
      );
      return _json({'message': 'Account created.'}, 201);
    }

    if (request.method == 'POST' && path == '/auth/login') {
      final email = body['email']?.toString().trim().toLowerCase() ?? '';
      final user = _users[email];
      if (user == null || user.password != body['password']) {
        return _json({'message': 'Invalid credentials.'}, 401);
      }
      return _json({
        'accessToken': _accessToken(user),
        'refreshToken': _refreshToken(user),
      }, 200);
    }

    if (request.method == 'POST' && path == '/auth/refresh') {
      final refreshToken = body['refreshToken']?.toString() ?? '';
      final user = _userForToken(refreshToken, prefix: 'test-refresh-');
      if (user == null) {
        return _json({'message': 'Invalid refresh token.'}, 401);
      }
      return _json({
        'tokens': {
          'accessToken': _accessToken(user),
          'refreshToken': _refreshToken(user),
        },
      }, 200);
    }

    if (request.method == 'POST' && path == '/auth/logout') {
      return http.Response('', 204);
    }

    final user = _authorizedUser(request);
    if (request.method == 'GET' && path == '/me') {
      if (user == null) return _unauthorized();
      return _json({
        'data': {
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'role': user.role,
        },
      }, 200);
    }

    if (path == '/me/passenger-profile') {
      if (user == null) return _unauthorized();
      if (request.method == 'PATCH') {
        final updatedEmail =
            body['email']?.toString().trim().toLowerCase() ?? user.email;
        if (updatedEmail != user.email) {
          _users.remove(user.email);
          user.email = updatedEmail;
          _users[updatedEmail] = user;
        }
        user.name = body['name']?.toString() ?? user.name;
        user.phone = body['phone']?.toString() ?? user.phone;
        user.identificationNumber =
            body['identificationNumber']?.toString() ??
            user.identificationNumber;
      } else if (request.method != 'GET') {
        return _notFound();
      }
      return _json({
        'data': {
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'identificationNumber': user.identificationNumber,
        },
      }, 200);
    }

    if (request.method == 'GET' &&
        {
          '/routes',
          '/routes/admin/list',
          '/schedules',
          '/schedules/admin/list',
          '/bookings/mine',
          '/bookings/admin/list',
        }.contains(path)) {
      if (path == '/routes' || path == '/routes/admin/list') {
        return _json({
          'data': sampleRoutes.map((route) => route.toJson()).toList(),
        }, 200);
      }
      return _json({'data': []}, 200);
    }

    return _notFound();
  }

  _FakeUser? _authorizedUser(http.Request request) {
    final authorization = request.headers['authorization'] ?? '';
    if (!authorization.startsWith('Bearer ')) return null;
    return _userForToken(
      authorization.substring('Bearer '.length),
      prefix: 'test-access-',
    );
  }

  _FakeUser? _userForToken(String token, {required String prefix}) {
    if (!token.startsWith(prefix)) return null;
    return _users[token.substring(prefix.length).toLowerCase()];
  }

  String _accessToken(_FakeUser user) => 'test-access-${user.email}';
  String _refreshToken(_FakeUser user) => 'test-refresh-${user.email}';

  http.Response _unauthorized() =>
      _json({'message': 'Please sign in to continue.'}, 401);

  http.Response _notFound() => _json({'message': 'Not found.'}, 404);

  http.Response _json(Object body, int statusCode) => http.Response(
    jsonEncode(body),
    statusCode,
    headers: const {'content-type': 'application/json'},
  );
}

class _FakeUser {
  final int id;
  String email;
  final String password;
  String name;
  final String role;
  String phone;
  String identificationNumber;

  _FakeUser({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    required this.phone,
    required this.identificationNumber,
  });
}
