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

  List<BookingDraft> get bookings => List.unmodifiable(_bookings);
  bool get isLoaded => _loaded;

  Future<void> load() {
    if (_loaded) return Future<void>.value();
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      final values = jsonDecode(stored) as List<dynamic>;
      _bookings
        ..clear()
        ..addAll(
          values.map((value) {
            final json = value as Map<String, dynamic>;
            return BookingDraft(
              trip: Trip.fromJson(json['trip'] as Map<String, dynamic>),
              reference: json['reference'] as String,
              selectedSeats: (json['selectedSeats'] as List<dynamic>)
                  .cast<int>(),
              passengerName: json['passengerName'] as String? ?? '',
              passengerEmail: json['passengerEmail'] as String? ?? '',
              phoneNumber: json['phoneNumber'] as String? ?? '',
              identificationNumber:
                  json['identificationNumber'] as String? ?? '',
              paymentMethod: json['paymentMethod'] as String? ?? '',
              paymentReference: json['paymentReference'] as String? ?? '',
              paid: json['paid'] as bool? ?? false,
              cancelled: json['cancelled'] as bool? ?? false,
            );
          }),
        );
    }
    _loaded = true;
    changes.value++;
  }

  void addBooking(BookingDraft booking) {
    final index = _bookings.indexWhere(
      (item) => item.reference == booking.reference,
    );
    if (index == -1) {
      _bookings.add(booking);
    } else {
      _bookings[index] = booking;
    }
    changes.value++;
    unawaited(_persist());
  }

  void updateBooking(BookingDraft booking) {
    final index = _bookings.indexWhere(
      (item) => item.reference == booking.reference,
    );

    if (index != -1) {
      _bookings[index] = booking;
      changes.value++;
      unawaited(_persist());
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
    _bookings.removeWhere((booking) => booking.reference == reference);
    changes.value++;
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(
        _bookings.map((booking) {
          return {
            'trip': booking.trip.toJson(),
            'reference': booking.reference,
            'selectedSeats': booking.selectedSeats,
            'passengerName': booking.passengerName,
            'passengerEmail': booking.passengerEmail,
            'phoneNumber': booking.phoneNumber,
            'identificationNumber': booking.identificationNumber,
            'paymentMethod': booking.paymentMethod,
            'paymentReference': booking.paymentReference,
            'paid': booking.paid,
            'cancelled': booking.cancelled,
          };
        }).toList(),
      ),
    );
  }
}
