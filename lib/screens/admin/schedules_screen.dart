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

  @override
  void initState() {
    super.initState();
    _store.load();
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
    final seats = TextEditingController(
      text: existing?.totalSeats.toString() ?? '',
    );
    final operator = TextEditingController(
      text: existing?.operatorName ?? 'MOVA Express',
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
                _field(seats, 'Total seats', number: true),
                _field(operator, 'Operator'),
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
              final seatCount = int.tryParse(seats.text.trim());
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
              if (seatCount == null ||
                  seatCount <= 0 ||
                  seatCount < (existing?.bookedSeats.length ?? 0)) {
                _message('Total seats cannot be below seats already booked.');
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
                  totalSeats: seatCount,
                  bookedSeats: existing?.bookedSeats ?? const [],
                  operatorName: operator.text.trim(),
                  transportMode: existing?.transportMode ?? 'Bus',
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    origin.dispose();
    destination.dispose();
    departure.dispose();
    arrival.dispose();
    fare.dispose();
    seats.dispose();
    operator.dispose();
    if (result == null) return;
    await _store.saveTrip(result);
    if (mounted) _message('Schedule saved.');
  }

  Future<void> _deleteTrip(Trip trip) async {
    if (trip.bookedSeats.isNotEmpty) {
      _message('Schedules with booked seats cannot be deleted.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete schedule?'),
        content: Text('${trip.origin} → ${trip.destination}'),
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
    await _store.removeTrip(trip.id);
  }

  String _dateTimeString(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

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
          builder: (context, _, _) {
            final trips = _store.trips;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Schedules & seats',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text('Manage departure, fare, and seat capacity.'),
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
                              return Card(
                                child: ListTile(
                                  title: Text(
                                    '${trip.origin} → ${trip.destination}',
                                  ),
                                  subtitle: Text(
                                    '${_dateTimeString(trip.departureTime)} · '
                                    '${trip.availableSeats}/${trip.totalSeats} '
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
    );
  }
}
