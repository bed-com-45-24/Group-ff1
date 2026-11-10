import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../models/booking_model.dart';
import '../models/trip_model.dart';

class BookingStore {
  BookingStore._({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient.instance;

  static final BookingStore instance = BookingStore._();
  BookingStore.forApi({required ApiClient apiClient})
    : _api = apiClient,
      _backendEnabled = true;

  static const _storageKey = 'mova_bookings_v1';

  final ApiClient _api;
  final List<BookingDraft> _bookings = [];
  final ValueNotifier<int> changes = ValueNotifier(0);
  bool _backendEnabled = false;
  bool _loaded = false;
  Future<void>? _loadFuture;
  Future<void> _writeQueue = Future<void>.value();

  List<BookingDraft> get bookings => List.unmodifiable(_bookings);
  bool get isLoaded => _loaded;

  void enableBackend() {
    if (_backendEnabled) return;
    _backendEnabled = true;
    _bookings.clear();
    _loaded = false;
    _loadFuture = null;
  }

  Future<void> load({bool refresh = false}) {
    if (_loaded && (!refresh || !_backendEnabled)) {
      return Future<void>.value();
    }
    return _loadFuture ??= _load().whenComplete(() => _loadFuture = null);
  }

  Future<void> _load() async {
    if (_backendEnabled) {
      final token = await _api.accessToken;
      final role = token == null
          ? null
          : await AuthService(apiClient: _api).getUserRole();
      final response = await _api.get(
        role == 'admin' ? 'bookings/admin/list' : 'bookings/mine',
        authenticated: true,
      );
      final values = _listResponse(response, 'bookings');
      _bookings
        ..clear()
        ..addAll(
          values.map(
            (value) => BookingDraft.fromApiJson(
              Map<String, dynamic>.from(value as Map),
            ),
          ),
        );
      _loaded = true;
      changes.value++;
      return;
    }

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

  void _upsert(BookingDraft booking) {
    final index = _bookings.indexWhere(
      (item) => item.reference == booking.reference,
    );
    if (index == -1) {
      _bookings.insert(0, booking);
    } else {
      _bookings[index] = booking;
    }
    changes.value++;
  }

  List<dynamic> _listResponse(dynamic response, String name) {
    if (response is List) return response;
    if (response is Map) {
      final data = response['data'] ?? response['items'] ?? response['results'];
      if (data is List) return data;
      if (data is Map && data['bookings'] is List) {
        return data['bookings'] as List;
      }
    }
    throw FormatException('The API returned an invalid $name response.');
  }

  Map<String, dynamic> _mapResponse(dynamic response, String name) {
    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response['booking'];
      if (data is Map) {
        final booking = data['booking'];
        if (booking is Map) return Map<String, dynamic>.from(booking);
        return Map<String, dynamic>.from(data);
      }
      return response;
    }
    throw FormatException('The API returned an invalid $name response.');
  }

  Future<BookingDraft> createDraft(BookingDraft booking) => _serialize(
    () async {
      await load();
      if (booking.status != BookingStatus.draft) {
        throw StateError('A new booking must start as a draft.');
      }
      if (_backendEnabled) {
        final response = await _api.post(
          'bookings',
          body: {
            'tripId': booking.trip.id,
            'selectedSeats': booking.selectedSeats,
          },
        );
        final created = BookingDraft.fromApiJson(
          _mapResponse(response, 'created booking'),
        );
        _upsert(created);
        return created;
      }
      if (_bookings.any((item) => item.reference == booking.reference)) {
        throw StateError('A booking with this reference already exists.');
      }
      final occupiedSeats = activeBookingSeatsForTrip(booking.trip);
      if (booking.selectedSeats.any(occupiedSeats.contains)) {
        throw StateError('One or more selected seats are no longer available.');
      }
      await _save([..._bookings, booking]);
      return booking;
    },
  );

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
    if (_backendEnabled) {
      final response = await _api.patch(
        'bookings/${Uri.encodeComponent(reference)}',
        body: {
          'passengerName': passengerName.trim(),
          'passengerEmail': passengerEmail.trim(),
          'phoneNumber': phoneNumber.trim(),
          'identificationNumber': identificationNumber.trim(),
        },
      );
      final reviewed = BookingDraft.fromApiJson(
        _mapResponse(response, 'reviewed booking'),
      );
      _upsert(reviewed);
      return reviewed;
    }
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
    if (_backendEnabled) {
      final response = await _api.post(
        'bookings/${Uri.encodeComponent(reference)}/payment',
        body: {
          'paymentMethod': paymentMethod.trim(),
          'paymentReference': paymentReference.trim(),
        },
      );
      final paidBooking = BookingDraft.fromApiJson(
        _mapResponse(response, 'paid booking'),
      );
      _upsert(paidBooking);
      return paidBooking;
    }
    final occupiedSeats = activeBookingSeatsForTrip(
      current.trip,
      excludingReference: current.reference,
    );
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
    if (_backendEnabled) {
      final response = await _api.post(
        'bookings/${Uri.encodeComponent(reference)}/confirm',
      );
      final confirmed = BookingDraft.fromApiJson(
        _mapResponse(response, 'confirmed booking'),
      );
      _upsert(confirmed);
      return confirmed;
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
    if (_backendEnabled) {
      if (current.status != BookingStatus.reviewed &&
          current.status != BookingStatus.paid) {
        throw StateError('Only a reviewed booking can be paid.');
      }
      if (current.status == BookingStatus.reviewed &&
          (paymentMethod.trim().isEmpty || paymentReference.trim().isEmpty)) {
        throw ArgumentError('Payment method and reference are required.');
      }
      final response = current.status == BookingStatus.reviewed
          ? await _api.post(
              'bookings/${Uri.encodeComponent(reference)}/payment',
              body: {
                'paymentMethod': paymentMethod.trim(),
                'paymentReference': paymentReference.trim(),
              },
            )
          : await _api.post(
              'bookings/${Uri.encodeComponent(reference)}/confirm',
            );
      var completed = BookingDraft.fromApiJson(
        _mapResponse(response, 'confirmed booking'),
      );
      if (completed.status == BookingStatus.paid) {
        final confirmResponse = await _api.post(
          'bookings/${Uri.encodeComponent(reference)}/confirm',
        );
        completed = BookingDraft.fromApiJson(
          _mapResponse(confirmResponse, 'confirmed booking'),
        );
      }
      if (completed.status != BookingStatus.confirmed) {
        throw StateError('The backend did not confirm the booking payment.');
      }
      final newlyConfirmed =
          completed.status == BookingStatus.confirmed &&
          current.status != BookingStatus.confirmed;
      _upsert(completed);
      return (booking: completed, newlyConfirmed: newlyConfirmed);
    }
    if (current.status == BookingStatus.reviewed) {
      if (paymentMethod.trim().isEmpty || paymentReference.trim().isEmpty) {
        throw ArgumentError('Payment method and reference are required.');
      }
      final occupiedSeats = activeBookingSeatsForTrip(
        current.trip,
        excludingReference: current.reference,
      );
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
    if (_backendEnabled) {
      final response = await _api.post(
        'bookings/${Uri.encodeComponent(reference)}/cancel',
      );
      final cancelled = BookingDraft.fromApiJson(
        _mapResponse(response, 'cancelled booking'),
      );
      _upsert(cancelled);
      return cancelled;
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
    ...activeBookingSeatsForTrip(trip),
  };

  Set<int> activeBookingSeatsForTrip(Trip trip, {String? excludingReference}) =>
      {
        for (final booking in _bookings)
          if (booking.trip.id == trip.id &&
              booking.reference != excludingReference &&
              booking.status != BookingStatus.cancelled)
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
