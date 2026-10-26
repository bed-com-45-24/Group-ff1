import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking_model.dart';
import '../models/trip_model.dart';

class BookingStore {
  BookingStore._();

  static final BookingStore instance = BookingStore._();
  static const _storageKey = 'mova_bookings_v1';

  final List<BookingDraft> _bookings = [];
  final ValueNotifier<int> changes = ValueNotifier(0);
  bool _loaded = false;
  Future<void>? _loadFuture;
  Future<void> _writeQueue = Future<void>.value();

  List<BookingDraft> get bookings => List.unmodifiable(_bookings);
  bool get isLoaded => _loaded;

  Future<void> load() {
    if (_loaded) return Future<void>.value();
    return _loadFuture ??= _load().catchError((Object error) {
      _loadFuture = null;
      Error.throwWithStackTrace(error, StackTrace.current);
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      final values = jsonDecode(stored) as List<dynamic>;
      final loaded = values.map((value) {
        final json = value as Map<String, dynamic>;
        final cancelled = json['cancelled'] as bool? ?? false;
        final paid = json['paid'] as bool? ?? false;
        final status = json['status'] == null
            ? cancelled
                  ? BookingStatus.cancelled
                  : paid
                  ? BookingStatus.confirmed
                  : (json['passengerName'] as String? ?? '').isNotEmpty
                  ? BookingStatus.reviewed
                  : BookingStatus.draft
            : BookingStatus.values.byName(json['status'] as String);

        return BookingDraft(
          trip: Trip.fromJson(json['trip'] as Map<String, dynamic>),
          reference: json['reference'] as String,
          selectedSeats: (json['selectedSeats'] as List<dynamic>).cast<int>(),
          passengerName: json['passengerName'] as String? ?? '',
          passengerEmail: json['passengerEmail'] as String? ?? '',
          phoneNumber: json['phoneNumber'] as String? ?? '',
          identificationNumber: json['identificationNumber'] as String? ?? '',
          paymentMethod: json['paymentMethod'] as String? ?? '',
          paymentReference: json['paymentReference'] as String? ?? '',
          status: status,
        );
      }).toList();
      final references = loaded.map((booking) => booking.reference).toSet();
      if (references.length != loaded.length) {
        throw const FormatException(
          'Stored bookings contain duplicate references.',
        );
      }
      _bookings.addAll(loaded);
    }
    _loaded = true;
    changes.value++;
  }

  Future<void> createDraft(BookingDraft booking) => _serialize(() async {
    await load();
    if (booking.status != BookingStatus.draft) {
      throw StateError('A new booking must start as a draft.');
    }
    if (_bookings.any((item) => item.reference == booking.reference)) {
      throw StateError('A booking with this reference already exists.');
    }
    final occupiedSeats = _bookings
        .where(
          (item) =>
              item.trip.id == booking.trip.id &&
              (item.status == BookingStatus.paid ||
                  item.status == BookingStatus.confirmed),
        )
        .expand((item) => item.selectedSeats)
        .toSet();
    if (booking.selectedSeats.any(occupiedSeats.contains)) {
      throw StateError('One or more selected seats are no longer available.');
    }
    await _save([..._bookings, booking]);
  });

  Future<BookingDraft> reviewBooking({
    required String reference,
    required String passengerName,
    required String passengerEmail,
    required String phoneNumber,
    required String identificationNumber,
  }) => _serialize(() async {
    await load();
    final current = _requireBooking(reference);
    if (current.status != BookingStatus.draft) {
      throw StateError('Only a draft booking can be reviewed.');
    }
    current.validateForReview(
      name: passengerName,
      email: passengerEmail,
      phone: phoneNumber,
    );
    final updated = current.copyWith(
      passengerName: passengerName.trim(),
      passengerEmail: passengerEmail.trim(),
      phoneNumber: phoneNumber.trim(),
      identificationNumber: identificationNumber.trim(),
      status: BookingStatus.reviewed,
    );
    await _replace(updated);
    return updated;
  });

  Future<BookingDraft> markPaid({
    required String reference,
    required String paymentMethod,
    required String paymentReference,
  }) => _serialize(() async {
    await load();
    final current = _requireBooking(reference);
    if (current.status == BookingStatus.paid ||
        current.status == BookingStatus.confirmed) {
      return current;
    }
    if (current.status != BookingStatus.reviewed) {
      throw StateError('Only a reviewed booking can be paid.');
    }
    if (paymentMethod.trim().isEmpty || paymentReference.trim().isEmpty) {
      throw ArgumentError('Payment method and reference are required.');
    }
    final occupiedSeats = _bookings
        .where(
          (booking) =>
              booking.trip.id == current.trip.id &&
              booking.reference != current.reference &&
              (booking.status == BookingStatus.paid ||
                  booking.status == BookingStatus.confirmed),
        )
        .expand((booking) => booking.selectedSeats)
        .toSet();
    if (current.selectedSeats.any(occupiedSeats.contains)) {
      throw StateError('One or more selected seats are no longer available.');
    }
    final updated = current.copyWith(
      paymentMethod: paymentMethod.trim(),
      paymentReference: paymentReference.trim(),
      status: BookingStatus.paid,
    );
    await _replace(updated);
    return updated;
  });

  Future<BookingDraft> confirmBooking(String reference) => _serialize(() async {
    await load();
    final current = _requireBooking(reference);
    if (current.status == BookingStatus.confirmed) return current;
    if (current.status != BookingStatus.paid) {
      throw StateError('Only a paid booking can be confirmed.');
    }
    final updated = current.copyWith(status: BookingStatus.confirmed);
    await _replace(updated);
    return updated;
  });

  Future<({BookingDraft booking, bool newlyConfirmed})> completePayment({
    required String reference,
    required String paymentMethod,
    required String paymentReference,
  }) => _serialize(() async {
    await load();
    var current = _requireBooking(reference);
    if (current.status == BookingStatus.confirmed) {
      return (booking: current, newlyConfirmed: false);
    }
    if (current.status == BookingStatus.reviewed) {
      if (paymentMethod.trim().isEmpty || paymentReference.trim().isEmpty) {
        throw ArgumentError('Payment method and reference are required.');
      }
      final occupiedSeats = _bookings
          .where(
            (booking) =>
                booking.trip.id == current.trip.id &&
                booking.reference != current.reference &&
                (booking.status == BookingStatus.paid ||
                    booking.status == BookingStatus.confirmed),
          )
          .expand((booking) => booking.selectedSeats)
          .toSet();
      if (current.selectedSeats.any(occupiedSeats.contains)) {
        throw StateError('One or more selected seats are no longer available.');
      }
      current = current.copyWith(
        paymentMethod: paymentMethod.trim(),
        paymentReference: paymentReference.trim(),
        status: BookingStatus.paid,
      );
      await _replace(current);
    } else if (current.status != BookingStatus.paid) {
      throw StateError('Only a reviewed booking can be paid.');
    }

    final confirmed = current.copyWith(status: BookingStatus.confirmed);
    await _replace(confirmed);
    return (booking: confirmed, newlyConfirmed: true);
  });

  Future<BookingDraft> cancelBooking(String reference) => _serialize(() async {
    await load();
    final current = _requireBooking(reference);
    if (current.status == BookingStatus.cancelled) return current;
    if (current.status == BookingStatus.paid ||
        current.status == BookingStatus.confirmed) {
      throw StateError('Paid bookings cannot be cancelled here.');
    }
    final updated = current.copyWith(status: BookingStatus.cancelled);
    await _replace(updated);
    return updated;
  });

  BookingDraft? findBooking(String reference) {
    for (final booking in _bookings) {
      if (booking.reference == reference) return booking;
    }
    return null;
  }

  Set<int> occupiedSeatsForTrip(Trip trip) => {
    ...trip.bookedSeats,
    for (final booking in _bookings)
      if (booking.trip.id == trip.id &&
          (booking.status == BookingStatus.paid ||
              booking.status == BookingStatus.confirmed))
        ...booking.selectedSeats,
  };

  Future<void> _replace(BookingDraft booking) async {
    final next = [
      for (final current in _bookings)
        if (current.reference == booking.reference) booking else current,
    ];
    await _save(next);
  }

  Future<void> _save(List<BookingDraft> next) async {
    final prefs = await SharedPreferences.getInstance();
    final persisted = await prefs.setString(
      _storageKey,
      jsonEncode(next.map(_toJson).toList()),
    );
    if (!persisted) {
      throw StateError('Booking changes could not be saved to this device.');
    }
    _bookings
      ..clear()
      ..addAll(next);
    changes.value++;
  }

  Map<String, Object?> _toJson(BookingDraft booking) => {
    'trip': booking.trip.toJson(),
    'reference': booking.reference,
    'selectedSeats': booking.selectedSeats,
    'passengerName': booking.passengerName,
    'passengerEmail': booking.passengerEmail,
    'phoneNumber': booking.phoneNumber,
    'identificationNumber': booking.identificationNumber,
    'paymentMethod': booking.paymentMethod,
    'paymentReference': booking.paymentReference,
    'status': booking.status.name,
  };

  BookingDraft _requireBooking(String reference) {
    final booking = findBooking(reference);
    if (booking == null) {
      throw StateError('Booking $reference does not exist.');
    }
    return booking;
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = _writeQueue.then((_) => action());
    _writeQueue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }
}
