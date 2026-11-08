import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mova/data/booking_service.dart';
import 'package:mova/data/booking_store.dart';
import 'package:mova/models/booking_model.dart';
import 'package:mova/models/trip_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('booking lifecycle persists state and reserves seats once', () async {
    SharedPreferences.setMockInitialValues({});
    final store = BookingStore.instance;
    await store.load();
    final trip = Trip(
      id: 'lifecycle-test-trip',
      origin: 'Lilongwe',
      destination: 'Blantyre',
      departureTime: DateTime(2026, 10, 25, 8),
      arrivalTime: DateTime(2026, 10, 25, 14),
      fare: 25000,
      totalSeats: 40,
    );
    final draft = BookingDraft(
      trip: trip,
      reference: 'MOVA-LIFECYCLE-TEST',
      selectedSeats: [2, 1],
    );

    await store.createDraft(draft);
    expect(store.findBooking(draft.reference)?.status, BookingStatus.draft);
    expect(
      () => BookingDraft(
        trip: trip,
        reference: 'MOVA-INVALID-SEATS',
        selectedSeats: [1, 1],
      ),
      throwsArgumentError,
    );
    expect(() => store.createDraft(draft), throwsStateError);

    final reviewed = await store.reviewBooking(
      reference: draft.reference,
      passengerName: 'Test Passenger',
      passengerEmail: 'passenger@example.test',
      phoneNumber: '0991234567',
      identificationNumber: '',
    );
    expect(reviewed.status, BookingStatus.reviewed);

    final confirmed = await BookingService.instance.completePayment(
      reference: draft.reference,
      paymentMethod: 'Mobile Money',
      paymentReference: 'DEMO-LIFECYCLE-TEST',
    );
    expect(confirmed.status, BookingStatus.confirmed);
    expect(store.occupiedSeatsForTrip(trip), {1, 2});

    final repeatedPayment = await BookingService.instance.completePayment(
      reference: draft.reference,
      paymentMethod: 'Bank Card',
      paymentReference: 'DEMO-DUPLICATE',
    );
    expect(repeatedPayment.paymentReference, 'DEMO-LIFECYCLE-TEST');
    expect(
      store.bookings.where((booking) => booking.reference == draft.reference),
      hasLength(1),
    );

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('mova_bookings_v1'),
      contains('"status":"confirmed"'),
    );
  });
}
