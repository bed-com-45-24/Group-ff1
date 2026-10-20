import 'package:flutter/material.dart';

import '../../data/booking_store.dart';
import '../../models/booking_model.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final _store = BookingStore.instance;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: _store.changes,
          builder: (context, _, _) {
            final bookings = _store.bookings.reversed.toList();
            if (!_store.isLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            if (bookings.isEmpty) {
              return const Center(child: Text('No bookings have been made.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) =>
                  _BookingCard(booking: bookings[index]),
            );
          },
        ),
      ),
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
      child: ExpansionTile(
        leading: Icon(
          booking.paid ? Icons.check_circle_outline : Icons.pending_outlined,
          color: booking.paid ? Colors.green : Colors.orange,
        ),
        title: Text('${trip.origin} → ${trip.destination}'),
        subtitle: Text(
          '${booking.passengerName} · ${booking.paid ? 'Paid' : 'Pending'}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _detail('Booking reference', booking.reference),
          _detail('Passenger email', booking.passengerEmail),
          _detail('Phone', booking.phoneNumber),
          _detail('Identification', booking.identificationNumber),
          _detail('Departure', trip.departureTime.toString()),
          _detail('Seats', booking.selectedSeats.join(', ')),
          _detail('Amount', 'MWK ${booking.total.toStringAsFixed(0)}'),
          _detail('Payment method', booking.paymentMethod),
          _detail('Payment reference', booking.paymentReference),
          _detail('Status', booking.cancelled ? 'Cancelled' : 'Active'),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value.isEmpty ? 'Not provided' : value)),
      ],
    ),
  );
}
