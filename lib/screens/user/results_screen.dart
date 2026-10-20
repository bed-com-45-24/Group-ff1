import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/osm_route_model.dart';
import '../../models/route_model.dart';
import '../../services/openstreetmap_service.dart';
import 'booking/booking_summary_screen.dart';
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
  final _openStreetMap = OpenStreetMapService();
  Map<String, dynamic>? _searchArguments;
  List<OsmRouteModel> _routes = [];
  LatLng? _originPoint;
  LatLng? _destinationPoint;
  String _originName = '';
  String _destinationName = '';
  String? _errorMessage;
  String? _activeRouteId;
  bool _loading = true;
  bool _readArguments = false;

  String get _effectiveOrigin =>
      (widget.origin.isNotEmpty
              ? widget.origin
              : _searchArguments?['origin']?.toString() ?? '')
          .trim();

  String get _effectiveDestination =>
      (widget.destination.isNotEmpty
              ? widget.destination
              : _searchArguments?['address']?.toString() ??
                    _searchArguments?['name']?.toString() ??
                    '')
          .trim();

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
      _routes = [];
    });
    try {
      final originName = _effectiveOrigin;
      final destinationName = _effectiveDestination;
      if (destinationName.isEmpty) {
        throw Exception('Search for a destination to see available routes.');
      }

      final origin = originName.isEmpty
          ? await _openStreetMap.currentPosition()
          : await _openStreetMap.findPlace(originName);
      final latitude = double.tryParse(
        _searchArguments?['latitude']?.toString() ?? '',
      );
      final longitude = double.tryParse(
        _searchArguments?['longitude']?.toString() ?? '',
      );
      if (originName.isNotEmpty && (latitude == null || longitude == null)) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      final destination = latitude != null && longitude != null
          ? LatLng(latitude, longitude)
          : await _openStreetMap.findPlace(destinationName);
      final routes = await _openStreetMap.findRoutes(
        origin: origin,
        destination: destination,
      );
      if (!mounted) return;
      setState(() {
        _originPoint = origin;
        _destinationPoint = destination;
        _originName = originName.isEmpty ? 'Your location' : originName;
        _destinationName = destinationName;
        _routes = routes;
        _activeRouteId = routes.first.id;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
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

  void _selectRoute(OsmRouteModel route) {
    setState(() => _activeRouteId = route.id);
    _fitMap(route);
  }

  double _estimatedFareAmount(OsmRouteModel route) =>
      ((route.distanceMeters / 1000) * 220).roundToDouble();

  String _estimateFare(OsmRouteModel route) =>
      'MWK ${_estimatedFareAmount(route).toStringAsFixed(0)}';

  void _compareRoutes() {
    if (_routes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least two routes to compare.')),
      );
      return;
    }

    final comparisonRoutes = List<OsmRouteModel>.from(_routes)
      ..sort(
        (first, second) =>
            first.durationSeconds.compareTo(second.durationSeconds),
      );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompareRoutesScreen(
          routes: comparisonRoutes,
          origin: _originName,
          destination: _destinationName,
          estimateFare: _estimateFare,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeRoute = _routes.where((route) => route.id == _activeRouteId);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _effectiveDestination.isEmpty
              ? 'Routes'
              : 'Routes to ${_destinationName.isEmpty ? _effectiveDestination : _destinationName}',
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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.route_outlined,
                      size: 48,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 12),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadRoutes,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : _routes.isEmpty
          ? const Center(child: Text('No routes found.'))
          : Column(
              children: [
                SizedBox(
                  height: 300,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _originPoint!,
                      initialZoom: 8,
                      onMapReady: () {
                        if (activeRoute.isNotEmpty) {
                          _fitMap(activeRoute.first);
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
                        polylines: _routes.map((route) {
                          final active = route.id == _activeRouteId;
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
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$_originName → $_destinationName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text('${_routes.length} route options'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Map-based travel times are estimates, not bus schedules. '
                        'Fares are distance-based estimates in Malawi kwacha.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: _routes.length,
                    itemBuilder: (context, index) {
                      final route = _routes[index];
                      final selected = route.id == _activeRouteId;
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
                          title: Text('Route ${index + 1}'),
                          subtitle: Text(
                            'Distance: ${route.distanceLabel} · '
                            'Map time: ${route.durationLabel}\n'
                            'Estimated fare: ${_estimateFare(route)}',
                          ),
                          isThreeLine: true,
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
                          onPressed: activeRoute.isEmpty
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RouteDirectionsDetailsScreen(
                                          route: activeRoute.first,
                                          origin: _originName,
                                          destination: _destinationName,
                                          estimatedFare: _estimatedFareAmount(
                                            activeRoute.first,
                                          ),
                                        ),
                                  ),
                                ),
                          icon: const Icon(Icons.list_alt),
                          label: const Text('Full route details'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _compareRoutes,
                          icon: const Icon(Icons.compare_arrows),
                          label: const Text('Compare'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class CompareRoutesScreen extends StatefulWidget {
  final List<OsmRouteModel> routes;
  final String origin;
  final String destination;
  final String Function(OsmRouteModel route) estimateFare;

  const CompareRoutesScreen({
    super.key,
    required this.routes,
    required this.origin,
    required this.destination,
    required this.estimateFare,
  });

  @override
  State<CompareRoutesScreen> createState() => _CompareRoutesScreenState();
}

class _CompareRoutesScreenState extends State<CompareRoutesScreen> {
  late int _selectedRouteIndex = 0;

  void _continueWithSelectedRoute() {
    final selectedRoute = widget.routes[_selectedRouteIndex];
    final fare = (selectedRoute.distanceMeters / 1000 * 220).roundToDouble();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSummaryScreen(
          route: RouteModel(
            id: selectedRoute.id,
            companyName: 'Map route estimate',
            name:
                '${widget.origin} - ${widget.destination} · '
                'Route ${_selectedRouteIndex + 1}',
            origin: widget.origin,
            destination: widget.destination,
            stops: [widget.origin, widget.destination],
            fare: fare,
            duration: selectedRoute.durationLabel,
            mapDistance: selectedRoute.distanceLabel,
            transfers: 0,
            fareIsEstimate: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare routes'),
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
              const Text(
                'Compare map-based travel times and distances with estimated '
                'fares in Malawi kwacha (MWK).',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              const Text(
                'Estimated fares are calculated from route distance at MWK '
                '220 per kilometre. Confirm the actual fare with the operator.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
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
                          children: [
                            Expanded(
                              child: Text(
                                'Route ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (index == 0)
                              const Chip(
                                label: Text('Fastest'),
                                visualDensity: VisualDensity.compact,
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
                          label: 'Estimated travel time (map)',
                          value: widget.routes[index].durationLabel,
                        ),
                        _ComparisonMetric(
                          label: 'Distance (map)',
                          value: widget.routes[index].distanceLabel,
                        ),
                        _ComparisonMetric(
                          label: 'Estimated fare (Malawi kwacha)',
                          value: widget.estimateFare(widget.routes[index]),
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
                  label: const Text('View Trip Summary'),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
