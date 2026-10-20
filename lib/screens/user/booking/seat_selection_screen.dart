import 'package:flutter/material.dart';

import '../../../models/trip_model.dart';
import '../../../models/booking_model.dart';
import 'passenger_details_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Trip trip;

  const SeatSelectionScreen({super.key, required this.trip});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final Set<int> selectedSeats = {};

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

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
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: trip.totalSeats,
              itemBuilder: (context, index) {
                final seat = index + 1;
                final booked = trip.bookedSeats.contains(seat);
                final selected = selectedSeats.contains(seat);

                return InkWell(
                  onTap: booked
                      ? null
                      : () {
                          setState(() {
                            if (selected) {
                              selectedSeats.remove(seat);
                            } else if (selectedSeats.length >= 5) {
                              ScaffoldMessenger.of(context).showSnackBar(
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
                    onPressed: selectedSeats.isEmpty
                        ? null
                        : () {
                            final booking = BookingDraft(
                              trip: trip,
                              reference:
                                  'MOVA-${DateTime.now().millisecondsSinceEpoch}',
                              selectedSeats: selectedSeats.toList()..sort(),
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PassengerDetailsScreen(booking: booking),
                              ),
                            );
                          },
                    child: const Text('Continue'),
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
