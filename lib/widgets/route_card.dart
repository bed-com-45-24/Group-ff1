import 'package:flutter/material.dart';

import '../models/route_model.dart';
import '../services/openstreetmap_service.dart';

class RouteCard extends StatefulWidget {
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
  State<RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<RouteCard> {
  final _openStreetMap = OpenStreetMapService();
  String? _mapDuration;
  String? _mapError;
  bool _loadingMapDuration = true;

  @override
  void initState() {
    super.initState();
    _loadMapDuration();
  }

  @override
  void didUpdateWidget(covariant RouteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route.origin != widget.route.origin ||
        oldWidget.route.destination != widget.route.destination) {
      _mapDuration = null;
      _mapError = null;
      _loadingMapDuration = true;
      _loadMapDuration();
    }
  }

  Future<void> _loadMapDuration() async {
    try {
      final routes = await _openStreetMap.findRoutesBetweenPlaces(
        origin: widget.route.origin,
        destination: widget.route.destination,
      );
      if (!mounted) return;
      setState(() {
        _mapDuration = routes.first.durationLabel;
        _loadingMapDuration = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _mapError = error.toString().replaceFirst('Exception: ', '');
        _loadingMapDuration = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final durationLabel = _loadingMapDuration
        ? 'Loading map estimate...'
        : _mapDuration ?? 'Map estimate unavailable';
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

            Text('Duration: $durationLabel'),
            if (_mapError != null)
              Text(
                'Map travel time could not be loaded: $_mapError',
                style: const TextStyle(color: Colors.red),
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
                    onPressed: widget.onTap,
                    child: const Text('View details'),
                  ),
                ),

                if (widget.showCompare) ...[
                  const SizedBox(width: 8),

                  Checkbox(
                    value: widget.isSelected,
                    onChanged: widget.onCompareChanged == null
                        ? null
                        : (value) {
                            widget.onCompareChanged!(value ?? false);
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
