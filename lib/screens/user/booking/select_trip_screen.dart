import 'package:flutter/material.dart';

import '../../../data/booking_store.dart';
import '../../../data/trip_store.dart';
import '../../../models/route_model.dart';
import '../../../models/trip_model.dart';
import 'seat_selection_screen.dart';

class SelectTripScreen extends StatefulWidget {
  final bool showAppBar;
  final RouteModel? initialRoute;

  const SelectTripScreen({
    super.key,
    this.showAppBar = true,
    this.initialRoute,
  });

  @override
  State<SelectTripScreen> createState() => _SelectTripScreenState();
}

class _SelectTripScreenState extends State<SelectTripScreen> {
  final _tripStore = TripStore.instance;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _originController;
  late final TextEditingController _destinationController;

  DateTime? travelDate;
  List<Trip> results = const [];
  List<Trip> _routeTrips = const [];
  bool _hasSearched = false;
  bool _isLoading = false;
  bool _isLoadingSchedules = false;
  String? _searchMessage;
  String? _scheduleLoadError;
  int _scheduleRequestId = 0;

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController(
      text: widget.initialRoute?.origin ?? '',
    );
    _destinationController = TextEditingController(
      text: widget.initialRoute?.destination ?? '',
    );
    _tripStore.changes.addListener(_onSchedulesChanged);
    BookingStore.instance.changes.addListener(_onSchedulesChanged);
    if (_originController.text.trim().isNotEmpty &&
        _destinationController.text.trim().isNotEmpty) {
      _refreshRouteTrips();
    }
  }

  void _onSchedulesChanged() {
    if (!mounted || !_tripStore.isLoaded || !BookingStore.instance.isLoaded) {
      return;
    }
    setState(() {
      _routeTrips = _matchingTripsForRoute(
        _tripStore.trips,
        _originController.text,
        _destinationController.text,
        roadName: widget.initialRoute?.roadName ?? '',
      );
      _scheduleLoadError = null;
    });
  }

  Future<void> _refreshRouteTrips() async {
    final requestId = ++_scheduleRequestId;
    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();
    if (origin.isEmpty || destination.isEmpty) {
      if (!mounted) return;
      setState(() {
        _routeTrips = const [];
        _isLoadingSchedules = false;
        _scheduleLoadError = null;
      });
      return;
    }

    setState(() {
      _isLoadingSchedules = true;
      _scheduleLoadError = null;
    });
    try {
      await Future.wait([
        _tripStore.load(refresh: true),
        BookingStore.instance.load(refresh: true),
      ]);
      if (!mounted || requestId != _scheduleRequestId) return;
      setState(() {
        _routeTrips = _matchingTripsForRoute(
          _tripStore.trips,
          origin,
          destination,
          roadName: widget.initialRoute?.roadName ?? '',
        );
        _isLoadingSchedules = false;
      });
    } catch (error) {
      if (!mounted || requestId != _scheduleRequestId) return;
      setState(() {
        _isLoadingSchedules = false;
        _scheduleLoadError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onRouteChanged() {
    setState(() {
      travelDate = null;
      _hasSearched = false;
      results = const [];
      _searchMessage = null;
    });
    _refreshRouteTrips();
  }

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
      await BookingStore.instance.load();
      _routeTrips = _matchingTripsForRoute(
        _tripStore.trips,
        _originController.text,
        _destinationController.text,
        roadName: widget.initialRoute?.roadName ?? '',
      );
      final matchingTrips = _findTripsForDate();
      if (!mounted) return;
      setState(() {
        _hasSearched = true;
        _isLoading = false;
        results = matchingTrips;
        _searchMessage = matchingTrips.isEmpty
            ? 'No scheduled trips match this route and travel date.'
            : null;
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
    return _routeTrips
        .where(
          (trip) =>
              (travelDate == null ||
                  DateUtils.isSameDay(trip.departureTime, travelDate)) &&
              trip.departureTime.isAfter(DateTime.now()),
        )
        .toList();
  }

  Future<void> _selectTravelDate() async {
    if (_originController.text.trim().isEmpty ||
        _destinationController.text.trim().isEmpty) {
      _formKey.currentState?.validate();
      return;
    }
    await _refreshRouteTrips();
    if (!mounted) return;
    final selection = await showDialog<_ScheduleSelection>(
      context: context,
      builder: (context) => _ScheduleDatePickerDialog(
        origin: _originController.text.trim(),
        destination: _destinationController.text.trim(),
        roadName: widget.initialRoute?.roadName ?? '',
        initialDate: travelDate,
        loadError: _scheduleLoadError,
      ),
    );
    if (selection == null || !mounted) return;
    setState(() {
      travelDate = selection.date == null
          ? null
          : DateUtils.dateOnly(selection.date!);
    });
    final selectedTrip = selection.trip;
    if (selectedTrip != null &&
        selectedTrip.departureTime.isAfter(DateTime.now()) &&
        _availableSeats(selectedTrip) > 0) {
      _selectScheduledTrip(selectedTrip);
    }
  }

  int _availableSeats(Trip trip) =>
      (trip.totalSeats -
              BookingStore.instance.occupiedSeatsForTrip(trip).length)
          .clamp(0, trip.totalSeats);

  void _selectScheduledTrip(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeatSelectionScreen(
          trip: widget.initialRoute == null
              ? trip
              : trip.copyWith(
                  fare: widget.initialRoute!.fare,
                  routeName: widget.initialRoute!.roadName.trim().isEmpty
                      ? trip.routeName
                      : widget.initialRoute!.roadName,
                  fareIsEstimate: widget.initialRoute!.fareIsEstimate,
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tripStore.changes.removeListener(_onSchedulesChanged);
    BookingStore.instance.changes.removeListener(_onSchedulesChanged);
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
            Text(
              widget.initialRoute == null
                  ? 'Enter your route and travel date to see scheduled trips.'
                  : 'Choose a travel date to see scheduled trips for '
                        '${widget.initialRoute!.origin} to '
                        '${widget.initialRoute!.destination}.',
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
              onChanged: (_) => _onRouteChanged(),
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
              onChanged: (_) => _onRouteChanged(),
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
                  travelDate == null
                      ? 'Any upcoming date'
                      : MaterialLocalizations.of(context)
                            .formatMediumDate(travelDate!),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (travelDate != null)
                      IconButton(
                        tooltip: 'Clear travel date',
                        onPressed: () {
                          setState(() {
                            travelDate = null;
                            _hasSearched = false;
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    IconButton(
                      tooltip: 'Choose travel date',
                      onPressed: _selectTravelDate,
                      icon: const Icon(Icons.edit_calendar),
                    ),
                  ],
                ),
                onTap: _selectTravelDate,
              ),
            ),
            if (_isLoadingSchedules)
              const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading
                    ? null
                    : widget.initialRoute != null && travelDate == null
                    ? _selectTravelDate
                    : searchTrips,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.directions_bus),
                label: Text(
                  widget.initialRoute == null
                      ? 'Book a trip'
                      : travelDate == null
                      ? 'Select travel date'
                      : 'Find available trips',
                ),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_hasSearched) ...[
              const SizedBox(height: 24),
              Text(
                'Scheduled trips matching your search',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (_searchMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_searchMessage!),
                  ),
                ),
              ...results.map((trip) {
                final availableSeats = _availableSeats(trip);
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.route),
                    title: Text('${trip.origin} → ${trip.destination}'),
                    subtitle: Text(
                      '${trip.routeName.isEmpty ? 'Road not specified' : trip.routeName}'
                      ' · ${trip.operatorName}'
                      '${trip.vehicleName.isEmpty ? '' : ' · ${trip.vehicleName}'}\n'
                      '${_durationLabel(trip)} · '
                      '${MaterialLocalizations.of(context).formatMediumDate(trip.departureTime)} · '
                      '${_timeLabel(trip.departureTime)} · '
                      '$availableSeats seats available',
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
                        const Text('Fare'),
                      ],
                    ),
                    onTap: availableSeats > 0
                        ? () => _selectScheduledTrip(trip)
                        : null,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
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

List<Trip> _matchingTripsForRoute(
  List<Trip> trips,
  String origin,
  String destination, {
  String roadName = '',
}) {
  final normalizedOrigin = _normalizeLocation(origin);
  final normalizedDestination = _normalizeLocation(destination);
  final normalizedRoadName = _normalizeLocation(roadName);
  if (normalizedOrigin.isEmpty || normalizedDestination.isEmpty) {
    return const [];
  }
  return trips.where((trip) {
    final scheduledOrigin = _normalizeLocation(trip.origin);
    final scheduledDestination = _normalizeLocation(trip.destination);
    final scheduledRoadName = _normalizeLocation(trip.routeName);
    return !trip.id.startsWith('MAP-ESTIMATE-') &&
        (scheduledOrigin.contains(normalizedOrigin) ||
            normalizedOrigin.contains(scheduledOrigin)) &&
        (scheduledDestination.contains(normalizedDestination) ||
            normalizedDestination.contains(scheduledDestination)) &&
        (normalizedRoadName.isEmpty ||
            (scheduledRoadName.isNotEmpty &&
                (scheduledRoadName.contains(normalizedRoadName) ||
                    normalizedRoadName.contains(scheduledRoadName))));
  }).toList()..sort(
    (first, second) => first.departureTime.compareTo(second.departureTime),
  );
}

String _normalizeLocation(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

class _ScheduleSelection {
  final DateTime? date;
  final Trip? trip;

  const _ScheduleSelection({this.date, this.trip});
}

class _ScheduleDatePickerDialog extends StatefulWidget {
  final String origin;
  final String destination;
  final String roadName;
  final DateTime? initialDate;
  final String? loadError;

  const _ScheduleDatePickerDialog({
    required this.origin,
    required this.destination,
    required this.roadName,
    required this.initialDate,
    required this.loadError,
  });

  @override
  State<_ScheduleDatePickerDialog> createState() =>
      _ScheduleDatePickerDialogState();
}

class _ScheduleDatePickerDialogState extends State<_ScheduleDatePickerDialog> {
  late DateTime _displayedMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _selectedDate = widget.initialDate == null
        ? null
        : DateUtils.dateOnly(widget.initialDate!);
    _displayedMonth = DateTime(
      (_selectedDate ?? today).year,
      (_selectedDate ?? today).month,
    );
  }

  List<Trip> _scheduledTrips() => _matchingTripsForRoute(
    TripStore.instance.trips,
    widget.origin,
    widget.destination,
    roadName: widget.roadName,
  );

  void _changeMonth(int offset) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + offset,
      );
    });
  }

  void _complete({Trip? trip, required DateTime? date}) {
    Navigator.pop(context, _ScheduleSelection(date: date, trip: trip));
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final today = DateUtils.dateOnly(DateTime.now());

    return Dialog(
      key: const ValueKey('schedule-date-picker-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        key: const ValueKey('schedule-date-picker-content'),
        width: double.infinity,
        height: mediaSize.height * 0.9,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: ValueListenableBuilder<int>(
            valueListenable: TripStore.instance.changes,
            builder: (context, _, _) => ValueListenableBuilder<int>(
              valueListenable: BookingStore.instance.changes,
              builder: (context, _, _) {
                final trips = _scheduledTrips();
                final routeDates = trips
                    .map((trip) => DateUtils.dateOnly(trip.departureTime))
                    .toSet();
                final selectedDate =
                    _selectedDate != null && routeDates.contains(_selectedDate)
                    ? _selectedDate
                    : null;
                final visibleTrips = selectedDate == null
                    ? trips
                    : trips
                          .where(
                            (trip) => DateUtils.isSameDay(
                              trip.departureTime,
                              selectedDate,
                            ),
                          )
                          .toList();
                final calendar = _buildCalendar(
                  today: today,
                  routeDates: routeDates,
                  selectedDate: selectedDate,
                );
                final scheduleList = _buildScheduleList(
                  trips: visibleTrips,
                  hasRouteSchedules: trips.isNotEmpty,
                  scheduleCount: visibleTrips.length,
                  selectedDate: selectedDate,
                );

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Choose a travel date',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 282,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 280,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: calendar,
                                ),
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          const SizedBox(height: 6),
                          Expanded(child: scheduleList),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(64, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () => _complete(date: selectedDate),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar({
    required DateTime today,
    required Set<DateTime> routeDates,
    required DateTime? selectedDate,
  }) {
    final firstOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month);
    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
    final leadingDays = firstOfMonth.weekday - 1;
    final cellCount = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    final latestSchedule = routeDates.isEmpty
        ? today
        : routeDates.reduce(
            (first, second) => first.isAfter(second) ? first : second,
          );
    final localizations = MaterialLocalizations.of(context);

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              onPressed:
                  _displayedMonth.year == today.year &&
                      _displayedMonth.month == today.month
                  ? null
                  : () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                localizations.formatMonthYear(_displayedMonth),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              onPressed: _displayedMonth.year > latestSchedule.year + 1
                  ? null
                  : () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final day = index - leadingDays + 1;
              if (day < 1 || day > daysInMonth) {
                return const SizedBox.shrink();
              }
              final date = DateUtils.dateOnly(
                DateTime(_displayedMonth.year, _displayedMonth.month, day),
              );
              final hasSchedule = routeDates.contains(date);
              final isSelected = DateUtils.isSameDay(date, selectedDate);
              final isToday = DateUtils.isSameDay(date, today);
              final enabled = !date.isBefore(today) && hasSchedule;
              final colorScheme = Theme.of(context).colorScheme;
              return Center(
                child: InkWell(
                  key: ValueKey(
                    'schedule-calendar-day-${date.year}-${date.month}-${date.day}',
                  ),
                  onTap: enabled
                      ? () => setState(() => _selectedDate = date)
                      : null,
                  customBorder: const CircleBorder(),
                  child: Container(
                    key: ValueKey(
                      'schedule-calendar-circle-${date.year}-${date.month}-${date.day}',
                    ),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? colorScheme.primary : null,
                      border: isToday
                          ? Border.all(
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.primary,
                              width: isSelected ? 2 : 1.5,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : isToday && enabled
                                ? colorScheme.primary
                                : enabled
                                ? null
                                : Theme.of(context).disabledColor,
                            fontSize: 12,
                            fontWeight: isToday || isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasSchedule
                                ? (isSelected
                                      ? colorScheme.onPrimary
                                      : colorScheme.primary)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleList({
    required List<Trip> trips,
    required bool hasRouteSchedules,
    required int scheduleCount,
    required DateTime? selectedDate,
  }) {
    final title = 'Schedules for ${widget.origin} to ${widget.destination}';
    if (widget.loadError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 2),
          _scheduleCountLabel(scheduleCount),
          const SizedBox(height: 4),
          Expanded(
            child: Center(
              child: Text(
                'Schedules could not be loaded: ${widget.loadError}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    if (!hasRouteSchedules) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 2),
          _scheduleCountLabel(scheduleCount),
          const SizedBox(height: 4),
          const Expanded(
            child: Center(
              child: Text(
                'No schedules found for this route. Try another date or route..',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 2),
        _scheduleCountLabel(scheduleCount),
        const SizedBox(height: 4),
        Expanded(
          child: trips.isEmpty
              ? const Center(
                  child: Text(
                    'No schedules available for this date.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  key: const ValueKey('route-schedule-list'),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    final availableSeats =
                        (trip.totalSeats -
                                BookingStore.instance
                                    .occupiedSeatsForTrip(trip)
                                    .length)
                            .clamp(0, trip.totalSeats);
                    return Card(
                      key: ValueKey('schedule-trip-${trip.id}'),
                      margin: const EdgeInsets.fromLTRB(2, 2, 2, 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.directions_bus),
                        title: Text(_scheduleDateTimeLabel(context, trip)),
                        subtitle: Text(
                          '${trip.transportMode} · ${trip.operatorName}\n'
                          '$availableSeats of ${trip.totalSeats} '
                          'seats available',
                        ),
                        isThreeLine: true,
                        dense: true,
                        visualDensity: const VisualDensity(
                          horizontal: -2,
                          vertical: -3,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        minLeadingWidth: 24,
                        horizontalTitleGap: 8,
                        titleTextStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        subtitleTextStyle: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontSize: 11),
                        onTap:
                            availableSeats > 0 &&
                                trip.departureTime.isAfter(DateTime.now())
                            ? () => _complete(trip: trip, date: selectedDate)
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _scheduleCountLabel(int count) => Text(
    '$count ${count == 1 ? 'schedule' : 'schedules'} found',
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Colors.black54),
  );

  String _scheduleDateTimeLabel(BuildContext context, Trip trip) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final date = trip.departureTime;
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(date));
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} '
        '${date.day} · $time';
  }
}
