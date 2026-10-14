
import 'package:flutter/material.dart';
import '../../models/route_model.dart';
import 'booking/booking_summary_screen.dart';

class RouteDetailsScreen extends StatelessWidget {
  final RouteModel route;

  const RouteDetailsScreen({
    super.key,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MOVA Route Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            route.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          const SizedBox(height: 8),

          Text('Transport company: ${route.companyName}'),

          const SizedBox(height: 16),

          const Divider(),

          const Text(
            'Journey Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          for (int i = 0; i < route.stops.length; i++)
            ListTile(
              leading: CircleAvatar(
                child: Text('${i + 1}'),
              ),
              title: Text(route.stops[i]),
            ),

          const Divider(height: 32),

          ListTile(
            leading: const Icon(Icons.payments),
            title: const Text('Reference Fare'),
            subtitle: Text(
              'MWK ${route.fare.toStringAsFixed(0)}',
            ),
          ),

          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Journey Duration'),
            subtitle: Text(
              route.duration ?? 'Not published',
            ),
          ),

          ListTile(
            leading: const Icon(Icons.directions_bus),
            title: const Text('Transfers'),
            subtitle: Text(
              route.transfers?.toString() ?? 'Not published',
            ),
          ),

          if (route.departureTimes.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Departure Times'),
              subtitle: Text(
                route.departureTimes.join(', '),
              ),
            ),

          const SizedBox(height: 16),

          const Text(
            'Fare reference: SoSoSo Coaches poster '
            'effective 3 April 2026. Confirm the applicable '
            'fare and schedule before travelling.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingSummaryScreen(
                      route: route,
                    ),
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
