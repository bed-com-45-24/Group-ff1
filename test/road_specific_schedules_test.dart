import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mova/data/trip_store.dart';
import 'package:mova/models/route_model.dart';
import 'package:mova/screens/admin/schedules_screen.dart';
import 'package:mova/screens/user/booking/seat_selection_screen.dart';
import 'package:mova/screens/user/booking/select_trip_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('same-endpoint schedules retain distinct roads and vehicles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = TripStore.instance;
    final departure = DateTime.now().add(const Duration(days: 1));

    await tester.pumpWidget(const MaterialApp(home: SchedulesScreen()));
    await tester.pumpAndSettle();

    await _addSchedule(
      tester,
      road: 'M1',
      vehicle: 'MOVA 1',
      departure: departure,
    );
    await _addSchedule(
      tester,
      road: 'M5',
      vehicle: 'MOVA 2',
      departure: departure.add(const Duration(hours: 2)),
    );

    final schedules = store.trips
        .where(
          (trip) =>
              trip.origin == 'Zomba' &&
              trip.destination == 'Mzuzu' &&
              {'M1', 'M5'}.contains(trip.routeName),
        )
        .toList();
    expect(schedules.map((trip) => trip.routeName).toSet(), {'M1', 'M5'});
    expect(schedules.map((trip) => trip.vehicleName).toSet(), {
      'MOVA 1',
      'MOVA 2',
    });

    final route = RouteModel(
      id: 'ZOMBA-MZUZU-M5',
      companyName: 'MOVA',
      name: 'Zomba - Mzuzu',
      origin: 'Zomba',
      destination: 'Mzuzu',
      roadName: 'M5',
      stops: const ['Zomba', 'Mzuzu'],
      fare: 22000,
    );

    await tester.pumpWidget(
      MaterialApp(home: SelectTripScreen(initialRoute: route)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose travel date'));
    await tester.pumpAndSettle();
    final travelDate = DateUtils.dateOnly(departure);
    await tester.tap(find.text('${travelDate.day}').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find available trips'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('M5 · MOVA Express · MOVA 2'),
      findsOneWidget,
    );
    expect(find.textContaining('M1 ·'), findsNothing);

    await tester.tap(find.text('Zomba → Mzuzu'));
    await tester.pumpAndSettle();
    final seatSelection = tester.widget<SeatSelectionScreen>(
      find.byType(SeatSelectionScreen),
    );
    expect(seatSelection.trip.routeName, 'M5');
    expect(seatSelection.trip.vehicleName, 'MOVA 2');

    for (final trip in schedules) {
      await store.removeTrip(trip.id);
    }
  });
}

Future<void> _addSchedule(
  WidgetTester tester, {
  required String road,
  required String vehicle,
  required DateTime departure,
}) async {
  await tester.tap(find.text('Add schedule'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).at(0), 'Zomba');
  await tester.enterText(find.byType(TextFormField).at(1), 'Mzuzu');
  await tester.enterText(
    find.byType(TextFormField).at(2),
    _dateTimeString(departure),
  );
  await tester.enterText(
    find.byType(TextFormField).at(3),
    _dateTimeString(departure.add(const Duration(hours: 5))),
  );
  await tester.enterText(find.byType(TextFormField).at(4), '22000');
  await tester.enterText(find.byType(TextFormField).at(5), 'MOVA Express');
  await tester.enterText(find.byType(TextFormField).at(6), road);
  await tester.enterText(find.byType(TextFormField).at(7), vehicle);
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

String _dateTimeString(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')} '
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
