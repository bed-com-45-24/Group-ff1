
import '../models/trip_model.dart';

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
