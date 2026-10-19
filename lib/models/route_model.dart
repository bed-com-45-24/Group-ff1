class RouteModel {
  final String id;
  final String companyName;
  final String name;
  final String origin;
  final String destination;
  final List<String> stops;
  final double fare;
  final String? duration;
  final int? transfers;
  final List<String> departureTimes;
  final bool fareIsEstimate;

  const RouteModel({
    required this.id,
    required this.companyName,
    required this.name,
    required this.origin,
    required this.destination,
    required this.stops,
    required this.fare,
    this.duration,
    this.transfers,
    this.departureTimes = const [],
    this.fareIsEstimate = false,
  });

  String get pickupPoint => origin;

  String get dropOffPoint => destination;
}
