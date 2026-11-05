import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/osm_route_model.dart';
import '../../services/openstreetmap_service.dart';
import '../../services/location_service.dart';
import '../../utils/malawi_map.dart';
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
  final List<OsmRouteModel> _routes = [];
  String? _selectedRouteId;
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

  OsmRouteModel? get _selectedRoute {
    for (final route in _routes) {
      if (route.id == _selectedRouteId) return route;
    }
    return _routes.isEmpty ? null : _routes.first;
  }

  LatLng? _routeLabelPoint(OsmRouteModel route) {
    final points = route.points;
    if (points.isEmpty) return null;
    return points[points.length ~/ 2];
  }

  Future<void> _routeTo(LatLng destination) async {
    if (_findingRoute) return;
    setState(() {
      _findingRoute = true;
      _destination = destination;
      _routes.clear();
      _selectedRouteId = null;
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
        _routes
          ..clear()
          ..addAll(routes);
        _selectedRouteId = route.id;
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
        _routes.clear();
        _selectedRouteId = null;
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
                    cameraConstraint: CameraConstraint.containCenter(
                      bounds: malawiBounds,
                    ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                    onMapReady: () => _mapReady = true,
                    onTap: (_, point) {
                      if (!isWithinMalawi(point)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Select a destination within Malawi.'),
                          ),
                        );
                        return;
                      }
                      _routeTo(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mova',
                    ),
                    if (_routes.isNotEmpty)
                      PolylineLayer(
                        polylines: _routes.map((route) {
                          final colors = [
                            Colors.deepPurple,
                            Colors.orange,
                            Colors.teal,
                            Colors.blue,
                            Colors.red,
                          ];
                          final index = _routes.indexOf(route);
                          final selected = route.id == _selectedRouteId;
                          return Polyline(
                            points: route.points,
                            color: selected
                                ? colors[index % colors.length]
                                : colors[index % colors.length].withValues(
                                    alpha: 0.35,
                                  ),
                            strokeWidth: selected ? 7 : 4,
                          );
                        }).toList(),
                      ),
                    if (_userLocation != null || _destination != null)
                      MarkerLayer(
                        markers: [
                          for (var index = 0; index < _routes.length; index++)
                            if (_routeLabelPoint(_routes[index]) != null)
                              Marker(
                              point: _routeLabelPoint(_routes[index])!,
                              width: 42,
                              height: 42,
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _routes[index].id == _selectedRouteId
                                      ? Colors.deepPurple
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.deepPurple,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: _routes[index].id == _selectedRouteId
                                        ? Colors.white
                                        : Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
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
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
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
                                      : _selectedRoute == null
                                      ? 'Drag to move · pinch or scroll to zoom · tap to plan a route'
                                      : 'Route ${_routes.indexOf(_selectedRoute!) + 1} of ${_routes.length} · '
                                        '${_selectedRoute!.distanceLabel} · '
                                        '${_selectedRoute!.durationLabel}\n'
                                        '${_selectedRoute!.roadNamesLabel}',
                                ),
                            ),
                              if (_routes.isNotEmpty)
                                IconButton(
                                  tooltip: 'Clear route',
                                  onPressed: () => setState(() {
                                    _routes.clear();
                                    _selectedRouteId = null;
                                    _destination = null;
                                  }),
                                  icon: const Icon(Icons.close),
                                ),
                            ],
                          ),
                          if (_routes.length > 1) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 72,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _routes.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final route = _routes[index];
                                  final selected = route.id == _selectedRouteId;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedRouteId = route.id;
                                      });
                                      _mapController.fitCamera(
                                        CameraFit.bounds(
                                          bounds: LatLngBounds.fromPoints(route.points),
                                          padding: const EdgeInsets.all(56),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 220,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? Colors.deepPurple.shade50
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected
                                              ? Colors.deepPurple
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Route ${index + 1}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            '${route.distanceLabel} · ${route.durationLabel}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          Expanded(
                                            child: Text(
                                              route.roadNamesLabel,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
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
