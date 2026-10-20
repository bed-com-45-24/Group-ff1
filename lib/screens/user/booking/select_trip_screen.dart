import 'package:flutter/material.dart';

import '../../../data/trip_store.dart';
import '../../../models/osm_route_model.dart';
import '../../../models/trip_model.dart';
import '../../../services/openstreetmap_service.dart';
import 'seat_selection_screen.dart';

class SelectTripScreen extends StatefulWidget {
  final bool showAppBar;
  final OpenStreetMapService? openStreetMapService;

  const SelectTripScreen({
    super.key,
    this.showAppBar = true,
    this.openStreetMapService,
  });

  @override
  State<SelectTripScreen> createState() => _SelectTripScreenState();
}

class _SelectTripScreenState extends State<SelectTripScreen> {
  final _tripStore = TripStore.instance;
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  late final OpenStreetMapService _openStreetMap =
      widget.openStreetMapService ?? OpenStreetMapService();

  DateTime travelDate = DateUtils.dateOnly(DateTime.now());
  List<_BookingOption> results = const [];
  bool _hasSearched = false;
  bool _isLoading = false;
  String? _searchMessage;

  Future<void> searchTrips() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _hasSearched = false;
      _searchMessage = null;
      results = const [];
    });

    try {
      await _tripStore.load();
      final tripsForDate = _findTripsForDate();
      final bookableTrips = tripsForDate
          .where(
            (trip) =>
                trip.availableSeats > 0 &&
                !trip.departureTime.isBefore(DateTime.now()),
          )
          .toList();
      if (tripsForDate.isNotEmpty && bookableTrips.isEmpty) {
        throw Exception(
          'There are no bookable departures for this route on the selected '
          'date. Choose another date.',
        );
      }

      final originName = _originController.text.trim();
      final destinationName = _destinationController.text.trim();
      final origin = await _openStreetMap.findPlace(originName);
      final destination = await _openStreetMap.findPlace(destinationName);
      final mapRoutes = await _openStreetMap.findRoutes(
        origin: origin,
        destination: destination,
      );
      if (mapRoutes.isEmpty) {
        throw Exception('No drivable routes were found between those places.');
      }

      final options = _makeBookingOptions(
        mapRoutes,
        bookableTrips,
        originName,
        destinationName,
      );
      if (!mounted) return;
      setState(() {
        _hasSearched = true;
        _isLoading = false;
        results = options;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _hasSearched = true;
        _isLoading = false;
        _searchMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Trip> _findTripsForDate() {
    final origin = _originController.text.trim().toLowerCase();
    final destination = _destinationController.text.trim().toLowerCase();
    return _tripStore.trips.where((trip) {
      return !trip.id.startsWith('MAP-ESTIMATE-') &&
          trip.origin.toLowerCase().contains(origin) &&
          trip.destination.toLowerCase().contains(destination) &&
          DateUtils.isSameDay(trip.departureTime, travelDate);
    }).toList();
  }

  List<_BookingOption> _makeBookingOptions(
    List<OsmRouteModel> routes,
    List<Trip> scheduledTrips,
    String origin,
    String destination,
  ) {
    final options = <_BookingOption>[];
    for (final route in routes) {
      final fare = (route.distanceMeters / 1000 * 220).roundToDouble();
      final departureTrips = scheduledTrips.isEmpty
          ? [_newMapTrip(origin, destination, route, fare)]
          : scheduledTrips;
      for (final trip in departureTrips) {
        final estimatedTrip = trip.copyWith(
          arrivalTime: trip.departureTime.add(
            Duration(seconds: route.durationSeconds.round()),
          ),
          fare: fare,
          mapDistanceMeters: route.distanceMeters,
          fareIsEstimate: true,
        );
        options.add(_BookingOption(trip: estimatedTrip, routeId: route.id));
      }
    }
    return options;
  }

  Trip _newMapTrip(
    String origin,
    String destination,
    OsmRouteModel route,
    double fare,
  ) {
    final dateKey =
        '${travelDate.year.toString().padLeft(4, '0')}'
        '${travelDate.month.toString().padLeft(2, '0')}'
        '${travelDate.day.toString().padLeft(2, '0')}';
    String idPart(String value) => value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final departure = _defaultDepartureTime(travelDate);
    final id =
        'MAP-ESTIMATE-$dateKey-${idPart(origin)}-'
        '${idPart(destination)}-${route.id}';
    for (final storedTrip in _tripStore.trips) {
      if (storedTrip.id == id) {
        return storedTrip.copyWith(
          fare: fare,
          mapDistanceMeters: route.distanceMeters,
          fareIsEstimate: true,
          arrivalTime: departure.add(
            Duration(seconds: route.durationSeconds.round()),
          ),
        );
      }
    }
    return Trip(
      id: id,
      origin: origin,
      destination: destination,
      departureTime: departure,
      arrivalTime: departure.add(
        Duration(seconds: route.durationSeconds.round()),
      ),
      fare: fare,
      mapDistanceMeters: route.distanceMeters,
      fareIsEstimate: true,
      totalSeats: 40,
      operatorName: 'Map route · operator to be confirmed',
    );
  }

  DateTime _defaultDepartureTime(DateTime date) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(date, now)) {
      final oneHourLater = now.add(const Duration(hours: 1));
      return DateUtils.isSameDay(date, oneHourLater)
          ? oneHourLater
          : now.add(const Duration(minutes: 1));
    }
    return DateTime(date.year, date.month, date.day, 9);
  }

  Future<void> _selectOption(_BookingOption option) async {
    var trip = option.trip;
    if (trip.id.startsWith('MAP-ESTIMATE-')) {
      final storedTrips = _tripStore.trips.where(
        (stored) => stored.id == trip.id,
      );
      if (storedTrips.isNotEmpty) {
        final stored = storedTrips.first;
        if (stored.availableSeats <= 0) {
          setState(
            () => _searchMessage = 'No seats remain for this map route.',
          );
          return;
        }
        trip = stored.copyWith(
          arrivalTime: trip.arrivalTime,
          fare: trip.fare,
          mapDistanceMeters: trip.mapDistanceMeters,
          fareIsEstimate: true,
        );
      } else {
        await _tripStore.saveTrip(trip);
      }
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SeatSelectionScreen(trip: trip)),
    );
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Book a Trip'))
          : null,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Plan your journey',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter your route and travel date to continue your booking.',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _originController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Departure location',
                prefixIcon: Icon(Icons.trip_origin),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your departure location'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _destinationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Destination',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your destination'
                  : null,
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Travel date'),
                subtitle: Text(
                  MaterialLocalizations.of(context)
                      .formatMediumDate(travelDate),
                ),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () async {
                  final today = DateUtils.dateOnly(DateTime.now());
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: travelDate.isBefore(today)
                        ? today
                        : travelDate,
                    firstDate: today,
                    lastDate: today.add(const Duration(days: 365)),
                  );

                  if (selected != null) {
                    setState(() => travelDate = DateUtils.dateOnly(selected));
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : searchTrips,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.directions_bus),
                label: const Text('Book a trip'),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Finding places and calculating routes and estimated fares…',
                  textAlign: TextAlign.center,
                ),
              ),
            if (_hasSearched) ...[
              const SizedBox(height: 24),
              if (_searchMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_searchMessage!),
                  ),
                )
              else ...[
                Text(
                  'Choose your departure',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
              ],
              if (_searchMessage == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Fares are map estimates calculated at MWK 220 per '
                    'kilometre, not published operator fares. Confirm the '
                    'final fare and departure with the operator.',
                  ),
                ),
              ...results.map((option) {
                final trip = option.trip;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.route),
                    title: Text('${trip.origin} → ${trip.destination}'),
                    subtitle: Text(
                      '${option.routeId.replaceFirst('route-', 'Map route ')}'
                      ' · ${_distanceLabel(trip.mapDistanceMeters)}'
                      ' · ${_durationLabel(trip)}\n'
                      '${trip.operatorName} · '
                      '${_timeLabel(trip.departureTime)} · '
                      '${trip.availableSeats} seats available',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'MWK ${trip.fare.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('Estimated fare'),
                      ],
                    ),
                    onTap: () => _selectOption(option),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _distanceLabel(double? meters) {
    if (meters == null) return 'Distance unavailable';
    return meters >= 1000
        ? '${(meters / 1000).toStringAsFixed(1)} km'
        : '${meters.round()} m';
  }

  String _durationLabel(Trip trip) {
    final duration = trip.arrivalTime.difference(trip.departureTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours == 0 ? '$minutes min' : '${hours}h ${minutes}m';
  }

  String _timeLabel(DateTime value) =>
      MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay.fromDateTime(value));
}

class _BookingOption {
  final Trip trip;
  final String routeId;

  const _BookingOption({required this.trip, required this.routeId});
}
