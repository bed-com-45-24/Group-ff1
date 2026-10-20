import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mova/main.dart';
import 'package:mova/models/osm_route_model.dart';
import 'package:mova/models/booking_model.dart';
import 'package:mova/models/route_model.dart';
import 'package:mova/models/trip_model.dart';
import 'package:mova/data/route_store.dart';
import 'package:mova/screens/user/booking/passenger_details_screen.dart';
import 'package:mova/screens/user/booking/booking_summary_screen.dart';
import 'package:mova/screens/user/route_directions_details_screen.dart';
import 'package:mova/screens/user/results_screen.dart';
import 'package:mova/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MOVA asks the user to choose a role before login', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MovaApp());
    await tester.pumpAndSettle();

    expect(find.text('Company admin'), findsOneWidget);
    expect(find.text('Normal user'), findsOneWidget);

    await tester.tap(find.text('Normal user'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to MOVA'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('Signing in as Normal user'), findsOneWidget);
  });

  testWidgets('Admin role signs in to the admin dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final authService = AuthService();
    await authService.signup(
      'admin@mova.test',
      'password123',
      'MOVA Admin',
      role: 'admin',
    );

    await tester.pumpWidget(const MovaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Company admin'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'admin@mova.test');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Company admin · Routes'), findsOneWidget);
    expect(find.text('Manage routes'), findsOneWidget);

    await tester.tap(find.text('Schedules'));
    await tester.pumpAndSettle();
    expect(find.text('Schedules & seats'), findsOneWidget);

    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();
    expect(find.text('No bookings have been made.'), findsOneWidget);
  });

  test('Registered passenger details persist for future bookings', () async {
    SharedPreferences.setMockInitialValues({});
    final authService = AuthService();

    expect(
      await authService.signup(
        'passenger@mova.test',
        'password123',
        'Test Passenger',
        role: 'passenger',
      ),
      isTrue,
    );
    expect(
      await authService.login(
        'passenger@mova.test',
        'password123',
        role: 'passenger',
      ),
      isTrue,
    );

    var details = await authService.getPassengerDetails();
    expect(details['name'], 'Test Passenger');
    expect(details['email'], 'passenger@mova.test');

    await authService.savePassengerDetails(
      name: details['name']!,
      email: details['email']!,
      phoneNumber: '0991234567',
      identificationNumber: 'ID12345',
    );

    details = await authService.getPassengerDetails();
    expect(details['phoneNumber'], '0991234567');
    expect(details['identificationNumber'], 'ID12345');
  });

  test('Unregistered credentials cannot sign in as company admin', () async {
    SharedPreferences.setMockInitialValues({});
    expect(
      await AuthService().login(
        'unknown@mova.test',
        'password123',
        role: 'admin',
      ),
      isFalse,
    );
  });

  test('Admin route updates are stored for passenger browsing', () async {
    SharedPreferences.setMockInitialValues({});
    final store = RouteStore.instance;
    await store.load();
    const route = RouteModel(
      id: 'ADMIN-TEST',
      companyName: 'MOVA',
      name: 'Test Origin - Test Destination',
      origin: 'Test Origin',
      destination: 'Test Destination',
      stops: ['Test Origin', 'Test Stop', 'Test Destination'],
      fare: 12345,
      departureTimes: ['09:00'],
      active: false,
    );

    await store.saveRoute(route);
    expect(store.routes.any((item) => item.id == route.id), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('admin_routes_v1'), contains('Test Destination'));
    await store.removeRoute(route.id);
  });

  testWidgets(
    'Passenger details form is prefilled from local account storage',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_logged_in': true,
        'user_email': 'passenger@mova.test',
        'user_name': 'Test Passenger',
        'passenger_profile_passenger@mova.test':
            '{"name":"Test Passenger","email":"passenger@mova.test",'
            '"phoneNumber":"0991234567","identificationNumber":"ID12345"}',
      });
      final booking = BookingDraft(
        trip: Trip(
          id: 'trip-1',
          origin: 'Lilongwe',
          destination: 'Blantyre',
          departureTime: DateTime(2026, 10, 20, 8),
          arrivalTime: DateTime(2026, 10, 20, 14),
          fare: 25000,
          totalSeats: 40,
        ),
        reference: 'MOVA-TEST',
      );

      await tester.pumpWidget(
        MaterialApp(home: PassengerDetailsScreen(booking: booking)),
      );
      await tester.pumpAndSettle();

      final fields = tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      );
      expect(fields.elementAt(0).controller!.text, 'Test Passenger');
      expect(fields.elementAt(1).controller!.text, 'passenger@mova.test');
      expect(fields.elementAt(2).controller!.text, '0991234567');
      expect(fields.elementAt(3).controller!.text, 'ID12345');
    },
  );

  testWidgets(
    'Passenger home has a single destination search and popular routes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({
        'is_logged_in': true,
        'user_role': 'passenger',
        'user_name': 'Test Passenger',
      });

      await tester.pumpWidget(const MovaApp());
      await tester.pumpAndSettle();

      expect(find.text('Plan your journey'), findsOneWidget);
      expect(find.text('Search destination'), findsOneWidget);
      expect(find.text('Current location'), findsNothing);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.text('From'), findsNothing);
      expect(find.text('To'), findsNothing);
      expect(find.text('Search routes'), findsNothing);
      expect(find.text('View all'), findsNothing);
      expect(find.text('Your trip summary'), findsNothing);
      expect(find.text('Search destinations'), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('home-content')).first).width,
        430,
      );

      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      expect(find.text('Search destination'), findsOneWidget);
      expect(find.text('Where are you heading?'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Popular routes'), findsWidgets);
      expect(find.text('Blantyre - Lilongwe'), findsWidgets);

      await tester.tap(find.text('Routes'));
      await tester.pumpAndSettle();
      expect(find.text('All routes'), findsOneWidget);

      await tester.tap(find.text('Bookings'));
      await tester.pumpAndSettle();

      expect(find.text('Bookings'), findsWidgets);
      expect(find.text('Find a trip'), findsOneWidget);
      expect(find.text('My bookings'), findsOneWidget);

      await tester.tap(find.text('My bookings'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No bookings yet'), findsOneWidget);
    },
  );

  test('OSRM GeoJSON route exposes distance, time, points and directions', () {
    final route = OsmRouteModel.fromJson({
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [33.78, -13.96],
          [34.00, -14.10],
        ],
      },
      'distance': 12500,
      'duration': 1800,
      'legs': [
        {
          'steps': [
            {
              'maneuver': {'type': 'depart'},
            },
            {
              'maneuver': {'type': 'turn', 'modifier': 'left'},
            },
          ],
        },
      ],
    }, 0);

    expect(route.distanceLabel, '12.5 km');
    expect(route.durationLabel, '30 min');
    expect(route.points, hasLength(2));
    expect(route.steps, ['depart', 'turn left']);
  });

  testWidgets('Map route trip summary shows estimated map time and MWK fare', (
    tester,
  ) async {
    final route = OsmRouteModel.fromJson({
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [33.78, -13.96],
          [34.00, -14.10],
        ],
      },
      'distance': 12500,
      'duration': 1800,
      'legs': [
        {'steps': <Map<String, dynamic>>[]},
      ],
    }, 0);

    await tester.pumpWidget(
      MaterialApp(
        home: RouteDirectionsDetailsScreen(
          route: route,
          origin: 'Lilongwe',
          destination: 'Blantyre',
          estimatedFare: 2750,
        ),
      ),
    );

    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('MWK 2750'), findsOneWidget);
    await tester.tap(find.text('Trip summary'));
    await tester.pumpAndSettle();

    expect(find.text('Journey duration'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('Estimated map fare'), findsOneWidget);
    expect(find.text('MWK 2750'), findsNWidgets(2));
    expect(find.textContaining('Malawi kwacha (MWK)'), findsOneWidget);
  });

  testWidgets('Selected comparison route is included in the booking summary', (
    tester,
  ) async {
    final routes = [
      OsmRouteModel.fromJson({
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [33.78, -13.96],
            [34.00, -14.10],
          ],
        },
        'distance': 12500,
        'duration': 1800,
        'legs': [
          {'steps': <Map<String, dynamic>>[]},
        ],
      }, 0),
      OsmRouteModel.fromJson({
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [33.78, -13.96],
            [34.00, -14.10],
          ],
        },
        'distance': 18000,
        'duration': 2700,
        'legs': [
          {'steps': <Map<String, dynamic>>[]},
        ],
      }, 1),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: CompareRoutesScreen(
          routes: routes,
          origin: 'Origin',
          destination: 'Destination',
          estimateFare: (route) =>
              'MWK ${(route.distanceMeters / 1000 * 220).round()}',
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('route-option-selector-1')));
    await tester.pumpAndSettle();
    expect(find.text('Use Route 2 in booking summary'), findsOneWidget);

    await tester.ensureVisible(find.text('Use Route 2 in booking summary'));
    await tester.tap(find.text('Use Route 2 in booking summary'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Route 2'), findsWidgets);
    expect(find.text('Selected route option'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);
    expect(find.text('18.0 km'), findsOneWidget);
  });

  testWidgets('Trip summary shows route, stop, and fare information', (
    tester,
  ) async {
    const route = RouteModel(
      id: 'test-route',
      companyName: 'MOVA',
      name: 'Lilongwe to Blantyre',
      origin: 'Lilongwe',
      destination: 'Blantyre',
      stops: ['Lilongwe', 'Dedza', 'Blantyre'],
      fare: 25000,
      duration: '5h',
      mapDistance: '250 km',
      transfers: 0,
    );

    await tester.pumpWidget(
      const MaterialApp(home: BookingSummaryScreen(route: route)),
    );

    expect(find.text('Journey details'), findsOneWidget);
    expect(find.text('Lilongwe → Dedza → Blantyre'), findsOneWidget);
    expect(find.text('Journey duration'), findsOneWidget);
    expect(find.text('Distance (map)'), findsOneWidget);
    expect(find.text('250 km'), findsOneWidget);
    expect(find.text('Transfers'), findsNothing);
    expect(find.text('Total for one passenger'), findsOneWidget);
    expect(find.text('MWK 25000'), findsNWidgets(2));
  });
}
