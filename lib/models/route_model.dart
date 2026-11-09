class RouteModel {
  final String id;
  final String companyName;
  final String name;
  final String origin;
  final String destination;
  final String roadName;
  final String? pickupLocation;
  final String? dropOffLocation;
  final List<String> stops;
  final double fare;
  final String? duration;
  final String? mapDistance;
  final int? transfers;
  final List<String> departureTimes;
  final bool fareIsEstimate;
  final bool active;

  const RouteModel({
    required this.id,
    required this.companyName,
    required this.name,
    required this.origin,
    required this.destination,
    this.roadName = '',
    this.pickupLocation,
    this.dropOffLocation,
    required this.stops,
    required this.fare,
    this.duration,
    this.mapDistance,
    this.transfers,
    this.departureTimes = const [],
    this.fareIsEstimate = false,
    this.active = true,
  });

  String get pickupPoint {
    final savedPickup = pickupLocation?.trim();
    if (savedPickup != null && savedPickup.isNotEmpty) return savedPickup;
    return RegExp(r'\bdepot\b', caseSensitive: false).hasMatch(origin)
        ? origin.trim()
        : origin.trim();
  }

  String get dropOffPoint {
    final savedDropOff = dropOffLocation?.trim();
    if (savedDropOff != null && savedDropOff.isNotEmpty) return savedDropOff;
    return RegExp(r'\bdepot\b', caseSensitive: false).hasMatch(destination)
        ? destination.trim()
        : destination.trim();
  }

  RouteModel copyWith({
    String? companyName,
    String? name,
    String? origin,
    String? destination,
    String? roadName,
    String? pickupLocation,
    String? dropOffLocation,
    List<String>? stops,
    double? fare,
    String? duration,
    String? mapDistance,
    int? transfers,
    List<String>? departureTimes,
    bool? fareIsEstimate,
    bool? active,
  }) {
    return RouteModel(
      id: id,
      companyName: companyName ?? this.companyName,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      roadName: roadName ?? this.roadName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropOffLocation: dropOffLocation ?? this.dropOffLocation,
      stops: stops ?? this.stops,
      fare: fare ?? this.fare,
      duration: duration ?? this.duration,
      mapDistance: mapDistance ?? this.mapDistance,
      transfers: transfers ?? this.transfers,
      departureTimes: departureTimes ?? this.departureTimes,
      fareIsEstimate: fareIsEstimate ?? this.fareIsEstimate,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyName': companyName,
    'name': name,
    'origin': origin,
    'destination': destination,
    'roadName': roadName,
    'pickupLocation': pickupLocation,
    'dropOffLocation': dropOffLocation,
    'stops': stops,
    'fare': fare,
    'duration': duration,
    'mapDistance': mapDistance,
    'transfers': transfers,
    'departureTimes': departureTimes,
    'fareIsEstimate': fareIsEstimate,
    'active': active,
  };

  factory RouteModel.fromJson(Map<String, dynamic> json) => RouteModel(
    id: json['id'] as String,
    companyName: json['companyName'] as String,
    name: json['name'] as String,
    origin: json['origin'] as String,
    destination: json['destination'] as String,
    roadName: json['roadName'] as String? ?? '',
    pickupLocation: json['pickupLocation'] as String?,
    dropOffLocation: json['dropOffLocation'] as String?,
    stops: (json['stops'] as List<dynamic>).cast<String>(),
    fare: (json['fare'] as num).toDouble(),
    duration: json['duration'] as String?,
    mapDistance: json['mapDistance'] as String?,
    transfers: json['transfers'] as int?,
    departureTimes: (json['departureTimes'] as List<dynamic>? ?? const [])
        .cast<String>(),
    fareIsEstimate: json['fareIsEstimate'] as bool? ?? false,
    active: json['active'] as bool? ?? true,
  );
}
