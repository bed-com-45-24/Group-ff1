import 'package:flutter/material.dart';

import '../../data/route_store.dart';
import '../../models/route_model.dart';

const Color appBlue = Color(0xFF2189E5);
const Color appBackground = Color(0xFFF5F6FA);
const Color activeGreen = Color(0xFF2E7D32);
const Color mutedText = Color(0xFF858585);

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final _store = RouteStore.instance;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  // Hard-coded depot mapping for Malawi towns.
  String _getDepot(String location) {
    final place = location.trim().toLowerCase();

    const depots = {
      'lilongwe': 'Lilongwe Bus Depot',
      'llz': 'Lilongwe Bus Depot',
      'blantyre': 'Wenela Bus Depot',
      'bts': 'Wenela Bus Depot',
      'zomba': 'Zomba Depot',
      'karonga': 'Karonga Depot',
      'mzuzu': 'Mzuzu Depot',
      'mangochi': 'Mangochi Depot',
      'kasungu': 'Kasungu Depot',
      'salima': 'Salima Depot',
      'dedza': 'Dedza Depot',
      'ntcheu': 'Ntcheu Depot',
      'balaka': 'Balaka Depot',
      'liwonde': 'Liwonde Depot',
      'mulanje': 'Mulanje Depot',
      'thyolo': 'Thyolo Depot',
      'mzimba': 'Mzimba Depot',
      'nkhata bay': 'Nkhata Bay Depot',
    };

    return depots[place] ?? '$location Depot';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _normalizeRouteValue(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Future<void> _editRoute([RouteModel? existing]) async {
    final origin = TextEditingController(text: existing?.origin ?? '');
    final destination = TextEditingController(
      text: existing?.destination ?? '',
    );
    final roadName = TextEditingController(text: existing?.roadName ?? '');

    final pickupLocation = TextEditingController(
      text: _getDepot(existing?.origin ?? ''),
    );

    final dropoffLocation = TextEditingController(
      text: _getDepot(existing?.destination ?? ''),
    );

    // Automatically update pickup depot when origin changes.
    origin.addListener(() {
      pickupLocation.text = _getDepot(origin.text);
    });

    // Automatically update drop-off depot when destination changes.
    destination.addListener(() {
      dropoffLocation.text = _getDepot(destination.text);
    });

    final company = TextEditingController(
      text: existing?.companyName ?? 'MOVA',
    );

    final fare = TextEditingController(
      text: existing == null ? '' : existing.fare.toStringAsFixed(0),
    );

    final departures = TextEditingController(
      text: existing?.departureTimes.join(', ') ?? '',
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<RouteModel>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add route' : 'Edit route'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(origin, 'Origin'),
                _field(destination, 'Destination'),
                _field(roadName, 'Road / highway (for example M1 or M5)'),

                // Pickup depot is automatically determined by origin.
                _field(pickupLocation, 'Pickup depot', readOnly: true),

                // Drop-off depot is automatically determined by destination.
                _field(dropoffLocation, 'Drop-off depot', readOnly: true),

                _field(company, 'Transport company'),

                _field(
                  fare,
                  'Fare in MWK',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');

                    return amount == null || amount <= 0
                        ? 'Enter a fare greater than zero'
                        : null;
                  },
                ),

                _field(
                  departures,
                  'Departure times (comma-separated)',
                  required: false,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;

              final from = origin.text.trim();
              final to = destination.text.trim();
              final road = roadName.text.trim();

              final duplicate = _store.routes.any(
                (route) =>
                    route.id != existing?.id &&
                    _normalizeRouteValue(route.origin) ==
                        _normalizeRouteValue(from) &&
                    _normalizeRouteValue(route.destination) ==
                        _normalizeRouteValue(to) &&
                    _normalizeRouteValue(route.roadName) ==
                        _normalizeRouteValue(road),
              );

              if (duplicate) {
                _showMessage('That route on $road already exists.');
                return;
              }

              final intermediateStops =
                  existing != null && existing.stops.length > 2
                  ? existing.stops.sublist(1, existing.stops.length - 1)
                  : const <String>[];

              Navigator.pop(
                dialogContext,
                RouteModel(
                  id:
                      existing?.id ??
                      'R-${DateTime.now().microsecondsSinceEpoch}',
                  companyName: company.text.trim(),
                  name: '$from - $to',
                  origin: from,
                  destination: to,
                  roadName: road,
                  pickupLocation: _getDepot(from),
                  stops: [from, ...intermediateStops, to],
                  fare: double.parse(fare.text.trim()),
                  duration: existing?.duration,
                  mapDistance: existing?.mapDistance,
                  transfers: existing?.transfers,
                  departureTimes: departures.text
                      .split(',')
                      .map((time) => time.trim())
                      .where((time) => time.isNotEmpty)
                      .toList(),
                  active: existing?.active ?? true,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    await WidgetsBinding.instance.endOfFrame;

    origin.dispose();
    destination.dispose();
    roadName.dispose();
    pickupLocation.dispose();
    dropoffLocation.dispose();
    company.dispose();
    fare.dispose();
    departures.dispose();

    if (result == null) return;

    await _store.saveRoute(result);

    if (mounted) {
      _showMessage('Route saved.');
    }
  }

  Future<void> _removeRoute(RouteModel route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete route?'),
        content: Text('Delete ${route.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _store.removeRoute(route.id);

    if (mounted) {
      _showMessage('Route deleted.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
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
                    'Manage routes',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Manage routes, pickup depots and drop-off depots.',
                    style: TextStyle(color: mutedText),
                  ),

                  const SizedBox(height: 18),

                  Expanded(
                    child: !_store.isLoaded
                        ? const Center(child: CircularProgressIndicator())
                        : routes.isEmpty
                        ? const Center(child: Text('No routes yet. Add one.'))
                        : ListView.builder(
                            itemCount: routes.length,
                            itemBuilder: (context, index) {
                              final route = routes[index];

                              return Card(
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(
                                    route.roadName.isEmpty
                                        ? route.name
                                        : '${route.name} · ${route.roadName}',
                                  ),

                                  subtitle: Text(
                                    'Pickup: ${_getDepot(route.origin)}\n'
                                    'Drop-off: ${_getDepot(route.destination)}\n'
                                    'MWK ${route.fare.toStringAsFixed(0)}',
                                  ),

                                  isThreeLine: true,

                                  onTap: () => _editRoute(route),

                                  trailing: Wrap(
                                    spacing: 0,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Switch(
                                        value: route.active,
                                        onChanged: (active) => _store.saveRoute(
                                          route.copyWith(active: active),
                                        ),
                                      ),

                                      IconButton(
                                        tooltip: 'Delete route',
                                        onPressed: () => _removeRoute(route),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _editRoute(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add route'),
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

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool required = true,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator:
            validator ??
            (value) => required && (value == null || value.trim().isEmpty)
                ? 'This field is required'
                : null,
      ),
    );
  }
}
