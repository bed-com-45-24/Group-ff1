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
  final originController = TextEditingController();
  final destinationController = TextEditingController();

  DateTime travelDate = DateTime(2026, 11, 1);
  List<Trip> results = const [];

  @override
  void initState() {
    super.initState();
    _tripStore.changes.addListener(_refreshTrips);
    _tripStore.load();
  }

  void _refreshTrips() {
    if (!mounted) return;
    setState(() {
      final upcomingTrips = _tripStore.trips
          .where((trip) => !trip.departureTime.isBefore(DateTime.now()))
          .toList();
      if (upcomingTrips.isNotEmpty) {
        travelDate = upcomingTrips.first.departureTime;
      } else {
        travelDate = DateTime.now();
      }
      _filterTrips();
    });
  }

  void _filterTrips() {
    final origin = originController.text.trim().toLowerCase();
    final destination = destinationController.text.trim().toLowerCase();
    results = _tripStore.trips.where((trip) {
      return trip.availableSeats > 0 &&
          !trip.departureTime.isBefore(DateTime.now()) &&
          trip.origin.toLowerCase().contains(origin) &&
          trip.destination.toLowerCase().contains(destination) &&
          trip.departureTime.year == travelDate.year &&
          trip.departureTime.month == travelDate.month &&
          trip.departureTime.day == travelDate.day;
    }).toList();
  }

  void searchTrips() {
    setState(() {
      _filterTrips();
    });
  }

  @override
  void dispose() {
    _tripStore.changes.removeListener(_refreshTrips);
    originController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Find a Trip'))
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: originController,
            decoration: const InputDecoration(
              labelText: 'Departure location',
              prefixIcon: Icon(Icons.trip_origin),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: destinationController,
            decoration: const InputDecoration(
              labelText: 'Destination',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Travel date'),
            subtitle: Text(
              '${travelDate.day}/${travelDate.month}/${travelDate.year}',
            ),
            onTap: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: travelDate.isBefore(DateTime.now())
                    ? DateTime.now()
                    : travelDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );

              if (selected != null) {
                setState(() => travelDate = selected);
                searchTrips();
              }
            },
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: searchTrips,
            icon: const Icon(Icons.search),
            label: const Text('Search trips'),
          ),
          const SizedBox(height: 20),
          if (results.isEmpty)
            const Center(child: Text('No trips found. Try another date.')),
          ...results.map(
            (trip) => Card(
              child: ListTile(
                title: Text('${trip.origin} → ${trip.destination}'),
                subtitle: Text(
                  '${trip.operatorName}\n'
                  '${trip.departureTime.hour.toString().padLeft(2, '0')}:'
                  '${trip.departureTime.minute.toString().padLeft(2, '0')} '
                  '• ${trip.availableSeats} seats available',
                ),
                isThreeLine: true,
                trailing: Text(
                  'MWK ${trip.fare.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SeatSelectionScreen(trip: trip),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
