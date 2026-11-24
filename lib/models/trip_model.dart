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

  factory Trip.fromApiJson(Map<String, dynamic> json) {
    final route = _apiMap(json['route']);
    final origin = _apiString([
      json['origin'],
      json['originStop'],
      route['origin'],
      route['originStop'],
    ]);
    final destination = _apiString([
      json['destination'],
      json['destinationStop'],
      route['destination'],
      route['destinationStop'],
    ]);
    final id = (json['id'] ?? json['scheduleId'])?.toString() ?? '';
    final departureTime = _apiDateTime(
      json['departureTime'] ?? json['departureAt'],
      json['departureDate'],
    );
    final arrivalTime = _apiDateTime(
      json['arrivalTime'] ?? json['arrivalAt'],
      json['arrivalDate'],
    );
    final fareValue = json['fare'] ?? json['fareAmount'] ?? json['price'];
    final fare = _apiNumber(fareValue is Map ? fareValue['amount'] : fareValue);
    if (id.isEmpty || origin.isEmpty || destination.isEmpty || fare == null) {
      throw const FormatException('The API returned an invalid schedule.');
    }

    return Trip(
      id: id,
      origin: origin,
      destination: destination,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      fare: fare,
      totalSeats: busSeatCapacity,
      bookedSeats: _apiSeats(
        json['bookedSeats'] ?? json['occupiedSeats'] ?? json['seats'],
      ),
      transportMode: _apiString([
        json['transportMode'],
        json['vehicleType'],
        'Bus',
      ]),
      operatorName: _apiString([
        json['operatorName'],
        json['companyName'],
        json['operator'],
      ]),
      routeName: _apiString([
        json['routeName'],
        json['roadName'],
        json['road'],
        route['roadName'],
      ]),
      vehicleName: _apiString([
        json['vehicleName'],
        json['vehicleIdentifier'],
        _apiMap(json['vehicle'])['name'],
        _apiMap(json['vehicle'])['registrationNumber'],
      ]),
    );
  }

  static Map<String, dynamic> _apiMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static String _apiString(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is Map) {
        final name = value['name'] ?? value['label'];
        if (name != null && name.toString().trim().isNotEmpty) {
          return name.toString().trim();
        }
      }
    }
    return '';
  }

  static double? _apiNumber(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');

  static DateTime _apiDateTime(dynamic value, dynamic date) {
    final text = value?.toString();
    final parsed = text == null ? null : DateTime.tryParse(text);
    if (parsed != null) return parsed;
    final dateText = date?.toString();
    if (dateText != null && text != null) {
      final withDate = DateTime.tryParse('${dateText}T$text');
      if (withDate != null) return withDate;
    }
    throw const FormatException('The API returned an invalid schedule time.');
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
}
