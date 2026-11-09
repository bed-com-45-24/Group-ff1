import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mova/data/route_store.dart';
import 'package:mova/screens/admin/routes_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin can add the same endpoints on different roads', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = RouteStore.instance;

    await tester.pumpWidget(const MaterialApp(home: RoutesScreen()));
    await tester.pumpAndSettle();

    await _addRoute(tester, road: 'M1');
    await _addRoute(tester, road: 'M5');

    final zombaMzuzuRoutes = store.routes
        .where(
          (route) =>
              route.origin == 'Zomba' &&
              route.destination == 'Mzuzu' &&
              {'M1', 'M5'}.contains(route.roadName),
        )
        .toList();

    expect(zombaMzuzuRoutes.map((route) => route.roadName).toSet(), {
      'M1',
      'M5',
    });
    for (final road in ['M1', 'M5']) {
      final routeTitle = find.text('Zomba - Mzuzu · $road');
      await tester.scrollUntilVisible(
        routeTitle,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(routeTitle, findsOneWidget);
    }

    for (final route in zombaMzuzuRoutes) {
      await store.removeRoute(route.id);
    }
  });
}

Future<void> _addRoute(WidgetTester tester, {required String road}) async {
  await tester.tap(find.text('Add route'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).at(0), 'Zomba');
  await tester.enterText(find.byType(TextFormField).at(1), 'Mzuzu');
  await tester.enterText(find.byType(TextFormField).at(2), road);
  await tester.enterText(find.byType(TextFormField).at(6), '25000');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}
