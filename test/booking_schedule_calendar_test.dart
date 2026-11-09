import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mova/data/booking_store.dart';
import 'package:mova/data/trip_store.dart';
import 'package:mova/models/trip_model.dart';
import 'package:mova/screens/user/booking/select_trip_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('calendar filters admin schedules and opens the selected trip', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final firstDeparture = DateTime.now().add(const Duration(days: 5));
    final firstTrip = Trip(
      id: 'CALENDAR-SCHEDULE-ONE',
      origin: 'Planner Origin',
      destination: 'Planner Destination',
      departureTime: DateTime(
        firstDeparture.year,
        firstDeparture.month,
        firstDeparture.day,
        7,
      ),
      arrivalTime: firstDeparture.add(const Duration(hours: 3)),
      fare: 25000,
      totalSeats: Trip.busSeatCapacity,
      bookedSeats: const [1, 2, 3],
      operatorName: 'MOVA 1',
    );
    final secondDeparture = firstDeparture.add(const Duration(days: 1));
    final secondTrip = Trip(
      id: 'CALENDAR-SCHEDULE-TWO',
      origin: 'Planner Origin',
      destination: 'Planner Destination',
      departureTime: DateTime(
        secondDeparture.year,
        secondDeparture.month,
        secondDeparture.day,
        8,
      ),
      arrivalTime: secondDeparture.add(const Duration(hours: 3)),
      fare: 27000,
      totalSeats: Trip.busSeatCapacity,
      operatorName: 'MOVA 2',
    );
    final tripStore = TripStore.instance;
    await tripStore.saveTrip(firstTrip);
    await tripStore.saveTrip(secondTrip);
    await BookingStore.instance.load();
    addTearDown(() async {
      await tripStore.removeTrip(firstTrip.id);
      await tripStore.removeTrip(secondTrip.id);
    });

    await tester.pumpWidget(const MaterialApp(home: SelectTripScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Planner Origin');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Planner Destination',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Travel date'));
    await tester.pumpAndSettle();

    expect(
      find.text('Schedules for Planner Origin to Planner Destination'),
      findsOneWidget,
    );
    expect(find.text('2 schedules found'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('schedule-date-picker-content')))
          .width,
      lessThanOrEqualTo(328),
    );
    expect(find.textContaining('39 of 42 seats available'), findsOneWidget);

    final today = DateUtils.dateOnly(DateTime.now());
    final todayCircle = tester.widget<Container>(
      find.byKey(
        ValueKey(
          'schedule-calendar-circle-${today.year}-${today.month}-${today.day}',
        ),
      ),
    );
    final todayDecoration = todayCircle.decoration! as BoxDecoration;
    expect(todayDecoration.color, isNull);
    expect(todayDecoration.border, isNotNull);

    final firstDateKey = ValueKey(
      'schedule-calendar-day-${firstTrip.departureTime.year}-'
      '${firstTrip.departureTime.month}-${firstTrip.departureTime.day}',
    );
    final secondDateKey = ValueKey(
      'schedule-calendar-day-${secondTrip.departureTime.year}-'
      '${secondTrip.departureTime.month}-${secondTrip.departureTime.day}',
    );

    await tester.tap(find.byKey(firstDateKey));
    await tester.pumpAndSettle();
    final selectedCircle = tester.widget<Container>(
      find.byKey(
        ValueKey(
          'schedule-calendar-circle-${firstTrip.departureTime.year}-'
          '${firstTrip.departureTime.month}-${firstTrip.departureTime.day}',
        ),
      ),
    );
    expect(
      (selectedCircle.decoration! as BoxDecoration).color,
      Theme.of(tester.element(find.byType(Dialog))).colorScheme.primary,
    );
    expect(find.textContaining('Bus · MOVA 1'), findsOneWidget);
    expect(find.textContaining('Bus · MOVA 2'), findsNothing);

    await tester.tap(find.byKey(secondDateKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bus · MOVA 1'), findsNothing);
    expect(find.textContaining('Bus · MOVA 2'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('schedule-trip-CALENDAR-SCHEDULE-TWO')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select Seats'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'all route schedules fit and remain scrollable on a small phone',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final firstDeparture = DateTime.now().add(const Duration(days: 5));
      final trips = List.generate(
        20,
        (index) => Trip(
          id: 'CALENDAR-SCHEDULE-MANY-$index',
          origin: 'Many Origin',
          destination: 'Many Destination',
          departureTime: firstDeparture.add(Duration(minutes: index * 15)),
          arrivalTime: firstDeparture.add(
            Duration(hours: 2, minutes: index * 15),
          ),
          fare: 25000,
          totalSeats: Trip.busSeatCapacity,
          operatorName: 'MOVA $index',
        ),
      );
      final tripStore = TripStore.instance;
      for (final trip in trips) {
        await tripStore.saveTrip(trip);
      }
      await BookingStore.instance.load();
      addTearDown(() async {
        for (final trip in trips) {
          await tripStore.removeTrip(trip.id);
        }
      });

      await tester.pumpWidget(const MaterialApp(home: SelectTripScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Many Origin');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Many Destination',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Travel date'));
      await tester.pumpAndSettle();

      expect(find.text('20 schedules found'), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('schedule-date-picker-content')))
            .width,
        lessThanOrEqualTo(328),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('schedule-trip-CALENDAR-SCHEDULE-MANY-19')),
        220,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('route-schedule-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(
        find.byKey(const ValueKey('schedule-trip-CALENDAR-SCHEDULE-MANY-19')),
        findsOneWidget,
      );
      final addedTrip = Trip(
        id: 'CALENDAR-SCHEDULE-ADDED',
        origin: 'Many Origin',
        destination: 'Many Destination',
        departureTime: firstDeparture.add(const Duration(hours: 8)),
        arrivalTime: firstDeparture.add(const Duration(hours: 10)),
        fare: 25000,
        totalSeats: Trip.busSeatCapacity,
        operatorName: 'MOVA Added',
      );
      await tripStore.saveTrip(addedTrip);
      await tester.pumpAndSettle();
      expect(find.text('21 schedules found'), findsOneWidget);
      await tripStore.removeTrip(addedTrip.id);
      await tester.pumpAndSettle();
      expect(find.text('20 schedules found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
