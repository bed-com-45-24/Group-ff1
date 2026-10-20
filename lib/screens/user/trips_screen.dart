import 'package:flutter/material.dart';

import '../../data/booking_store.dart';
import '../../models/booking_model.dart';
import 'booking/select_trip_screen.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bookings'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.directions_bus), text: 'Book a trip'),
              Tab(icon: Icon(Icons.confirmation_number), text: 'My bookings'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [SelectTripScreen(showAppBar: false), _MyBookingsTab()],
        ),
      ),
    );
  }
}

class _MyBookingsTab extends StatelessWidget {
  const _MyBookingsTab();

  @override
  Widget build(BuildContext context) {
    final store = BookingStore.instance;
    return ValueListenableBuilder<int>(
      valueListenable: store.changes,
      builder: (context, value, _) {
        final bookings = store.bookings.reversed.toList();
        if (bookings.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No bookings yet. Find a trip and book your seats to see it here.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) =>
              _BookingCard(booking: bookings[index]),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingDraft booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final trip = booking.trip;
    return Card(
      child: ListTile(
        leading: Icon(
          booking.cancelled ? Icons.cancel_outlined : Icons.confirmation_number,
          color: booking.cancelled ? Colors.red : Colors.deepPurple,
        ),
        title: Text('${trip.origin} → ${trip.destination}'),
        subtitle: Text(
          'Ref: ${booking.reference}\n'
          'Seats: ${booking.selectedSeats.join(', ')} · '
          '${booking.paid ? 'Paid' : 'Payment pending'}',
        ),
        isThreeLine: true,
        trailing: Text(
          'MWK ${booking.total.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
