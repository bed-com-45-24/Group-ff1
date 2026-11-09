import 'package:flutter/material.dart';

import '../../../models/booking_model.dart';
import '../../../services/openstreetmap_service.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final BookingDraft booking;

  const BookingConfirmationScreen({super.key, required this.booking});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final _openStreetMap = OpenStreetMapService();
  String? _mapDuration;
  String? _mapError;
  bool _loadingMapDuration = true;

  @override
  void initState() {
    super.initState();
    _loadMapDuration();
  }

  Future<void> _loadMapDuration() async {
    try {
      final routes = await _openStreetMap.findRoutesBetweenPlaces(
        origin: widget.booking.trip.origin,
        destination: widget.booking.trip.destination,
      );
      if (!mounted) return;
      setState(() {
        _mapDuration = routes.first.durationLabel;
        _loadingMapDuration = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _mapError = error.toString().replaceFirst('Exception: ', '');
        _loadingMapDuration = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return Scaffold(
      appBar: AppBar(title: const Text('E-Ticket')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 72),
                  const SizedBox(height: 12),
                  const Text(
                    'Booking Confirmed!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Your demonstration e-ticket'),
                  const Divider(height: 32),
                  _ticketRow('Reference', booking.reference),
                  _ticketRow(
                    'Route',
                    '${booking.trip.origin} → ${booking.trip.destination}',
                  ),
                  _ticketRow(
                    'Road / route',
                    booking.trip.routeName.trim().isEmpty
                        ? 'Not specified'
                        : booking.trip.routeName.trim(),
                  ),
                  _ticketRow('Transport company', booking.trip.operatorName),
                  if (booking.trip.vehicleName.trim().isNotEmpty)
                    _ticketRow('Vehicle', booking.trip.vehicleName),
                  _ticketRow('Passenger', booking.passengerName),
                  _ticketRow('Phone', booking.phoneNumber),
                  _ticketSeats(booking.selectedSeats),
                  _ticketRow(
                    'Departure',
                    booking.trip.departureTime.toString(),
                  ),
                  _ticketRow(
                    'Estimated travel time (map)',
                    _loadingMapDuration
                        ? 'Loading map estimate...'
                        : _mapDuration ?? 'Map estimate unavailable',
                  ),
                  if (_mapError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Map-based travel time could not be loaded: $_mapError',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  _ticketRow('Paid', 'MWK ${booking.total.toStringAsFixed(0)}'),
                  _ticketRow('Payment', booking.paymentMethod),
                  const SizedBox(height: 20),
                  const Text(
                    'Please keep your booking reference for your journey.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                    child: const Text('Return to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ticketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketSeats(List<int> seats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: Text('Seats')),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              runSpacing: 4,
              children: seats
                  .map(
                    (seat) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_seat,
                          size: 18,
                          color: Colors.deepPurple.shade700,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$seat',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
