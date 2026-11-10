# MOVA — Project Requirements

MOVA is a Flutter client for public-transport route information and scheduled bus bookings in Malawi. Authentication, routes, fares, schedules, and bookings use the configured REST API when the app is launched normally. The backend source code is not included in this repository. Map tiles, place lookup, and driving directions use OpenStreetMap-related public services.

## Project scope

The app has passenger and company-admin roles. It supports route and fare discovery, maps, scheduled bus seat bookings, simulated checkout, and administration. The Flutter client expects a shared backend; this repository does not contain or deploy that server. Checkout remains simulated and does not charge a payment method.

## Backend API contract

The app has no hard-coded API server URL. Supply the current API base URL at launch with `--dart-define=MOVA_API_BASE_URL=https://your-api-host/api/v1`. Protected requests send `Authorization: Bearer <access-token>`. The API should return lists as a raw JSON array or `{ "data": [...] }`, and a single resource as a raw object or `{ "data": {...} }`.

### Frontend-only demo mode

To run and exercise the UI without a backend, launch with:

```shell
flutter run --dart-define=MOVA_USE_BACKEND=false
```

This mode uses local route, schedule, and booking storage and does not send
authentication or app data to the backend. Use `admin@mova.test` with password
`password123` to open the admin screens, or create a passenger account with a
Gmail address from the shared sign-in screen. Demo accounts and sign-in state
are held in memory; locally edited routes, schedules, and bookings are stored
on the device. Demo mode is for UI testing only, not production use.

| Method | Endpoint | Purpose |
| --- | --- | --- |
| POST | `/auth/register` | Register a passenger |
| POST | `/auth/login` | Sign in and return access/refresh tokens |
| POST | `/auth/refresh` | Refresh tokens |
| POST | `/auth/logout` | End the current session |
| GET | `/me` | Return the authenticated user's ID, name, email, and server-assigned role |
| GET, PATCH | `/me/passenger-profile` | Read or update passenger contact details |
| GET | `/routes` | List active passenger routes |
| GET | `/routes/admin/list` | List routes for an administrator |
| POST | `/routes` | Create an administrator route |
| PATCH, DELETE | `/routes/{id}` | Update or delete a route |
| GET | `/stops/places/search?q={name}&limit=8` | Resolve route stop names to backend stop IDs |
| PATCH | `/routes/{id}/stops` | Replace a route's ordered stops |
| POST | `/routes/{id}/fares` | Create a route fare |
| PATCH | `/routes/{id}/fare` | Update a route fare |
| GET | `/schedules` | List passenger schedules, including occupied seats |
| GET | `/schedules/admin/list` | List schedules for an administrator |
| POST | `/schedules` | Create a schedule |
| PATCH, DELETE | `/schedules/{id}` | Update or delete a schedule |
| GET | `/bookings/mine` | List the passenger's bookings |
| GET | `/bookings/admin/list` | List bookings for an administrator |
| POST | `/bookings` | Reserve seats on a schedule |
| PATCH | `/bookings/{reference}` | Save passenger details and review a booking |
| POST | `/bookings/{reference}/payment` | Record the app's simulated payment result |
| POST | `/bookings/{reference}/confirm` | Confirm a paid booking |
| POST | `/bookings/{reference}/cancel` | Cancel an unpaid booking |

Schedule responses must include an ID, origin, destination, departure and arrival timestamps, fare, and occupied seat numbers. The client treats bus capacity as 42 seats, and seat 2 is reserved for the administrator. Booking responses must include a reference, status, selected seats, and the associated schedule/trip; paid or confirmed bookings must also include payment method and reference. The server must validate seat availability atomically when creating a booking, reject reservations for seat 2, enforce passenger/admin authorization, and reject invalid state transitions. The payment endpoints above only record the current demo checkout result; they must not charge cards or mobile-money accounts.

## Use cases

The use cases below describe the current client behavior. “System” refers to the MOVA app and its configured backend API.

### UC-01 — Register or sign in

- **Primary actor:** Passenger or company administrator
- **Precondition:** The app is installed; to sign in, the account exists on the backend.
- **Main flow:** Both roles use the same sign-in screen. Passengers create an account with a Gmail address before signing in; administrators use accounts provisioned by MOVA and cannot register through the app. The backend assigns the role, and successful sign-in opens the passenger home or admin dashboard accordingly.
- **Alternative flows:** Invalid fields, non-Gmail passenger registration addresses, duplicate registration, unavailable services, or incorrect credentials produce an error and the user can try again. Admin roles cannot be assigned by public registration.
- **Related requirements:** FR-01

### UC-02 — Find a route and view its details

- **Primary actor:** Passenger
- **Precondition:** Route data is available from the backend.
- **Main flow:** The passenger browses routes or enters an origin and destination. The system displays matching active routes and available map directions. The passenger can compare map options, review each option's distance, duration, and fare, and select **Book now** on the preferred option to search for scheduled trips for that journey. The passenger can also view route stops, pickup/drop-off information, operator, and fare.
- **Alternative flows:** If no route matches, the system shows no results. The passenger may search a destination or request map directions; online map services or device location may be unavailable.
- **Related requirements:** FR-02–FR-05, FR-12

### UC-03 — Search scheduled trips and select seats

- **Primary actor:** Passenger
- **Precondition:** At least one future schedule is available from the backend.
- **Main flow:** The passenger enters an origin, destination, and travel date, either directly or after selecting **Book now** for a map option. The system lists matching future trips. The passenger selects a trip, chooses up to five available seats, and continues to passenger details.
- **Alternative flows:** If no scheduled trip matches, the system reports that no trips are available. Occupied seats cannot be selected; if a seat becomes unavailable before the booking is saved, the system rejects the booking and asks the passenger to choose again.
- **Related requirements:** FR-06–FR-07, FR-12

### UC-04 — Review and pay for a booking

- **Primary actor:** Passenger
- **Precondition:** The passenger has selected an available trip and seats.
- **Main flow:** The passenger enters required passenger details and optional email/identification details. The system validates the details, displays the booking summary and calculated total, and lets the passenger choose Mobile Money or Bank Card. The prototype simulates payment, confirms the booking, generates a reference, displays a demonstration e-ticket, and adds an in-app payment notification.
- **Alternative flows:** Invalid passenger/payment form details must be corrected. A simulated or booking-processing failure displays a failure state; no real charge is made.
- **Related requirements:** FR-08–FR-11

### UC-05 — Manage routes, stops, and fares

- **Primary actor:** Company administrator
- **Precondition:** The administrator is signed in with the admin role.
- **Main flow:** The administrator adds or edits a route, configures its origin and destination and road/highway, manages intermediate stops, and sets a positive fare in MWK. Multiple routes may share endpoints when their roads differ. The administrator may activate/deactivate or delete a route. Changes are saved by the backend and reflected in passenger route data.
- **Alternative flows:** A route with the same origin, destination, and road cannot be duplicated. The origin and destination stops cannot be removed from a route.
- **Related requirements:** FR-13–FR-15, FR-18

### UC-06 — Manage trip schedules

- **Primary actor:** Company administrator
- **Precondition:** The administrator is signed in with the admin role.
- **Main flow:** The administrator adds or edits a schedule's origin, destination, road/highway, departure and arrival times, fare, transport company, and vehicle identifier. Multiple schedules may share endpoints when assigned to different roads and vehicles. The app validates the schedule and saves it through the backend. The administrator can review availability and delete schedules.
- **Alternative flows:** The system rejects invalid date/time values, a departure in the past, an arrival that is not after departure, or a non-positive fare.
- **Related requirements:** FR-16–FR-17, FR-19

### UC-07 — Review passenger bookings

- **Primary actor:** Company administrator
- **Precondition:** The administrator is signed in and booking data is available from the backend.
- **Main flow:** The administrator opens bookings and reviews each booking's reference, passenger details, trip, selected seats, amount, payment method, and status.
- **Alternative flows:** If there are no bookings, the system displays an empty-state message.
- **Related requirements:** FR-17

## Functional requirements

### Passenger

| ID | Requirement | Status |
| --- | --- | --- |
| FR-01 | The application shall provide a shared sign-in screen for passengers and administrators; passengers register with Gmail addresses, while administrators use backend-provisioned accounts. The backend-assigned role determines the destination screen. | Implemented through the configured REST API; server-side role assignment is authoritative. |
| FR-02 | The application shall let a passenger browse active routes and search for routes by origin and destination. | Implemented using backend route data. |
| FR-03 | The application shall show route details, including origin, destination, road/highway, stops, pickup/drop-off information, operator, available departure times, and fare where provided. | Implemented; displayed information depends on the route record. |
| FR-04 | The application shall display configured route fares in MWK and distinguish map-distance fare estimates from configured fares. | Implemented. Estimate and schedule data are not guaranteed operator prices. |
| FR-05 | The application shall display an interactive map and driving directions for supported places, and shall request device-location permission when current location is needed. | Implemented using OpenStreetMap, Nominatim, and OSRM public services; network and permission required. |
| FR-06 | The application shall let a passenger search for future scheduled bus trips by origin, destination, and travel date, and display matching departure/arrival times and fares. | Implemented using backend schedules. |
| FR-07 | The application shall let a passenger select up to five available seats from a 42-seat bus and prevent selection of occupied seats. | Implemented; seat 2 is reserved for the administrator. |
| FR-08 | Before booking confirmation, the application shall collect and validate passenger name and phone number, accept an optional email and identification number, and show a booking summary and total fare. | Implemented. |
| FR-09 | The application shall create a unique booking reference, retain booking details and status, and let the passenger view booking history. | Implemented through backend bookings. |
| FR-10 | The application shall offer Mobile Money and Bank Card checkout options and show the result of the checkout flow. | Implemented as a simulation only; no payment is processed. |
| FR-11 | The application shall show an in-app confirmation notification when a simulated payment completes. | Implemented for payment confirmations; notifications are not sent by SMS or email. |
| FR-12 | When multiple map-route options are available for a destination search, the application shall show a **Book now** action for each option and pass the chosen option into scheduled-trip search. | Implemented on the map-options comparison screen. A configured operator route retains its published fare; a map-only option uses an explicitly estimated fare. |

### Company administrator

| ID | Requirement | Status |
| --- | --- | --- |
| FR-13 | An administrator shall be able to create, edit, activate/deactivate, and delete routes. | Implemented through the backend API. |
| FR-14 | An administrator shall be able to add or remove intermediate stops while retaining each route's origin and destination. | Implemented through the backend API. |
| FR-15 | An administrator shall be able to set a positive MWK fare for a route. Passengers shall not edit that fare. | Implemented through the backend API; map-based estimates are separate from configured route fares. |
| FR-16 | An administrator shall be able to create, edit, and delete bus schedules, including origin, destination, departure and arrival times, fare, road, operator, and vehicle identifier. | Implemented through the backend API; schedules require a future departure and arrival after departure. |
| FR-17 | An administrator shall be able to view scheduled-trip seat availability and inspect passenger booking and payment-status details. | Implemented through the backend API. |
| FR-18 | An administrator shall be able to distinguish routes with identical endpoints by assigning each a road/highway name; otherwise duplicate routes with the same endpoints and road shall be rejected. | Implemented in the client; the backend must also enforce uniqueness. |
| FR-19 | An administrator shall be able to assign each schedule a road/highway, transport company, and vehicle identifier so trips to the same destination can be distinguished. Passenger trip search shall retain the selected route's road and show the scheduled vehicle. | Implemented through the backend API; enter the same road name on the route and its schedules for road-specific results. |

## Non-functional requirements

| ID | Requirement | Current project scope |
| --- | --- | --- |
| NFR-01 Reliability | The application shall validate user input and booking state before saving, preserve booking/route/schedule changes in shared storage, and report errors rather than silently confirming failed operations. | Client validation and API error handling are implemented; server availability and durability depend on the external backend. |
| NFR-02 Data integrity | A booking shall have a unique reference and distinct available seats; its total shall be calculated from the trip fare and selected seats. Route fares must be positive, and schedule arrival must be after departure. | Client validation is implemented; the backend must enforce authorization, seat concurrency, uniqueness, and state transitions. |
| NFR-03 Transparency and fairness | The interface shall show the fare and currency associated with a configured route or trip and shall identify estimated fares as estimates. The passenger shall not be able to change an administrator-configured fare. | Implemented in the prototype; source data is not verified operator data. |
| NFR-04 Privacy and security | The production system shall protect accounts, passenger details, and location data from unauthorized access and shall use a secure authentication service. | The client uses bearer tokens, but the backend is external and has not been audited. Tokens are stored in shared preferences; use secure storage before production. Payment PIN/card fields are not saved or sent. |
| NFR-05 Availability | Route, booking, and map functions should communicate clearly when data or external services cannot be loaded. | API-backed data requires the configured server; map tiles, place lookup, and directions require internet and public-service availability. |
| NFR-06 Interoperability | The mobile client shall integrate with device location services and its configured map, geocoding, and directions providers. | Implemented with Flutter location plugins and OpenStreetMap/Nominatim/OSRM public endpoints. |
| NFR-07 Usability and accessibility | The application shall provide readable labels, understandable navigation, form validation, and clear booking and fare information on supported mobile screen sizes. | Implemented as a Flutter mobile UI; accessibility and device coverage require further evaluation. |
| NFR-08 Compatibility | The prototype shall run on supported Android devices using the Flutter SDK version specified by `pubspec.yaml`. | Android is the target platform; confirm behavior on the intended device/emulator. |
| NFR-09 Maintainability | Route, trip, booking, authentication, and location responsibilities shall remain separated into models, stores, services, and screens so the prototype can be extended. | Reflected in the current Flutter project structure. |
| NFR-10 Scalability | A deployed system shall support multiple users and a growing set of routes, schedules, and bookings without relying on one device's local storage. | The client is wired to a shared API; server capacity and database behavior cannot be assessed from this repository. |

## Out of scope for this prototype

The following are not current application capabilities and require additional product/backend work:

- The backend source code, database schema, deployment, and operational monitoring are not included in this repository.
- Real payment-provider integration, payment settlement, or refunds.
- Sending booking confirmations or route alerts through SMS, email, or push notifications.
- Passenger self-service booking changes or cancellations.
- Production-grade verification of transport operators, routes, schedules, and fares.

## Running and testing

### Requirements

- Flutter SDK and a Dart SDK satisfying the constraint in `pubspec.yaml` (`^3.13.4`).
- Android SDK and an Android device or emulator.
- Internet access for map tiles, place lookup, and driving directions.

From the repository root:

```shell
flutter pub get
flutter run
```

To point the client at a different backend, pass its API base URL:

```shell
flutter run --dart-define=MOVA_API_BASE_URL=https://your-api-host/api/v1
```

Allow location access when prompted to use device location. Run the tests and static analysis with:

```shell
flutter test
flutter analyze
```

## Project layout

```text
lib/
  data/       API-backed route, trip, and booking stores; local notification state
  models/     Route, trip, booking, and map data models
  screens/
    admin/    Route, stop, fare, schedule, and booking management
    auth/     Role selection, sign-in, and registration
    user/     Passenger route discovery, maps, and trip booking
      booking/
      payment/
  services/   REST API client, authentication, location, and OpenStreetMap services
  utils/      Map configuration and shared helpers
  widgets/    Reusable interface components
test/         Widget and booking/schedule tests
```
