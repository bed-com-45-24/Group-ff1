import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'results_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _locationService = LocationService();

  String _districtName = 'Finding location...';
  String _userInitial = 'U';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _detectCurrentLocation();
  }

  Future<void> _loadUserInfo() async {
    final userName = await _authService.getUserName();
    final userEmail = await _authService.getUserEmail();
    if (!mounted) return;

    final displayName = (userName ?? userEmail ?? '').trim();
    setState(() {
      _userInitial = displayName.isEmpty
          ? 'U'
          : displayName.substring(0, 1).toUpperCase();
    });
  }

  Future<void> _detectCurrentLocation() async {
    final locationName = await _locationService.getCurrentLocationName();
    if (!mounted) return;

    setState(() {
      _districtName = locationName;
    });
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text(
          'MOVA',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                SizedBox(
                  width: 100,
                  child: Text(
                    _districtName,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _openProfile,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _userInitial,
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to MOVA!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find your location and explore places around you.',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openScreen(const SearchScreen()),
                icon: const Icon(Icons.search),
                label: const Text('Search for a Destination'),
                style: _buttonStyle(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openScreen(const ResultsScreen()),
                icon: const Icon(Icons.directions_bus),
                label: const Text('Browse Available Routes'),
                style: _buttonStyle(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openScreen(const MapScreen()),
                icon: const Icon(Icons.map),
                label: const Text('View Map'),
                style: _buttonStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.deepPurple,
      padding: const EdgeInsets.all(16),
      side: const BorderSide(color: Colors.deepPurple),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
