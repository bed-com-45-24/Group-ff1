import '../models/route_model.dart';
import '../models/trip_model.dart';

RouteModel _makeRoute(
  String id,
  String origin,
  String destination,
  double fare,
) {
  return RouteModel(
    id: id,
    companyName: 'MOVA',
    name: '$origin - $destination',
    origin: origin,
    destination: destination,
    stops: [origin, destination],
    fare: fare,
  );
}

final List<RouteModel> sampleRoutes = [
  // Fares from Blantyre
  _makeRoute('R001', 'Blantyre', 'Ntcheu', 60000),
  _makeRoute('R002', 'Blantyre', 'Lilongwe', 75000),
  _makeRoute('R003', 'Blantyre', 'Kasungu', 120000),
  _makeRoute('R004', 'Blantyre', 'Jenda', 130000),
  _makeRoute('R005', 'Blantyre', 'Mzimba/Mzuzu', 140000),

  // Fares from Lilongwe
  _makeRoute('R006', 'Lilongwe', 'Ntcheu', 60000),
  _makeRoute('R007', 'Lilongwe', 'Blantyre', 75000),
  _makeRoute('R008', 'Lilongwe', 'Kasungu', 60000),
  _makeRoute('R009', 'Lilongwe', 'Jenda', 75000),
  _makeRoute('R010', 'Lilongwe', 'Mzimba/Mzuzu', 85000),
  _makeRoute('R011', 'Lilongwe', 'Phwezi', 125000),
  _makeRoute('R012', 'Lilongwe', 'Uliwa/Chitimba', 135000),
  _makeRoute('R013', 'Lilongwe', 'Karonga', 140000),

  // Fares from Mzuzu
  _makeRoute('R014', 'Mzuzu', 'Mzimba', 55000),
  _makeRoute('R015', 'Mzuzu', 'Jenda', 65000),
  _makeRoute('R016', 'Mzuzu', 'Kasungu', 75000),
  _makeRoute('R017', 'Mzuzu', 'Lilongwe', 85000),
  _makeRoute('R018', 'Mzuzu', 'Ntcheu', 130000),
  _makeRoute('R019', 'Mzuzu', 'Blantyre', 140000),
  _makeRoute('R020', 'Mzuzu', 'Phwezi', 55000),
  _makeRoute('R021', 'Mzuzu', 'Uliwa/Chitimba', 65000),
  _makeRoute('R022', 'Mzuzu', 'Karonga', 75000),

  // Fares from Karonga
  _makeRoute('R023', 'Karonga', 'Uliwa', 45000),
  _makeRoute('R024', 'Karonga', 'Phwezi', 60000),
  _makeRoute('R025', 'Karonga', 'Mzuzu', 70000),
  _makeRoute('R026', 'Karonga', 'Mzimba T/OFF', 100000),
  _makeRoute('R027', 'Karonga', 'Jenda', 120000),
  _makeRoute('R028', 'Karonga', 'Kasungu', 130000),
  _makeRoute('R029', 'Karonga', 'Lilongwe', 140000),
];

const double returnTicketDiscount = 10000;

const List<String> sampleNotifications = [
  'Welcome to MOVA.',
  'Check your selected journey and fare before booking.',
  'Confirm the applicable fare and schedule with the transport operator '
      'before travelling.',
];

final List<Trip> sampleTrips = [
  Trip(
    id: 'TRIP001',
    origin: 'Lilongwe',
    destination: 'Blantyre',
    departureTime: DateTime(2026, 11, 1, 7, 0),
    arrivalTime: DateTime(2026, 11, 1, 12, 0),
    fare: 25000,
    totalSeats: 40,
    bookedSeats: [3, 7, 12],
    transportMode: 'Bus',
    operatorName: 'MOVA Express',
  ),
  Trip(
    id: 'TRIP002',
    origin: 'Lilongwe',
    destination: 'Mzuzu',
    departureTime: DateTime(2026, 11, 1, 8, 30),
    arrivalTime: DateTime(2026, 11, 1, 13, 0),
    fare: 18000,
    totalSeats: 32,
    bookedSeats: [2, 5, 9],
    transportMode: 'Bus',
    operatorName: 'Northern Express',
  ),
  Trip(
    id: 'TRIP003',
    origin: 'Blantyre',
    destination: 'Lilongwe',
    departureTime: DateTime(2026, 11, 1, 6, 0),
    arrivalTime: DateTime(2026, 11, 1, 11, 0),
    fare: 25000,
    totalSeats: 40,
    bookedSeats: [1, 4, 10],
    transportMode: 'Bus',
    operatorName: 'MOVA Express',
  ),
];
