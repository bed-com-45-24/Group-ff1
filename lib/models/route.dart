class MovaRoute {
  final String id;
  final String name;
  final int fare;
  final List<String> stops;
  final String duration;

  MovaRoute({
    required this.id,
    required this.name,
    required this.fare,
    required this.stops,
    required this.duration,
  });
}