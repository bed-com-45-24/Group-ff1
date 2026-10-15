import 'package:flutter/material.dart';
import '../../data/sample_data.dart';
import '../../models/route_model.dart';
import '../../widgets/route_card.dart';
import 'route_details_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final Set<String> selectedRouteIds = {};

  void openRoute(RouteModel route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteDetailsScreen(route: route),
      ),
    );
  }

  void compareRoutes() {
    final selectedRoutes = sampleRoutes
        .where((route) => selectedRouteIds.contains(route.id))
        .toList();

    if (selectedRoutes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least two routes to compare.'),
        ),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Fare: MWK ${route.fare.toStringAsFixed(0)}',
                    ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Routes'),
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
              itemCount: sampleRoutes.length,
              itemBuilder: (context, index) {
                final route = sampleRoutes[index];

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