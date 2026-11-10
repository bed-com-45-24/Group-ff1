import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/route_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'sample_data.dart';

class RouteStore {
  RouteStore._({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.instance;

  static final RouteStore instance = RouteStore._();
  RouteStore.forApi({required ApiClient apiClient})
    : _api = apiClient,
      _backendEnabled = true {
    _routes = [];
  }

  static const _storageKey = 'admin_routes_v1';

  final ApiClient _api;
  final ValueNotifier<int> changes = ValueNotifier(0);
  List<RouteModel> _routes = List.of(sampleRoutes);
  bool _backendEnabled = false;
  bool _loaded = false;
  Future<void>? _loadFuture;

  List<RouteModel> get routes => List.unmodifiable(_routes);
  bool get isLoaded => _loaded;

  void enableBackend() {
    if (_backendEnabled) return;
    _backendEnabled = true;
    _routes = [];
    _loaded = false;
    _loadFuture = null;
  }

  Future<void> load({bool refresh = false}) {
    if (_loaded && (!refresh || !_backendEnabled)) {
      return Future<void>.value();
    }
    return _loadFuture ??= _load().whenComplete(() => _loadFuture = null);
  }

  Future<void> _load() async {
    if (!_backendEnabled) {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_storageKey);
      if (stored != null) {
        final values = jsonDecode(stored) as List<dynamic>;
        _routes = values
            .map((value) => RouteModel.fromJson(value as Map<String, dynamic>))
            .toList();
      } else {
        await _persist(preferences: preferences);
      }
      _loaded = true;
      changes.value++;
      return;
    }

    final token = await _api.accessToken;
    final role = token == null
        ? null
        : await AuthService(apiClient: _api).getUserRole();
    final response = await _api.get(
      role == 'admin' ? 'routes/admin/list' : 'routes',
      authenticated: role == 'admin',
    );
    final values = _listResponse(response, 'routes');
    _routes = values
        .map(
          (value) =>
              RouteModel.fromApiJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
    _loaded = true;
    changes.value++;
  }

  Future<void> saveRoute(RouteModel route) async {
    await load();
    if (!_backendEnabled) {
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
      return;
    }

    final existing = _routes.any((item) => item.id == route.id);
    final savedRoute = existing
        ? await _updateRoute(route, route.id)
        : await _createRoute(route);
    final index = _routes.indexWhere((item) => item.id == savedRoute.id);
    _routes = index == -1
        ? [..._routes, savedRoute]
        : [
            for (var i = 0; i < _routes.length; i++)
              if (i == index) savedRoute else _routes[i],
          ];
    changes.value++;
  }

  Future<RouteModel> _createRoute(RouteModel route) async {
    final stopIds = await _resolveStopIds(route.stops);
    final response = await _api.post(
      'routes',
      body: {
        'name': route.name,
        'roadName': route.roadName,
        'originStopId': stopIds.first,
        'destinationStopId': stopIds.last,
        'intermediateStopIds': stopIds
            .skip(1)
            .take(stopIds.length - 2)
            .toList(),
        'companyName': route.companyName,
        'pickupLocation': route.pickupPoint,
        'dropOffLocation': route.dropOffPoint,
        'departureTimes': route.departureTimes,
        'isActive': route.active,
        if (route.duration != null) 'duration': route.duration,
        if (route.transfers != null) 'transfers': route.transfers,
        if (route.mapDistance != null)
          'distance': double.tryParse(route.mapDistance!),
        'featured': false,
      },
    );
    final result = _mapResponse(response, 'created route');
    final created = RouteModel.fromApiJson(result);
    if (route.fare > 0) {
      await _api.post(
        'routes/${created.id}/fares',
        body: {
          'originStopId': stopIds.first,
          'destinationStopId': stopIds.last,
          'amount': route.fare,
          'currency': 'MWK',
        },
      );
    }
    return created.copyWith(
      roadName: route.roadName,
      fare: route.fare,
      dropOffLocation: route.dropOffLocation,
    );
  }

  Future<RouteModel> _updateRoute(RouteModel route, String routeId) async {
    final oldRoute = _routes.where((item) => item.id == route.id).firstOrNull;
    final payload = <String, dynamic>{
      'name': route.name,
      'roadName': route.roadName,
      'companyName': route.companyName,
      'pickupLocation': route.pickupPoint,
      'dropOffLocation': route.dropOffPoint,
      'departureTimes': route.departureTimes,
      'isActive': route.active,
      if (route.duration != null) 'duration': route.duration,
      if (route.transfers != null) 'transfers': route.transfers,
    };
    if (route.mapDistance != null) {
      payload['distance'] = double.tryParse(route.mapDistance!);
    }
    final encodedId = Uri.encodeComponent(routeId);
    final response = await _api.patch('routes/$encodedId', body: payload);
    final updated = RouteModel.fromApiJson(_mapResponse(response, 'route'));

    if (oldRoute == null || !_sameStops(oldRoute.stops, route.stops)) {
      final stopIds = await _resolveStopIds(route.stops);
      await _api.patch('routes/$encodedId/stops', body: {'stopIds': stopIds});
    }
    if (oldRoute == null || oldRoute.fare != route.fare) {
      await _api.patch(
        'routes/$encodedId/fare',
        body: {'amount': route.fare, 'currency': 'MWK'},
      );
    }
    return updated.copyWith(
      roadName: route.roadName,
      dropOffLocation: route.dropOffLocation,
      fare: route.fare,
      active: route.active,
      stops: route.stops,
    );
  }

  Future<List<int>> _resolveStopIds(List<String> stopNames) async {
    if (stopNames.length < 2) {
      throw ArgumentError('A route needs an origin and destination stop.');
    }
    final stopIds = <int>[];
    for (final name in stopNames) {
      final response = await _api.get(
        'stops/places/search',
        query: {'q': name, 'limit': '8'},
        authenticated: false,
      );
      final stops = _listResponse(response, 'stop search results');
      final normalizedName = _normalize(name);
      Map? match;
      for (final stop in stops) {
        if (stop is Map &&
            _normalize(stop['name']?.toString() ?? '') == normalizedName) {
          match = stop;
          break;
        }
      }
      if (match == null) {
        throw StateError('The backend could not resolve the stop "$name".');
      }
      final id = int.tryParse(match['id']?.toString() ?? '');
      if (id == null) {
        throw StateError('The backend could not resolve the stop "$name".');
      }
      stopIds.add(id);
    }
    return stopIds;
  }

  Future<void> removeRoute(String id) async {
    await load();
    if (!_backendEnabled) {
      final updatedRoutes = _routes.where((route) => route.id != id).toList();
      await _persist(routes: updatedRoutes);
      _routes = updatedRoutes;
      changes.value++;
      return;
    }

    await _api.delete('routes/${Uri.encodeComponent(id)}');
    _routes = _routes.where((route) => route.id != id).toList();
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
      return _matchesEndpoint(route.origin, normalizedOrigin) &&
          _matchesEndpoint(route.destination, normalizedDestination);
    }).toList();
  }

  List<dynamic> _listResponse(dynamic response, String name) {
    if (response is List) return response;
    if (response is Map) {
      final data = response['data'] ?? response['items'] ?? response['results'];
      if (data is List) return data;
      if (data is Map && data['routes'] is List) return data['routes'] as List;
    }
    throw FormatException('The API returned an invalid $name response.');
  }

  Map<String, dynamic> _mapResponse(dynamic response, String name) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map) {
        final route = data['route'];
        if (route is Map) return Map<String, dynamic>.from(route);
        return Map<String, dynamic>.from(data);
      }
      return response;
    }
    throw FormatException('The API returned an invalid $name response.');
  }

  bool _sameStops(List<String> first, List<String> second) =>
      first.length == second.length &&
      List.generate(
        first.length,
        (index) => index,
      ).every((index) => _normalize(first[index]) == _normalize(second[index]));

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  bool _matchesEndpoint(String endpoint, String query) {
    if (query.isEmpty) return true;
    final normalizedEndpoint = _normalize(endpoint);
    return normalizedEndpoint.contains(query) ||
        query.contains(normalizedEndpoint);
  }
}
