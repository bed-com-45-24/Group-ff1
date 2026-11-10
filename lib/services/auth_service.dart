import 'app_config.dart';
import 'api_client.dart';

class AuthService {
  AuthService({ApiClient? apiClient, bool? backendEnabled})
    : _apiClient = apiClient ?? ApiClient.instance,
      _backendEnabled = backendEnabled ?? AppConfig.backendEnabled;

  static final Map<String, _DemoUser> _demoUsers = {
    'admin@mova.test': _DemoUser(
      email: 'admin@mova.test',
      password: 'password123',
      name: 'MOVA Demo Admin',
      role: 'admin',
    ),
  };
  static _DemoUser? _currentDemoUser;

  final ApiClient _apiClient;
  final bool _backendEnabled;

  Future<bool> isLoggedIn() async => _backendEnabled
      ? (await _apiClient.accessToken) != null
      : _currentDemoUser != null;

  Future<String?> getUserEmail() async => _backendEnabled
      ? _stringField(await _loadCurrentUser(), ['email'])
      : _currentDemoUser?.email;

  Future<String?> getUserName() async => _backendEnabled
      ? _stringField(await _loadCurrentUser(), ['name', 'fullName'])
      : _currentDemoUser?.name;

  Future<String?> getUserRole() async {
    if (!_backendEnabled) return _currentDemoUser?.role;
    final user = await _loadCurrentUser();
    final role = _roleFor(user);
    if (role != null) return role;
    throw const FormatException(
      'The API did not return a role for the signed-in user.',
    );
  }

  Future<Map<String, String>> getPassengerDetails() async {
    if (!_backendEnabled) {
      final user = _requireDemoUser();
      return {
        'name': user.name,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'identificationNumber': user.identificationNumber,
      };
    }
    final profile = _asMap(
      await _apiClient.get('me/passenger-profile'),
      responseName: 'passenger profile',
    );
    return {
      'name': (profile['name'] ?? '').toString(),
      'email': (profile['email'] ?? '').toString(),
      'phoneNumber': (profile['phone'] ?? profile['phoneNumber'] ?? '')
          .toString(),
      'identificationNumber': (profile['identificationNumber'] ?? '')
          .toString(),
    };
  }

  Future<void> savePassengerDetails({
    required String name,
    required String email,
    required String phoneNumber,
    required String identificationNumber,
  }) async {
    if (!_backendEnabled) {
      final user = _requireDemoUser();
      final updatedEmail = email.trim().toLowerCase();
      if (updatedEmail != user.email) {
        _demoUsers.remove(user.email);
        user.email = updatedEmail;
        _demoUsers[updatedEmail] = user;
      }
      user
        ..name = name.trim()
        ..phoneNumber = phoneNumber.trim()
        ..identificationNumber = identificationNumber.trim();
      return;
    }
    await _apiClient.patch(
      'me/passenger-profile',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phoneNumber.trim(),
        'identificationNumber': identificationNumber.trim(),
      },
    );
  }

  Future<bool> login(String email, String password) async {
    if (!_backendEnabled) {
      final normalizedEmail = email.trim().toLowerCase();
      final user = _demoUsers[normalizedEmail];
      if (user == null || user.password != password) {
        throw const ApiException(401, 'Email or password is incorrect.');
      }
      _currentDemoUser = user;
      return true;
    }
    final rawResponse = await _apiClient.post(
      'auth/login',
      authenticated: false,
      body: {'email': email.trim(), 'password': password},
    );
    if (rawResponse is! Map) {
      throw const FormatException('The API returned an invalid login.');
    }
    final response = Map<String, dynamic>.from(rawResponse);
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'] as Map)
        : response;
    final tokenValue = data['tokens'] ?? response['tokens'];
    final tokens = tokenValue is Map
        ? Map<String, dynamic>.from(tokenValue)
        : data;
    final accessToken = _stringField(tokens, ['accessToken', 'access_token']);
    final refreshToken = _stringField(tokens, [
      'refreshToken',
      'refresh_token',
    ]);
    if (accessToken == null || refreshToken == null) {
      throw const FormatException(
        'The API login response did not include both tokens.',
      );
    }
    await _apiClient.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    try {
      final user = await _loadCurrentUser();
      if (_roleFor(user) == null) {
        throw const FormatException(
          'The API did not return a role for the signed-in user.',
        );
      }
      return true;
    } catch (_) {
      await _apiClient.clearTokens();
      rethrow;
    }
  }

  Future<bool> signup(
    String email,
    String password,
    String name, {
    required String role,
  }) async {
    if (role != 'passenger') {
      throw const ApiException(
        403,
        'Administrator access must be granted by the backend.',
      );
    }
    if (!_backendEnabled) {
      final normalizedEmail = email.trim().toLowerCase();
      if (!RegExp(
        r'^[^@\s]+@gmail\.com$',
        caseSensitive: false,
      ).hasMatch(normalizedEmail)) {
        throw const ApiException(
          400,
          'Passenger accounts must use a valid @gmail.com address.',
        );
      }
      if (_demoUsers.containsKey(normalizedEmail)) {
        throw const ApiException(409, 'This email is already registered.');
      }
      _demoUsers[normalizedEmail] = _DemoUser(
        email: normalizedEmail,
        password: password,
        name: name.trim(),
        role: 'passenger',
      );
      return true;
    }
    await _apiClient.post(
      'auth/register',
      authenticated: false,
      body: {'name': name.trim(), 'email': email.trim(), 'password': password},
    );
    return true;
  }

  Future<void> logout() async {
    if (!_backendEnabled) {
      _currentDemoUser = null;
      return;
    }
    try {
      if (await isLoggedIn()) await _apiClient.post('auth/logout');
    } finally {
      await _apiClient.clearTokens();
    }
  }

  Future<Map<String, dynamic>> _loadCurrentUser() async =>
      _asMap(await _apiClient.get('me'), responseName: 'current user');

  _DemoUser _requireDemoUser() {
    final user = _currentDemoUser;
    if (user == null) {
      throw const ApiException(401, 'Please sign in to continue.');
    }
    return user;
  }

  String? _roleFor(Map<String, dynamic> user) {
    final role = _stringField(user, ['role', 'userRole']);
    if (role != null) return _normalizeRole(role);
    final roles = user['roles'];
    if (roles is List && roles.isNotEmpty) {
      final first = roles.first;
      if (first is String) return _normalizeRole(first);
      if (first is Map) {
        final name = first['name']?.toString();
        if (name != null && name.trim().isNotEmpty) {
          return _normalizeRole(name);
        }
      }
    }
    return null;
  }

  Map<String, dynamic> _asMap(dynamic value, {required String responseName}) {
    if (value is Map<String, dynamic>) {
      final data = value['data'];
      final payload = data is Map<String, dynamic> ? data : value;
      for (final key in ['user', 'profile', 'currentUser']) {
        final nested = payload[key];
        if (nested is Map<String, dynamic>) return nested;
      }
      if (data is Map<String, dynamic>) return data;
      return value;
    }
    throw FormatException('The API returned an invalid $responseName.');
  }

  String? _stringField(Map<String, dynamic> value, List<String> keys) {
    for (final key in keys) {
      final field = value[key];
      if (field is String && field.trim().isNotEmpty) return field.trim();
    }
    return null;
  }

  String _normalizeRole(String role) => role.trim().toLowerCase();
}

class _DemoUser {
  _DemoUser({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });

  String email;
  final String password;
  String name;
  final String role;
  String phoneNumber = '';
  String identificationNumber = '';
}
