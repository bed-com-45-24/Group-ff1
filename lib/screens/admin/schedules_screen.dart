
import 'package:flutter/material.dart';

import '../../data/trip_store.dart';
import '../../models/trip_model.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final _store = TripStore.instance;

  final List<String> _buses = [
    'MOVA 1',
    'MOVA 2',
    'MOVA 3',
  ];

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  Future<void> _editTrip([Trip? existing]) async {
    final origin = TextEditingController(
      text: existing?.origin ?? '',
    );

    final destination = TextEditingController(
      text: existing?.destination ?? '',
    );

    final departure = TextEditingController(
      text: existing == null
          ? ''
          : _dateTimeString(existing.departureTime),
    );

    final arrival = TextEditingController(
      text: existing == null
          ? ''
          : _dateTimeString(existing.arrivalTime),
    );

    final fare = TextEditingController(
      text: existing?.fare.toStringAsFixed(0) ?? '',
    );

    final routeName = TextEditingController(
      text: existing?.routeName ?? '',
    );

    final formKey = GlobalKey<FormState>();

    String selectedBus = _buses.contains(existing?.operatorName)
        ? existing!.operatorName
        : _buses.first;

    final result = await showDialog<Trip>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'Add schedule' : 'Edit schedule',
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Origin
                  _field(origin, 'Origin'),

                  // Destination
                  _field(destination, 'Destination'),

                  // Bus dropdown
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      value: selectedBus,
                      decoration: const InputDecoration(
                        labelText: 'Select bus',
                        border: OutlineInputBorder(),
                      ),
                      items: _buses.map((bus) {
                        return DropdownMenuItem<String>(
                          value: bus,
                          child: Text(bus),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedBus = value;
                          });
                        }
                      },
                    ),
                  ),

                  // Bus capacity - fixed at 40
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      initialValue: '40',
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Bus capacity',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event_seat),
                      ),
                    ),
                  ),

                  // Departure
                  _field(
                    departure,
                    'Departure (YYYY-MM-DD HH:mm)',
                  ),

                  // Arrival
                  _field(
                    arrival,
                    'Arrival (YYYY-MM-DD HH:mm)',
                  ),

                  // Fare
                  _field(
                    fare,
                    'Fare per seat (MWK)',
                    number: true,
                  ),

                  // Route name
                  _field(
                    routeName,
                    'Route name / road (for example M1 Road)',
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

                final departureTime =
                    _parseDateTime(departure.text);

                final arrivalTime =
                    _parseDateTime(arrival.text);

                final amount =
                    double.tryParse(fare.text.trim());

                if (departureTime == null || arrivalTime == null) {
                  _message(
                    'Enter schedule times as YYYY-MM-DD HH:mm.',
                  );
                  return;
                }

                if (!arrivalTime.isAfter(departureTime)) {
                  _message('Arrival must be after departure.');
                  return;
                }

                if (departureTime.isBefore(DateTime.now())) {
                  _message('Departure must be in the future.');
                  return;
                }

                if ((existing?.bookedSeats.length ?? 0) > 40) {
                  _message(
                    'Booked seats cannot exceed 40.',
                  );
                  return;
                }

                if (amount == null || amount <= 0) {
                  _message('Enter a fare greater than zero.');
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  Trip(
                    id: existing?.id ??
                        'TRIP-${DateTime.now().microsecondsSinceEpoch}',

                    origin: origin.text.trim(),

                    destination: destination.text.trim(),

                    departureTime: departureTime,

                    arrivalTime: arrivalTime,

                    fare: amount,

                    // Every bus has a capacity of 40.
                    totalSeats: 40,

                    // Preserve existing bookings.
                    bookedSeats: existing?.bookedSeats ?? const [],

                    // Store selected bus.
                    operatorName: selectedBus,

                    routeName: routeName.text.trim(),

                    transportMode: 'Bus',
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    await WidgetsBinding.instance.endOfFrame;

    origin.dispose();
    destination.dispose();
    departure.dispose();
    arrival.dispose();
    fare.dispose();
    routeName.dispose();

    if (result == null) return;

    await _store.saveTrip(result);

    if (mounted) {
      _message('Schedule saved.');
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    if (trip.bookedSeats.isNotEmpty) {
      _message(
        'Schedules with booked seats cannot be deleted.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete schedule?'),
        content: Text(
          '${trip.origin} → ${trip.destination}',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _store.removeTrip(trip.id);
  }

  String _dateTimeString(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  String _durationLabel(Trip trip) {
    final duration =
        trip.arrivalTime.difference(trip.departureTime);

    final hours = duration.inHours;

    final minutes = duration.inMinutes.remainder(60);

    return hours == 0
        ? '$minutes min'
        : '${hours}h ${minutes}m';
  }

  DateTime? _parseDateTime(String value) {
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$',
    ).firstMatch(value.trim());

    if (match == null) return null;

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);

    if (month < 1 ||
        month > 12 ||
        day < 1 ||
        hour > 23 ||
        minute > 59) {
      return null;
    }

    final result = DateTime(
      year,
      month,
      day,
      hour,
      minute,
    );

    return result.year == year &&
            result.month == month &&
            result.day == day
        ? result
        : null;
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: number
            ? TextInputType.number
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty
                ? 'Required'
                : null,
      ),
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
            final trips = _store.trips;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Schedules & seats',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Manage buses, departures, fares, and seat capacity.',
                  ),

                  const SizedBox(height: 18),

                  Expanded(
                    child: !_store.isLoaded
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : trips.isEmpty
                            ? const Center(
                                child: Text('No schedules yet.'),
                              )
                            : ListView.builder(
                                itemCount: trips.length,
                                itemBuilder: (context, index) {
                                  final trip = trips[index];

                                  return Card(
                                    child: ListTile(
                                      title: Text(
                                        '${trip.origin} → ${trip.destination}',
                                      ),

                                      subtitle: Text(
                                        '${trip.operatorName} · '
                                        '${_dateTimeString(trip.departureTime)} → '
                                        '${_dateTimeString(trip.arrivalTime)} · '
                                        '${_durationLabel(trip)} · '
                                        '${trip.availableSeats}/40 seats available · '
                                        'MWK ${trip.fare.toStringAsFixed(0)}',
                                      ),

                                      isThreeLine: true,

                                      onTap: () => _editTrip(trip),

                                      trailing: Wrap(
                                        spacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          IconButton(
                                            tooltip: 'Edit schedule',
                                            onPressed: () =>
                                                _editTrip(trip),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                          ),

                                          IconButton(
                                            tooltip: 'Delete schedule',
                                            onPressed: () =>
                                                _deleteTrip(trip),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
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
                      onPressed: () => _editTrip(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add schedule'),
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
