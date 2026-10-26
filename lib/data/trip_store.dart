import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_model.dart';
import 'sample_data.dart';

class TripStore {
  TripStore._();

  static final TripStore instance = TripStore._();
  static const _storageKey = 'admin_trips_v1';

  final ValueNotifier<int> changes = ValueNotifier(0);
  List<Trip> _trips = List.of(sampleTrips);
  bool _loaded = false;
  Future<void>? _loadFuture;

  List<Trip> get trips => List.unmodifiable(_trips);
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
      _trips = values
          .map((value) => Trip.fromJson(value as Map<String, dynamic>))
          .toList();
    } else {
      await _writeTrips(_trips, prefs);
    }
    _loaded = true;
    changes.value++;
  }

  Future<void> saveTrip(Trip trip) async {
    await load();
    final index = _trips.indexWhere((item) => item.id == trip.id);
    final updatedTrips = index == -1
        ? [..._trips, trip]
        : [
            for (var i = 0; i < _trips.length; i++)
              if (i == index) trip else _trips[i],
          ];
    await _writeTrips(updatedTrips);
    _trips = updatedTrips;
    changes.value++;
  }

  Future<void> removeTrip(String id) async {
    await load();
    final updatedTrips = _trips.where((trip) => trip.id != id).toList();
    await _writeTrips(updatedTrips);
    _trips = updatedTrips;
    changes.value++;
  }

  Future<void> _writeTrips(
    List<Trip> trips, [
    SharedPreferences? preferences,
  ]) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _storageKey,
      jsonEncode(trips.map((trip) => trip.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Scheduled trips could not be saved on this device.');
    }
  }
}
