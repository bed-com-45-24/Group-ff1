import 'package:flutter/material.dart';

import '../../data/route_store.dart';
import '../../data/trip_store.dart';
import '../../models/route_model.dart';

class FaresScreen extends StatefulWidget {
  const FaresScreen({super.key});

  @override
  State<FaresScreen> createState() => _FaresScreenState();
}

class _FaresScreenState extends State<FaresScreen> {
  final _store = RouteStore.instance;
  final _tripStore = TripStore.instance;

  @override
  void initState() {
    super.initState();
    _store.load();
    _tripStore.load();
  }

  Future<void> _editFare(RouteModel route) async {
    final controller = TextEditingController(
      text: route.fare.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();
    final fare = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update fare · ${route.name}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Fare in MWK',
              prefixText: 'MWK ',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final amount = double.tryParse(value?.trim() ?? '');
              return amount == null || amount <= 0
                  ? 'Enter a fare greater than zero'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, double.parse(controller.text));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (fare == null) return;
    await _store.saveRoute(route.copyWith(fare: fare));
    final matchingTrips = _tripStore.trips.where(
      (trip) =>
          trip.origin.toLowerCase() == route.origin.toLowerCase() &&
          trip.destination.toLowerCase() == route.destination.toLowerCase(),
    );
    await Future.wait(
      matchingTrips.map((trip) => _tripStore.saveTrip(trip.copyWith(fare: fare))),
    );
    if (mounted) _message('Fare updated and saved.');
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: _store.changes,
          builder: (context, _, _) {
            final routes = _store.routes;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage fares',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text('Fare changes are reflected in passenger routes.'),
                  const SizedBox(height: 18),
                  Expanded(
                    child: !_store.isLoaded
                        ? const Center(child: CircularProgressIndicator())
                        : routes.isEmpty
                        ? const Center(
                            child: Text('Add a route before setting fares.'),
                          )
                        : ListView.builder(
                            itemCount: routes.length,
                            itemBuilder: (context, index) {
                              final route = routes[index];
                              return Card(
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(route.name),
                                  subtitle: Text(
                                    route.active ? 'Active route' : 'Inactive',
                                  ),
                                  trailing: Text(
                                    'MWK ${route.fare.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Color(0xFFE87916),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  onTap: () => _editFare(route),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
