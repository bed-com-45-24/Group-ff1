import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../models/trip_model.dart';
import 'sample_data.dart';

class TripStore {
  TripStore._({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.instance;

  static final TripStore instance = TripStore._();
  TripStore.forApi({required ApiClient apiClient})
    : _api = apiClient,
      _backendEnabled = true {
    _trips = [];
  }

  static const _storageKey = 'admin_trips_v1';
  static const _adminSeat = 2;
  static const _demoAvailableSeats = {1, 4, 10};

  final ApiClient _api;
  final ValueNotifier<int> changes = ValueNotifier(0);
  List<Trip> _trips = List.of(sampleTrips);
  bool _backendEnabled = false;
  bool _loaded = false;
  Future<void>? _loadFuture;

  List<Trip> get trips => List.unmodifiable(_trips);
  bool get isLoaded => _loaded;

  void enableBackend() {
    if (_backendEnabled) return;
    _backendEnabled = true;
    _trips = [];
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
    if (_backendEnabled) {
      final token = await _api.accessToken;
      final role = token == null
          ? null
          : await AuthService(apiClient: _api).getUserRole();
      final response = await _api.get(
        role == 'admin' ? 'schedules/admin/list' : 'schedules',
        authenticated: role == 'admin',
      );
      final values = _listResponse(response, 'schedules');
      _trips = values
          .map(
            (value) =>
                Trip.fromApiJson(Map<String, dynamic>.from(value as Map)),
          )
          .toList();
      _loaded = true;
      changes.value++;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      final values = jsonDecode(stored) as List<dynamic>;
      var tripsUpdated = false;
      final sampleTripsById = {for (final trip in sampleTrips) trip.id: trip};
      _trips = values.map((value) {
        final trip = Trip.fromJson(value as Map<String, dynamic>);
        final sampleTrip = sampleTripsById[trip.id];
        final refreshSampleTime =
            sampleTrip != null && trip.departureTime.isBefore(DateTime.now());
        final bookedSeats = trip.bookedSeats;
        final seatsToClear = <int>{
          _adminSeat,
          if (trip.id == 'TRIP003') ..._demoAvailableSeats,
        };
        final cleanedBookedSeats = bookedSeats
            .where((seat) => !seatsToClear.contains(seat))
            .toList();
        if (refreshSampleTime ||
            trip.totalSeats != Trip.busSeatCapacity ||
            cleanedBookedSeats.length != bookedSeats.length) {
          tripsUpdated = true;
          return trip.copyWith(
            totalSeats: Trip.busSeatCapacity,
            bookedSeats: cleanedBookedSeats,
            departureTime: refreshSampleTime ? sampleTrip.departureTime : null,
            arrivalTime: refreshSampleTime ? sampleTrip.arrivalTime : null,
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
    if (_backendEnabled) {
      final payload = _apiPayload(normalizedTrip);
      final isNew = !_trips.any((trip) => trip.id == normalizedTrip.id);
      final response = isNew
          ? await _api.post('schedules', body: payload)
          : await _api.patch(
              'schedules/${Uri.encodeComponent(normalizedTrip.id)}',
              body: payload,
            );
      final saved = Trip.fromApiJson({
        ...payload,
        ..._mapResponse(response, 'schedule'),
      });
      _replace(saved);
      return;
    }

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
    if (_backendEnabled) {
      await _api.delete('schedules/${Uri.encodeComponent(id)}');
      _trips = _trips.where((trip) => trip.id != id).toList();
      changes.value++;
      return;
    }

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

  Map<String, dynamic> _apiPayload(Trip trip) => {
    'origin': trip.origin,
    'destination': trip.destination,
    'departureTime': trip.departureTime.toIso8601String(),
    'arrivalTime': trip.arrivalTime.toIso8601String(),
    'fare': trip.fare,
    'currency': 'MWK',
    'totalSeats': Trip.busSeatCapacity,
    'operatorName': trip.operatorName,
    'routeName': trip.routeName,
    'vehicleName': trip.vehicleName,
    'transportMode': trip.transportMode,
  };

  void _replace(Trip trip) {
    final index = _trips.indexWhere((item) => item.id == trip.id);
    _trips = index == -1
        ? [..._trips, trip]
        : [
            for (var i = 0; i < _trips.length; i++)
              if (i == index) trip else _trips[i],
          ];
    changes.value++;
  }

  List<dynamic> _listResponse(dynamic response, String name) {
    if (response is List) return response;
    if (response is Map) {
      final data = response['data'] ?? response['items'] ?? response['results'];
      if (data is List) return data;
      if (data is Map && data['schedules'] is List) {
        return data['schedules'] as List;
      }
    }
    throw FormatException('The API returned an invalid $name response.');
  }

  Map<String, dynamic> _mapResponse(dynamic response, String name) {
    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response['schedule'];
      if (data is Map) {
        final schedule = data['schedule'] ?? data['trip'];
        if (schedule is Map) return Map<String, dynamic>.from(schedule);
        return Map<String, dynamic>.from(data);
      }
      return response;
    }
    throw FormatException('The API returned an invalid $name response.');
  }
}
