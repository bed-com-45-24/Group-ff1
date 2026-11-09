class Trip {
  static const int busSeatCapacity = 42;

  final String id;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double fare;
  final double? mapDistanceMeters;
  final bool fareIsEstimate;
  final int totalSeats;
  final List<int> bookedSeats;
  final String transportMode;
  final String operatorName;
  final String routeName;
  final String vehicleName;

  const Trip({
    required this.id,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.fare,
    this.mapDistanceMeters,
    this.fareIsEstimate = false,
    required this.totalSeats,
    this.bookedSeats = const [],
    this.transportMode = 'Bus',
    this.operatorName = 'MOVA Transport',
    this.routeName = '',
    this.vehicleName = '',
  });

  int get availableSeats => totalSeats - bookedSeats.length;

  Trip copyWith({
    String? origin,
    String? destination,
    DateTime? departureTime,
    DateTime? arrivalTime,
    double? fare,
    double? mapDistanceMeters,
    bool? fareIsEstimate,
    int? totalSeats,
    List<int>? bookedSeats,
    String? transportMode,
    String? operatorName,
    String? routeName,
    String? vehicleName,
  }) {
    return Trip(
      id: id,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      fare: fare ?? this.fare,
      mapDistanceMeters: mapDistanceMeters ?? this.mapDistanceMeters,
      fareIsEstimate: fareIsEstimate ?? this.fareIsEstimate,
      totalSeats: totalSeats ?? this.totalSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      transportMode: transportMode ?? this.transportMode,
      operatorName: operatorName ?? this.operatorName,
      routeName: routeName ?? this.routeName,
      vehicleName: vehicleName ?? this.vehicleName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'origin': origin,
    'destination': destination,
    'departureTime': departureTime.toIso8601String(),
    'arrivalTime': arrivalTime.toIso8601String(),
    'fare': fare,
    'mapDistanceMeters': mapDistanceMeters,
    'fareIsEstimate': fareIsEstimate,
    'totalSeats': totalSeats,
    'bookedSeats': bookedSeats,
    'transportMode': transportMode,
    'operatorName': operatorName,
    'routeName': routeName,
    'vehicleName': vehicleName,
  };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'] as String,
    origin: json['origin'] as String,
    destination: json['destination'] as String,
    departureTime: DateTime.parse(json['departureTime'] as String),
    arrivalTime: DateTime.parse(json['arrivalTime'] as String),
    fare: (json['fare'] as num).toDouble(),
    mapDistanceMeters: (json['mapDistanceMeters'] as num?)?.toDouble(),
    fareIsEstimate: json['fareIsEstimate'] as bool? ?? false,
    totalSeats: json['totalSeats'] as int,
    bookedSeats: (json['bookedSeats'] as List<dynamic>? ?? const [])
        .cast<int>(),
    transportMode: json['transportMode'] as String? ?? 'Bus',
    operatorName: json['operatorName'] as String? ?? 'MOVA Transport',
    routeName: json['routeName'] as String? ?? '',
    vehicleName: json['vehicleName'] as String? ?? '',
  );
}
