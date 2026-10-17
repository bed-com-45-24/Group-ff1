import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'search_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentLocation = 'Finding your location...';
  String _coordinates = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _detectCurrentLocation();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _currentLocation = 'Finding your location...';
      _coordinates = '';
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _updateLocation('Please enable location services.');
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _updateLocation(
          'Location permission is required to find your location.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        _currentLocation = 'Location detected successfully!';
        _coordinates =
            'Latitude: ${position.latitude.toStringAsFixed(5)}\n'
            'Longitude: ${position.longitude.toStringAsFixed(5)}';
        _isLoading = false;
      });
    } catch (e) {
      _updateLocation(
        'Unable to find your location. Please try again.',
      );
    }
  }

  void _updateLocation(String message) {
    if (!mounted) return;

    setState(() {
      _currentLocation = message;
      _coordinates = '';
      _isLoading = false;
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

            // Current location card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE5DFF0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        color: Colors.deepPurple,
                        size: 26,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your Current Location',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(
                          alpha: 0.08,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        size: 42,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Center(
                    child: Text(
                      _currentLocation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  if (_coordinates.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F7FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _coordinates,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.8,
                        ),
                      ),
                    ),
                  ],

                  if (_isLoading) ...[
                    const SizedBox(height: 18),
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : _detectCurrentLocation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh My Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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
          ],
        ),
      ),
    );
  }
}