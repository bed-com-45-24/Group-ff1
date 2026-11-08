import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mova/data/booking_store.dart';
import 'package:mova/data/trip_store.dart';
import 'package:mova/models/booking_model.dart';
import 'package:mova/models/trip_model.dart';
import 'package:mova/screens/admin/schedules_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin schedule availability updates as seats are reserved', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final trip = Trip(
      id: 'SCHEDULE-AVAILABILITY-TEST',
      origin: 'Availability Origin',
      destination: 'Availability Destination',
      departureTime: DateTime(2026, 12, 1, 8),
      arrivalTime: DateTime(2026, 12, 1, 12),
      fare: 10000,
      totalSeats: Trip.busSeatCapacity,
    );
    final trips = TripStore.instance;
    final bookings = BookingStore.instance;
    await trips.saveTrip(trip);
    await bookings.load();
    addTearDown(() async {
      await trips.removeTrip(trip.id);
    });

    await tester.pumpWidget(const MaterialApp(home: SchedulesScreen()));
    await tester.pumpAndSettle();
    final tripCard = find.ancestor(
      of: find.text('Availability Origin → Availability Destination'),
      matching: find.byType(Card),
    );
    expect(
      find.descendant(
        of: tripCard,
        matching: find.textContaining('42/42 seats'),
      ),
      findsOneWidget,
    );

    final draft = BookingDraft(
      trip: trip.copyWith(bookedSeats: [2]),
      reference: 'SCHEDULE-AVAILABILITY-DRAFT',
      selectedSeats: [1, 3],
    );
    await bookings.createDraft(draft);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: tripCard,
        matching: find.textContaining('40/42 seats'),
      ),
      findsOneWidget,
    );

    await bookings.cancelBooking(draft.reference);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: tripCard,
        matching: find.textContaining('42/42 seats'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Add schedule'));
    await tester.pumpAndSettle();
    final capacityBox = tester.widget<InputDecorator>(
      find
          .ancestor(of: find.text('42'), matching: find.byType(InputDecorator))
          .last,
    );
    expect(capacityBox.decoration.labelText, 'Total seats');
    expect(capacityBox.decoration.border, isA<OutlineInputBorder>());
  });
}
