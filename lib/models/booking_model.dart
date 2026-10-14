
import 'trip_model.dart';

class BookingDraft {
  final Trip trip;
  final String reference;
  List<int> selectedSeats;
  String passengerName;
  String phoneNumber;
  String identificationNumber;
  String paymentMethod;
  String paymentReference;
  bool paid;
  bool cancelled;

  BookingDraft({
    required this.trip,
    required this.reference,
    this.selectedSeats = const [],
    this.passengerName = '',
    this.phoneNumber = '',
    this.identificationNumber = '',
    this.paymentMethod = '',
    this.paymentReference = '',
    this.paid = false,
    this.cancelled = false,
  });

  double get total => trip.fare * selectedSeats.length;
}
