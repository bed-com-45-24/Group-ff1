# MOVA Frontend API Contract

This document defines the entities and HTTP API required by the Flutter frontend.
The base URL is `/api/v1`.

## Shared conventions

- Send and receive JSON: `Content-Type: application/json` and `Accept: application/json`.
- Authenticated requests send `Authorization: Bearer <accessToken>`.
- IDs are strings in the frontend, even if a database uses integers.
- Times use ISO 8601 strings, for example `2026-11-23T08:30:00.000Z`.
- Money is a JSON number in MWK. Do not use strings for fare or amount fields.
- Currency is `MWK`.
- Paginated list responses may use `data`, `items`, or `results`; booking and route
  parsers also accept `data.bookings` and `data.routes`. The frontend should
  receive one stable envelope from the backend.
- A recommended list envelope is:

```json
{
  "data": [],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 42
  }
}
```

- Error responses:

```json
{
  "statusCode": 400,
  "error": "Bad Request",
  "message": "Human-readable explanation"
}
```

## Required entities

### User

Represents the signed-in account.

```json
{
  "id": "1",
  "name": "Jane Passenger",
  "email": "jane@example.com",
  "role": "passenger",
  "createdAt": "2026-11-22T10:00:00Z",
  "updatedAt": "2026-11-22T10:00:00Z"
}
```

`role` must be `passenger` or `admin`.

### PassengerProfile

Represents editable passenger booking details.

```json
{
  "name": "Jane Passenger",
  "email": "jane@example.com",
  "phone": "+265991234567",
  "identificationNumber": "P123456"
}
```

### AuthTokens

```json
{
  "accessToken": "jwt-access-token",
  "refreshToken": "jwt-refresh-token"
}
```

Login may wrap these in `data.tokens`, but the frontend also accepts top-level
`accessToken` and `refreshToken`.

### Stop

```json
{
  "id": 1,
  "name": "Lilongwe",
  "latitude": -13.9626,
  "longitude": 33.7741,
  "isActive": true
}
```

The frontend currently requires integer stop IDs when assigning route stops.

### Route

```json
{
  "id": "R001",
  "name": "Lilongwe - Blantyre",
  "companyName": "MOVA Express",
  "roadName": "M1",
  "originStop": {
    "id": 1,
    "name": "Lilongwe"
  },
  "destinationStop": {
    "id": 2,
    "name": "Blantyre"
  },
  "routeStops": [
    { "id": 1, "name": "Lilongwe" },
    { "id": 3, "name": "Dedza" },
    { "id": 2, "name": "Blantyre" }
  ],
  "pickupLocation": "Lilongwe Bus Depot",
  "dropOffLocation": "Wenela Bus Depot",
  "fareEstimate": 75000,
  "currency": "MWK",
  "distance": 312.5,
  "duration": "4h 30m",
  "transfers": 0,
  "departureTimes": ["07:00", "14:00"],
  "isActive": true,
  "featured": false
}
```

Frontend field mapping:

- `originStop.name` -> `origin`
- `destinationStop.name` -> `destination`
- `routeStops[].name` or `stops[].name` -> `stops`
- `fareEstimate` or `fare.amount` -> `fare`
- `isActive` or `active` -> `active`

### RouteFare

Fares are route-level, in this first frontend version.

```json
{
  "id": "F001",
  "routeId": "R001",
  "originStopId": 1,
  "destinationStopId": 2,
  "amount": 75000,
  "currency": "MWK"
}
```

### Schedule

The frontend calls this `Trip`.

```json
{
  "id": "TRIP001",
  "route": {
    "id": "R001",
    "roadName": "M1",
    "originStop": { "id": 1, "name": "Lilongwe" },
    "destinationStop": { "id": 2, "name": "Blantyre" }
  },
  "origin": "Lilongwe",
  "destination": "Blantyre",
  "departureTime": "2026-11-23T07:00:00Z",
  "arrivalTime": "2026-11-23T12:00:00Z",
  "fare": 75000,
  "currency": "MWK",
  "totalSeats": 42,
  "bookedSeats": [3, 7, 12],
  "transportMode": "Bus",
  "operatorName": "MOVA Express",
  "routeName": "M1",
  "vehicleName": "MOVA 1"
}
```

Seat numbers must be integers from `1` through `totalSeats`. The frontend
supports a maximum of 42 seats and a maximum of 5 seats per booking draft.

### Vehicle

Although currently represented as a name, the frontend needs vehicle metadata
for schedule creation and availability.

```json
{
  "id": "V001",
  "name": "MOVA 1",
  "registrationNumber": "BA 1234",
  "type": "Bus",
  "seatCapacity": 42,
  "isActive": true
}
```

### Operator

```json
{
  "id": "O001",
  "name": "MOVA Express",
  "isActive": true
}
```

### Passenger

Used inside a booking response.

```json
{
  "name": "Jane Passenger",
  "email": "jane@example.com",
  "phone": "+265991234567",
  "identificationNumber": "P123456"
}
```

### Payment

```json
{
  "method": "MobileMoney",
  "reference": "MPAY-123456",
  "amount": 150000,
  "currency": "MWK",
  "status": "paid",
  "paidAt": "2026-11-22T10:30:00Z"
}
```

Supported frontend methods are `MobileMoney` and `Card`.

### Booking

The frontend calls this `BookingDraft`, regardless of lifecycle state.

```json
{
  "id": "100",
  "reference": "MOVA-ABC123",
  "tripId": "TRIP001",
  "schedule": {
    "id": "TRIP001",
    "origin": "Lilongwe",
    "destination": "Blantyre",
    "departureTime": "2026-11-23T07:00:00Z",
    "arrivalTime": "2026-11-23T12:00:00Z",
    "fare": 75000,
    "totalSeats": 42,
    "bookedSeats": [3, 7, 12],
    "routeName": "M1",
    "operatorName": "MOVA Express",
    "vehicleName": "MOVA 1",
    "transportMode": "Bus"
  },
  "selectedSeats": [1, 2],
  "passenger": {
    "name": "Jane Passenger",
    "email": "jane@example.com",
    "phone": "+265991234567",
    "identificationNumber": "P123456"
  },
  "passengerName": "Jane Passenger",
  "passengerEmail": "jane@example.com",
  "phoneNumber": "+265991234567",
  "identificationNumber": "P123456",
  "payment": {
    "method": "MobileMoney",
    "reference": "MPAY-123456",
    "amount": 150000,
    "currency": "MWK",
    "status": "paid"
  },
  "paymentMethod": "MobileMoney",
  "paymentReference": "MPAY-123456",
  "status": "confirmed"
}
```

Canonical booking statuses:

```text
draft -> reviewed -> paid -> confirmed
                    \-> cancelled
```

The backend may return compatibility statuses such as `pending`, `created`,
`awaiting_payment`, `payment_received`, `complete`, or `completed`, but
canonical API responses should use the five statuses above.

### SeatAvailability

Useful for a schedule seat-selection endpoint.

```json
{
  "scheduleId": "TRIP001",
  "totalSeats": 42,
  "bookedSeats": [3, 7, 12],
  "availableSeats": [1, 2, 4, 5, 6, 8, 9, 10]
}
```

### Notification

The frontend currently creates payment notifications locally. A persistent
notification API is needed so notifications survive app restarts and are
available across devices.

```json
{
  "id": "N001",
  "title": "Payment completed",
  "message": "Your payment of MWK 150000 via MobileMoney is complete.",
  "category": "Payment confirmation",
  "read": false,
  "createdAt": "2026-11-22T10:30:00Z"
}
```

### OsmRoute

This entity comes from external OpenStreetMap/OSRM services, not the MOVA
backend. It does not need a backend database table.

```json
{
  "id": "route-1",
  "geoJson": {
    "type": "LineString",
    "coordinates": [[33.7741, -13.9626], [34.9089, -15.7861]]
  },
  "distanceMeters": 312500,
  "durationSeconds": 16200,
  "steps": ["Continue onto M1 · 120 km"],
  "roadNames": ["M1"]
}
```

## Required endpoints

All paths below are relative to `/api/v1`.

### Authentication and account

| Method | Path | Auth | Purpose | Body / response |
|---|---|---:|---|---|
| POST | `auth/register` | No | Create passenger account | `{name,email,phone,password}`; 201 account response |
| POST | `auth/login` | No | Authenticate account | `{email,password}`; `accessToken`, `refreshToken` |
| POST | `auth/refresh` | No | Rotate tokens | `{refreshToken}`; new `AuthTokens` |
| POST | `auth/logout` | Yes | Revoke session | Empty body; 204 |
| GET | `me` | Yes | Get current user | `User` |
| GET | `me/passenger-profile` | Yes | Get passenger details | `PassengerProfile` |
| PATCH | `me/passenger-profile` | Yes | Update passenger details | `{name,email,phone,identificationNumber}` |

Passenger registration must set role `passenger`. The backend must not allow a
normal registration request to grant `admin`.

### Stops

| Method | Path | Auth | Purpose | Body / response |
|---|---|---:|---|---|
| GET | `stops/places/search?q=<text>&limit=<n>` | No | Resolve a stop name to a stop ID | `Stop[]` |
| GET | `stops` | Yes admin | List stops | `Stop[]` |
| POST | `stops` | Yes admin | Create stop | `{name,latitude,longitude,isActive}` |
| PATCH | `stops/:id` | Yes admin | Update stop | Partial stop fields |
| DELETE | `stops/:id` | Yes admin | Delete stop | 204 |

Stop search should perform a case-insensitive partial name search and return
the canonical stop ID.

### Routes

| Method | Path | Auth | Purpose | Body / response |
|---|---|---:|---|---|
| GET | `routes` | No | Passenger route search/list | `Route[]` |
| GET | `routes/admin/list` | Yes admin | Admin route list | `Route[]` |
| POST | `routes` | Yes admin | Create route | Route create fields |
| PATCH | `routes/:id` | Yes admin | Update route metadata | Partial route fields |
| PATCH | `routes/:id/stops` | Yes admin | Replace route stop order | `{stopIds:[1,3,2]}` |
| DELETE | `routes/:id` | Yes admin | Delete route | 204 |

Create route body:

```json
{
  "name": "Lilongwe - Blantyre",
  "roadName": "M1",
  "originStopId": 1,
  "destinationStopId": 2,
  "intermediateStopIds": [3],
  "companyName": "MOVA Express",
  "pickupLocation": "Lilongwe Bus Depot",
  "dropOffLocation": "Wenela Bus Depot",
  "departureTimes": ["07:00", "14:00"],
  "isActive": true,
  "distance": 312.5,
  "duration": "4h 30m",
  "transfers": 0,
  "featured": false
}
```

Passenger route responses must include `stops` and a positive route fare when
available.

### Fares

| Method | Path | Auth | Purpose | Body / response |
|---|---|---:|---|---|
| POST | `routes/:id/fares` | Yes admin | Create route fare | `{originStopId,destinationStopId,amount,currency:"MWK"}` |
| PATCH | `routes/:id/fare` | Yes admin | Update route fare | `{amount,currency:"MWK"}` |
| GET | `routes/:id/fares` | No | List fares for route | `RouteFare[]` |

### Schedules

| Method | Path | Auth | Purpose | Body / response |
|---|---|---:|---|---|
| GET | `schedules` | No | List passenger schedules | `Schedule[]` |
| GET | `schedules/admin/list` | Yes admin | Admin schedule list | `Schedule[]` |
| GET | `schedules/:id` | No | Get schedule and seat availability | `Schedule` |
| GET | `schedules/:id/seats` | No | Get seat availability | `SeatAvailability` |
| POST | `schedules` | Yes admin | Create schedule | Schedule create fields |
| PATCH | `schedules/:id` | Yes admin | Update schedule | Partial schedule fields |
| DELETE | `schedules/:id` | Yes admin | Delete schedule | 204 |

Recommended passenger schedule query parameters:

```text
?origin=Lilongwe&destination=Blantyre&date=2026-11-23
```

Create schedule body:

```json
{
  "origin": "Lilongwe",
  "destination": "Blantyre",
  "departureTime": "2026-11-23T07:00:00Z",
  "arrivalTime": "2026-11-23T12:00:00Z",
  "fare": 75000,
  "currency": "MWK",
  "totalSeats": 42,
  "operatorName": "MOVA Express",
  "routeName": "M1",
  "vehicleName": "MOVA 1",
  "transportMode": "Bus"
}
```

If `routeId`, `vehicleId`, or `operatorId` is used, include the corresponding
canonical ID fields and keep the human-readable names in the response.

### Vehicles and operators

These endpoints are needed if the frontend replaces the local dropdown lists
with backend-managed values.

| Method | Path | Auth | Purpose |
|---|---|---:|---|
| GET | `vehicles` | Yes admin | List vehicles |
| POST | `vehicles` | Yes admin | Create vehicle |
| PATCH | `vehicles/:id` | Yes admin | Update vehicle |
| DELETE | `vehicles/:id` | Yes admin | Delete vehicle |
| GET | `operators` | Yes admin | List operators |
| POST | `operators` | Yes admin | Create operator |
| PATCH | `operators/:id` | Yes admin | Update operator |

### Bookings

| Method | Path | Auth | Purpose | Body / response |
|---|---|---:|---|---|
| GET | `bookings/mine` | Yes passenger | Passenger booking history | `Booking[]` |
| GET | `bookings/admin/list` | Yes admin | All bookings | `Booking[]` |
| GET | `bookings/:reference` | Yes | Get one booking | `Booking` |
| POST | `bookings` | Yes passenger | Create draft and reserve selected seats | `{tripId,selectedSeats}`; `Booking` |
| PATCH | `bookings/:reference` | Yes passenger | Add passenger details | `{passengerName,passengerEmail,phoneNumber,identificationNumber}` |
| POST | `bookings/:reference/payment` | Yes passenger | Record or initiate payment | `{paymentMethod,paymentReference}`; `Booking` |
| POST | `bookings/:reference/confirm` | Yes passenger/admin | Confirm paid booking | `Booking` |
| POST | `bookings/:reference/cancel` | Yes passenger | Cancel draft/reviewed booking | `Booking` |

Booking lifecycle rules:

- A booking starts in `draft`.
- Reviewing adds passenger details and changes status to `reviewed`.
- A successful payment changes status to `paid`.
- Confirming changes status to `confirmed`.
- A paid or confirmed booking cannot be cancelled through this endpoint.
- Seat numbers must be unique, within capacity, and not already booked.
- At most 5 seats may be selected in one booking.
- Payment and confirmation must be atomic with the seat reservation.

### Notifications

| Method | Path | Auth | Purpose |
|---|---|---:|---|
| GET | `notifications/mine` | Yes | List current user's notifications |
| PATCH | `notifications/:id/read` | Yes | Mark notification as read |
| DELETE | `notifications/:id` | Yes | Delete notification |

Payment confirmation may create a notification automatically after successful
confirmation.

### External map APIs

The frontend calls these providers directly:

| Provider | Endpoint | Purpose |
|---|---|---|
| Nominatim | `https://nominatim.openstreetmap.org/search?q=<query>&format=jsonv2&limit=1&countrycodes=mw` | Find place coordinates |
| OSRM | `https://router.project-osrm.org/route/v1/driving/<lon1>,<lat1>;...` | Calculate distances, durations, geometry, and driving steps |

These responses must be normalized to `OsmRoute` by the frontend. No MOVA
backend proxy is required unless third-party keys or privacy restrictions make
one necessary.
