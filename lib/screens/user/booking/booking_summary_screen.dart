import 'package:flutter/material.dart';

import '../../../models/booking_model.dart';
import '../../../models/route_model.dart';
import '../payment/payment_method_screen.dart';

class BookingSummaryScreen extends StatelessWidget {
  final RouteModel? route;
  final BookingDraft? booking;

  const BookingSummaryScreen({super.key, this.route, this.booking})
    : assert(route != null || booking != null);

  @override
  Widget build(BuildContext context) {
    final currentBooking = booking;
    if (currentBooking != null) {
      return _buildBookingSummary(context, currentBooking);
    }

    return _buildRouteSummary(context, route!);
  }

  Widget _buildRouteSummary(BuildContext context, RouteModel route) {
    return Scaffold(
      appBar: AppBar(title: const Text('MOVA Trip Summary')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _summaryCard(
            child: Column(
              children: [
                const Icon(
                  Icons.directions_bus,
                  color: Colors.deepPurple,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  route.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${route.origin} → ${route.destination}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _summaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Journey details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _row('Company', route.companyName),
                if (route.fareIsEstimate)
                  _row('Selected route option', route.name),
                _row('Pickup point', route.pickupPoint),
                _row('Drop-off point', route.dropOffPoint),
                _row('Journey duration', route.duration ?? 'Not published'),
                _row('Distance (map)', route.mapDistance ?? 'Not available'),
                _row('Stops', route.stops.join(' → ')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _summaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fare summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _row(
                  route.fareIsEstimate
                      ? 'Estimated map fare'
                      : 'Published fare',
                  'MWK ${_money(route.fare)}',
                ),
                const Divider(),
                _row(
                  'Total for one passenger',
                  'MWK ${_money(route.fare)}',
                  bold: true,
                ),
                const SizedBox(height: 8),
                Text(
                  route.fareIsEstimate
                      ? 'This is a distance-based map estimate in Malawi '
                            'kwacha (MWK), calculated at MWK 220 per kilometre. '
                            'Confirm the actual fare with the operator.'
                      : 'This is a published reference fare. Confirm the '
                            'current fare and departure schedule with the '
                            'operator before travel.',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.alt_route),
            label: const Text('Back to routes'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummary(BuildContext context, BookingDraft booking) {
    final trip = booking.trip;
    final duration = trip.arrivalTime.difference(trip.departureTime);
    final durationText = duration.inMinutes <= 0
        ? 'Not available'
        : '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Summary')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _summaryCard(
            child: Column(
              children: [
                const Icon(
                  Icons.confirmation_number,
                  size: 56,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 12),
                Text(
                  '${trip.origin} → ${trip.destination}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${trip.operatorName} · ${trip.transportMode}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.paid ? 'Payment complete' : 'Payment not completed',
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _summaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Journey and passenger',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _row('Departure', _formatDateTime(trip.departureTime)),
                _row('Arrival', _formatDateTime(trip.arrivalTime)),
                _row('Estimated journey time', durationText),
                if (trip.mapDistanceMeters != null)
                  _row(
                    'Map distance',
                    '${(trip.mapDistanceMeters! / 1000).toStringAsFixed(1)} km',
                  ),
                _row('Passenger', booking.passengerName),
                if (booking.passengerEmail.isNotEmpty)
                  _row('Email', booking.passengerEmail),
                _row('Phone', booking.phoneNumber),
                _row(
                  'Identification',
                  booking.identificationNumber.isEmpty
                      ? 'Not provided'
                      : booking.identificationNumber,
                ),
                _row('Selected seats', booking.selectedSeats.join(', ')),
                _row('Booking reference', booking.reference),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _summaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fare breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _row(
                  trip.fareIsEstimate
                      ? 'Estimated map fare per seat'
                      : 'Fare per seat',
                  'MWK ${_money(trip.fare)}',
                ),
                _row('Number of seats', '${booking.selectedSeats.length}'),
                const Divider(),
                _row(
                  'Total amount',
                  'MWK ${_money(booking.total)}',
                  bold: true,
                ),
                if (trip.fareIsEstimate) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'This is an estimated fare based on map route distance '
                    'at MWK 220 per kilometre, not a published fare. Confirm '
                    'the final fare with the transport operator.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!booking.paid)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentMethodScreen(booking: booking),
                  ),
                );
              },
              child: const Text('Continue to Payment'),
            ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour < 12 ? 'AM' : 'PM';
    return '${value.day}/${value.month}/${value.year} · '
        '$hour:$minute $period';
  }

  String _money(num value) => value.toStringAsFixed(0);

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
                color: bold ? Colors.black : Colors.black54,
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
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
