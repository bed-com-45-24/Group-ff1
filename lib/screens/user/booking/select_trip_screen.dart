import 'package:flutter/material.dart';

import '../../../data/trip_store.dart';
import '../../../models/trip_model.dart';
import 'seat_selection_screen.dart';

class SelectTripScreen extends StatefulWidget {
  final bool showAppBar;

  const SelectTripScreen({super.key, this.showAppBar = true});

  @override
  State<SelectTripScreen> createState() => _SelectTripScreenState();
}

class _SelectTripScreenState extends State<SelectTripScreen> {
  final _tripStore = TripStore.instance;
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();

  DateTime? travelDate;
  List<Trip> results = const [];
  bool _hasSearched = false;
  bool _isLoading = false;
  String? _searchMessage;

  Future<void> searchTrips() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _hasSearched = false;
      _searchMessage = null;
      results = const [];
    });

    try {
      await _tripStore.load();
      final matchingTrips = _findTripsForDate();
      if (!mounted) return;
      setState(() {
        _hasSearched = true;
        _isLoading = false;
        results = matchingTrips;
        _searchMessage = matchingTrips.isEmpty
            ? 'No scheduled trips match this route and travel date.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _hasSearched = true;
        _isLoading = false;
        _searchMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Trip> _findTripsForDate() {
    final origin = _normalizeLocation(_originController.text);
    final destination = _normalizeLocation(_destinationController.text);
    final trips =
        _tripStore.trips.where((trip) {
          return !trip.id.startsWith('MAP-ESTIMATE-') &&
              _locationMatches(trip.origin, origin) &&
              _locationMatches(trip.destination, destination) &&
              (travelDate == null ||
                  DateUtils.isSameDay(trip.departureTime, travelDate)) &&
              trip.departureTime.isAfter(DateTime.now());
        }).toList()..sort(
          (first, second) =>
              first.departureTime.compareTo(second.departureTime),
        );
    return trips;
  }

  String _normalizeLocation(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  bool _locationMatches(String scheduledLocation, String search) {
    final scheduled = _normalizeLocation(scheduledLocation);
    if (scheduled.isEmpty || search.isEmpty) return false;
    return scheduled.contains(search) || search.contains(scheduled);
  }

  Future<void> _selectTravelDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: travelDate == null || travelDate!.isBefore(today)
          ? today
          : travelDate!,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (selected != null) {
      setState(() => travelDate = DateUtils.dateOnly(selected));
    }
  }

  void _selectScheduledTrip(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SeatSelectionScreen(trip: trip)),
    );
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Book a Trip'))
          : null,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Plan your journey',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter your route and travel date to see scheduled trips.',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _originController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Departure location',
                prefixIcon: Icon(Icons.trip_origin),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your departure location'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _destinationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Destination',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your destination'
                  : null,
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Travel date'),
                subtitle: Text(
                  travelDate == null
                      ? 'Any upcoming date'
                      : MaterialLocalizations.of(context)
                            .formatMediumDate(travelDate!),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (travelDate != null)
                      IconButton(
                        tooltip: 'Clear travel date',
                        onPressed: () => setState(() => travelDate = null),
                        icon: const Icon(Icons.clear),
                      ),
                    IconButton(
                      tooltip: 'Choose travel date',
                      onPressed: _selectTravelDate,
                      icon: const Icon(Icons.edit_calendar),
                    ),
                  ],
                ),
                onTap: _selectTravelDate,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : searchTrips,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.directions_bus),
                label: const Text('Book a trip'),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_hasSearched) ...[
              const SizedBox(height: 24),
              Text(
                'Scheduled trips matching your search',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (_searchMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_searchMessage!),
                  ),
                ),
              ...results.map((trip) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.route),
                    title: Text('${trip.origin} → ${trip.destination}'),
                    subtitle: Text(
                      '${_durationLabel(trip)} · ${trip.operatorName}\n'
                      '${MaterialLocalizations.of(context).formatMediumDate(trip.departureTime)} · '
                      '${_timeLabel(trip.departureTime)} · '
                      '${trip.availableSeats} seats available',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'MWK ${trip.fare.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('Fare'),
                      ],
                    ),
                    onTap: trip.availableSeats > 0
                        ? () => _selectScheduledTrip(trip)
                        : null,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _durationLabel(Trip trip) {
    final duration = trip.arrivalTime.difference(trip.departureTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours == 0 ? '$minutes min' : '${hours}h ${minutes}m';
  }

  String _timeLabel(DateTime value) =>
      MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay.fromDateTime(value));
}
