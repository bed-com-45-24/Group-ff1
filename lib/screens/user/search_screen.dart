
import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../models/trip_model.dart';
import 'booking/seat_selection_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  DateTime? _travelDate;
  List<Trip> _results = sampleTrips;
  bool _searched = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  void _searchTrips() {
    final from = _fromController.text.trim().toLowerCase();
    final to = _toController.text.trim().toLowerCase();

    setState(() {
      _searched = true;

      _results = sampleTrips.where((trip) {
        final matchesFrom =
            from.isEmpty || trip.origin.toLowerCase().contains(from);

        final matchesTo =
            to.isEmpty || trip.destination.toLowerCase().contains(to);

        final matchesDate = _travelDate == null ||
            _sameDate(trip.departureTime, _travelDate!);

        return matchesFrom &&
            matchesTo &&
            matchesDate &&
            trip.availableSeats > 0;
      }).toList();
    });
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _travelDate ?? today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 2, 12, 31),
    );

    if (selected != null && mounted) {
      setState(() {
        _travelDate = selected;
      });
    }
  }

  String _dateText(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _timeText(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Trips'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find Your Journey',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Search for available trips with MOVA.'),
              const SizedBox(height: 20),

              TextField(
                controller: _fromController,
                decoration: const InputDecoration(
                  labelText: 'Departure city',
                  hintText: 'e.g. Lilongwe',
                  prefixIcon: Icon(Icons.trip_origin),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: 'Destination city',
                  hintText: 'e.g. Blantyre',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  _travelDate == null
                      ? 'Choose travel date (optional)'
                      : _dateText(_travelDate!),
                ),
              ),

              if (_travelDate != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _travelDate = null;
                    });
                  },
                  child: const Text('Clear date'),
                ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _searchTrips,
                  icon: const Icon(Icons.search),
                  label: const Text('Search Available Trips'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                _searched
                    ? 'Search Results (${_results.length})'
                    : 'Available Trips',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (_results.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No available trips found. '
                      'Try another departure, destination, or date.',
                    ),
                  ),
                )
              else
                ..._results.map(_buildTripCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bus, color: Colors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${trip.origin} → ${trip.destination}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            _detail('Operator', trip.operatorName),
            _detail('Transport', trip.transportMode),
            _detail('Travel date', _dateText(trip.departureTime)),
            _detail('Departure', _timeText(trip.departureTime)),
            _detail('Arrival', _timeText(trip.arrivalTime)),
            _detail('Available seats', '${trip.availableSeats}'),

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'MWK ${trip.fare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.teal,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: trip.availableSeats > 0
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SeatSelectionScreen(trip: trip),
                            ),
                          );
                        }
                      : null,
                  child: const Text('Select Trip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
