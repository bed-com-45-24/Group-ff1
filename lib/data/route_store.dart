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
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      final values = jsonDecode(stored) as List<dynamic>;
      _routes = values
          .map(
            (value) =>
                RouteModel.fromJson(value as Map<String, dynamic>),
          )
          .toList();
    } else {
      await _persist(prefs);
    }
    _loaded = true;
    changes.value++;
  }

  Future<void> saveRoute(RouteModel route) async {
    final index = _routes.indexWhere((item) => item.id == route.id);
    print('Saving route: ${route.name}, index: $index');
    if (index == -1) {
      _routes = [..._routes, route];
    } else {
      _routes = [
        for (var i = 0; i < _routes.length; i++)
          if (i == index) route else _routes[i],
      ];
    }
    await _persist();
    print('Route saved: ${route.name}');
    changes.value++;
  }

  Future<void> removeRoute(String id) async {
    _routes = _routes.where((route) => route.id != id).toList();
    await _persist();
    changes.value++;
  }

  Future<void> _persist([SharedPreferences? preferences]) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    print('Persisting routes: ${_routes.length} routes');
    await prefs.setString(
      _storageKey,
      jsonEncode(_routes.map((route) => route.toJson()).toList()),
    );
  }
} 