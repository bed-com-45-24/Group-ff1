import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/booking_store.dart';
import '../../data/route_store.dart';
import '../../data/trip_store.dart';
import '../../models/route_model.dart';
import '../../models/osm_route_model.dart';
import '../../models/trip_model.dart';
import '../../services/openstreetmap_service.dart';
import '../../utils/malawi_map.dart';
import '../../utils/malawi_route_names.dart';
import 'booking/select_trip_screen.dart';

class RouteDetailsScreen extends StatefulWidget {
  final RouteModel route;

  const RouteDetailsScreen({super.key, required this.route});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  final _openStreetMap = OpenStreetMapService();
  final _mapKey = GlobalKey();
  final MapController _mapController = MapController();
  OsmRouteModel? _mapRoute;
  List<_MapRouteOption> _mapRouteOptions = [];
  int? _selectedRouteIndex;
  Offset? _tooltipPosition;
  String? _mapError;
  bool _loadingMapRoute = true;
  bool _loadingSchedules = true;
  String? _scheduleError;
  List<Trip> _scheduledTrips = [];

  RouteModel get route => widget.route;

  @override
  void initState() {
    super.initState();
    _loadMapRoute();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      await Future.wait([
        TripStore.instance.load(),
        BookingStore.instance.load(),
      ]);
      final origin = _normalizeLocation(route.origin);
      final destination = _normalizeLocation(route.destination);
      final pickup = _normalizeLocation(route.pickupPoint);
      final dropOff = _normalizeLocation(route.dropOffPoint);
      final trips =
          TripStore.instance.trips
              .where(
                (trip) =>
                    trip.departureTime.isAfter(DateTime.now()) &&
                    _locationMatches(
                      trip.origin,
                      [pickup, origin],
                    ) &&
                    _locationMatches(
                      trip.destination,
                      [dropOff, destination],
                    ),
              )
              .toList()
            ..sort(
              (first, second) =>
                  first.departureTime.compareTo(second.departureTime),
            );
      if (!mounted) return;
      setState(() {
        _scheduledTrips = trips;
        _loadingSchedules = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _scheduleError = error.toString().replaceFirst('Exception: ', '');
        _loadingSchedules = false;
      });
    }
  }

  String _normalizeLocation(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  bool _locationMatches(String scheduledLocation, List<String> configured) {
    final normalizedScheduled = _normalizeLocation(scheduledLocation);
    return configured.any((location) {
      final normalizedLocation = location.trim();
      return normalizedScheduled == normalizedLocation ||
          (normalizedScheduled.isNotEmpty &&
              normalizedLocation.isNotEmpty &&
              (normalizedScheduled.contains(normalizedLocation) ||
                  normalizedLocation.contains(normalizedScheduled)));
    });
  }

  Future<void> _viewMap() async {
    final mapContext = _mapKey.currentContext;
    if (mapContext == null) return;
    await Scrollable.ensureVisible(
      mapContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _bookThisTrip() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SelectTripScreen(initialRoute: route)),
    );
  }

  Future<void> _loadMapRoute() async {
    try {
      await RouteStore.instance.load();
      final normalizedOrigin = _normalizeLocation(route.origin);
      final normalizedDestination = _normalizeLocation(route.destination);
      final configuredRoutes = RouteStore.instance.routes
          .where(
            (candidate) =>
                candidate.active &&
                _normalizeLocation(candidate.origin) == normalizedOrigin &&
                _normalizeLocation(candidate.destination) ==
                    normalizedDestination,
          )
          .toList();
      final routesToMap = configuredRoutes.isEmpty ? [route] : configuredRoutes;
      final options = <_MapRouteOption>[];

      for (final configuredRoute in routesToMap) {
        final alternatives = await _openStreetMap.findRoutesBetweenPlaces(
          origin: configuredRoute.pickupPoint,
          destination: configuredRoute.dropOffPoint,
        );
        final routesToAdd = routesToMap.length == 1
            ? alternatives.take(2).toList()
            : alternatives.take(1).toList();
        options.addAll(
          routesToAdd.map(
            (mapRoute) => _MapRouteOption(
              configuredRoute: configuredRoute,
              mapRoute: mapRoute,
            ),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _mapRouteOptions = options.asMap().entries.map((entry) {
          final option = entry.value;
          return option.copyWith(
            name: _routeOptionName(entry.key, options.length, option),
          );
        }).toList();
        _mapRoute = _mapRouteOptions.isEmpty
            ? null
            : _mapRouteOptions.first.mapRoute;
        _loadingMapRoute = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _mapError = error.toString().replaceFirst('Exception: ', '');
        _loadingMapRoute = false;
      });
    }
  }

  String get _effectiveDurationText {
    return _mapRoute?.durationLabel ??
        (_loadingMapRoute
            ? 'Loading map estimate...'
            : 'Map estimate unavailable');
  }

  String get _effectiveDistanceText =>
      _mapRoute?.distanceLabel ??
      (_loadingMapRoute
          ? 'Loading map estimate...'
          : route.mapDistance ?? 'Not available');

  String _routeOptionName(int index, int count, _MapRouteOption option) {
    final genericName =
        '${option.configuredRoute.origin} - ${option.configuredRoute.destination}';
    if (option.configuredRoute.name.trim().isNotEmpty &&
        option.configuredRoute.name.trim() != genericName &&
        count <= countConfiguredRoutesForMap()) {
      return option.configuredRoute.name.trim();
    }
    final knownName = knownMalawiRouteName(
      option.configuredRoute.origin,
      option.configuredRoute.destination,
    );
    if (index == 0 && knownName.isNotEmpty) return knownName;
    if (knownName.isNotEmpty && count > 1) {
      final isLilongweMzuzu =
          (_normalizeLocation(option.configuredRoute.origin)
                  .contains('lilongwe') &&
              _normalizeLocation(option.configuredRoute.destination)
                  .contains('mzuzu')) ||
          (_normalizeLocation(option.configuredRoute.origin)
                  .contains('mzuzu') &&
              _normalizeLocation(option.configuredRoute.destination)
                  .contains('lilongwe'));
      if (isLilongweMzuzu && index == 1) return 'Other route';
      return 'Alternative route $index';
    }
    final roadName = option.mapRoute.roadNamesLabel;
    if (roadName != 'Road name unavailable') return '$roadName route';
    return '${option.configuredRoute.origin} - ${option.configuredRoute.destination} route ${index + 1}';
  }

  int countConfiguredRoutesForMap() {
    final origin = _normalizeLocation(route.origin);
    final destination = _normalizeLocation(route.destination);
    return RouteStore.instance.routes.where((candidate) {
      return candidate.active &&
          _normalizeLocation(candidate.origin) == origin &&
          _normalizeLocation(candidate.destination) == destination;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MOVA Route Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(route.name, style: Theme.of(context).textTheme.headlineSmall),

          const SizedBox(height: 8),

          Text('Transport company: ${route.companyName}'),

          const SizedBox(height: 16),

          Text(
            '${route.origin} → ${route.destination}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(key: _mapKey, child: _buildRouteMap()),

          const SizedBox(height: 16),

          const Divider(),

          const Text(
            'Journey Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          ListTile(
            leading: const Icon(Icons.trip_origin),
            title: const Text('Pickup depot'),
            subtitle: Text(route.pickupPoint),
          ),

          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Destination / Drop-off'),
            subtitle: Text(route.dropOffPoint),
          ),

          const SizedBox(height: 12),

          const Text(
            'Known Route Stops',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          for (int i = 0; i < route.stops.length; i++)
            ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(route.stops[i]),
            ),

          const Divider(height: 32),

          ListTile(
            leading: const Icon(Icons.payments),
            title: const Text('Fare'),
            subtitle: Text('MWK ${route.fare.toStringAsFixed(0)}'),
          ),

          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Estimated travel time (map)'),
            subtitle: Text(_effectiveDurationText),
          ),

          ListTile(
            leading: const Icon(Icons.route),
            title: const Text('Distance (map)'),
            subtitle: Text(_effectiveDistanceText),
          ),

          if (_mapError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Map distance and time could not be loaded: $_mapError',
                style: const TextStyle(color: Colors.red),
              ),
            ),

          if (route.departureTimes.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Departure Times'),
              subtitle: Text(route.departureTimes.join(', ')),
            ),

          ListTile(
            leading: const Icon(Icons.directions_bus),
            title: const Text('Bus type'),
            subtitle: Text(
              _loadingSchedules
                  ? 'Loading scheduled bus types...'
                  : _scheduleError != null
                  ? 'Unavailable: $_scheduleError'
                  : _scheduledTrips.isEmpty
                  ? 'Shown with available scheduled trips'
                  : _scheduledTrips
                        .map((trip) => trip.transportMode)
                        .toSet()
                        .join(', '),
            ),
          ),

          const Divider(height: 32),

          const Text(
            'Scheduled trips',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_loadingSchedules)
            const ListTile(
              leading: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Loading seat availability...'),
            )
          else if (_scheduleError != null)
            ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: const Text('Schedule information unavailable'),
              subtitle: Text(_scheduleError!),
            )
          else if (_scheduledTrips.isEmpty)
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('No upcoming scheduled trips'),
              subtitle: Text(
                'Choose Book This Trip to check available travel dates.',
              ),
            )
          else
            for (final trip in _scheduledTrips)
              ValueListenableBuilder<int>(
                valueListenable: BookingStore.instance.changes,
                builder: (context, _, _) {
                  final occupiedSeats = BookingStore.instance
                      .occupiedSeatsForTrip(trip);
                  final availableSeats = trip.totalSeats - occupiedSeats.length;
                  return ListTile(
                    leading: const Icon(Icons.directions_bus),
                    title: Text(
                      '${MaterialLocalizations.of(context).formatMediumDate(trip.departureTime)} · '
                      '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(trip.departureTime))}',
                    ),
                    subtitle: Text(
                      '${trip.transportMode} · ${trip.operatorName}\n'
                      '$availableSeats of ${trip.totalSeats} seats available',
                    ),
                    isThreeLine: true,
                  );
                },
              ),

          const SizedBox(height: 16),

          const Text(
            'The fare shown is set by the transport administrator.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _viewMap,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('View on Map'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _bookThisTrip,
                  icon: const Icon(Icons.confirmation_number_outlined),
                  label: const Text('Book This Trip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteMap() {
    if (_loadingMapRoute) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final points = _mapRoute?.points;
    if (points == null || points.length < 2) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.deepPurple.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _mapError == null
                ? 'A map route is not available for ${route.origin} to ${route.destination}.'
                : 'Map unavailable: $_mapError',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 320,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: points.first,
                initialZoom: 8,
                cameraConstraint: CameraConstraint.containCenter(
                  bounds: malawiBounds,
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                initialCameraFit: CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(points),
                  padding: const EdgeInsets.all(48),
                ),
                onTap: _handleMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mova',
                ),
                PolylineLayer(
                  polylines: [
                    for (
                      var index = 0;
                      index < _mapRouteOptions.length;
                      index++
                    )
                      Polyline(
                        points: _mapRouteOptions[index].mapRoute.points,
                        color: _routeColor(index),
                        strokeWidth:
                            _selectedRouteIndex == null ||
                                _selectedRouteIndex == index
                            ? 6
                            : 3,
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: points.first,
                      width: 110,
                      height: 54,
                      child: _RouteMapMarker(
                        label: route.pickupPoint,
                        color: Colors.green.shade700,
                        icon: Icons.trip_origin,
                      ),
                    ),
                    Marker(
                      point: points.last,
                      width: 130,
                      height: 54,
                      child: _RouteMapMarker(
                        label: route.dropOffPoint,
                        color: Colors.red.shade700,
                        icon: Icons.location_on,
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
            if (_selectedRouteIndex != null && _tooltipPosition != null)
              Positioned(
                left: (_tooltipPosition!.dx - 110).clamp(8.0, 192.0),
                top: (_tooltipPosition!.dy - 78).clamp(8.0, 242.0),
                child: _MapRouteTooltip(
                  option: _mapRouteOptions[_selectedRouteIndex!],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _routeColor(int index) {
    final colors = <Color>[
      Colors.deepPurple,
      Colors.teal,
      Colors.orange.shade800,
      Colors.blue.shade700,
    ];
    if (_selectedRouteIndex == null || _selectedRouteIndex == index) {
      return colors[index % colors.length];
    }
    return colors[index % colors.length].withValues(alpha: 0.18);
  }

  void _handleMapTap(TapPosition tapPosition, LatLng _) {
    final tapOffset = tapPosition.relative;
    if (tapOffset == null) return;

    var closestIndex = -1;
    var closestDistance = 24.0;
    for (
      var routeIndex = 0;
      routeIndex < _mapRouteOptions.length;
      routeIndex++
    ) {
      final routePoints = _mapRouteOptions[routeIndex].mapRoute.points;
      for (
        var pointIndex = 0;
        pointIndex < routePoints.length - 1;
        pointIndex++
      ) {
        final start = _mapController.camera.latLngToScreenOffset(
          routePoints[pointIndex],
        );
        final end = _mapController.camera.latLngToScreenOffset(
          routePoints[pointIndex + 1],
        );
        final distance = _distanceToSegment(tapOffset, start, end);
        if (distance < closestDistance) {
          closestDistance = distance;
          closestIndex = routeIndex;
        }
      }
    }

    setState(() {
      _selectedRouteIndex = closestIndex == -1 ? null : closestIndex;
      _tooltipPosition = closestIndex == -1 ? null : tapOffset;
    });
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
}

class _MapRouteOption {
  final String name;
  final RouteModel configuredRoute;
  final OsmRouteModel mapRoute;

  const _MapRouteOption({
    this.name = '',
    required this.configuredRoute,
    required this.mapRoute,
  });

  _MapRouteOption copyWith({required String name}) {
    return _MapRouteOption(
      name: name,
      configuredRoute: configuredRoute,
      mapRoute: mapRoute,
    );
  }
}

class _MapRouteTooltip extends StatelessWidget {
  final _MapRouteOption option;

  const _MapRouteTooltip({required this.option});

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
              option.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              option.mapRoute.distanceLabel,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteMapMarker extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _RouteMapMarker({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 26),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
