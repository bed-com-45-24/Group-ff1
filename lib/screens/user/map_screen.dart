import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/osm_route_model.dart';
import '../../services/openstreetmap_service.dart';
import '../../services/location_service.dart';
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
  final _locationService = LocationService();
  LatLng? _center;
  LatLng? _userLocation;
  LatLng? _destination;
  OsmRouteModel? _route;
  String? _locationError;
  bool _locating = false;
  bool _findingRoute = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _goToCurrentLocation();
  }

  Future<void> _goToCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        throw Exception(
          'Turn on location services and allow MOVA to access your location.',
        );
      }
      final point = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _center = point;
        _userLocation = point;
        _locationError = null;
      });
      if (_mapReady) _mapController.move(point, 14);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _locationError = error.toString().replaceFirst('Exception: ', ''),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _routeTo(LatLng destination) async {
    if (_findingRoute) return;
    setState(() {
      _findingRoute = true;
      _destination = destination;
      _route = null;
    });
    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        throw Exception(
          'Turn on location services and allow MOVA to access your location.',
        );
      }
      final origin = LatLng(position.latitude, position.longitude);
      final routes = await _openStreetMap.findRoutes(
        origin: origin,
        destination: destination,
      );
      if (!mounted) return;
      final route = routes.first;
      setState(() {
        _userLocation = origin;
        _destination = destination;
        _route = route;
        _center = origin;
        _locationError = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && route.points.length > 1) {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(route.points),
              padding: const EdgeInsets.all(56),
            ),
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _destination = null;
        _route = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _findingRoute = false);
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
      body: _center == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_locating)
                      const CircularProgressIndicator()
                    else ...[
                      const Icon(
                        Icons.location_off_outlined,
                        size: 48,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _locationError ?? 'Waiting for device location...',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _goToCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Try again'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center!,
                    initialZoom: 7,
                    onMapReady: () => _mapReady = true,
                    onTap: (_, point) => _routeTo(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mova',
                    ),
                    if (_route != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _route!.points,
                            color: Colors.deepPurple,
                            strokeWidth: 6,
                          ),
                        ],
                      ),
                    if (_userLocation != null || _destination != null)
                      MarkerLayer(
                        markers: [
                          if (_userLocation != null)
                            Marker(
                              point: _userLocation!,
                              width: 42,
                              height: 42,
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                          if (_destination != null)
                            Marker(
                              point: _destination!,
                              width: 42,
                              height: 42,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 38,
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
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (_findingRoute)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            const Icon(
                              Icons.touch_app_outlined,
                              color: Colors.deepPurple,
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _findingRoute
                                  ? 'Finding route...'
                                  : _route == null
                                  ? 'Tap the map to plan a route from your location'
                                  : '${_route!.distanceLabel} · ${_route!.durationLabel}',
                            ),
                          ),
                          if (_route != null)
                            IconButton(
                              tooltip: 'Clear route',
                              onPressed: () => setState(() {
                                _route = null;
                                _destination = null;
                              }),
                              icon: const Icon(Icons.close),
                            ),
                        ],
                      ),
                    ),
                  ),
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
