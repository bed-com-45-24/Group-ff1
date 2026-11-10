import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/route_store.dart';
import '../../models/osm_route_model.dart';
import '../../models/route_model.dart';
import '../../services/openstreetmap_service.dart';
import '../../utils/malawi_map.dart';
import '../../utils/malawi_route_names.dart';
import 'route_details_screen.dart';
import 'route_directions_details_screen.dart';
import 'booking/select_trip_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String origin;
  final String destination;
  final OpenStreetMapService? openStreetMapService;

  const ResultsScreen({
    super.key,
    this.origin = '',
    this.destination = '',
    this.openStreetMapService,
  });

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
  bool _usingMapFallback = false;
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

  String get _displayOrigin =>
      _effectiveOrigin.isEmpty ? 'Your current location' : _effectiveOrigin;

  OpenStreetMapService get _mapService =>
      widget.openStreetMapService ?? _openStreetMap;

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
      _usingMapFallback = false;
    });

    try {
      await _store.load(refresh: true);
      final destinationQueries = {
        _searchArguments?['name']?.toString().trim() ?? _effectiveDestination,
        _searchArguments?['address']?.toString().trim() ?? '',
      }..remove('');
      final routes = _store.routes
          .where(
            (route) =>
                route.active &&
                _routeMatchesSearch(
                  route,
                  _effectiveOrigin,
                  destinationQueries,
                ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _selectedRouteId = routes.firstOrNull?.id;
        _usingMapFallback = routes.isEmpty;
        _loading = false;
      });
      await _loadMapRoute(
        origin: _effectiveOrigin.isEmpty
            ? routes.firstOrNull?.origin ?? ''
            : _effectiveOrigin,
        destination: _effectiveDestination,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool _routeMatchesSearch(
    RouteModel route,
    String origin,
    Set<String> destinations,
  ) {
    if (origin.trim().isEmpty) return false;
    final stops = <String>[route.origin, ...route.stops, route.destination];
    final originIndex = stops.indexWhere((stop) => _matchesPlace(stop, origin));
    if (originIndex == -1) return false;
    return destinations.any((destination) {
      return stops.asMap().entries.any(
        (entry) =>
            entry.key > originIndex && _matchesPlace(entry.value, destination),
      );
    });
  }

  bool _matchesPlace(String first, String second) {
    final normalizedFirst = _normalizePlace(first);
    final normalizedSecond = _normalizePlace(second);
    if (normalizedFirst.isEmpty || normalizedSecond.isEmpty) return false;
    return normalizedFirst.contains(normalizedSecond) ||
        normalizedSecond.contains(normalizedFirst);
  }

  String _normalizePlace(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Future<void> _loadMapRoute({
    required String origin,
    required String destination,
  }) async {
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
      final originLatitude = double.tryParse(
        _searchArguments?['originLatitude']?.toString() ?? '',
      );
      final originLongitude = double.tryParse(
        _searchArguments?['originLongitude']?.toString() ?? '',
      );
      final originPoint = originLatitude != null && originLongitude != null
          ? LatLng(originLatitude, originLongitude)
          : origin.trim().isEmpty
          ? await _mapService.currentPosition()
          : await _mapService.findPlace(origin);
      final destinationLatitude = double.tryParse(
        _searchArguments?['latitude']?.toString() ?? '',
      );
      final destinationLongitude = double.tryParse(
        _searchArguments?['longitude']?.toString() ?? '',
      );
      final destinationPoint =
          destinationLatitude != null && destinationLongitude != null
          ? LatLng(destinationLatitude, destinationLongitude)
          : await _mapService.findPlace(
              _searchArguments?['address']?.toString() ?? destination,
            );
      final mapRoutes = await _mapService.findRoutes(
        origin: originPoint,
        destination: destinationPoint,
      );
      if (!mounted || requestId != _mapRequestId) return;
      setState(() {
        _originPoint = originPoint;
        _destinationPoint = destinationPoint;
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

  Future<void> _selectRoute(RouteModel route) async {
    setState(() => _selectedRouteId = route.id);
    await _loadMapRoute(
      origin: _effectiveOrigin.isEmpty ? route.origin : _effectiveOrigin,
      destination: _effectiveDestination,
    );
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

  LatLng? _routeLabelPoint(OsmRouteModel route) {
    if (route.points.isEmpty) return null;
    return route.points[route.points.length ~/ 2];
  }

  String _mapRouteLabel(OsmRouteModel route) {
    final selectedRoute = _selectedRoute;
    if (selectedRoute == null) return route.routeName;
    if (selectedRoute.roadName.trim().isNotEmpty) {
      return selectedRoute.roadName;
    }
    final knownName = knownMalawiRouteName(
      selectedRoute.origin,
      selectedRoute.destination,
    );
    if (knownName.isNotEmpty) return '$knownName Road';
    return route.roadNames.isEmpty ? route.routeName : route.roadNamesLabel;
  }

  double _estimatedFare(OsmRouteModel route) =>
      (route.distanceMeters / 1000 * 220).roundToDouble();

  void _compareRoutes() {
    if (_mapRoutes.length < 2) {
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompareRoutesScreen(
          routes: comparisonRoutes,
          origin: _selectedRoute?.origin ?? _displayOrigin,
          destination: _selectedRoute?.destination ?? _effectiveDestination,
          configuredRoute: _selectedRoute,
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
          : _routes.isEmpty && !_usingMapFallback
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
                if (_usingMapFallback)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      border: Border.all(color: Colors.amber.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'This route is not defined by the administrator. '
                      'Map routes and fares are estimates from '
                      '$_displayOrigin to $_effectiveDestination.',
                    ),
                  ),
                if (_mapRoutes.isNotEmpty &&
                    _originPoint != null &&
                    _destinationPoint != null)
                  SizedBox(
                    height: 300,
                    child: FlutterMap(
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
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.mova',
                        ),
                        PolylineLayer(
                          polylines: _mapRoutes.map((route) {
                            final active = route.id == _activeMapRouteId;
                            return Polyline(
                              points: route.points,
                              color: active
                                  ? Colors.deepPurple
                                  : Colors.deepPurple.withValues(alpha: 0.35),
                              strokeWidth: active ? 6 : 3,
                            );
                          }).toList(),
                        ),
                        MarkerLayer(
                          markers: [
                            if (activeMapRoute != null &&
                                _routeLabelPoint(activeMapRoute) != null)
                              Marker(
                                point: _routeLabelPoint(activeMapRoute)!,
                                width: 110,
                                height: 36,
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.deepPurple,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _mapRouteLabel(activeMapRoute),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.deepPurple,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
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
                              label: Text('Map option ${index + 1}'),
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
                          _usingMapFallback
                              ? 'No administrator-defined route'
                              : '${_routes.length} administrator-configured route'
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
                if (_usingMapFallback && activeMapRoute != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Estimated fare: MWK '
                      '${_estimatedFare(activeMapRoute).toStringAsFixed(0)} '
                      '(map estimate; confirm the actual fare with the operator).',
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
                            '${route.roadName.isEmpty ? 'Road not specified' : 'Road: ${route.roadName}'} · '
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
                          onPressed: activeMapRoute == null
                              ? null
                              : () {
                                  final configuredRoute = _selectedRoute;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RouteDirectionsDetailsScreen(
                                            route: activeMapRoute,
                                            origin: _displayOrigin,
                                            destination: _effectiveDestination,
                                            estimatedFare:
                                                configuredRoute?.fare ??
                                                _estimatedFare(activeMapRoute),
                                            configuredRoute: configuredRoute,
                                          ),
                                    ),
                                  );
                                },
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
  final String origin;
  final String destination;
  final RouteModel? configuredRoute;

  const CompareRoutesScreen({
    super.key,
    required this.routes,
    required this.origin,
    required this.destination,
    required this.configuredRoute,
  });

  @override
  State<CompareRoutesScreen> createState() => _CompareRoutesScreenState();
}

class _CompareRoutesScreenState extends State<CompareRoutesScreen> {
  int _selectedRouteIndex = 0;

  double _estimatedFare(OsmRouteModel route) =>
      (route.distanceMeters / 1000 * 220).roundToDouble();

  RouteModel _routeForBooking(int index) {
    final mapRoute = widget.routes[index];
    final configuredRoute = widget.configuredRoute;
    if (configuredRoute != null) {
      return configuredRoute.copyWith(
        name: '${configuredRoute.name} · Map option ${index + 1}',
        duration: mapRoute.durationLabel,
        mapDistance: mapRoute.distanceLabel,
      );
    }

    return RouteModel(
      id: mapRoute.id,
      companyName: 'Map route estimate',
      name: 'Map option ${index + 1}: ${mapRoute.routeName}',
      origin: widget.origin,
      destination: widget.destination,
      stops: [widget.origin, widget.destination],
      fare: _estimatedFare(mapRoute),
      duration: mapRoute.durationLabel,
      mapDistance: mapRoute.distanceLabel,
      transfers: 0,
      fareIsEstimate: true,
    );
  }

  void _bookMapOption(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectTripScreen(initialRoute: _routeForBooking(index)),
      ),
    );
  }

  void _continueWithSelectedRoute() {
    final selectedMapRoute = widget.routes[_selectedRouteIndex];
    final configuredRoute = widget.configuredRoute;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteDirectionsDetailsScreen(
          route: selectedMapRoute,
          origin: widget.origin,
          destination: widget.destination,
          estimatedFare:
              configuredRoute?.fare ?? _estimatedFare(selectedMapRoute),
          configuredRoute: configuredRoute,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                '${widget.origin} → ${widget.destination}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.configuredRoute == null
                    ? 'Choose a map option to search for scheduled trips. '
                          'The displayed map fare is an estimate.'
                    : 'Driving directions for '
                          '${widget.configuredRoute!.name}. '
                          'The administrator-set fare is MWK '
                          '${widget.configuredRoute!.fare.toStringAsFixed(0)}.',
                style: const TextStyle(color: Colors.black54),
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
                        Row(
                          key: ValueKey('map-option-header-$index'),
                          children: [
                            Expanded(
                              child: Text(
                                'Map option ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              key: ValueKey('book-map-option-$index'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _bookMapOption(index),
                              icon: const Icon(
                                Icons.confirmation_number_outlined,
                                size: 16,
                              ),
                              label: const Text(
                                'Book now',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
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
                          label: widget.configuredRoute == null
                              ? 'Estimated map fare'
                              : 'Administrator-set fare',
                          value:
                              'MWK '
                              '${(widget.configuredRoute?.fare ?? _estimatedFare(widget.routes[index])).toStringAsFixed(0)}',
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
                  label: const Text('View selected map option'),
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
