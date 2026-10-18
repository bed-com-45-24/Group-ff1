import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import 'search_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _districtName = 'Finding location...';
  String _userInitial = 'U';
  final _authService = AuthService();
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _detectCurrentLocation();
  }

  Future<void> _loadUserInfo() async {
    final userName = await _authService.getUserName();
    final userEmail = await _authService.getUserEmail();
    if (mounted) {
      setState(() {
        _userInitial = (userName ?? userEmail ?? 'U').substring(0, 1).toUpperCase();
      });
    }
  }

  Future<void> _detectCurrentLocation() async {
    setState(() {
      _districtName = 'Finding location...';
    });

    final locationName = await _locationService.getCurrentLocationName();
    _updateLocation(locationName);
  }

  void _updateLocation(String district) {
    if (!mounted) return;

    setState(() {
      _districtName = district;
    });
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _userInitial,
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
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
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Find your location and explore places around you.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 28),

            // Navigate to the existing search screen
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Search for a Destination'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.all(16),
                  side: const BorderSide(
                    color: Colors.deepPurple,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Navigate to map screen
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MapScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text('View Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.all(16),
                  side: const BorderSide(
                    color: Colors.deepPurple,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}