import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../models/route_model.dart';
import '../../widgets/route_card.dart';
import 'route_details_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String origin;
  final String destination;

  const ResultsScreen({super.key, this.origin = '', this.destination = ''});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final Set<String> selectedRouteIds = {};
  Map<String, dynamic>? _searchArguments;
  bool _readArguments = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readArguments) return;
    _readArguments = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      _searchArguments = arguments;
    }
  }

  List<RouteModel> get _matchingRoutes {
    final origin = _effectiveOrigin.toLowerCase();
    final destination = _effectiveDestination.toLowerCase();

    return sampleRoutes.where((route) {
      return (origin.isEmpty || route.origin.toLowerCase().contains(origin)) &&
          (destination.isEmpty ||
              route.destination.toLowerCase().contains(destination));
    }).toList();
  }

  String get _effectiveOrigin =>
      (widget.origin.isNotEmpty
              ? widget.origin
              : _searchArguments?['origin']?.toString() ?? '')
          .trim();

  String get _effectiveDestination =>
      (widget.destination.isNotEmpty
              ? widget.destination
              : _searchArguments?['name']?.toString() ?? '')
          .trim();

  void openRoute(RouteModel route) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RouteDetailsScreen(route: route)),
    );
  }

  void compareRoutes() {
    final selectedRoutes = _matchingRoutes
        .where((route) => selectedRouteIds.contains(route.id))
        .toList();

    if (selectedRoutes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least two routes to compare.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Compare routes'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: selectedRoutes.map((route) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Fare: MWK ${route.fare.toStringAsFixed(0)}'),
                    Text('Duration: ${route.duration}'),
                    Text('Transfers: ${route.transfers}'),
                    const Divider(),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routes = _matchingRoutes;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _effectiveOrigin.isEmpty && _effectiveDestination.isEmpty
              ? 'Available Routes'
              : '${_effectiveOrigin.isEmpty ? 'All origins' : _effectiveOrigin} → '
                    '${_effectiveDestination.isEmpty ? 'All destinations' : _effectiveDestination}',
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Choose a route to view its details. '
              'Select two or more routes to compare them.',
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];

                return RouteCard(
                  route: route,
                  onTap: () => openRoute(route),
                  showCompare: true,
                  isSelected: selectedRouteIds.contains(route.id),
                  onCompareChanged: (selected) {
                    setState(() {
                      if (selected) {
                        selectedRouteIds.add(route.id);
                      } else {
                        selectedRouteIds.remove(route.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          if (routes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No routes match those locations. Try different From or To values.',
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: compareRoutes,
                child: const Text('Compare selected routes'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
