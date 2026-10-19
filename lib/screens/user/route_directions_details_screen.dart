import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../models/osm_route_model.dart';
import '../../models/route_model.dart';
import 'booking/booking_summary_screen.dart';

class RouteDirectionsDetailsScreen extends StatelessWidget {
  final OsmRouteModel route;
  final String origin;
  final String destination;
  final double estimatedFare;

  const RouteDirectionsDetailsScreen({
    super.key,
    required this.route,
    required this.origin,
    required this.destination,
    required this.estimatedFare,
  });

  @override
  Widget build(BuildContext context) {
    final points = route.points;
    return Scaffold(
      appBar: AppBar(title: const Text('Full route details')),
      body: ListView(
        children: [
          SizedBox(
            height: 300,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: points.first,
                initialZoom: 8,
                initialCameraFit: CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(points),
                  padding: const EdgeInsets.all(28),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mova',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      color: Colors.deepPurple,
                      strokeWidth: 6,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: points.first,
                      width: 36,
                      height: 36,
                      child: const Icon(
                        Icons.trip_origin,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                    Marker(
                      point: points.last,
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
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$origin → $destination',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RouteMetric(
                        icon: Icons.route,
                        label: 'Distance',
                        value: route.distanceLabel,
                      ),
                    ),
                    Expanded(
                      child: _RouteMetric(
                        icon: Icons.schedule,
                        label: 'Estimated time',
                        value: route.durationLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _RouteMetric(
                  icon: Icons.payments_outlined,
                  label: 'Estimated fare (Malawi kwacha)',
                  value: 'MWK ${estimatedFare.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingSummaryScreen(
                          route: RouteModel(
                            id: route.id,
                            companyName: 'Map route estimate',
                            name: '$origin - $destination',
                            origin: origin,
                            destination: destination,
                            stops: [origin, destination],
                            fare: estimatedFare,
                            duration: route.durationLabel,
                            transfers: 0,
                            fareIsEstimate: true,
                          ),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.summarize_outlined),
                    label: const Text('Trip summary'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Turn-by-turn directions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (route.steps.isEmpty)
                  const Text('Detailed directions are not available.')
                else
                  for (var index = 0; index < route.steps.length; index++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(route.steps[index]),
                    ),
                const SizedBox(height: 8),
                const Text(
                  'Route geometry and directions are provided by OpenStreetMap '
                  'data via OSRM. Travel time is an estimate.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RouteMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
