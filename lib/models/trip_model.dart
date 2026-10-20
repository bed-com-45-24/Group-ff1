
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

  Trip copyWith({
    String? origin,
    String? destination,
    DateTime? departureTime,
    DateTime? arrivalTime,
    double? fare,
    int? totalSeats,
    List<int>? bookedSeats,
    String? transportMode,
    String? operatorName,
  }) {
    return Trip(
      id: id,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      fare: fare ?? this.fare,
      totalSeats: totalSeats ?? this.totalSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      transportMode: transportMode ?? this.transportMode,
      operatorName: operatorName ?? this.operatorName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'origin': origin,
    'destination': destination,
    'departureTime': departureTime.toIso8601String(),
    'arrivalTime': arrivalTime.toIso8601String(),
    'fare': fare,
    'totalSeats': totalSeats,
    'bookedSeats': bookedSeats,
    'transportMode': transportMode,
    'operatorName': operatorName,
  };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'] as String,
    origin: json['origin'] as String,
    destination: json['destination'] as String,
    departureTime: DateTime.parse(json['departureTime'] as String),
    arrivalTime: DateTime.parse(json['arrivalTime'] as String),
    fare: (json['fare'] as num).toDouble(),
    totalSeats: json['totalSeats'] as int,
    bookedSeats: (json['bookedSeats'] as List<dynamic>? ?? const [])
        .cast<int>(),
    transportMode: json['transportMode'] as String? ?? 'Bus',
    operatorName: json['operatorName'] as String? ?? 'MOVA Transport',
  );
}
