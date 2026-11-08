import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/route_store.dart';
import '../../data/trip_store.dart';
import '../../models/osm_route_model.dart';
import '../../models/route_model.dart';
import '../../models/trip_model.dart';
import '../../services/openstreetmap_service.dart';
import '../../utils/malawi_map.dart';
import 'route_details_screen.dart';
import 'route_directions_details_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String origin;
  final String destination;

  const ResultsScreen({super.key, this.origin = '', this.destination = ''});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _mapController = MapController();
  final _store = RouteStore.instance;
  final _openStreetMap = OpenStreetMapService();
  Map<String, dynamic>? _searchArguments;
  List<RouteModel> _routes = [];
  List<OsmRouteModel> _mapRoutes = [];
  LatLng? _originPoint;
  LatLng? _destinationPoint;
  String? _errorMessage;
  String? _mapError;
  String? _selectedRouteId;
  String? _activeMapRouteId;
  bool _loading = true;
  bool _loadingMap = false;
  bool _readArguments = false;
  int _mapRequestId = 0;

  String get _effectiveOrigin =>
      (widget.origin.isNotEmpty
              ? widget.origin
              : _searchArguments?['origin']?.toString() ?? '')
          .trim();

  String get _effectiveDestination =>
      (widget.destination.isNotEmpty
              ? widget.destination
              : _searchArguments?['name']?.toString() ??
                    _searchArguments?['address']?.toString() ??
                    '')
          .trim();

  String get _pickupAddress =>
      (_searchArguments?['pickupAddress']?.toString() ?? _effectiveOrigin)
          .trim();

  String get _destinationAddress =>
      (_searchArguments?['address']?.toString() ?? _effectiveDestination)
          .trim();

  RouteModel? get _selectedRoute {
    for (final route in _routes) {
      if (route.id == _selectedRouteId) return route;
    }
    return null;
  }

  OsmRouteModel? get _activeMapRoute {
    for (final route in _mapRoutes) {
      if (route.id == _activeMapRouteId) return route;
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readArguments) return;
    _readArguments = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      _searchArguments = arguments;
    }
    _loadRoutes();
  }

  @override
  void didUpdateWidget(covariant ResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.origin != widget.origin ||
        oldWidget.destination != widget.destination) {
      _loadRoutes();
    }
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _mapError = null;
      _routes = [];
      _mapRoutes = [];
      _originPoint = null;
      _destinationPoint = null;
      _selectedRouteId = null;
      _activeMapRouteId = null;
    });

    try {
      await _store.load();
      final destinationQueries = {
        _effectiveDestination,
        _searchArguments?['address']?.toString().trim() ?? '',
      }..remove('');
      final routesById = <String, RouteModel>{};
      for (final destination in destinationQueries) {
        for (final route in _store.searchRoutes(
          origin: _effectiveOrigin,
          destination: destination,
        )) {
          routesById.putIfAbsent(route.id, () => route);
        }
      }
      final routes = routesById.values.toList();
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _selectedRouteId = routes.firstOrNull?.id;
        _loading = false;
      });
      if (routes.isNotEmpty) {
        await _loadMapRoute(routes.first);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadMapRoute(RouteModel route) async {
    final requestId = ++_mapRequestId;
    setState(() {
      _loadingMap = true;
      _mapError = null;
      _mapRoutes = [];
      _activeMapRouteId = null;
      _originPoint = null;
      _destinationPoint = null;
    });

    try {
      final scheduledTrip = await _scheduledTripFor(route);
      final origin = await _openStreetMap.findPlace(
        scheduledTrip?.origin ??
            (route.pickupPoint.trim().isNotEmpty
                ? route.pickupPoint
                : _pickupAddress.isNotEmpty
                    ? _pickupAddress
                    : route.origin),
      );
      await Future<void>.delayed(const Duration(seconds: 1));
      final destination = await _openStreetMap.findPlace(
        scheduledTrip?.destination ??
            (route.dropOffPoint.trim().isNotEmpty
                ? route.dropOffPoint
                : _destinationAddress.isNotEmpty
                    ? _destinationAddress
                    : route.destination),
      );
      final mapRoutes = await _openStreetMap.findRoutes(
        origin: origin,
        destination: destination,
      );
      if (!mounted || requestId != _mapRequestId) return;
      setState(() {
        _originPoint = origin;
        _destinationPoint = destination;
        _mapRoutes = mapRoutes;
        _activeMapRouteId = mapRoutes.firstOrNull?.id;
        _loadingMap = false;
      });
    } catch (error) {
      if (!mounted || requestId != _mapRequestId) return;
      setState(() {
        _loadingMap = false;
        _mapError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<Trip?> _scheduledTripFor(RouteModel route) async {
    await TripStore.instance.load();
    return TripStore.instance.trips.where((trip) {
      if (!trip.departureTime.isAfter(DateTime.now())) return false;
      final scheduledOrigin = _normalizeLocation(trip.origin);
      final scheduledDestination = _normalizeLocation(trip.destination);
      return _locationMatchesAny(
            scheduledOrigin,
            [route.pickupPoint, route.origin, ...route.stops],
          ) &&
          _locationMatchesAny(
            scheduledDestination,
            [route.dropOffPoint, route.destination, ...route.stops],
          );
    }).firstOrNull;
  }

  bool _locationMatchesAny(String scheduledLocation, List<String> locations) {
    return locations.any((location) {
      final normalizedLocation = _normalizeLocation(location);
      return scheduledLocation == normalizedLocation ||
          (scheduledLocation.isNotEmpty &&
              normalizedLocation.isNotEmpty &&
              (scheduledLocation.contains(normalizedLocation) ||
                  normalizedLocation.contains(scheduledLocation)));
    });
  }

  String _normalizeLocation(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Future<void> _selectRoute(RouteModel route) async {
    setState(() => _selectedRouteId = route.id);
    await _loadMapRoute(route);
  }

  void _fitMap(OsmRouteModel route) {
    if (route.points.length < 2) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(route.points),
        padding: const EdgeInsets.all(32),
      ),
    );
  }

  void _selectMapRoute(OsmRouteModel route) {
    setState(() => _activeMapRouteId = route.id);
    _fitMap(route);
  }

  void _handleMapTap(TapPosition tapPosition) {
    final tapOffset = tapPosition.relative;
    if (tapOffset == null) return;
    OsmRouteModel? nearest;
    var nearestDistance = 24.0;
    for (final route in _mapRoutes) {
      final points = route.points;
      for (var i = 0; i < points.length - 1; i++) {
        final start = _mapController.camera.latLngToScreenOffset(points[i]);
        final end = _mapController.camera.latLngToScreenOffset(points[i + 1]);
        final distance = _distanceToSegment(tapOffset, start, end);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearest = route;
        }
      }
    }
    setState(() {
      _activeMapRouteId = nearest?.id;
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

  Future<void> _compareRoutes() async {
    final configuredRoute = _selectedRoute;
    if (configuredRoute == null || _mapRoutes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There are no map alternatives to compare.'),
        ),
      );
      return;
    }

    final comparisonRoutes = List<OsmRouteModel>.from(_mapRoutes)
      ..sort(
        (first, second) =>
            first.durationSeconds.compareTo(second.durationSeconds),
      );
    await TripStore.instance.load();
    final scheduledTrip = _scheduledTripForSync(configuredRoute);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompareRoutesScreen(
          routes: comparisonRoutes,
          configuredRoute: configuredRoute,
          pickupPoint: scheduledTrip?.origin ?? configuredRoute.pickupPoint,
          dropOffPoint:
              scheduledTrip?.destination ?? configuredRoute.dropOffPoint,
        ),
      ),
    );
  }

  Trip? _scheduledTripForSync(RouteModel route) {
    for (final trip in TripStore.instance.trips) {
      if (!trip.departureTime.isAfter(DateTime.now())) continue;
      final originMatches = _locationMatchesAny(
        _normalizeLocation(trip.origin),
        [route.pickupPoint, route.origin, ...route.stops],
      );
      final destinationMatches = _locationMatchesAny(
        _normalizeLocation(trip.destination),
        [route.dropOffPoint, route.destination, ...route.stops],
      );
      if (originMatches && destinationMatches) return trip;
    }
    return null;
  }

  Future<void> _openMapDirections(
    RouteModel configuredRoute,
    OsmRouteModel mapRoute,
  ) async {
    await TripStore.instance.load();
    final scheduledTrip = _scheduledTripForSync(configuredRoute);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteDirectionsDetailsScreen(
          route: mapRoute,
          origin: scheduledTrip?.origin ?? configuredRoute.pickupPoint,
          destination:
              scheduledTrip?.destination ?? configuredRoute.dropOffPoint,
          estimatedFare: configuredRoute.fare,
          configuredRoute: configuredRoute,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMapRoute = _activeMapRoute;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _effectiveDestination.isEmpty
              ? 'Available routes'
              : 'Routes to $_effectiveDestination',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh routes',
            onPressed: _loading ? null : _loadRoutes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _message(_errorMessage!, onRetry: _loadRoutes)
          : _routes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _effectiveOrigin.isEmpty
                      ? 'No administrator-configured routes are available to '
                            '${_effectiveDestination.isEmpty ? 'that destination' : _effectiveDestination}.'
                      : 'No administrator-configured routes are available from '
                            '$_effectiveOrigin to $_effectiveDestination.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                if (_mapRoutes.isNotEmpty &&
                    _originPoint != null &&
                    _destinationPoint != null)
                  SizedBox(
                    height: 300,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _originPoint!,
                            initialZoom: 8,
                            cameraConstraint: CameraConstraint.containCenter(
                              bounds: malawiBounds,
                            ),
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all,
                            ),
                            onMapReady: () {
                              if (activeMapRoute != null) {
                                _fitMap(activeMapRoute);
                              }
                            },
                            onTap: (tapPosition, _) =>
                                _handleMapTap(tapPosition),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.mova',
                            ),
                            PolylineLayer(
                              polylines: _mapRoutes.map((route) {
                                final active = route.id == _activeMapRouteId;
                                return Polyline(
                                  points: route.points,
                                  color: active
                                      ? Colors.deepPurple
                                      : Colors.deepPurple.withValues(
                                          alpha: 0.35,
                                        ),
                                  strokeWidth: active ? 6 : 3,
                                );
                              }).toList(),
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _originPoint!,
                                  width: 38,
                                  height: 38,
                                  child: const Icon(
                                    Icons.trip_origin,
                                    color: Colors.green,
                                    size: 30,
                                  ),
                                ),
                                Marker(
                                  point: _destinationPoint!,
                                  width: 38,
                                  height: 38,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 34,
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
                      ],
                    ),
                  )
                else if (_loadingMap)
                  const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_mapRoutes.length > 1)
                  SizedBox(
                    height: 68,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        for (var index = 0; index < _mapRoutes.length; index++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(
                                'Option ${index + 1}\n'
                                '${_mapRoutes[index].durationLabel}',
                                textAlign: TextAlign.center,
                              ),
                              selected:
                                  _mapRoutes[index].id == _activeMapRouteId,
                              onSelected: (_) =>
                                  _selectMapRoute(_mapRoutes[index]),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (_mapError != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Map directions are unavailable: $_mapError',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_routes.length} administrator-configured route'
                          '${_routes.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (_mapRoutes.isNotEmpty)
                        Text(
                          '${_mapRoutes.length} map option${_mapRoutes.length == 1 ? '' : 's'}',
                        ),
                    ],
                  ),
                ),
                if (_selectedRoute != null && _mapRoutes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Map paths are driving directions for the configured '
                      'route; the fare below is the administrator-set fare.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: _routes.length,
                    itemBuilder: (context, index) {
                      final route = _routes[index];
                      final selected = route.id == _selectedRouteId;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        color: selected ? Colors.deepPurple.shade50 : null,
                        child: ListTile(
                          onTap: () => _selectRoute(route),
                          leading: Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selected ? Colors.deepPurple : null,
                          ),
                          title: Text('${route.origin} → ${route.destination}'),
                          subtitle: Text(
                            '${route.companyName} · ${route.name}\n'
                            'Fare: MWK '
                            '${route.fare.toStringAsFixed(0)}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            tooltip: 'View route details',
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RouteDetailsScreen(route: route),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _selectedRoute == null || activeMapRoute == null
                              ? null
                              : () => _openMapDirections(
                                  _selectedRoute!,
                                  activeMapRoute,
                                ),
                          icon: const Icon(Icons.list_alt),
                          label: const Text('Map directions'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _mapRoutes.length < 2
                              ? null
                              : _compareRoutes,
                          icon: const Icon(Icons.compare_arrows),
                          label: const Text('Compare map options'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _message(String message, {required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class CompareRoutesScreen extends StatefulWidget {
  final List<OsmRouteModel> routes;
  final RouteModel configuredRoute;
  final String pickupPoint;
  final String dropOffPoint;

  const CompareRoutesScreen({
    super.key,
    required this.routes,
    required this.configuredRoute,
    required this.pickupPoint,
    required this.dropOffPoint,
  });

  @override
  State<CompareRoutesScreen> createState() => _CompareRoutesScreenState();
}

class _CompareRoutesScreenState extends State<CompareRoutesScreen> {
  final MapController _mapController = MapController();
  int _selectedRouteIndex = 0;
  Offset? _routeTooltipPosition;

  void _continueWithSelectedRoute() {
    final selectedMapRoute = widget.routes[_selectedRouteIndex];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteDirectionsDetailsScreen(
          route: selectedMapRoute,
          origin: widget.pickupPoint,
          destination: widget.dropOffPoint,
          estimatedFare: widget.configuredRoute.fare,
          configuredRoute: widget.configuredRoute,
        ),
      ),
    );
  }

  String _routeName(OsmRouteModel route) {
    if (route.roadNames.isNotEmpty) return route.roadNamesLabel;
    if (route.routeName.trim().isNotEmpty) return route.routeName.trim();
    return widget.configuredRoute.name;
  }

  void _handleRouteTap(TapPosition tapPosition) {
    final tapOffset = tapPosition.relative;
    if (tapOffset == null) return;

    var nearestIndex = _selectedRouteIndex;
    var nearestDistance = double.infinity;
    for (var routeIndex = 0;
        routeIndex < widget.routes.length;
        routeIndex++) {
      final points = widget.routes[routeIndex].points;
      for (var pointIndex = 0;
          pointIndex < points.length - 1;
          pointIndex++) {
        final start = _mapController.camera.latLngToScreenOffset(
          points[pointIndex],
        );
        final end = _mapController.camera.latLngToScreenOffset(
          points[pointIndex + 1],
        );
        final distance = _distanceToSegment(tapOffset, start, end);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestIndex = routeIndex;
        }
      }
    }

    if (nearestDistance <= 24) {
      setState(() {
        _selectedRouteIndex = nearestIndex;
        _routeTooltipPosition = tapOffset;
      });
    }
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    if (segment.distanceSquared == 0) return (point - start).distance;
    final projection =
        ((point - start).dx * segment.dx +
            (point - start).dy * segment.dy) /
        segment.distanceSquared;
    final t = projection.clamp(0.0, 1.0).toDouble();
    final nearest = Offset(
      start.dx + segment.dx * t,
      start.dy + segment.dy * t,
    );
    return (point - nearest).distance;
  }

  @override
  Widget build(BuildContext context) {
    final selectedRoute = widget.routes[_selectedRouteIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare map options'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.pickupPoint} → '
                '${widget.dropOffPoint}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Driving directions for ${widget.configuredRoute.name}. '
                'The administrator-set fare is MWK '
                '${widget.configuredRoute.fare.toStringAsFixed(0)}.',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: selectedRoute.points.first,
                          initialZoom: 8,
                          cameraConstraint: CameraConstraint.containCenter(
                            bounds: malawiBounds,
                          ),
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                          initialCameraFit: CameraFit.bounds(
                            bounds: LatLngBounds.fromPoints(selectedRoute.points),
                            padding: const EdgeInsets.all(28),
                          ),
                          onTap: (tapPosition, _) =>
                              _handleRouteTap(tapPosition),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.mova',
                          ),
                          PolylineLayer(
                            polylines: [
                              for (var index = 0;
                                  index < widget.routes.length;
                                  index++)
                                Polyline(
                                  points: widget.routes[index].points,
                                  color: index == _selectedRouteIndex
                                      ? Colors.deepPurple
                                      : Colors.deepPurple.withValues(
                                          alpha: 0.35,
                                        ),
                                  strokeWidth:
                                      index == _selectedRouteIndex ? 6 : 3,
                                ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: selectedRoute.points.first,
                                width: 36,
                                height: 36,
                                child: const Icon(
                                  Icons.trip_origin,
                                  color: Colors.green,
                                  size: 28,
                                ),
                              ),
                              Marker(
                                point: selectedRoute.points.last,
                                width: 36,
                                height: 36,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 32,
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
                      if (_routeTooltipPosition != null)
                        Positioned(
                          left: (_routeTooltipPosition!.dx - 90).clamp(8, 220),
                          top: (_routeTooltipPosition!.dy - 58).clamp(8, 190),
                          child: IgnorePointer(
                            child: Material(
                              elevation: 5,
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                child: Text(
                                  _routeName(selectedRoute),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < widget.routes.length; index++)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: index == _selectedRouteIndex
                      ? Colors.deepPurple.shade50
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Map option ${index + 1}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          key: ValueKey('route-option-selector-$index'),
                          onTap: () {
                            setState(() => _selectedRouteIndex = index);
                          },
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Checkbox(
                              value: index == _selectedRouteIndex,
                              onChanged: (selected) {
                                if (selected == true) {
                                  setState(() => _selectedRouteIndex = index);
                                }
                              },
                            ),
                          ),
                        ),
                        const Divider(),
                        _ComparisonMetric(
                          label: 'Estimated driving time',
                          value: widget.routes[index].durationLabel,
                        ),
                        _ComparisonMetric(
                          label: 'Map distance',
                          value: widget.routes[index].distanceLabel,
                        ),
                        _ComparisonMetric(
                          label: 'Roads',
                          value: widget.routes[index].roadNamesLabel,
                        ),
                        _ComparisonMetric(
                          label: 'Administrator-set fare',
                          value:
                              'MWK ${widget.configuredRoute.fare.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.routes.isEmpty
                      ? null
                      : _continueWithSelectedRoute,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('View configured route'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparisonMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ComparisonMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
