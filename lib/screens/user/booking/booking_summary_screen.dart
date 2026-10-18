<<<<<<< HEAD
//import 'package:flutter/material.dart';
//import '../../models/route_model.dart';
import 'package:flutter/material.dart';
import '../../../models/route_model.dart';


class BookingSummaryScreen extends StatelessWidget {
  final RouteModel route;

  const BookingSummaryScreen({
    super.key,
    required this.route,
=======

import 'package:flutter/material.dart';
import '../../../models/booking_model.dart';
import '../payment/payment_method_screen.dart';

class BookingSummaryScreen extends StatelessWidget {
  final BookingDraft booking;

  const BookingSummaryScreen({
    super.key,
    required this.booking,
>>>>>>> origin/feature/booking-payment
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Scaffold(
      appBar: AppBar(
        title: const Text('MOVA Trip Summary'),
      ),
      body: Center(
        child: Text(
          '${route.origin} → ${route.destination}\n'
          'Fare: MWK ${route.fare.toStringAsFixed(0)}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
=======
    final trip = booking.trip;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Summary')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.confirmation_number,
            size: 60,
            color: Colors.teal,
          ),
          const SizedBox(height: 16),
          Text(
            '${trip.origin} → ${trip.destination}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _row('Operator', trip.operatorName),
          _row('Transport', trip.transportMode),
          _row('Departure', trip.departureTime.toString()),
          _row('Arrival', trip.arrivalTime.toString()),
          _row('Passenger', booking.passengerName),
          _row('Phone', booking.phoneNumber),
          _row('Seats', booking.selectedSeats.join(', ')),
          _row('Booking reference', booking.reference),
          const Divider(height: 32),
          _row(
            'Fare per seat',
            'MWK ${trip.fare.toStringAsFixed(0)}',
          ),
          _row('Number of seats', '${booking.selectedSeats.length}'),
          _row(
            'TOTAL',
            'MWK ${booking.total.toStringAsFixed(0)}',
            bold: true,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PaymentMethodScreen(booking: booking),
                ),
              );
            },
            child: const Text('Continue to Payment'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
>>>>>>> origin/feature/booking-payment
