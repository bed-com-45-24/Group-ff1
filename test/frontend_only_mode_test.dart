import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/main.dart';
import 'package:mova/services/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('frontend-only app signs in the demo admin without a backend', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MovaApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Frontend-only demo'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'admin@mova.test');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Company admin · Routes'), findsOneWidget);
    expect(find.text('Manage routes'), findsOneWidget);
  }, skip: AppConfig.backendEnabled);
}
