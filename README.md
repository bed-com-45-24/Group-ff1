# MOVA — Project Requirements

MOVA is a Flutter prototype for public-transport route information and scheduled bus bookings in Malawi. This document describes the functional and non-functional requirements for the current project. Unless marked otherwise, “implemented” means implemented in the local prototype, not backed by a production service.

## Project scope

The prototype has passenger and company-admin roles. It supports route and fare discovery, maps, scheduled bus seat bookings, simulated checkout, and local administration. It does not have a backend or synchronize data between devices. Its route, fare, and schedule records are demonstration data and must not be treated as authoritative operator information.

## Use cases

The use cases below describe the current prototype. “System” refers to the MOVA mobile application and its on-device stores.

### UC-01 — Register or sign in

- **Primary actor:** Passenger or company administrator
- **Precondition:** The app is installed; to sign in, an account has already been registered on this device.
- **Main flow:** The user chooses a role, enters registration details or existing credentials, and submits the form. The system validates the input and stores or checks the local account. After successful sign-in, the system opens the passenger home or admin dashboard for the selected role.
- **Alternative flows:** Invalid fields or incorrect credentials produce an error and the user can try again. Registration with an existing email is rejected.
- **Related requirements:** FR-01

### UC-02 — Find a route and view its details

- **Primary actor:** Passenger
- **Precondition:** Route data is available in the app.
- **Main flow:** The passenger browses routes or enters an origin and destination. The system displays matching active routes. The passenger selects a route to view its stops, pickup/drop-off information, operator, fare, and available route details.
- **Alternative flows:** If no route matches, the system shows no results. The passenger may search a destination or request map directions; online map services or device location may be unavailable.
- **Related requirements:** FR-02–FR-05

### UC-03 — Search scheduled trips and select seats

- **Primary actor:** Passenger
- **Precondition:** At least one future schedule is stored on the device.
- **Main flow:** The passenger enters an origin, destination, and travel date. The system lists matching future trips. The passenger selects a trip, chooses up to five available seats, and continues to passenger details.
- **Alternative flows:** If no scheduled trip matches, the system reports that no trips are available. Occupied seats cannot be selected; if a seat becomes unavailable before the booking is saved, the system rejects the booking and asks the passenger to choose again.
- **Related requirements:** FR-06–FR-07

### UC-04 — Review and pay for a booking

- **Primary actor:** Passenger
- **Precondition:** The passenger has selected an available trip and seats.
- **Main flow:** The passenger enters required passenger details and optional email/identification details. The system validates the details, displays the booking summary and calculated total, and lets the passenger choose Mobile Money or Bank Card. The prototype simulates payment, confirms the booking, generates a reference, displays a demonstration e-ticket, and adds an in-app payment notification.
- **Alternative flows:** Invalid passenger/payment form details must be corrected. A simulated or booking-processing failure displays a failure state; no real charge is made.
- **Related requirements:** FR-08–FR-11

### UC-05 — Manage routes, stops, and fares

- **Primary actor:** Company administrator
- **Precondition:** The administrator is signed in with the admin role.
- **Main flow:** The administrator adds or edits a route, configures its origin and destination, manages intermediate stops, and sets a positive fare in MWK. The administrator may activate/deactivate or delete a route. Changes are saved locally and reflected in passenger route data on this device.
- **Alternative flows:** Invalid or duplicate route details are rejected. The origin and destination stops cannot be removed from a route.
- **Related requirements:** FR-12–FR-14

### UC-06 — Manage trip schedules

- **Primary actor:** Company administrator
- **Precondition:** The administrator is signed in with the admin role.
- **Main flow:** The administrator adds or edits a schedule's origin, destination, departure and arrival times, fare, and route/operator details. The system validates the schedule and saves it locally. The administrator can review availability and delete schedules.
- **Alternative flows:** The system rejects invalid date/time values, a departure in the past, an arrival that is not after departure, or a non-positive fare.
- **Related requirements:** FR-15–FR-16

### UC-07 — Review passenger bookings

- **Primary actor:** Company administrator
- **Precondition:** The administrator is signed in and booking data is available on this device.
- **Main flow:** The administrator opens bookings and reviews each booking's reference, passenger details, trip, selected seats, amount, payment method, and status.
- **Alternative flows:** If there are no bookings, the system displays an empty-state message.
- **Related requirements:** FR-16

## Functional requirements

### Passenger

| ID | Requirement | Status |
| --- | --- | --- |
| FR-01 | The application shall let a user choose the passenger or company-admin role, register or sign in locally, and log out. | Implemented as a local prototype; not production authentication. |
| FR-02 | The application shall let a passenger browse active routes and search for routes by origin and destination. | Implemented using locally stored route data. |
| FR-03 | The application shall show route details, including origin, destination, stops, pickup/drop-off information, operator, available departure times, and fare where provided. | Implemented; displayed information depends on the route record. |
| FR-04 | The application shall display configured route fares in MWK and distinguish map-distance fare estimates from configured fares. | Implemented. Estimate and schedule data are not guaranteed operator prices. |
| FR-05 | The application shall display an interactive map and driving directions for supported places, and shall request device-location permission when current location is needed. | Implemented using OpenStreetMap, Nominatim, and OSRM public services; network and permission required. |
| FR-06 | The application shall let a passenger search for future scheduled bus trips by origin, destination, and travel date, and display matching departure/arrival times and fares. | Implemented using locally stored schedules. |
| FR-07 | The application shall let a passenger select up to five available seats from a 42-seat bus and prevent selection of occupied seats. | Implemented; seat 2 is reserved for the administrator. |
| FR-08 | Before booking confirmation, the application shall collect and validate passenger name and phone number, accept an optional email and identification number, and show a booking summary and total fare. | Implemented. |
| FR-09 | The application shall create a unique booking reference, retain booking details and status on the device, and let the passenger view booking history. | Implemented with local persistence. |
| FR-10 | The application shall offer Mobile Money and Bank Card checkout options and show the result of the checkout flow. | Implemented as a simulation only; no payment is processed. |
| FR-11 | The application shall show an in-app confirmation notification when a simulated payment completes. | Implemented for payment confirmations; notifications are not sent by SMS or email. |

### Company administrator

| ID | Requirement | Status |
| --- | --- | --- |
| FR-12 | An administrator shall be able to create, edit, activate/deactivate, and delete routes. | Implemented locally. |
| FR-13 | An administrator shall be able to add or remove intermediate stops while retaining each route's origin and destination. | Implemented locally. |
| FR-14 | An administrator shall be able to set a positive MWK fare for a route. Passengers shall not edit that fare. | Implemented locally; map-based estimates are separate from configured route fares. |
| FR-15 | An administrator shall be able to create, edit, and delete bus schedules, including origin, destination, departure and arrival times, fare, and operator/route details. | Implemented locally; schedules require a future departure and arrival after departure. |
| FR-16 | An administrator shall be able to view scheduled-trip seat availability and inspect passenger booking and payment-status details. | Implemented locally. |

## Non-functional requirements

| ID | Requirement | Current project scope |
| --- | --- | --- |
| NFR-01 Reliability | The application shall validate user input and booking state before saving, preserve booking/route/schedule changes on the device, and report errors rather than silently confirming failed operations. | Implemented in the prototype for core booking and local data flows. |
| NFR-02 Data integrity | A booking shall have a unique reference and distinct available seats; its total shall be calculated from the trip fare and selected seats. Route fares must be positive, and schedule arrival must be after departure. | Enforced by the local models, stores, and forms. |
| NFR-03 Transparency and fairness | The interface shall show the fare and currency associated with a configured route or trip and shall identify estimated fares as estimates. The passenger shall not be able to change an administrator-configured fare. | Implemented in the prototype; source data is not verified operator data. |
| NFR-04 Privacy and security | The production system shall protect accounts, passenger details, and location data from unauthorized access and shall use a secure authentication service. | Not met for production: credentials and records are stored locally by the demo. Do not use real credentials or sensitive personal/payment data. Payment PIN fields are not saved or sent. |
| NFR-05 Availability | Route, booking, and map functions should communicate clearly when data or external services cannot be loaded. | Locally stored data is device-local; map tiles, place lookup, and directions require internet and public-service availability. |
| NFR-06 Interoperability | The mobile client shall integrate with device location services and its configured map, geocoding, and directions providers. | Implemented with Flutter location plugins and OpenStreetMap/Nominatim/OSRM public endpoints. |
| NFR-07 Usability and accessibility | The application shall provide readable labels, understandable navigation, form validation, and clear booking and fare information on supported mobile screen sizes. | Implemented as a Flutter mobile UI; accessibility and device coverage require further evaluation. |
| NFR-08 Compatibility | The prototype shall run on supported Android devices using the Flutter SDK version specified by `pubspec.yaml`. | Android is the target platform; confirm behavior on the intended device/emulator. |
| NFR-09 Maintainability | Route, trip, booking, authentication, and location responsibilities shall remain separated into models, stores, services, and screens so the prototype can be extended. | Reflected in the current Flutter project structure. |
| NFR-10 Scalability | A deployed system shall support multiple users and a growing set of routes, schedules, and bookings without relying on one device's local storage. | Not implemented; requires a shared backend and database. |

## Out of scope for this prototype

The following are not current application capabilities and require additional product/backend work:

- Shared accounts, server-side authentication, and synchronization of routes, schedules, fares, or bookings between users/devices.
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

Allow location access when prompted to use device location. Run the tests and static analysis with:

```shell
flutter test
flutter analyze
```

## Project layout

```text
lib/
  data/       Local route, trip, booking, and notification stores
  models/     Route, trip, booking, and map data models
  screens/
    admin/    Route, stop, fare, schedule, and booking management
    auth/     Role selection, sign-in, and registration
    user/     Passenger route discovery, maps, and trip booking
      booking/
      payment/
  services/   Authentication, location, and OpenStreetMap services
  utils/      Map configuration and shared helpers
  widgets/    Reusable interface components
test/         Widget and booking/schedule tests
```
