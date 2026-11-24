import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/screens/user/booking/booking_cancel_action.dart';

void main() {
  testWidgets('booking cancel action confirms before leaving the flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const _BookingStep()),
              ),
              child: const Text('Start booking'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start booking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Leave booking?'), findsOneWidget);

    await tester.tap(find.text('Keep booking'));
    await tester.pumpAndSettle();
    expect(find.text('Booking step'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text('Start booking'), findsOneWidget);
  });
}

class _BookingStep extends StatelessWidget {
  const _BookingStep();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Booking'),
      actions: const [BookingCancelAction()],
    ),
    body: const Center(child: Text('Booking step')),
  );
}
