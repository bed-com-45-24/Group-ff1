import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/booking_store.dart';
import '../../models/booking_model.dart';
import '../../models/osm_route_model.dart';
import '../../services/location_service.dart';
import '../../services/openstreetmap_service.dart';
import '../../utils/malawi_map.dart';
import 'profile_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _routeColors = [
    Colors.deepPurple,
    Colors.teal,
    Colors.orange,
    Colors.indigo,
    Colors.pink,
  ];

  final _mapController = MapController();
  final _openStreetMap = OpenStreetMapService();
  final _locationService = LocationService();
  final _placeCache = <String, LatLng>{};
  List<_BookedTripRoute> _routes = [];
  LatLng? _userLocation;
  LatLng _mapCenter = malawiCenter;
  String? _locationError;
  List<String> _routeErrors = [];
  int _bookedTripCount = 0;
  int _lastBookingRevision = -1;
  DateTime? _lastPlaceLookup;
  bool _isLoadingRoutes = false;
  bool _reloadPending = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    BookingStore.instance.changes.addListener(_onBookingsChanged);
    _loadBookedTrips();
  }

  @override
  void dispose() {
    BookingStore.instance.changes.removeListener(_onBookingsChanged);
    super.dispose();
  }

  void _onBookingsChanged() {
    final revision = BookingStore.instance.changes.value;
    if (revision == _lastBookingRevision) return;
    _lastBookingRevision = revision;
    if (_isLoadingRoutes) {
      _reloadPending = true;
      return;
    }
    _loadBookedTrips();
  }

  Future<void> _loadBookedTrips() async {
    if (_isLoadingRoutes) {
      _reloadPending = true;
      return;
    }
    setState(() {
      _isLoadingRoutes = true;
      _routeErrors = [];
      _locationError = null;
    });

    try {
      final store = BookingStore.instance;
      await store.load();
      _lastBookingRevision = store.changes.value;
      _reloadPending = false;
      final bookings = store.bookings.where((booking) => booking.paid).toList();
      final errors = <String>[];
      LatLng? currentLocation;

      try {
        final position = await _locationService.getCurrentPosition();
        if (position == null) {
          _locationError =
              'Current location is unavailable. Allow location access to see '
              'the dotted route to your pickup.';
        } else {
          currentLocation = LatLng(position.latitude, position.longitude);
        }
      } catch (error) {
        _locationError = _errorMessage(error);
      }

      final bookedRoutes = <_BookedTripRoute>[];
      for (var index = 0; index < bookings.length; index++) {
        final booking = bookings[index];
        try {
          final origin = await _findPlace(booking.trip.origin);
          final destination = await _findPlace(booking.trip.destination);
          final tripRoute = await _findRoute(origin, destination);
          List<LatLng>? approachPoints;
          if (currentLocation != null) {
            try {
              approachPoints = (await _findRoute(
                currentLocation,
                origin,
              )).points;
            } catch (error) {
              errors.add(
                'Your location to ${booking.trip.origin}: '
                '${_errorMessage(error)}',
              );
            }
          }
          bookedRoutes.add(
            _BookedTripRoute(
              booking: booking,
              color: _routeColors[index % _routeColors.length],
              origin: origin,
              destination: destination,
              tripPoints: tripRoute.points,
              approachPoints: approachPoints,
            ),
          );
        } catch (error) {
          errors.add(
            '${booking.trip.origin} to ${booking.trip.destination}: '
            '${_errorMessage(error)}',
          );
        }
      }

      if (!mounted) return;
      final visiblePoints = <LatLng>[
        ?currentLocation,
        for (final route in bookedRoutes) ...[
          ...route.tripPoints,
          ...?route.approachPoints,
        ],
      ];
      setState(() {
        _userLocation = currentLocation;
        _routes = bookedRoutes;
        _bookedTripCount = bookings.length;
        _routeErrors = errors;
        if (visiblePoints.isNotEmpty) _mapCenter = visiblePoints.first;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToRoutes());
    } catch (error) {
      if (!mounted) return;
      setState(() => _routeErrors = [_errorMessage(error)]);
    } finally {
      if (mounted) {
        setState(() => _isLoadingRoutes = false);
        if (_reloadPending) _loadBookedTrips();
      }
    }
  }

  Future<LatLng> _findPlace(String name) async {
    final key = name.trim().toLowerCase();
    final cached = _placeCache[key];
    if (cached != null) return cached;

    final lastLookup = _lastPlaceLookup;
    if (lastLookup != null) {
      final wait =
          const Duration(seconds: 1) - DateTime.now().difference(lastLookup);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }

    _lastPlaceLookup = DateTime.now();
    final point = await _openStreetMap.findPlace(name);
    _placeCache[key] = point;
    return point;
  }

  Future<OsmRouteModel> _findRoute(LatLng origin, LatLng destination) async {
    final routes = await _openStreetMap.findRoutes(
      origin: origin,
      destination: destination,
    );
    if (routes.isEmpty || routes.first.points.length < 2) {
      throw StateError('No drivable route was found.');
    }
    return routes.first;
  }

  String _errorMessage(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  void _fitMapToRoutes() {
    if (!_mapReady || !mounted) return;
    final points = <LatLng>[
      ?_userLocation,
      for (final route in _routes) ...[
        ...route.tripPoints,
        ...?route.approachPoints,
      ],
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 12);
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(72),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final polylines = <Polyline>[
      for (final route in _routes)
        if (route.approachPoints case final approachPoints?)
          Polyline(
            points: approachPoints,
            color: Colors.blue,
            strokeWidth: 4,
            pattern: const StrokePattern.dotted(),
          ),
      for (final route in _routes)
        Polyline(points: route.tripPoints, color: route.color, strokeWidth: 6),
    ];

    final markers = <Marker>[
      if (_userLocation case final userLocation?)
        Marker(
          point: userLocation,
          width: 42,
          height: 42,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
        ),
      for (final route in _routes) ...[
        Marker(
          point: route.origin,
          width: 42,
          height: 42,
          child: Icon(Icons.trip_origin, color: route.color, size: 30),
        ),
        Marker(
          point: route.destination,
          width: 42,
          height: 42,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 38),
        ),
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trip Map'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
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
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 6,
              cameraConstraint: CameraConstraint.containCenter(
                bounds: malawiBounds,
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onMapReady: () {
                _mapReady = true;
                _fitMapToRoutes();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mova',
              ),
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
              if (markers.isNotEmpty) MarkerLayer(markers: markers),
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
            child: _MapStatusCard(
              bookingCount: _bookedTripCount,
              routeCount: _routes.length,
              isLoading: _isLoadingRoutes,
              locationError: _locationError,
              routeErrors: _routeErrors,
              tripLabels: _routes
                  .map(
                    (route) =>
                        '${route.booking.trip.origin} → '
                        '${route.booking.trip.destination}',
                  )
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Refresh booked trips and location',
        onPressed: _isLoadingRoutes ? null : _loadBookedTrips,
        child: _isLoadingRoutes
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.my_location),
      ),
    );
  }
}

class _BookedTripRoute {
  final BookingDraft booking;
  final Color color;
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> tripPoints;
  final List<LatLng>? approachPoints;

  const _BookedTripRoute({
    required this.booking,
    required this.color,
    required this.origin,
    required this.destination,
    required this.tripPoints,
    required this.approachPoints,
  });
}

class _MapStatusCard extends StatelessWidget {
  final int bookingCount;
  final int routeCount;
  final bool isLoading;
  final String? locationError;
  final List<String> routeErrors;
  final List<String> tripLabels;

  const _MapStatusCard({
    required this.bookingCount,
    required this.routeCount,
    required this.isLoading,
    required this.locationError,
    required this.routeErrors,
    required this.tripLabels,
  });

  @override
  Widget build(BuildContext context) {
    final status = isLoading
        ? 'Loading your booked trips...'
        : bookingCount == 0
        ? 'No paid bookings to display yet.'
        : routeCount == 0
        ? 'Could not load a map route for your bookings.'
        : '$routeCount of $bookingCount booked '
              '${bookingCount == 1 ? 'trip' : 'trips'} shown';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.map_outlined, color: Colors.deepPurple),
                const SizedBox(width: 10),
                Expanded(child: Text(status)),
              ],
            ),
            if (!isLoading && routeCount > 0) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.horizontal_rule, color: Colors.deepPurple),
                  SizedBox(width: 4),
                  Text('Booked trip'),
                  SizedBox(width: 16),
                  Icon(Icons.more_horiz, color: Colors.blue),
                  SizedBox(width: 4),
                  Expanded(child: Text('Your location to pickup')),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: tripLabels.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) => Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(tripLabels[index]),
                  ),
                ),
              ),
            ],
            if (locationError != null) ...[
              const SizedBox(height: 6),
              Text(
                locationError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            for (final error in routeErrors.take(2)) ...[
              const SizedBox(height: 6),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (routeErrors.length > 2) ...[
              const SizedBox(height: 4),
              Text(
                'And ${routeErrors.length - 2} more route '
                '${routeErrors.length - 2 == 1 ? 'error' : 'errors'}.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
