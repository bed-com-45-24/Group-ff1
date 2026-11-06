import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/route_model.dart';
import 'sample_data.dart';

class RouteStore {
  RouteStore._();

  static final RouteStore instance = RouteStore._();
  static const _storageKey = 'admin_routes_v1';

  final ValueNotifier<int> changes = ValueNotifier(0);
  List<RouteModel> _routes = List.of(sampleRoutes);
  bool _loaded = false;
  Future<void>? _loadFuture;

  List<RouteModel> get routes => List.unmodifiable(_routes);
  bool get isLoaded => _loaded;

  Future<void> load() {
    if (_loaded) return Future<void>.value();
    return _loadFuture ??= _load().catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      _loadFuture = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      final values = jsonDecode(stored) as List<dynamic>;
      _routes = values
          .map((value) => RouteModel.fromJson(value as Map<String, dynamic>))
          .toList();
    } else {
      await _persist(preferences: prefs);
    }
    _loaded = true;
    changes.value++;
  }

  Future<void> saveRoute(RouteModel route) async {
    await load();
    final index = _routes.indexWhere((item) => item.id == route.id);
    final updatedRoutes = index == -1
        ? [..._routes, route]
        : [
            for (var i = 0; i < _routes.length; i++)
              if (i == index) route else _routes[i],
          ];
    await _persist(routes: updatedRoutes);
    _routes = updatedRoutes;
    changes.value++;
  }

  Future<void> removeRoute(String id) async {
    await load();
    final updatedRoutes = _routes.where((route) => route.id != id).toList();
    await _persist(routes: updatedRoutes);
    _routes = updatedRoutes;
    changes.value++;
  }

  Future<void> _persist({
    SharedPreferences? preferences,
    List<RouteModel>? routes,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _storageKey,
      jsonEncode((routes ?? _routes).map((route) => route.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Routes could not be saved on this device.');
    }
  }

  List<RouteModel> searchRoutes({String origin = '', String destination = ''}) {
    final normalizedOrigin = _normalize(origin);
    final normalizedDestination = _normalize(destination);
    if (normalizedOrigin.isEmpty && normalizedDestination.isEmpty) {
      return const [];
    }

    return _routes.where((route) {
      if (!route.active) return false;
      final pickupPoints = [route.origin, route.pickupPoint, ...route.stops];
      final dropOffPoints = [route.destination, ...route.stops];
      if (!_matchesAny(pickupPoints, normalizedOrigin) ||
          !_matchesAny(dropOffPoints, normalizedDestination)) {
        return false;
      }

      if (normalizedOrigin.isEmpty || normalizedDestination.isEmpty) {
        return true;
      }
      final journeyPoints = [route.origin, ...route.stops, route.destination]
          .where((point) => point.trim().isNotEmpty)
          .toList();
      final departureIndex = _matchingLocationIndex(
        journeyPoints,
        normalizedOrigin,
      );
      final destinationIndex = _matchingLocationIndex(
        journeyPoints,
        normalizedDestination,
      );
      if (departureIndex == -1 || destinationIndex == -1) return true;
      return departureIndex <= destinationIndex;
    }).toList();
  }

  int _matchingLocationIndex(List<String> locations, String query) {
    for (var index = 0; index < locations.length; index++) {
      if (_matchesEndpoint(locations[index], query)) return index;
    }
    return -1;
  }

  bool _matchesAny(List<String> locations, String query) {
    if (query.isEmpty) return true;
    return locations.any((location) => _matchesEndpoint(location, query));
  }

  String _normalize(String value) {
    final normalized =
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    const aliases = {
      'brantyre': 'blantyre',
      'blantyrecity': 'blantyre',
      'lilongwecitycentre': 'lilongwe',
    };
    return aliases[normalized] ?? normalized;
  }

  bool _matchesEndpoint(String endpoint, String query) {
    if (query.isEmpty) return true;
    final normalizedEndpoint = _normalize(endpoint);
    return normalizedEndpoint.contains(query) ||
        query.contains(normalizedEndpoint);
  }
}
