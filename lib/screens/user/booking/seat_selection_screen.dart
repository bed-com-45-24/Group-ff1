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
  static const int _busSeatCount = Trip.busSeatCapacity;
  static const int _adminSeat = 2;

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
      await BookingStore.instance.load(refresh: true);
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
      final occupiedSeats = _occupiedPassengerSeats(widget.trip);
      final booking = await BookingService.instance.createDraft(
        trip: widget.trip.copyWith(
          totalSeats: _busSeatCount,
          bookedSeats: {...occupiedSeats, _adminSeat}.toList()..sort(),
        ),
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

  Set<int> _occupiedPassengerSeats(Trip trip) => {
    ...BookingStore.instance.activeBookingSeatsForTrip(trip),
  };

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
                      final occupiedSeats = _occupiedPassengerSeats(trip)
                        ..add(_adminSeat);
                      const rearRowSeatCount = 6;
                      const standardSeatCount =
                          _busSeatCount - 1 - rearRowSeatCount;
                      final standardRowCount = (standardSeatCount + 4) ~/ 5;
                      final rowCount = standardRowCount + 1;
                      return Column(
                        children: [
                          const SizedBox(height: 12),
                          const Text(
                            '42 seats · Seat 2 reserved for admin',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Text('Choose up to 5 seats'),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            children: [
                              _legend(Colors.amber.shade700, 'Admin'),
                              _legend(Colors.blueGrey.shade400, 'Booked'),
                              _legend(Colors.green.shade700, 'Selected'),
                              _legend(Colors.deepPurple.shade100, 'Available'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
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
                                          16,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.shade100,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.amber.shade600,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    'DOOR',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 2,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                SizedBox(
                                                  width: 58,
                                                  child: _seatButton(
                                                    1,
                                                    _busSeatCount,
                                                    occupiedSeats,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Column(
                                                  children: [
                                                    Container(
                                                      width: 54,
                                                      height: 54,
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .blueGrey
                                                            .shade900,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                      ),
                                                      child: const Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.event_seat,
                                                            color: Colors.white,
                                                            size: 28,
                                                          ),
                                                          Text(
                                                            'DRV',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.amber,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    const Text(
                                                      'DRIVER',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        letterSpacing: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.separated(
                                          padding: const EdgeInsets.all(12),
                                          itemCount: rowCount,
                                          separatorBuilder: (_, _) => SizedBox(
                                            height: 8,
                                            child: Row(
                                              children: [
                                                const Expanded(
                                                  child: SizedBox.shrink(),
                                                ),
                                                Container(
                                                  width: 32,
                                                  color: Colors
                                                      .deepPurple
                                                      .shade100,
                                                ),
                                                const Expanded(
                                                  child: SizedBox.shrink(),
                                                ),
                                              ],
                                            ),
                                          ),
                                          itemBuilder: (context, rowIndex) {
                                            final isRearRow =
                                                rowIndex == standardRowCount;
                                            final firstSeat = isRearRow
                                                ? standardSeatCount + 2
                                                : rowIndex * 5 + 2;
                                            final seatsInRow = isRearRow
                                                ? rearRowSeatCount
                                                : (standardSeatCount -
                                                          rowIndex * 5)
                                                      .clamp(0, 5);

                                            if (isRearRow &&
                                                rearRowSeatCount == 6) {
                                              return Row(
                                                children: [
                                                  for (
                                                    var offset = 0;
                                                    offset < 2;
                                                    offset++
                                                  )
                                                    _seatSlot(
                                                      firstSeat + offset,
                                                      true,
                                                      _busSeatCount,
                                                      occupiedSeats,
                                                      isAdminSeat:
                                                          firstSeat + offset ==
                                                          _adminSeat,
                                                    ),
                                                  SizedBox(
                                                    width: 42,
                                                    child: _seatButton(
                                                      firstSeat + 2,
                                                      _busSeatCount,
                                                      occupiedSeats,
                                                      isAdminSeat:
                                                          firstSeat + 2 ==
                                                          _adminSeat,
                                                    ),
                                                  ),
                                                  for (
                                                    var offset = 3;
                                                    offset < 6;
                                                    offset++
                                                  )
                                                    _seatSlot(
                                                      firstSeat + offset,
                                                      true,
                                                      _busSeatCount,
                                                      occupiedSeats,
                                                    ),
                                                ],
                                              );
                                            }

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
                                                    _busSeatCount,
                                                    occupiedSeats,
                                                    isAdminSeat:
                                                        firstSeat + offset ==
                                                        _adminSeat,
                                                  ),
                                                SizedBox(
                                                  width: 32,
                                                  child: Container(
                                                    color: Colors
                                                        .deepPurple
                                                        .shade100,
                                                  ),
                                                ),
                                                for (
                                                  var offset = 2;
                                                  offset < 5;
                                                  offset++
                                                )
                                                  _seatSlot(
                                                    firstSeat + offset,
                                                    offset < seatsInRow,
                                                    _busSeatCount,
                                                    occupiedSeats,
                                                    isAdminSeat:
                                                        firstSeat + offset ==
                                                        _adminSeat,
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
    Set<int> occupiedSeats, {
    bool isAdminSeat = false,
  }) {
    if (!hasSeat || seat > totalSeats) {
      return const Expanded(child: SizedBox(height: 60));
    }
    return Expanded(
      child: _seatButton(
        seat,
        totalSeats,
        occupiedSeats,
        isAdminSeat: isAdminSeat,
      ),
    );
  }

  Widget _seatButton(
    int seat,
    int totalSeats,
    Set<int> occupiedSeats, {
    bool isAdminSeat = false,
  }) {
    if (seat > totalSeats) return const SizedBox(height: 60);

    final booked = occupiedSeats.contains(seat);
    final reserved = isAdminSeat;
    final selected = selectedSeats.contains(seat);
    final backgroundColor = reserved
        ? Colors.amber.shade100
        : booked
        ? Colors.blueGrey.shade100
        : selected
        ? Colors.green.shade700
        : Colors.white;
    final foregroundColor = reserved
        ? Colors.brown.shade800
        : booked
        ? Colors.blueGrey.shade600
        : selected
        ? Colors.white
        : Colors.deepPurple.shade600;
    final statusLabel = reserved
        ? 'reserved for admin'
        : booked
        ? 'booked'
        : selected
        ? 'selected'
        : 'available';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Semantics(
        button: true,
        enabled: !booked && !reserved,
        label: 'Seat $seat, $statusLabel',
        child: InkWell(
          onTap: booked || reserved
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
          child: Container(
            key: ValueKey('seat-$seat'),
            height: 54,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: reserved
                    ? Colors.amber.shade700
                    : booked
                    ? Colors.blueGrey.shade200
                    : selected
                    ? Colors.green.shade800
                    : Colors.deepPurple.shade100,
                width: selected || reserved ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!reserved)
                  Icon(
                    Icons.event_seat,
                    size: selected ? 26 : 23,
                    color: foregroundColor,
                  ),
                Text(
                  '$seat',
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.bold,
                    fontSize: reserved ? 11 : null,
                  ),
                ),
                if (reserved)
                  Text(
                    'ADMIN',
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
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
