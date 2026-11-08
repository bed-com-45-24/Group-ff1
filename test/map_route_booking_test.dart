import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mova/models/osm_route_model.dart';
import 'package:mova/models/route_model.dart';
import 'package:mova/screens/user/booking/select_trip_screen.dart';
import 'package:mova/screens/user/results_screen.dart';

void main() {
  testWidgets('each map option opens trip search for that selected option', (
    tester,
  ) async {
    final routes = [
      _mapRoute(id: 'route-1', distance: 10000, duration: 3600),
      _mapRoute(id: 'route-2', distance: 20000, duration: 7200),
    ];
    const configuredRoute = RouteModel(
      id: 'configured-route',
      companyName: 'MOVA',
      name: 'Lilongwe - Blantyre',
      origin: 'Lilongwe',
      destination: 'Blantyre',
      stops: ['Lilongwe', 'Blantyre'],
      fare: 25000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CompareRoutesScreen(
          routes: routes,
          origin: configuredRoute.origin,
          destination: configuredRoute.destination,
          configuredRoute: configuredRoute,
        ),
      ),
    );

    expect(find.text('Book now'), findsNWidgets(2));
    for (var index = 0; index < routes.length; index++) {
      final header = find.byKey(ValueKey('map-option-header-$index'));
      expect(
        find.descendant(
          of: header,
          matching: find.text('Map option ${index + 1}'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: header,
          matching: find.byKey(ValueKey('book-map-option-$index')),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byKey(ValueKey('book-map-option-$index'))).width,
        lessThan(150),
      );
    }

    final secondBookButton = find.byKey(const ValueKey('book-map-option-1'));
    await tester.ensureVisible(secondBookButton);
    await tester.pumpAndSettle();
    await tester.tap(secondBookButton);
    await tester.pumpAndSettle();

    var tripSearch = tester.widget<SelectTripScreen>(
      find.byType(SelectTripScreen),
    );
    expect(tripSearch.initialRoute!.name, contains('Map option 2'));
    expect(tripSearch.initialRoute!.fare, configuredRoute.fare);

    await tester.pageBack();
    await tester.pumpAndSettle();
    final firstBookButton = find.byKey(const ValueKey('book-map-option-0'));
    await tester.ensureVisible(firstBookButton);
    await tester.pumpAndSettle();
    await tester.tap(firstBookButton);
    await tester.pumpAndSettle();

    tripSearch = tester.widget<SelectTripScreen>(find.byType(SelectTripScreen));
    expect(tripSearch.initialRoute!.name, contains('Map option 1'));
    expect(tripSearch.initialRoute!.fare, configuredRoute.fare);
  });
}

OsmRouteModel _mapRoute({
  required String id,
  required double distance,
  required double duration,
}) => OsmRouteModel(
  id: id,
  geoJson: const {
    'coordinates': [
      [34.0, -13.0],
      [34.1, -13.1],
    ],
  },
  distanceMeters: distance,
  durationSeconds: duration,
  steps: const [],
);
