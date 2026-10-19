import 'package:latlong2/latlong.dart';

class OsmRouteModel {
  final String id;
  final Map<String, dynamic> geoJson;
  final double distanceMeters;
  final double durationSeconds;
  final List<String> steps;

  const OsmRouteModel({
    required this.id,
    required this.geoJson,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
  });

  List<LatLng> get points {
    final coordinates = geoJson['coordinates'] as List<dynamic>;
    return coordinates.map((coordinate) {
      final pair = coordinate as List<dynamic>;
      return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
    }).toList();
  }

  String get distanceLabel => distanceMeters >= 1000
      ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
      : '${distanceMeters.round()} m';

  String get durationLabel {
    final minutes = (durationSeconds / 60).round();
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return hours == 0 ? '$minutes min' : '${hours}h ${remainingMinutes}m';
  }

  factory OsmRouteModel.fromJson(Map<String, dynamic> json, int index) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final legs = json['legs'] as List<dynamic>;
    final steps = legs
        .expand(
          (leg) => (leg as Map<String, dynamic>)['steps'] as List<dynamic>,
        )
        .map((step) {
          final stepData = step as Map<String, dynamic>;
          final maneuver = stepData['maneuver'] as Map<String, dynamic>;
          final modifier = maneuver['modifier']?.toString();
          final type = maneuver['type']?.toString() ?? 'Continue';
          final road = stepData['name']?.toString() ?? '';
          final action = modifier == null ? type : '$type $modifier';
          final instruction = road.isEmpty ? action : '$action onto $road';
          final distance = (stepData['distance'] as num?)?.toDouble();
          if (distance == null || distance == 0) return instruction;
          final distanceText = distance >= 1000
              ? '${(distance / 1000).toStringAsFixed(1)} km'
              : '${distance.round()} m';
          return '$instruction · $distanceText';
        })
        .toList();

    return OsmRouteModel(
      id: 'route-${index + 1}',
      geoJson: geometry,
      distanceMeters: (json['distance'] as num).toDouble(),
      durationSeconds: (json['duration'] as num).toDouble(),
      steps: steps,
    );
  }
}
