class RouteModel {
  final String id;
  final String companyName;
  final String name;
  final String origin;
  final String destination;
  final String? pickupLocation;
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
    this.pickupLocation,
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
        : '${origin.trim()} Depot';
  }

  String get dropOffPoint => destination;

  RouteModel copyWith({
    String? companyName,
    String? name,
    String? origin,
    String? destination,
    String? pickupLocation,
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
      pickupLocation: pickupLocation ?? this.pickupLocation,
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
    'pickupLocation': pickupLocation,
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
    pickupLocation: json['pickupLocation'] as String?,
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
