import 'package:flutter/material.dart';

import '../../models/route_model.dart';
import '../../models/osm_route_model.dart';
import '../../services/openstreetmap_service.dart';
import 'booking/booking_summary_screen.dart';

class RouteDetailsScreen extends StatefulWidget {
  final RouteModel route;

  const RouteDetailsScreen({super.key, required this.route});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  final _openStreetMap = OpenStreetMapService();
  OsmRouteModel? _mapRoute;
  String? _mapError;
  bool _loadingMapRoute = true;

  RouteModel get route => widget.route;

  @override
  void initState() {
    super.initState();
    _loadMapRoute();
  }

  Future<void> _loadMapRoute() async {
    try {
      final origin = await _openStreetMap.findPlace(route.origin);
      final destination = await _openStreetMap.findPlace(route.destination);
      final routes = await _openStreetMap.findRoutes(
        origin: origin,
        destination: destination,
      );
      if (!mounted) return;
      setState(() {
        _mapRoute = routes.first;
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

  String get _effectiveDurationText =>
      _mapRoute?.durationLabel ??
      (_loadingMapRoute
          ? 'Loading map estimate...'
          : route.duration ?? 'Not available');

  String get _effectiveDistanceText =>
      _mapRoute?.distanceLabel ??
      (_loadingMapRoute
          ? 'Loading map estimate...'
          : route.mapDistance ?? 'Not available');

  @override
  Widget build(BuildContext context) {
    final routeForSummary = RouteModel(
      id: route.id,
      companyName: route.companyName,
      name: route.name,
      origin: route.origin,
      destination: route.destination,
      stops: route.stops,
      fare: route.fare,
      duration: _effectiveDurationText,
      mapDistance: _effectiveDistanceText,
      transfers: route.transfers,
      departureTimes: route.departureTimes,
      fareIsEstimate: route.fareIsEstimate,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('MOVA Route Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(route.name, style: Theme.of(context).textTheme.headlineSmall),

          const SizedBox(height: 8),

          Text('Transport company: ${route.companyName}'),

          const SizedBox(height: 16),

          const Divider(),

          const Text(
            'Journey Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          ListTile(
            leading: const Icon(Icons.trip_origin),
            title: const Text('Origin / Pickup'),
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
            title: const Text('Reference Fare'),
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

          const SizedBox(height: 16),

          const Text(
            'Confirm the applicable fare and schedule with the transport '
            'operator before travelling.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loadingMapRoute
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingSummaryScreen(route: routeForSummary),
                        ),
                      );
                    },
              child: const Text('View Trip Summary'),
            ),
          ),
        ],
      ),
    );
  }
}
