import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';
  static const String _keyRegisteredUsers = 'registered_users';

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  Future<bool> login(String email, String password) async {
    // TODO: Replace with actual API authentication
    // For demo, check against registered users or accept any non-empty credentials
    final prefs = await SharedPreferences.getInstance();
    final registeredUsersJson = prefs.getString(_keyRegisteredUsers);
    
    if (registeredUsersJson != null) {
      final registeredUsers = jsonDecode(registeredUsersJson) as List;
      final user = registeredUsers.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
        orElse: () => null,
      );
      
      if (user != null) {
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserEmail, email);
        return true;
      }
    }
    
    // Fallback for demo: accept any non-empty credentials
    if (email.isNotEmpty && password.isNotEmpty) {
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserEmail, email);
      return true;
    }
    return false;
  }

  Future<bool> signup(String email, String password, String name) async {
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
    if (registeredUsers.any((u) => u['email'] == email)) {
      return false; // Email already registered
    }
    
    // Add new user
    registeredUsers.add({
      'email': email,
      'password': password,
      'name': name,
    });
    
    await prefs.setString(_keyRegisteredUsers, jsonEncode(registeredUsers));
    
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserEmail);
  }
}
