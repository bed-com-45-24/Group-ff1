import '../models/booking_model.dart';
import '../models/trip_model.dart';
import 'booking_store.dart';
import 'notification_store.dart';

class BookingService {
  BookingService._();

  static final BookingService instance = BookingService._();

  final BookingStore _store = BookingStore.instance;

  Future<BookingDraft> createDraft({
    required Trip trip,
    required List<int> selectedSeats,
    required String reference,
  }) async {
    await _store.load();
    final booking = BookingDraft(
      trip: trip,
      reference: reference,
      selectedSeats: selectedSeats,
    );
    await _store.createDraft(booking);
    return booking;
  }

  Future<BookingDraft> review({
    required String reference,
    required String passengerName,
    required String passengerEmail,
    required String phoneNumber,
    required String identificationNumber,
  }) => _store.reviewBooking(
    reference: reference,
    passengerName: passengerName,
    passengerEmail: passengerEmail,
    phoneNumber: phoneNumber,
    identificationNumber: identificationNumber,
  );

  Future<BookingDraft> completePayment({
    required String reference,
    required String paymentMethod,
    required String paymentReference,
  }) async {
    await _store.load();
    final result = await _store.completePayment(
      reference: reference,
      paymentMethod: paymentMethod,
      paymentReference: paymentReference,
    );
    if (result.newlyConfirmed) {
      NotificationStore.instance.addPaymentConfirmation(
        paymentMethod: result.booking.paymentMethod,
        paymentReference: result.booking.paymentReference,
        amount: result.booking.total,
      );
    }
    return result.booking;
  }
}
