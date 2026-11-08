import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/osm_route_model.dart';
import 'location_service.dart';

class OpenStreetMapService {
  static const _headers = {
    'User-Agent': 'MOVAFlutterApp/1.0 (route planner)',
    'Accept': 'application/json',
  };

  Future<LatLng> findPlace(String query) async {
    final response = await http
        .get(
          Uri.https('nominatim.openstreetmap.org', '/search', {
            'q': query,
            'format': 'jsonv2',
            'limit': '1',
            'countrycodes': 'mw',
          }),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Place search failed (${response.statusCode}).');
    }

    final results = jsonDecode(response.body) as List<dynamic>;
    if (results.isEmpty) {
      throw Exception(
        'Could not find "$query". Try a nearby town or landmark.',
      );
    }
    final place = results.first as Map<String, dynamic>;
    return LatLng(
      double.parse(place['lat'] as String),
      double.parse(place['lon'] as String),
    );
  }

  Future<List<OsmRouteModel>> findRoutesBetweenPlaces({
    required String origin,
    required String destination,
  }) async {
    final originPoint = await findPlace(origin);
    await Future<void>.delayed(const Duration(seconds: 1));
    final destinationPoint = await findPlace(destination);
    return findRoutes(origin: originPoint, destination: destinationPoint);
  }

  Future<LatLng> currentPosition() async {
    final position = await LocationService().getCurrentPosition();
    if (position == null) {
      throw Exception(
        'Device location is unavailable. Check location services and '
        'permissions, or enter a starting location instead.',
      );
    }
    return LatLng(position.latitude, position.longitude);
  }

  Future<List<OsmRouteModel>> findRoutes({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final coordinates =
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';
    final response = await http
        .get(
          Uri.https(
            'router.project-osrm.org',
            '/route/v1/driving/$coordinates',
            {
              'alternatives': 'true',
              'overview': 'full',
              'geometries': 'geojson',
              'steps': 'true',
            },
          ),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Route search failed (${response.statusCode}).');
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    if (result['code'] != 'Ok') {
      throw Exception(
        result['message']?.toString() ?? 'No drivable routes were found.',
      );
    }
    final routes = result['routes'] as List<dynamic>;
    if (routes.isEmpty) {
      throw Exception('No routes were found between those locations.');
    }
    return routes
        .asMap()
        .entries
        .map(
          (entry) => OsmRouteModel.fromJson(
            entry.value as Map<String, dynamic>,
            entry.key,
          ),
        )
        .toList();
  }
}
