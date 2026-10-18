
class Trip {
  final String id;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double fare;
  final int totalSeats;
  final List<int> bookedSeats;
  final String transportMode;
  final String operatorName;

  const Trip({
    required this.id,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.fare,
    required this.totalSeats,
    this.bookedSeats = const [],
    this.transportMode = 'Bus',
    this.operatorName = 'MOVA Transport',
  });

  int get availableSeats => totalSeats - bookedSeats.length;
}
