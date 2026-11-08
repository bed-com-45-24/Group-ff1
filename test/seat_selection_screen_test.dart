import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mova/data/trip_store.dart';
import 'package:mova/models/trip_model.dart';
import 'package:mova/screens/user/booking/seat_selection_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saved routes reserve only seat 2 and clear stale demo seats', () async {
    final oldFirstTrip = _trip(totalSeats: 41).copyWith(bookedSeats: [2, 5, 9]);
    final oldFirstJson = oldFirstTrip.toJson()..['id'] = 'TRIP002';
    final oldDemoTrip = _trip(totalSeats: 41)
        .copyWith(bookedSeats: [1, 2, 4, 10, 12]);
    final oldDemoJson = oldDemoTrip.toJson()..['id'] = 'TRIP003';
    SharedPreferences.setMockInitialValues({
      'admin_trips_v1': jsonEncode([oldFirstJson, oldDemoJson]),
    });

    await TripStore.instance.load();
    final trips = TripStore.instance.trips;
    final firstTrip = trips.singleWhere((trip) => trip.id == 'TRIP002');
    final demoTrip = trips.singleWhere((trip) => trip.id == 'TRIP003');

    expect(firstTrip.totalSeats, Trip.busSeatCapacity);
    expect(firstTrip.bookedSeats, [5, 9]);
    expect(demoTrip.totalSeats, Trip.busSeatCapacity);
    expect(demoTrip.bookedSeats, [12]);
    expect(
      trips.every((trip) => trip.totalSeats == Trip.busSeatCapacity),
      isTrue,
    );
    final preferences = await SharedPreferences.getInstance();
    final savedTrips =
        jsonDecode(preferences.getString('admin_trips_v1')!) as List<dynamic>;
    final savedTripJson = savedTrips.cast<Map<String, dynamic>>();
    expect(
      savedTripJson.singleWhere(
        (trip) => trip['id'] == 'TRIP002',
      )['bookedSeats'],
      [5, 9],
    );
    expect(
      savedTripJson.singleWhere(
        (trip) => trip['id'] == 'TRIP003',
      )['bookedSeats'],
      [12],
    );

    await TripStore.instance.saveTrip(
      _trip(totalSeats: 18, id: 'NEW-SCHEDULE'),
    );
    expect(
      TripStore.instance.trips
          .singleWhere((trip) => trip.id == 'NEW-SCHEDULE')
          .totalSeats,
      Trip.busSeatCapacity,
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    '42-seat map reserves only seat 2 and leaves all others selectable',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: SeatSelectionScreen(
            trip: _trip(totalSeats: 12).copyWith(bookedSeats: [1, 4, 5, 9, 10]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('42 seats · Seat 2 reserved for admin'), findsOneWidget);
      expect(find.text('DOOR'), findsOneWidget);
      expect(find.text('DRIVER'), findsOneWidget);
      expect(find.text('Selected seats: 0 / 5'), findsOneWidget);
      expect(find.text('42 seats · Seat 2 reserved for admin'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('seat-2')));
      await tester.pump();
      expect(find.text('Selected seats: 0 / 5'), findsOneWidget);

      final door = tester.getRect(find.text('DOOR'));
      final seatOne = tester.getRect(find.byKey(const ValueKey('seat-1')));
      expect(seatOne.left, greaterThan(door.right));
      expect(seatOne.left - door.right, greaterThanOrEqualTo(8));
      await tester.tap(find.byKey(const ValueKey('seat-1')));
      await tester.pump();
      expect(find.text('Selected seats: 1 / 5'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('seat-4')));
      await tester.pump();
      expect(find.text('Selected seats: 2 / 5'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('seat-10')));
      await tester.pump();
      expect(find.text('Selected seats: 3 / 5'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('seat-5')));
      await tester.pump();
      expect(find.text('Selected seats: 4 / 5'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('seat-9')));
      await tester.pump();
      expect(find.text('Selected seats: 5 / 5'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('seat-5')));
      await tester.pump();
      expect(find.text('Selected seats: 4 / 5'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('seat-42')),
        300,
      );
      for (var seat = 32; seat <= 36; seat++) {
        expect(find.byKey(ValueKey('seat-$seat')), findsOneWidget);
      }
      for (var seat = 37; seat <= 42; seat++) {
        expect(find.byKey(ValueKey('seat-$seat')), findsOneWidget);
      }
      expect(
        tester.getRect(find.byKey(const ValueKey('seat-40'))).center.dx,
        lessThan(
          tester.getRect(find.byKey(const ValueKey('seat-41'))).center.dx,
        ),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('seat-41'))).center.dx,
        lessThan(
          tester.getRect(find.byKey(const ValueKey('seat-42'))).center.dx,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('seat-42')));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Passenger Details'), findsOneWidget);
    },
  );
}

Trip _trip({required int totalSeats, String id = 'SEAT-TEST'}) => Trip(
  id: id,
  origin: 'Origin',
  destination: 'Destination',
  departureTime: DateTime(2026, 11, 10, 8),
  arrivalTime: DateTime(2026, 11, 10, 12),
  fare: 10000,
  totalSeats: totalSeats,
);
