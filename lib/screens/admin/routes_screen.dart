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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editRoute([RouteModel? existing]) async {
    final origin = TextEditingController(text: existing?.origin ?? '');
    final destination = TextEditingController(
      text: existing?.destination ?? '',
    );
    final pickupLocation = TextEditingController(
      text: existing?.pickupLocation ?? '',
    );
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
                _field(pickupLocation, 'Pickup depot', required: false),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Use a known pickup point such as Limbe Depot. Leave blank '
                    'to use the origin name followed by “Depot”.',
                    style: TextStyle(color: mutedText),
                  ),
                ),
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
              final duplicate = _store.routes.any(
                (route) =>
                    route.id != existing?.id &&
                    route.origin.toLowerCase() == from.toLowerCase() &&
                    route.destination.toLowerCase() == to.toLowerCase(),
              );
              if (duplicate) {
                _showMessage('That route already exists.');
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
                  pickupLocation: pickupLocation.text.trim().isEmpty
                      ? null
                      : pickupLocation.text.trim(),
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
    pickupLocation.dispose();
    company.dispose();
    fare.dispose();
    departures.dispose();
    if (result == null) return;
    await _store.saveRoute(result);
    if (mounted) _showMessage('Route saved.');
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
    if (mounted) _showMessage('Route deleted.');
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
                    'Changes are saved and used by passenger route browsing.',
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
                                  title: Text(route.name),
                                  subtitle: Text(
                                    '${route.stops.length} stops · '
                                    'MWK ${route.fare.toStringAsFixed(0)}',
                                  ),
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
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
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
