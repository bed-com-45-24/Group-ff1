import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking_model.dart';
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
    return _loadFuture ??= _load();
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
      await _persist(prefs);
    }
    _loaded = true;
    changes.value++;
  }

  Future<void> saveTrip(Trip trip) async {
    final index = _trips.indexWhere((item) => item.id == trip.id);
    if (index == -1) {
      _trips = [..._trips, trip];
    } else {
      _trips = [
        for (var i = 0; i < _trips.length; i++)
          if (i == index) trip else _trips[i],
      ];
    }
    await _persist();
    changes.value++;
  }

  Future<void> removeTrip(String id) async {
    _trips = _trips.where((trip) => trip.id != id).toList();
    await _persist();
    changes.value++;
  }

  Future<void> markSeatsBooked(BookingDraft booking) async {
    final index = _trips.indexWhere((trip) => trip.id == booking.trip.id);
    if (index == -1) return;
    final trip = _trips[index];
    final seats = {...trip.bookedSeats, ...booking.selectedSeats}.toList()
      ..sort();
    _trips = [
      for (var i = 0; i < _trips.length; i++)
        if (i == index) trip.copyWith(bookedSeats: seats) else _trips[i],
    ];
    await _persist();
    changes.value++;
  }

  Future<void> _persist([SharedPreferences? preferences]) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_trips.map((trip) => trip.toJson()).toList()),
    );
  }
}
