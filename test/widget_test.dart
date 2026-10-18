import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mova/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MOVA app loads the login screen by default', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MovaApp());
    await tester.pump();

    expect(find.text('Welcome to MOVA'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
  });
}
