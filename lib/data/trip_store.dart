import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_model.dart';
import 'sample_data.dart';

class TripStore {
  TripStore._();

  static final TripStore instance = TripStore._();
  static const _storageKey = 'admin_trips_v1';
  static const _adminSeat = 2;
  static const _demoAvailableSeats = {1, 4, 10};

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
      var tripsUpdated = false;
      _trips = values.map((value) {
        final trip = Trip.fromJson(value as Map<String, dynamic>);
        final bookedSeats = trip.bookedSeats;
        final seatsToClear = <int>{
          _adminSeat,
          if (trip.id == 'TRIP003') ..._demoAvailableSeats,
        };
        final cleanedBookedSeats = bookedSeats
            .where((seat) => !seatsToClear.contains(seat))
            .toList();
        if (trip.totalSeats != Trip.busSeatCapacity ||
            cleanedBookedSeats.length != bookedSeats.length) {
          tripsUpdated = true;
          return trip.copyWith(
            totalSeats: Trip.busSeatCapacity,
            bookedSeats: cleanedBookedSeats,
          );
        }
        return trip;
      }).toList();
      if (tripsUpdated) await _writeTrips(_trips, prefs);
    } else {
      await _writeTrips(_trips, prefs);
    }
    _loaded = true;
    changes.value++;
  }

  Future<void> saveTrip(Trip trip) async {
    await load();
    final normalizedTrip = trip.copyWith(totalSeats: Trip.busSeatCapacity);
    final index = _trips.indexWhere((item) => item.id == normalizedTrip.id);
    final updatedTrips = index == -1
        ? [..._trips, normalizedTrip]
        : [
            for (var i = 0; i < _trips.length; i++)
              if (i == index) normalizedTrip else _trips[i],
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
