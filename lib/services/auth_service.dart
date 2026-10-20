import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserRole = 'user_role';
  static const String _keyRegisteredUsers = 'registered_users';
  static const String _keyPassengerProfilePrefix = 'passenger_profile_';

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole);
  }

  Future<Map<String, String>> getPassengerDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyUserEmail) ?? '';
    final profileJson = email.isEmpty
        ? null
        : prefs.getString(_passengerProfileKey(email));
    final profile = profileJson == null
        ? <String, dynamic>{}
        : jsonDecode(profileJson) as Map<String, dynamic>;

    return {
      'name': (profile['name'] ?? prefs.getString(_keyUserName) ?? '')
          .toString(),
      'email': (profile['email'] ?? email).toString(),
      'phoneNumber': (profile['phoneNumber'] ?? '').toString(),
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
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final profile = {
      'name': name.trim(),
      'email': normalizedEmail,
      'phoneNumber': phoneNumber.trim(),
      'identificationNumber': identificationNumber.trim(),
    };
    final accountEmail = prefs.getString(_keyUserEmail)?.trim();
    await prefs.setString(
      _passengerProfileKey(
        accountEmail == null || accountEmail.isEmpty
            ? normalizedEmail
            : accountEmail,
      ),
      jsonEncode(profile),
    );
  }

  Future<bool> login(
    String email,
    String password, {
    required String role,
  }) async {
    // TODO: Replace with actual API authentication
    // For demo, check against registered users or accept any non-empty credentials
    final prefs = await SharedPreferences.getInstance();
    final registeredUsersJson = prefs.getString(_keyRegisteredUsers);

    final registeredUsers = registeredUsersJson == null
        ? <dynamic>[]
        : jsonDecode(registeredUsersJson) as List<dynamic>;
    final matchingEmail = registeredUsers.where(
      (user) =>
          (user['email'] as String?)?.toLowerCase() == email.toLowerCase(),
    );

    if (matchingEmail.isNotEmpty) {
      final user = matchingEmail.first;
      if (user['password'] != password ||
          (user['role'] ?? 'passenger') != role) {
        return false;
      }

      await _saveLogin(prefs, email, user['name'] ?? email.split('@')[0], role);
      return true;
    }

    // Keep demo passenger sign-in permissive, but admins must be registered.
    if (role == 'admin') return false;
    if (email.isNotEmpty && password.isNotEmpty) {
      await _saveLogin(prefs, email, email.split('@')[0], role);
      return true;
    }
    return false;
  }

  Future<bool> signup(
    String email,
    String password,
    String name, {
    required String role,
  }) async {
    // TODO: Replace with actual API registration
    final prefs = await SharedPreferences.getInstance();
    final registeredUsersJson = prefs.getString(_keyRegisteredUsers);

    List<Map<String, dynamic>> registeredUsers = [];
    if (registeredUsersJson != null) {
      registeredUsers = (jsonDecode(registeredUsersJson) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }

    // Check if email already exists
    if (registeredUsers.any(
      (user) => (user['email'] as String).toLowerCase() == email.toLowerCase(),
    )) {
      return false; // Email already registered
    }

    // Add new user
    registeredUsers.add({
      'email': email,
      'password': password,
      'name': name,
      'role': role,
    });

    await prefs.setString(_keyRegisteredUsers, jsonEncode(registeredUsers));
    await prefs.setString(
      _passengerProfileKey(email),
      jsonEncode({
        'name': name,
        'email': email,
        'phoneNumber': '',
        'identificationNumber': '',
      }),
    );

    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserRole);
  }

  Future<void> _saveLogin(
    SharedPreferences prefs,
    String email,
    String name,
    String role,
  ) async {
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserRole, role);
  }

  String _passengerProfileKey(String email) =>
      '$_keyPassengerProfilePrefix${email.trim().toLowerCase()}';
}
