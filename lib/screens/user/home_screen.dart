import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
<<<<<<< HEAD
=======
import 'search_screen.dart';
import '../admin/admin_dashboard_screen.dart';
>>>>>>> 79a394f55137eed28e870aa81a9c5fe3d387881e
=======
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import 'search_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
>>>>>>> origin/maps

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
<<<<<<< HEAD
  String _currentLocationName = "Detecting...";
=======
  String _districtName = 'Finding location...';
  String _userInitial = 'U';
  final _authService = AuthService();
  final _locationService = LocationService();
>>>>>>> origin/maps

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _detectCurrentLocation();
  }

<<<<<<< HEAD
  // FR8: Detect the user's current device location
  Future<void> _detectCurrentLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _currentLocationName = "GPS Disabled");
        }
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _currentLocationName = "Location unavailable");
        }
        return;
      }

      // Display the last known location first for faster loading.
      Position? lastPosition =
          await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        _updateLocationName(lastPosition);
      }

      // Get the device's current location.
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      await _updateLocationName(position);
    } catch (e) {
      debugPrint('Location error: $e');

      if (mounted) {
        setState(() {
          _currentLocationName = "Location unavailable";
        });
      }
    }
  }

  // FR9: Convert GPS coordinates into a readable city name.
  Future<void> _updateLocationName(Position position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;

        setState(() {
          _currentLocationName =
              place.locality ??
              place.subAdministrativeArea ??
              place.administrativeArea ??
              'Unknown location';
        });
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
=======
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
>>>>>>> origin/maps
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: MOVA logo, current location and notifications.
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'M',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'MOVA',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),

                  // Dynamically displays the user's current city.
                  Flexible(
                    child: InkWell(
                      onTap: _detectCurrentLocation,
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.circle,
                              color: Colors.orange,
                              size: 10,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _currentLocationName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Notification icon.
                  Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        size: 28,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              Text(
                'Mwadzuka bwino, Chikondi',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Where do you\nwant to go?',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 30),

              // FR5: Navigate to destination search.
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/search');
=======
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
>>>>>>> origin/maps
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.grey.shade500,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Search destination...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
<<<<<<< HEAD
            ],
          ),
=======
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
>>>>>>> origin/maps
        ),
      ),
    );
  }
}