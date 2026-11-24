import 'package:flutter/material.dart';

import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/user/home_screen.dart';
import 'screens/user/search_screen.dart';
import 'screens/user/results_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'data/booking_store.dart';
import 'data/route_store.dart';
import 'data/trip_store.dart';
import 'services/app_config.dart';
import 'services/auth_service.dart';

void main() {
  if (AppConfig.backendEnabled) {
    RouteStore.instance.enableBackend();
    TripStore.instance.enableBackend();
    BookingStore.instance.enableBackend();
  }
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
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final loggedIn = await _authService.isLoggedIn();
      final role = loggedIn ? await _authService.getUserRole() : null;
      if (!mounted) return;
      setState(() {
        _isLoggedIn = loggedIn;
        _role = role ?? 'passenger';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _checkAuthStatus,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoggedIn) {
      return _role == 'admin'
          ? const AdminDashboardScreen()
          : const HomeScreen();
    }
    return const LoginScreen();
  }
}
