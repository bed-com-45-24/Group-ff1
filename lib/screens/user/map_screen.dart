import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/openstreetmap_service.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  final _openStreetMap = OpenStreetMapService();
  LatLng _center = const LatLng(-13.9626, 33.7741);
  bool _locating = false;
  bool _hasLocated = false;

  Future<void> _goToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final point = await _openStreetMap.currentPosition();
      if (!mounted) return;
      setState(() {
        _center = point;
        _hasLocated = true;
      });
      _mapController.move(point, 14);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenStreetMap'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Search destination',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: _center, initialZoom: 7),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mova',
          ),
          if (_hasLocated)
            MarkerLayer(
              markers: [
                Marker(
                  point: _center,
                  width: 38,
                  height: 38,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.deepPurple,
                    size: 30,
                  ),
                ),
              ],
            ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                '© OpenStreetMap contributors',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _locating ? null : _goToCurrentLocation,
        child: _locating
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.my_location),
      ),
    );
  }
}
