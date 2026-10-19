import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mova/main.dart';
import 'package:mova/models/route_model.dart';
import 'package:mova/screens/user/booking/booking_summary_screen.dart';

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
  });

  testWidgets('Passenger home has From and To search and requested tabs', (
    tester,
  ) async {
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
    expect(find.text('From'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.text('Your trip summary'), findsNothing);
    expect(find.text('Search destinations'), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('home-content')).first).width,
      430,
    );
    await tester.enterText(find.byType(TextField).at(0), 'Blantyre');
    await tester.enterText(find.byType(TextField).at(1), 'Lilongwe');
    await tester.tap(find.text('Find routes'));
    await tester.pumpAndSettle();
    expect(find.text('Blantyre → Lilongwe'), findsNWidgets(2));
    expect(find.text('Blantyre - Lilongwe'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Popular routes'), findsWidgets);
    expect(find.text('Blantyre - Lilongwe'), findsWidgets);

    await tester.tap(find.text('Trips'));
    await tester.pumpAndSettle();

    expect(find.text('Trips & bookings'), findsOneWidget);
    expect(find.text('Find a trip'), findsOneWidget);
    expect(find.text('My bookings'), findsOneWidget);

    await tester.tap(find.text('My bookings'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No bookings yet'), findsOneWidget);
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
      transfers: 0,
    );

    await tester.pumpWidget(
      const MaterialApp(home: BookingSummaryScreen(route: route)),
    );

    expect(find.text('Journey details'), findsOneWidget);
    expect(find.text('Lilongwe → Dedza → Blantyre'), findsOneWidget);
    expect(find.text('Total for one passenger'), findsOneWidget);
    expect(find.text('MWK 25000'), findsNWidgets(2));
  });
}
