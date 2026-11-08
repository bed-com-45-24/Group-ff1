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
                    builder: (context, _, _) {
                      final occupiedSeats = bookingStore.occupiedSeatsForTrip(
                        trip,
                      );
                      final hasRearAisleSeat =
                          trip.totalSeats >= 5 && trip.totalSeats % 4 == 1;
                      final standardSeatCount = hasRearAisleSeat
                          ? trip.totalSeats - 1
                          : trip.totalSeats;
                      final rowCount = (standardSeatCount + 3) ~/ 4;
                      return Column(
                        children: [
                          const SizedBox(height: 12),
                          const Text(
                            'Choose up to 5 seats',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            children: [
                              _legend(Colors.deepPurple.shade300, 'Booked'),
                              _legend(Colors.deepPurple, 'Selected'),
                              _legend(Colors.deepPurple.shade400, 'Available'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade50,
                                  border: Border.all(
                                    color: Colors.deepPurple.shade100,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        12,
                                        4,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade100,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.directions_bus, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'FRONT  ·  DRIVER',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.separated(
                                        padding: const EdgeInsets.all(12),
                                        itemCount: rowCount,
                                        separatorBuilder: (_, _) => SizedBox(
                                          height: 6,
                                          child: Row(
                                            children: [
                                              const Expanded(
                                                child: SizedBox.shrink(),
                                              ),
                                              Container(
                                                width: 30,
                                                color:
                                                    Colors.deepPurple.shade100,
                                              ),
                                              const Expanded(
                                                child: SizedBox.shrink(),
                                              ),
                                            ],
                                          ),
                                        ),
                                        itemBuilder: (context, rowIndex) {
                                          final firstSeat = rowIndex * 4 + 1;
                                          final isRearRow =
                                              rowIndex == rowCount - 1;
                                          if (hasRearAisleSeat && isRearRow) {
                                            return Row(
                                              children: [
                                                Expanded(
                                                  child: _seatButton(
                                                    firstSeat,
                                                    trip.totalSeats,
                                                    occupiedSeats,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: _seatButton(
                                                    firstSeat + 1,
                                                    trip.totalSeats,
                                                    occupiedSeats,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: _seatButton(
                                                    trip.totalSeats,
                                                    trip.totalSeats,
                                                    occupiedSeats,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: _seatButton(
                                                    firstSeat + 2,
                                                    trip.totalSeats,
                                                    occupiedSeats,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: _seatButton(
                                                    firstSeat + 3,
                                                    trip.totalSeats,
                                                    occupiedSeats,
                                                  ),
                                                ),
                                              ],
                                            );
                                          }

                                          final seatsInRow =
                                              (standardSeatCount -
                                                      firstSeat +
                                                      1)
                                                  .clamp(0, 4);
                                          return Row(
                                            children: [
                                              for (
                                                var offset = 0;
                                                offset < 2;
                                                offset++
                                              )
                                                _seatSlot(
                                                  firstSeat + offset,
                                                  offset < seatsInRow,
                                                  trip.totalSeats,
                                                  occupiedSeats,
                                                ),
                                              SizedBox(
                                                width: 30,
                                                child: Container(
                                                  color: Colors
                                                      .deepPurple
                                                      .shade100,
                                                  alignment: Alignment.center,
                                                  child: RotatedBox(
                                                    quarterTurns: 3,
                                                    child: Text(
                                                      rowIndex == 0
                                                          ? 'AISLE'
                                                          : '',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .deepPurple
                                                            .shade300,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        letterSpacing: 1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              for (
                                                var offset = 2;
                                                offset < 4;
                                                offset++
                                              )
                                                _seatSlot(
                                                  firstSeat + offset,
                                                  offset < seatsInRow,
                                                  trip.totalSeats,
                                                  occupiedSeats,
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Selected seats: ${selectedSeats.length} / 5'),
                if (selectedSeats.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 6,
                    children: (selectedSeats.toList()..sort())
                        .map(
                          (seat) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_seat,
                                size: 20,
                                color: Colors.deepPurple.shade700,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$seat',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ],
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

  Widget _seatSlot(
    int seat,
    bool hasSeat,
    int totalSeats,
    Set<int> occupiedSeats,
  ) {
    if (!hasSeat || seat > totalSeats) {
      return const Expanded(child: SizedBox(height: 60));
    }
    return Expanded(child: _seatButton(seat, totalSeats, occupiedSeats));
  }

  Widget _seatButton(int seat, int totalSeats, Set<int> occupiedSeats) {
    if (seat > totalSeats) return const SizedBox(height: 60);

    final booked = occupiedSeats.contains(seat);
    final selected = selectedSeats.contains(seat);
    final color = booked
        ? Colors.deepPurple.shade400
        : selected
        ? Colors.deepPurple.shade900
        : Colors.deepPurple.shade500;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Semantics(
        button: true,
        enabled: !booked,
        label:
            'Seat $seat, ${booked
                ? 'booked'
                : selected
                ? 'selected'
                : 'available'}',
        child: InkWell(
          onTap: booked
              ? null
              : () {
                  setState(() {
                    if (selected) {
                      selectedSeats.remove(seat);
                    } else if (selectedSeats.length >= 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You can book a maximum of 5 seats.'),
                        ),
                      );
                    } else {
                      selectedSeats.add(seat);
                    }
                  });
                },
          child: SizedBox(
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_seat, size: selected ? 28 : 24, color: color),
                Text(
                  '$seat',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_seat, size: 18, color: color),
        const SizedBox(width: 3),
        Text(label),
      ],
    );
  }
}
