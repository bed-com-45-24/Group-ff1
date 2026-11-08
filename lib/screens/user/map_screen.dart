import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/route_store.dart';
import '../../models/osm_route_model.dart';
import '../../models/route_model.dart';
import '../../services/openstreetmap_service.dart';
import '../../services/location_service.dart';
import '../../utils/malawi_map.dart';
import '../../utils/malawi_route_names.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class MapScreen extends StatefulWidget {
  final String origin;
  final String destination;

  const MapScreen({super.key, this.origin = '', this.destination = ''});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapRouteTooltip extends StatelessWidget {
  final String name;
  final String distance;

  const _MapRouteTooltip({required this.name, required this.distance});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              distance,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  final _openStreetMap = OpenStreetMapService();
  final _locationService = LocationService();
  LatLng? _center;
  LatLng? _userLocation;
  LatLng? _destination;
  final List<OsmRouteModel> _routes = [];
  final List<RouteModel> _configuredRoutes = [];
  final Map<String, String> _configuredRouteLabels = {};
  String? _selectedRouteId;
  Offset? _tooltipPosition;
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
      await _loadConfiguredRoutes(
        widget.origin.isNotEmpty
            ? widget.origin
            : await _locationService.getCurrentLocationName(),
        widget.destination,
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _locationError =
            'Turn on location services and allow MOVA to access your location.',
      );
      _center ??= malawiCenter;
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _loadConfiguredRoutes(String origin, String destination) async {
    await RouteStore.instance.load();
    final routes = destination.isEmpty
        ? RouteStore.instance.searchRoutes(origin: origin)
        : RouteStore.instance.searchRoutes(
            origin: origin,
            destination: destination,
          );
    if (!mounted) return;
    _configuredRoutes
      ..clear()
      ..addAll(routes.take(6));
    setState(() {});
    await _loadConfiguredRoutePaths();
  }

  Future<void> _loadConfiguredRoutePaths() async {
    final paths = <OsmRouteModel>[];
    final labels = <String, String>{};
    for (final route in _configuredRoutes) {
      try {
        final origin = await _openStreetMap.findPlace(route.pickupPoint);
        await Future<void>.delayed(const Duration(milliseconds: 700));
        final destination = await _openStreetMap.findPlace(route.dropOffPoint);
        final alternatives = await _openStreetMap.findRoutes(
          origin: origin,
          destination: destination,
        );
        for (
          var alternativeIndex = 0;
          alternativeIndex < alternatives.take(2).length;
          alternativeIndex++
        ) {
          final mapRoute = alternatives[alternativeIndex];
          final configuredRoute = OsmRouteModel(
            id: 'configured-${route.id}-${alternativeIndex + 1}',
            geoJson: mapRoute.geoJson,
            distanceMeters: mapRoute.distanceMeters,
            durationSeconds: mapRoute.durationSeconds,
            steps: mapRoute.steps,
            roadNames: mapRoute.roadNames,
          );
          paths.add(configuredRoute);
          final corridorName = knownMalawiRouteName(
            route.origin,
            route.destination,
          );
          final routeName = alternatives.length > 1 && alternativeIndex == 1
              ? 'Other route'
              : corridorName.isNotEmpty
              ? corridorName
              : route.name;
          labels[configuredRoute.id] =
              '$routeName · ${route.origin} to ${route.destination}';
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _routes
        ..clear()
        ..addAll(paths);
      _configuredRouteLabels
        ..clear()
        ..addAll(labels);
      if (_routes.isNotEmpty) {
        _selectedRouteId = _routes.first.id;
      }
    });
  }

  OsmRouteModel? get _selectedRoute {
    for (final route in _routes) {
      if (route.id == _selectedRouteId) return route;
    }
    return _routes.isEmpty ? null : _routes.first;
  }

  String _routeLabel(OsmRouteModel route) {
    final configuredLabel = _configuredRouteLabels[route.id]
        ?.split(' · ')
        .first;
    if (configuredLabel != null && configuredLabel.trim().isNotEmpty) {
      return configuredLabel.trim();
    }
    if (route.roadNames.isNotEmpty) return route.roadNames.join(' → ');
    return route.id;
  }

  OsmRouteModel? _routeAt(TapPosition tapPosition) {
    final tapOffset = tapPosition.relative;
    if (tapOffset == null) return null;
    OsmRouteModel? nearestRoute;
    var nearestDistance = 24.0;
    for (final route in _routes) {
      final points = route.points;
      for (var i = 0; i < points.length - 1; i++) {
        final start = _mapController.camera.latLngToScreenOffset(points[i]);
        final end = _mapController.camera.latLngToScreenOffset(points[i + 1]);
        final distance = _distanceToSegment(tapOffset, start, end);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestRoute = route;
        }
      }
    }
    return nearestRoute;
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    if (segment.distanceSquared == 0) return (point - start).distance;
    final projection =
        ((point - start).dx * segment.dx + (point - start).dy * segment.dy) /
        segment.distanceSquared;
    final t = projection.clamp(0.0, 1.0).toDouble();
    final nearest = Offset(
      start.dx + segment.dx * t,
      start.dy + segment.dy * t,
    );
    return (point - nearest).distance;
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
                    onTap: (tapPosition, point) {
                      final hitRoute = _routeAt(tapPosition);
                      if (hitRoute != null) {
                        setState(() {
                          _selectedRouteId = hitRoute.id;
                          _tooltipPosition = tapPosition.relative;
                        });
                        return;
                      }
                      setState(() {
                        _selectedRouteId = null;
                        _tooltipPosition = null;
                      });
                      if (!isWithinMalawi(point)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Select a destination within Malawi.',
                            ),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                                      : '${_routes.length} route${_routes.length == 1 ? '' : 's'} available',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                              if (_selectedRoute != null &&
                                  _tooltipPosition != null)
                                Positioned(
                                  left: (_tooltipPosition!.dx - 110).clamp(
                                    8.0,
                                    220.0,
                                  ),
                                  top: (_tooltipPosition!.dy - 72).clamp(
                                    8.0,
                                    420.0,
                                  ),
                                  child: _MapRouteTooltip(
                                    name: _routeLabel(_selectedRoute!),
                                    distance: _selectedRoute!.distanceLabel,
                                  ),
                                ),
                            ],
                          ),
                          if (_routes.length > 1) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 28 * _routes.length.toDouble(),
                              child: ListView.separated(
                                itemCount: _routes.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 2),
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
                                          bounds: LatLngBounds.fromPoints(
                                            route.points,
                                          ),
                                          padding: const EdgeInsets.all(56),
                                        ),
                                      );
                                    },
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Route ${index + 1} · '
                                        '${route.distanceLabel} · '
                                        '${route.durationLabel} · '
                                        '${_configuredRouteLabels[route.id] ?? route.routeName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: selected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: selected
                                              ? Colors.deepPurple
                                              : Colors.black87,
                                          fontSize: 12,
                                        ),
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
