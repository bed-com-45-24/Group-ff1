import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mova/services/api_client.dart';
import 'package:mova/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('API requests fail clearly when no server URL is configured', () async {
    final client = ApiClient(
      baseUrl: '',
      client: MockClient((_) async {
        fail('An API request must not be sent without a configured URL.');
      }),
    );

    await expectLater(
      client.get('routes', authenticated: false),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('Backend URL is not configured'),
        ),
      ),
    );
  });

  test('login uses API tokens and the server-assigned account role', () async {
    SharedPreferences.setMockInitialValues({});
    final requests = <http.Request>[];
    final client = ApiClient(
      baseUrl: 'https://mova.test/api/v1',
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response(
            jsonEncode({
              'accessToken': 'access-token',
              'refreshToken': 'refresh-token',
            }),
            201,
          );
        }
        if (request.url.path.endsWith('/me')) {
          return http.Response(
            jsonEncode({
              'id': 42,
              'email': 'admin@example.test',
              'name': 'Approved Admin',
              'role': 'admin',
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/auth/logout')) {
          return http.Response('', 201);
        }
        return http.Response('Not found', 404);
      }),
    );
    final auth = AuthService(apiClient: client);

    expect(await auth.login('admin@example.test', 'secret-password'), isTrue);
    expect(await auth.getUserRole(), 'admin');
    expect(requests.first.url.path, '/api/v1/auth/login');
    expect(jsonDecode(requests.first.body), {
      'email': 'admin@example.test',
      'password': 'secret-password',
    });
    expect(requests.last.headers['authorization'], 'Bearer access-token');

    await auth.logout();
    expect(await client.accessToken, isNull);
    expect(requests.last.url.path, '/api/v1/auth/logout');
  });

  test('registration does not allow assigning an admin role locally', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService(
      apiClient: ApiClient(
        baseUrl: 'https://mova.test/api/v1',
        client: MockClient((_) async {
          fail('Admin registration must not reach the API.');
        }),
      ),
    );

    await expectLater(
      auth.signup(
        'admin@example.test',
        'secret-password',
        'Unapproved Admin',
        role: 'admin',
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('frontend-only auth supports demo admin and Gmail passengers', () async {
    final auth = AuthService(backendEnabled: false);

    expect(await auth.login('admin@mova.test', 'password123'), isTrue);
    expect(await auth.getUserRole(), 'admin');
    await auth.logout();

    expect(
      await auth.signup(
        'passenger@gmail.com',
        'password123',
        'Demo Passenger',
        role: 'passenger',
      ),
      isTrue,
    );
    expect(await auth.login('passenger@gmail.com', 'password123'), isTrue);
    expect(await auth.getUserRole(), 'passenger');
    expect(await auth.getUserName(), 'Demo Passenger');
    await auth.logout();
  });
}
