
import 'package:flutter/material.dart';
import 'screens/user/home_screen.dart';
import 'screens/user/search_screen.dart';
import 'screens/user/results_screen.dart';

void main() {
  runApp(const MovaApp());
}

class MovaApp extends StatelessWidget {
  const MovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOVA',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/search': (context) => const SearchScreen(),
        '/results': (context) => const ResultsScreen(),
      },
    );
  }
}
