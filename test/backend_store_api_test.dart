import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mova/data/booking_store.dart';
import 'package:mova/data/route_store.dart';
import 'package:mova/data/trip_store.dart';
import 'package:mova/models/booking_model.dart';
import 'package:mova/models/route_model.dart';
import 'package:mova/models/trip_model.dart';
import 'package:mova/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads public schedules from the configured API', () async {
    SharedPreferences.setMockInitialValues({});
    final requests = <http.Request>[];
    final store = TripStore.forApi(
      apiClient: ApiClient(
        baseUrl: 'https://mova.test/api/v1',
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 42,
                  'origin': 'Lilongwe',
                  'destination': 'Blantyre',
                  'departureTime': '2026-11-10T07:00:00Z',
                  'arrivalTime': '2026-11-10T12:00:00Z',
                  'fare': 25000,
                  'bookedSeats': [3, 7],
                  'operatorName': 'MOVA Express',
                  'routeName': 'M1',
                  'vehicleName': 'MOVA 1',
                },
              ],
            }),
            200,
          );
        }),
      ),
    );

    await store.load();

    expect(requests.single.url.path, '/api/v1/schedules');
    expect(requests.single.method, 'GET');
    expect(store.trips.single.id, '42');
    expect(store.trips.single.origin, 'Lilongwe');
    expect(store.trips.single.totalSeats, Trip.busSeatCapacity);
    expect(store.trips.single.bookedSeats, [3, 7]);
  });

  test('creates an administrator route and persists its fare', () async {
    SharedPreferences.setMockInitialValues({
      'mova_access_token': 'access-token',
      'mova_refresh_token': 'refresh-token',
    });
    final requests = <http.Request>[];
    final store = RouteStore.forApi(
      apiClient: ApiClient(
        baseUrl: 'https://mova.test/api/v1',
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/me')) {
            return http.Response(jsonEncode({'id': 8, 'role': 'admin'}), 200);
          }
          if (request.method == 'GET' &&
              request.url.path.endsWith('/routes/admin/list')) {
            return http.Response(jsonEncode({'data': []}), 200);
          }
          if (request.method == 'GET' &&
              request.url.path.endsWith('/stops/places/search')) {
            final name = request.url.queryParameters['q']!;
            return http.Response(
              jsonEncode({
                'data': [
                  {'id': name == 'Zomba' ? 21 : 22, 'name': name},
                ],
              }),
              200,
            );
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/routes')) {
            return http.Response(
              jsonEncode({
                'data': {
                  'id': 42,
                  'name': 'Zomba - Mzuzu',
                  'originStop': {'name': 'Zomba'},
                  'destinationStop': {'name': 'Mzuzu'},
                  'routeStops': [
                    {'name': 'Zomba'},
                    {'name': 'Mzuzu'},
                  ],
                  'companyName': 'MOVA',
                  'fareEstimate': 26000,
                },
              }),
              201,
            );
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/routes/42/fares')) {
            return http.Response('', 201);
          }
          return http.Response('Unexpected request', 500);
        }),
      ),
    );

    await store.saveRoute(
      const RouteModel(
        id: 'temporary-route-id',
        companyName: 'MOVA',
        name: 'Zomba - Mzuzu',
        origin: 'Zomba',
        destination: 'Mzuzu',
        roadName: 'M1',
        stops: ['Zomba', 'Mzuzu'],
        fare: 26000,
      ),
    );

    expect(store.routes.single.id, '42');
    expect(store.routes.single.fare, 26000);
    expect(
      requests
          .map((request) => request.url.path)
          .where((path) => path.contains('/stops/places/search')),
      hasLength(2),
    );
    final createRequest = requests.singleWhere(
      (request) =>
          request.method == 'POST' && request.url.path.endsWith('/routes'),
    );
    expect(jsonDecode(createRequest.body), {
      'name': 'Zomba - Mzuzu',
      'roadName': 'M1',
      'originStopId': 21,
      'destinationStopId': 22,
      'intermediateStopIds': [],
      'companyName': 'MOVA',
      'pickupLocation': 'Zomba Depot',
      'dropOffLocation': 'Mzuzu Depot',
      'departureTimes': <String>[],
      'isActive': true,
      'featured': false,
    });
  });

  test('creates administrator schedules through the API', () async {
    SharedPreferences.setMockInitialValues({
      'mova_access_token': 'access-token',
      'mova_refresh_token': 'refresh-token',
    });
    final requests = <http.Request>[];
    final store = TripStore.forApi(
      apiClient: ApiClient(
        baseUrl: 'https://mova.test/api/v1',
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/me')) {
            return http.Response(jsonEncode({'id': 8, 'role': 'admin'}), 200);
          }
          if (request.method == 'GET' &&
              request.url.path.endsWith('/schedules/admin/list')) {
            return http.Response(jsonEncode({'data': []}), 200);
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/schedules')) {
            final payload = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'data': {'id': 73, ...payload, 'bookedSeats': const <int>[]},
              }),
              201,
            );
          }
          return http.Response('Unexpected request', 500);
        }),
      ),
    );
    final departure = DateTime.utc(2026, 11, 12, 8);

    await store.saveTrip(
      Trip(
        id: 'TRIP-123456',
        origin: 'Zomba',
        destination: 'Mzuzu',
        departureTime: departure,
        arrivalTime: departure.add(const Duration(hours: 5)),
        fare: 22000,
        totalSeats: 42,
        operatorName: 'MOVA Express',
        routeName: 'M1',
        vehicleName: 'MOVA 1',
      ),
    );

    expect(store.trips.single.id, '73');
    expect(store.trips.single.totalSeats, 42);
    final request = requests.last;
    expect(request.method, 'POST');
    expect(request.url.path, '/api/v1/schedules');
    expect(jsonDecode(request.body), {
      'origin': 'Zomba',
      'destination': 'Mzuzu',
      'departureTime': departure.toIso8601String(),
      'arrivalTime': departure.add(const Duration(hours: 5)).toIso8601String(),
      'fare': 22000,
      'currency': 'MWK',
      'totalSeats': 42,
      'operatorName': 'MOVA Express',
      'routeName': 'M1',
      'vehicleName': 'MOVA 1',
      'transportMode': 'Bus',
    });
  });

  test('creates, reviews, and confirms a booking through the API', () async {
    SharedPreferences.setMockInitialValues({
      'mova_access_token': 'access-token',
      'mova_refresh_token': 'refresh-token',
    });
    final requests = <http.Request>[];
    final tripJson = {
      'id': 'schedule-7',
      'origin': 'Lilongwe',
      'destination': 'Blantyre',
      'departureTime': '2026-11-10T07:00:00Z',
      'arrivalTime': '2026-11-10T12:00:00Z',
      'fare': 25000,
      'bookedSeats': [1],
    };

    Map<String, dynamic> bookingJson({
      required String status,
      String passengerName = '',
      String phoneNumber = '',
      String paymentMethod = '',
      String paymentReference = '',
    }) => {
      'reference': 'MOVA-123',
      'status': status,
      'selectedSeats': [1],
      'passengerName': passengerName,
      'phoneNumber': phoneNumber,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'schedule': tripJson,
    };

    final store = BookingStore.forApi(
      apiClient: ApiClient(
        baseUrl: 'https://mova.test/api/v1',
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/me')) {
            return http.Response(
              jsonEncode({'id': 7, 'role': 'passenger'}),
              200,
            );
          }
          if (request.method == 'GET' &&
              request.url.path.endsWith('/bookings/mine')) {
            return http.Response(jsonEncode({'data': []}), 200);
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/bookings')) {
            return http.Response(
              jsonEncode({'data': bookingJson(status: 'draft')}),
              201,
            );
          }
          if (request.method == 'PATCH' &&
              request.url.path.endsWith('/bookings/MOVA-123')) {
            return http.Response(
              jsonEncode({
                'data': bookingJson(
                  status: 'reviewed',
                  passengerName: 'Alex Passenger',
                  phoneNumber: '0991234567',
                ),
              }),
              200,
            );
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/bookings/MOVA-123/payment')) {
            return http.Response(
              jsonEncode({
                'data': bookingJson(
                  status: 'paid',
                  passengerName: 'Alex Passenger',
                  phoneNumber: '0991234567',
                  paymentMethod: 'Mobile Money',
                  paymentReference: 'PAY-123',
                ),
              }),
              200,
            );
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/bookings/MOVA-123/confirm')) {
            return http.Response(
              jsonEncode({
                'data': bookingJson(
                  status: 'confirmed',
                  passengerName: 'Alex Passenger',
                  phoneNumber: '0991234567',
                  paymentMethod: 'Mobile Money',
                  paymentReference: 'PAY-123',
                ),
              }),
              200,
            );
          }
          return http.Response('Unexpected request', 500);
        }),
      ),
    );

    final trip = Trip.fromApiJson(tripJson);
    final draft = BookingDraft(
      trip: trip.copyWith(bookedSeats: const []),
      reference: 'CLIENT-123',
      selectedSeats: const [1],
    );
    await store.createDraft(draft);
    await store.reviewBooking(
      reference: 'MOVA-123',
      passengerName: 'Alex Passenger',
      passengerEmail: '',
      phoneNumber: '0991234567',
      identificationNumber: '',
    );
    final result = await store.completePayment(
      reference: 'MOVA-123',
      paymentMethod: 'Mobile Money',
      paymentReference: 'PAY-123',
    );

    expect(result.booking.status, BookingStatus.confirmed);
    expect(requests.map((request) => request.method), [
      'GET',
      'GET',
      'POST',
      'PATCH',
      'POST',
      'POST',
    ]);
    expect(
      requests
          .where((request) => request.method != 'GET')
          .every(
            (request) =>
                request.headers['authorization'] == 'Bearer access-token',
          ),
      isTrue,
    );
    expect(jsonDecode(requests[2].body), {
      'tripId': 'schedule-7',
      'selectedSeats': [1],
    });
  });
}
