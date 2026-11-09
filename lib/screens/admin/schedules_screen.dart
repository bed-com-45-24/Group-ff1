import 'package:flutter/material.dart';

import '../../data/booking_store.dart';
import '../../data/trip_store.dart';
import '../../models/trip_model.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final _store = TripStore.instance;

  @override
  void initState() {
    super.initState();
    _store.load();
    BookingStore.instance.load();
  }

  Future<void> _editTrip([Trip? existing]) async {
    final origin = TextEditingController(text: existing?.origin ?? '');

    final destination = TextEditingController(
      text: existing?.destination ?? '',
    );

    final departure = TextEditingController(
      text: existing == null ? '' : _dateTimeString(existing.departureTime),
    );

    final arrival = TextEditingController(
      text: existing == null ? '' : _dateTimeString(existing.arrivalTime),
    );

    final fare = TextEditingController(
      text: existing?.fare.toStringAsFixed(0) ?? '',
    );
    final operator = TextEditingController(
      text: existing?.operatorName ?? 'MOVA Express',
    );
    final routeName = TextEditingController(text: existing?.routeName ?? '');
    final vehicleName = TextEditingController(
      text: existing?.vehicleName ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Trip>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add schedule' : 'Edit schedule'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(origin, 'Origin'),
                _field(destination, 'Destination'),
                _field(departure, 'Departure (YYYY-MM-DD HH:mm)'),
                _field(arrival, 'Arrival (YYYY-MM-DD HH:mm)'),
                _field(fare, 'Fare per seat (MWK)', number: true),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Total seats',
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    child: const Text('42'),
                  ),
                ),
                _field(operator, 'Transport company / operator'),
                _field(
                  routeName,
                  'Road / highway (match the admin route, e.g. M1 or M5)',
                ),
                _field(
                  vehicleName,
                  'Vehicle / car identifier (for example MOVA 1)',
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

              final departureTime = _parseDateTime(departure.text);
              final arrivalTime = _parseDateTime(arrival.text);
              final amount = double.tryParse(fare.text.trim());

              if (departureTime == null || arrivalTime == null) {
                _message('Enter schedule times as YYYY-MM-DD HH:mm.');
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

              if ((existing?.bookedSeats.length ?? 0) > 42) {
                _message('Booked seats cannot exceed 42.');
                return;
              }

              if (amount == null || amount <= 0) {
                _message('Enter a fare greater than zero.');
                return;
              }

              Navigator.pop(
                dialogContext,
                Trip(
                  id:
                      existing?.id ??
                      'TRIP-${DateTime.now().microsecondsSinceEpoch}',
                  origin: origin.text.trim(),
                  destination: destination.text.trim(),
                  departureTime: departureTime,
                  arrivalTime: arrivalTime,
                  fare: amount,
                  totalSeats: 42,
                  bookedSeats: existing?.bookedSeats ?? const [],
                  operatorName: operator.text.trim(),
                  routeName: routeName.text.trim(),
                  vehicleName: vehicleName.text.trim(),
                  transportMode: 'Bus',
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
    departure.dispose();
    arrival.dispose();
    fare.dispose();
    operator.dispose();
    routeName.dispose();
    vehicleName.dispose();

    if (result == null) return;

    await _store.saveTrip(result);

    if (mounted) {
      _message('Schedule saved.');
    }
  }

  // Delete immediately without confirmation or success message.
  // This also deletes schedules that have booked seats.
  Future<void> _deleteTrip(Trip trip) async {
    await _store.removeTrip(trip.id);
  }

  String _dateTimeString(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  String _durationLabel(Trip trip) {
    final duration = trip.arrivalTime.difference(trip.departureTime);

    final hours = duration.inHours;

    final minutes = duration.inMinutes.remainder(60);

    return hours == 0 ? '$minutes min' : '${hours}h ${minutes}m';
  }

  DateTime? _parseDateTime(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$')
        .firstMatch(value.trim());

    if (match == null) return null;

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);

    if (month < 1 || month > 12 || day < 1 || hour > 23 || minute > 59) {
      return null;
    }

    final result = DateTime(year, month, day, hour, minute);

    return result.year == year && result.month == month && result.day == day
        ? result
        : null;
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required' : null,
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
          builder: (context, _, _) => ValueListenableBuilder<int>(
            valueListenable: BookingStore.instance.changes,
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
                    const Text('Manage departure and fare.'),
                    const SizedBox(height: 18),
                    Expanded(
                      child: !_store.isLoaded
                          ? const Center(child: CircularProgressIndicator())
                          : trips.isEmpty
                          ? const Center(child: Text('No schedules yet.'))
                          : ListView.builder(
                              itemCount: trips.length,
                              itemBuilder: (context, index) {
                                final trip = trips[index];
                                final availableSeats =
                                    (trip.totalSeats -
                                            BookingStore.instance
                                                .activeBookingSeatsForTrip(trip)
                                                .length)
                                        .clamp(0, trip.totalSeats);
                                return Card(
                                  child: ListTile(
                                    title: Text(
                                      '${trip.origin} → ${trip.destination}',
                                    ),
                                    subtitle: Text(
                                      '${trip.routeName.isEmpty ? 'Road not set' : 'Road: ${trip.routeName}'} · '
                                      '${trip.operatorName}'
                                      '${trip.vehicleName.isEmpty ? '' : ' · ${trip.vehicleName}'}\n'
                                      '${_dateTimeString(trip.departureTime)} → '
                                      '${_dateTimeString(trip.arrivalTime)} · '
                                      '${_durationLabel(trip)} · '
                                      '$availableSeats/${trip.totalSeats} '
                                      'seats · MWK '
                                      '${trip.fare.toStringAsFixed(0)}',
                                    ),
                                    isThreeLine: true,
                                    onTap: () => _editTrip(trip),
                                    trailing: IconButton(
                                      tooltip: 'Delete schedule',
                                      onPressed: () => _deleteTrip(trip),
                                      icon: const Icon(Icons.delete_outline),
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
      ),
    );
  }
}
