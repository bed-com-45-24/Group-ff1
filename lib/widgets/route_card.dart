import 'package:flutter/material.dart';

import '../models/route_model.dart';

class RouteCard extends StatelessWidget {
  final RouteModel route;
  final VoidCallback onTap;
  final bool showCompare;
  final bool isSelected;
  final ValueChanged<bool>? onCompareChanged;

  const RouteCard({
    super.key,
    required this.route,
    required this.onTap,
    this.showCompare = false,
    this.isSelected = false,
    this.onCompareChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              route.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text('${route.origin} → ${route.destination}'),

            const SizedBox(height: 8),

            Text('Company: ${route.companyName}'),

            Text('Official fare: MWK ${route.fare.toStringAsFixed(0)}'),

            Text('Duration: ${route.duration ?? "Not published"}'),

            Text(
              'Transfers: ${route.transfers?.toString() ?? "Not published"}',
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                    ),
                    onPressed: onTap,
                    child: const Text('View details'),
                  ),
                ),

                if (showCompare) ...[
                  const SizedBox(width: 8),

                  Checkbox(
                    value: isSelected,
                    onChanged: onCompareChanged == null
                        ? null
                        : (value) {
                            onCompareChanged!(value ?? false);
                          },
                  ),

                  const Text('Compare'),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
