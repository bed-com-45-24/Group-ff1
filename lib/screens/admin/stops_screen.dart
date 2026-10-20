import 'package:flutter/material.dart';

import '../../data/route_store.dart';
import '../../models/route_model.dart';

class StopsScreen extends StatefulWidget {
  const StopsScreen({super.key});

  @override
  State<StopsScreen> createState() => _StopsScreenState();
}

class _StopsScreenState extends State<StopsScreen> {
  final _store = RouteStore.instance;
  final _stopController = TextEditingController();
  String? _selectedRouteId;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  void dispose() {
    _stopController.dispose();
    super.dispose();
  }

  Future<void> _addStop(RouteModel route) async {
    final stop = _stopController.text.trim();
    if (stop.isEmpty) {
      _message('Enter a stop name first.');
      return;
    }
    if (route.stops.any((item) => item.toLowerCase() == stop.toLowerCase())) {
      _message('That stop is already on this route.');
      return;
    }
    await _store.saveRoute(route.copyWith(stops: [...route.stops, stop]));
    _stopController.clear();
    if (mounted) {
      FocusScope.of(context).unfocus();
      _message('Stop saved to ${route.name}.');
    }
  }

  Future<void> _removeStop(RouteModel route, String stop) async {
    if (route.stops.length <= 2) {
      _message('A route must keep its origin and destination stops.');
      return;
    }
    await _store.saveRoute(
      route.copyWith(stops: route.stops.where((item) => item != stop).toList()),
    );
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
            if (routes.isNotEmpty &&
                !routes.any((route) => route.id == _selectedRouteId)) {
              _selectedRouteId = routes.first.id;
            }
            final selectedRoute = routes
                .where((route) => route.id == _selectedRouteId)
                .firstOrNull;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage stops',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text('Edit stops on the shared passenger routes.'),
                  const SizedBox(height: 18),
                  if (routes.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRouteId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Route',
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                      items: routes
                          .map(
                            (route) => DropdownMenuItem(
                              value: route.id,
                              child: Text(
                                route.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRouteId = value);
                        }
                      },
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: !_store.isLoaded
                        ? const Center(child: CircularProgressIndicator())
                        : selectedRoute == null
                        ? const Center(
                            child: Text('Add a route before managing stops.'),
                          )
                        : Card(
                            color: Colors.white,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: selectedRoute.stops.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final stop = selectedRoute.stops[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(stop),
                                  trailing: index == 0 ||
                                          index == selectedRoute.stops.length - 1
                                      ? const Icon(
                                          Icons.lock_outline,
                                          size: 18,
                                        )
                                      : IconButton(
                                          tooltip: 'Remove stop',
                                          onPressed: () =>
                                              _removeStop(selectedRoute, stop),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                  ),
                  if (selectedRoute != null)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _stopController,
                            decoration: const InputDecoration(
                              hintText: 'New intermediate stop',
                              filled: true,
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _addStop(selectedRoute),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => _addStop(selectedRoute),
                          child: const Text('Add'),
                        ),
                      ],
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
