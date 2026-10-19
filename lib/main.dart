import 'package:flutter/material.dart';

import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/user/home_screen.dart';
import 'screens/user/search_screen.dart';
import 'screens/user/results_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MovaApp());
}

class MovaApp extends StatelessWidget {
  const MovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOVA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/choose-role': (context) => const RoleSelectionScreen(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => LoginScreen(
          role:
              ModalRoute.of(context)?.settings.arguments as String? ??
              'passenger',
        ),
        '/signup': (context) => SignupScreen(
          role:
              ModalRoute.of(context)?.settings.arguments as String? ??
              'passenger',
        ),
        '/admin': (context) => const AdminDashboardScreen(),
        '/search': (context) => const SearchScreen(),
        '/results': (context) => const ResultsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _role = 'passenger';

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    final role = loggedIn ? await _authService.getUserRole() : null;
    if (!mounted) return;

    setState(() {
      _isLoggedIn = loggedIn;
      _role = role ?? 'passenger';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoggedIn) {
      return _role == 'admin'
          ? const AdminDashboardScreen()
          : const HomeScreen();
    }
    return const RoleSelectionScreen();
  }
}
