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
    return _defaultDepot(origin);
  }

  String get dropOffPoint {
    final savedDropOff = dropOffLocation?.trim();
    if (savedDropOff != null && savedDropOff.isNotEmpty) return savedDropOff;
    return _defaultDepot(destination);
  }

  static String _defaultDepot(String location) {
    final normalized = location.trim().toLowerCase();
    const depots = {
      'lilongwe': 'Lilongwe Bus Depot',
      'llz': 'Lilongwe Bus Depot',
      'blantyre': 'Wenela Bus Depot',
      'bts': 'Wenela Bus Depot',
      'zomba': 'Zomba Depot',
      'karonga': 'Karonga Depot',
      'mzuzu': 'Mzuzu Depot',
      'mangochi': 'Mangochi Depot',
      'kasungu': 'Kasungu Depot',
      'salima': 'Salima Depot',
      'dedza': 'Dedza Depot',
      'ntcheu': 'Ntcheu Depot',
      'balaka': 'Balaka Depot',
      'liwonde': 'Liwonde Depot',
      'mulanje': 'Mulanje Depot',
      'thyolo': 'Thyolo Depot',
      'mzimba': 'Mzimba Depot',
      'nkhata bay': 'Nkhata Bay Depot',
    };
    return depots[normalized] ?? location.trim();
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

  factory RouteModel.fromApiJson(Map<String, dynamic> json) {
    final routeStops = json['routeStops'] ?? json['stops'];
    final stops = routeStops is List
        ? routeStops.map(_apiStopName).where((name) => name.isNotEmpty).toList()
        : <String>[];
    final name = json['name']?.toString() ?? '';
    final endpoints = name.split(
      RegExp(r'\s+(?:to|[-–])\s+', caseSensitive: false),
    );
    final apiOrigin = _apiStopName(json['originStop'] ?? json['origin']);
    final origin = apiOrigin.isNotEmpty
        ? apiOrigin
        : stops.firstOrNull ?? (endpoints.isNotEmpty ? endpoints.first : '');
    final apiDestination = _apiStopName(
      json['destinationStop'] ?? json['destination'],
    );
    final destination = apiDestination.isNotEmpty
        ? apiDestination
        : stops.length > 1
        ? stops.last
        : endpoints.length > 1
        ? endpoints.last
        : '';
    if (stops.isEmpty && origin.isNotEmpty && destination.isNotEmpty) {
      stops.addAll([origin, destination]);
    }

    final fares = json['fares'];
    final fareValue =
        json['fareEstimate'] ??
        (fares is List && fares.isNotEmpty && fares.first is Map
            ? (fares.first as Map)['amount']
            : null);
    final parsedFare = double.tryParse(fareValue?.toString() ?? '') ?? 0;
    final rawId = json['id'];
    if (rawId == null || origin.isEmpty || destination.isEmpty) {
      throw const FormatException('The API returned an invalid route.');
    }
    return RouteModel(
      id: rawId.toString(),
      companyName: json['companyName']?.toString() ?? '',
      name: name.isEmpty ? '$origin - $destination' : name,
      origin: origin,
      destination: destination,
      roadName: json['roadName']?.toString() ?? '',
      pickupLocation: json['pickupLocation']?.toString(),
      dropOffLocation: json['dropOffLocation']?.toString(),
      stops: stops,
      fare: parsedFare,
      mapDistance: json['distance']?.toString(),
      transfers: int.tryParse(json['transfers']?.toString() ?? ''),
      departureTimes: (json['departureTimes'] as List? ?? const [])
          .map((time) => time.toString())
          .toList(),
      active: json['active'] as bool? ?? json['isActive'] as bool? ?? true,
    );
  }

  static String _apiStopName(dynamic value) {
    if (value is String) return value.trim();
    if (value is Map) {
      if (value['name'] != null) return value['name'].toString().trim();
      for (final nested in value.values) {
        final name = _apiStopName(nested);
        if (name.isNotEmpty) return name;
      }
    }
    return '';
  }
}
