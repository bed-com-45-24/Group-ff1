import 'package:flutter/material.dart';

import '../../../data/booking_service.dart';
import '../../../data/booking_store.dart';
import '../../../models/trip_model.dart';
import 'passenger_details_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Trip trip;

  const SeatSelectionScreen({super.key, required this.trip});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final Set<int> selectedSeats = {};
  bool _isLoadingBookings = true;
  bool _isCreatingBooking = false;
  String? _bookingLoadError;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      await BookingStore.instance.load();
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
          _bookingLoadError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
          _bookingLoadError = 'Could not load bookings: $error';
        });
      }
    }
  }

  Future<void> _continueToPassengerDetails() async {
    setState(() => _isCreatingBooking = true);
    try {
      final booking = await BookingService.instance.createDraft(
        trip: widget.trip,
        reference: 'MOVA-${DateTime.now().millisecondsSinceEpoch}',
        selectedSeats: selectedSeats.toList()..sort(),
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PassengerDetailsScreen(booking: booking),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create booking: $error')),
      );
    } finally {
      if (mounted) setState(() => _isCreatingBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final bookingStore = BookingStore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Seats')),
      body: Column(
        children: [
          const SizedBox(height: 12),
          const Text('Choose up to 5 seats'),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              _legend(Colors.grey, 'Booked'),
              _legend(Colors.teal, 'Selected'),
              _legend(Colors.white, 'Available'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoadingBookings
                ? const Center(child: CircularProgressIndicator())
                : _bookingLoadError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_bookingLoadError!, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: () {
                            setState(() => _isLoadingBookings = true);
                            _loadBookings();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : ValueListenableBuilder<int>(
                    valueListenable: bookingStore.changes,
                    builder: (context, _, _) => GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: trip.totalSeats,
                      itemBuilder: (context, index) {
                        final seat = index + 1;
                        final booked = bookingStore
                            .occupiedSeatsForTrip(trip)
                            .contains(seat);
                        final selected = selectedSeats.contains(seat);

                        return InkWell(
                          onTap: booked
                              ? null
                              : () {
                                  setState(() {
                                    if (selected) {
                                      selectedSeats.remove(seat);
                                    } else if (selectedSeats.length >= 5) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'You can book a maximum of 5 seats.',
                                              ),
                                            ),
                                          );
                                    } else {
                                      selectedSeats.add(seat);
                                    }
                                  });
                                },
                          child: Container(
                            decoration: BoxDecoration(
                              color: booked
                                  ? Colors.grey.shade400
                                  : selected
                                  ? Colors.teal
                                  : Colors.white,
                              border: Border.all(
                                color: selected ? Colors.teal : Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '$seat',
                                style: TextStyle(
                                  color: booked || selected
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Selected seats: ${selectedSeats.length} / 5'),
                if (trip.fareIsEstimate)
                  Text(
                    'Estimated map fare per seat: MWK '
                    '${trip.fare.toStringAsFixed(0)}'
                    '${trip.mapDistanceMeters == null ? '' : ' · '
                              '${(trip.mapDistanceMeters! / 1000).toStringAsFixed(1)} km'}',
                  ),
                Text(
                  '${trip.fareIsEstimate ? 'Estimated total' : 'Total'}: MWK '
                  '${(selectedSeats.length * trip.fare).toStringAsFixed(0)}',
                ),
                if (trip.fareIsEstimate)
                  const Text(
                    'Estimate: MWK 220 per kilometre. Confirm the final fare '
                    'with the operator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        selectedSeats.isEmpty ||
                            _isLoadingBookings ||
                            _isCreatingBooking
                        ? null
                        : _continueToPassengerDetails,
                    child: _isCreatingBooking
                        ? const CircularProgressIndicator()
                        : const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
