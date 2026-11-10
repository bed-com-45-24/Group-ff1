import 'trip_model.dart';

enum BookingStatus { draft, reviewed, paid, confirmed, cancelled }

extension BookingStatusLabel on BookingStatus {
  String get label => switch (this) {
    BookingStatus.draft => 'Draft',
    BookingStatus.reviewed => 'Reviewed',
    BookingStatus.paid => 'Paid',
    BookingStatus.confirmed => 'Confirmed',
    BookingStatus.cancelled => 'Cancelled',
  };
}

class BookingDraft {
  final Trip trip;
  final String reference;
  final List<int> selectedSeats;
  final String passengerName;
  final String passengerEmail;
  final String phoneNumber;
  final String identificationNumber;
  final String paymentMethod;
  final String paymentReference;
  final BookingStatus status;

  BookingDraft({
    required Trip trip,
    required this.reference,
    List<int> selectedSeats = const [],
    this.passengerName = '',
    this.passengerEmail = '',
    this.phoneNumber = '',
    this.identificationNumber = '',
    this.paymentMethod = '',
    this.paymentReference = '',
    this.status = BookingStatus.draft,
  }) : trip = Trip(
         id: trip.id,
         origin: trip.origin,
         destination: trip.destination,
         departureTime: trip.departureTime,
         arrivalTime: trip.arrivalTime,
         fare: trip.fare,
         mapDistanceMeters: trip.mapDistanceMeters,
         fareIsEstimate: trip.fareIsEstimate,
         totalSeats: trip.totalSeats,
         bookedSeats: List.unmodifiable(trip.bookedSeats),
         transportMode: trip.transportMode,
         operatorName: trip.operatorName,
         routeName: trip.routeName,
         vehicleName: trip.vehicleName,
       ),
       selectedSeats = List.unmodifiable(selectedSeats) {
    if (reference.trim().isEmpty) {
      throw ArgumentError.value(reference, 'reference', 'Must not be empty.');
    }
    if (trip.totalSeats <= 0 || !trip.fare.isFinite || trip.fare <= 0) {
      throw ArgumentError('Trip must have seats and a positive fare.');
    }
    if (this.selectedSeats.isEmpty ||
        this.selectedSeats.length > 5 ||
        this.selectedSeats.toSet().length != this.selectedSeats.length ||
        this.selectedSeats.any(
          (seat) =>
              seat < 1 ||
              seat > trip.totalSeats ||
              trip.bookedSeats.contains(seat),
        )) {
      throw ArgumentError(
        'Choose between 1 and 5 unique available seats on the trip.',
      );
    }
    if (status != BookingStatus.draft &&
        status != BookingStatus.cancelled &&
        (passengerName.trim().isEmpty || phoneNumber.trim().length < 7)) {
      throw ArgumentError('Reviewed bookings require passenger details.');
    }
    if (passengerEmail.trim().isNotEmpty &&
        !passengerEmail.trim().contains('@')) {
      throw ArgumentError('Passenger email must be valid when provided.');
    }
    if (paid &&
        (paymentMethod.trim().isEmpty || paymentReference.trim().isEmpty)) {
      throw ArgumentError('Paid bookings require payment details.');
    }
  }

  bool get paid =>
      status == BookingStatus.paid || status == BookingStatus.confirmed;

  bool get cancelled => status == BookingStatus.cancelled;
  double get total => trip.fare * selectedSeats.length;

  void validateForReview({
    required String name,
    required String email,
    required String phone,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Enter the passenger name.');
    }
    if (email.trim().isNotEmpty && !email.trim().contains('@')) {
      throw ArgumentError('Enter a valid email address.');
    }
    if (phone.trim().length < 7) {
      throw ArgumentError('Enter a valid phone number.');
    }
  }

  BookingDraft copyWith({
    String? passengerName,
    String? passengerEmail,
    String? phoneNumber,
    String? identificationNumber,
    String? paymentMethod,
    String? paymentReference,
    BookingStatus? status,
  }) {
    return BookingDraft(
      trip: trip,
      reference: reference,
      selectedSeats: selectedSeats,
      passengerName: passengerName ?? this.passengerName,
      passengerEmail: passengerEmail ?? this.passengerEmail,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      identificationNumber: identificationNumber ?? this.identificationNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      status: status ?? this.status,
    );
  }

  factory BookingDraft.fromApiJson(Map<String, dynamic> json) {
    final scheduleValue = json['schedule'] ?? json['trip'];
    final schedule = scheduleValue is Map
        ? Map<String, dynamic>.from(scheduleValue)
        : json;
    final selectedSeats = _apiSeats(
      json['selectedSeats'] ?? json['seatNumbers'] ?? json['seats'],
    );
    final trip = Trip.fromApiJson(schedule);
    final snapshot = trip.copyWith(
      bookedSeats: trip.bookedSeats
          .where((seat) => !selectedSeats.contains(seat))
          .toList(),
    );
    final passenger = json['passenger'] is Map
        ? Map<String, dynamic>.from(json['passenger'] as Map)
        : const <String, dynamic>{};
    final payment = json['payment'] is Map
        ? Map<String, dynamic>.from(json['payment'] as Map)
        : const <String, dynamic>{};
    final reference =
        (json['reference'] ?? json['bookingReference'] ?? json['id'])
            ?.toString();
    if (reference == null ||
        reference.trim().isEmpty ||
        selectedSeats.isEmpty) {
      throw const FormatException('The API returned an invalid booking.');
    }

    return BookingDraft(
      trip: snapshot,
      reference: reference,
      selectedSeats: selectedSeats,
      passengerName: _apiString([json['passengerName'], passenger['name']]),
      passengerEmail: _apiString([json['passengerEmail'], passenger['email']]),
      phoneNumber: _apiString([
        json['phoneNumber'],
        passenger['phone'],
        passenger['phoneNumber'],
      ]),
      identificationNumber: _apiString([
        json['identificationNumber'],
        passenger['identificationNumber'],
      ]),
      paymentMethod: _apiString([json['paymentMethod'], payment['method']]),
      paymentReference: _apiString([
        json['paymentReference'],
        payment['reference'],
      ]),
      status: _apiStatus(json['status'] ?? json['bookingStatus']),
    );
  }

  static List<int> _apiSeats(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((seat) {
          if (seat is Map) {
            seat = seat['seatNumber'] ?? seat['number'] ?? seat['seat'];
          }
          return seat is num
              ? seat.toInt()
              : int.tryParse(seat?.toString() ?? '');
        })
        .whereType<int>()
        .toSet()
        .toList();
  }

  static String _apiString(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static BookingStatus _apiStatus(dynamic value) {
    final status = value?.toString().trim().toLowerCase();
    return switch (status) {
      'draft' || 'pending' || 'created' => BookingStatus.draft,
      'reviewed' ||
      'awaiting_payment' ||
      'awaiting payment' => BookingStatus.reviewed,
      'paid' || 'payment_received' => BookingStatus.paid,
      'confirmed' || 'complete' || 'completed' => BookingStatus.confirmed,
      'cancelled' || 'canceled' => BookingStatus.cancelled,
      _ => throw const FormatException(
        'The API returned an invalid booking status.',
      ),
    };
  }
}
