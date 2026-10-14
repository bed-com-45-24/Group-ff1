
import '../models/booking_model.dart';

class BookingStore {
  BookingStore._();

  static final BookingStore instance = BookingStore._();

  final List<BookingDraft> _bookings = [];

  List<BookingDraft> get bookings =>
      List.unmodifiable(_bookings);

  void addBooking(BookingDraft booking) {
    final exists = _bookings.any(
      (item) => item.reference == booking.reference,
    );

    if (!exists) {
      _bookings.add(booking);
    }
  }

  void updateBooking(BookingDraft booking) {
    final index = _bookings.indexWhere(
      (item) => item.reference == booking.reference,
    );

    if (index != -1) {
      _bookings[index] = booking;
    }
  }

  BookingDraft? findBooking(String reference) {
    for (final booking in _bookings) {
      if (booking.reference == reference) {
        return booking;
      }
    }

    return null;
  }

  void removeBooking(String reference) {
    _bookings.removeWhere(
      (booking) => booking.reference == reference,
    );
  }
}
