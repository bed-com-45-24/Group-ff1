lib/
│
├── main.dart
│
├── screens/
│   │
│   ├── user/
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── home_screen.dart
│   │   ├── search_screen.dart
│   │   ├── results_screen.dart
│   │   ├── route_details_screen.dart
│   │   ├── map_screen.dart
│   │   │
│   │   ├── booking/
│   │   │   ├── select_trip_screen.dart
│   │   │   ├── seat_selection_screen.dart
│   │   │   ├── passenger_details_screen.dart
│   │   │   ├── booking_summary_screen.dart
│   │   │   └── booking_confirmation_screen.dart
│   │   │
│   │   ├── payment/
│   │   │   ├── payment_method_screen.dart
│   │   │   ├── mobile_money_screen.dart
│   │   │   ├── card_payment_screen.dart
│   │   │   ├── payment_processing_screen.dart
│   │   │   ├── payment_success_screen.dart
│   │   │   └── payment_failed_screen.dart
│   │   │
│   │   ├── my_bookings_screen.dart
│   │   ├── saved_routes_screen.dart
│   │   ├── history_screen.dart
│   │   ├── notifications_screen.dart
│   │   └── profile_screen.dart
│   │
│   └── admin/
│       ├── admin_login_screen.dart
│       ├── dashboard_screen.dart
│       ├── routes_screen.dart
│       ├── vehicles_screen.dart
│       ├── drivers_screen.dart
│       ├── fares_screen.dart
│       ├── bookings_screen.dart
│       ├── payments_screen.dart
│       ├── users_screen.dart
│       ├── reports_screen.dart
│       ├── notifications_screen.dart
│       └── settings_screen.dart
│
├── widgets/
│   ├── route_card.dart
│   ├── booking_card.dart
│   ├── payment_card.dart
│   ├── seat_widget.dart
│   ├── statistic_card.dart
│   └── navigation_bar.dart
│
├── models/
│   ├── user_model.dart
│   ├── route_model.dart
│   ├── vehicle_model.dart
│   ├── driver_model.dart
│   ├── booking_model.dart
│   └── payment_model.dart
│
├── data/
│   └── sample_data.dart
│
└── utils/
    ├── colors.dart
    └── constants.dart









    


MOVA
Software Requirements Specification
Version 1.0

29 September 2026

Group FF1

Lead Software Engineer: Chinguwo Yankho

Document Approval
The following Software Requirements Specification is prepared for the COM 311 Software Engineering group mini-project. Approval/sign-off may be completed by the group leader and course supervisor/instructor.

Group Leader: Chinguwo Yankho
Supervisor: Austin Munthali
Date: 29 September 2026


1. Introduction
1.1 Purpose
The purpose of this Software Requirements Specification (SRS) is to define the requirements for MOVA, a mobile application for public transport route and fare information. It provides sufficient detail to guide the design, implementation, testing, and evaluation of the frontend prototype and proposed system.

1.2 Scope
MOVA is a mobile application designed around a defined public transport service in Malawi. The system assumes that a transport company or authorized transport administrator defines and maintains the official routes, stops, vehicle services, and fares used by the application.
Passengers will be able to determine or select their starting location, search for a destination, view available company-defined routes, see fixed/official fares, identify pickup and drop-off points, compare available routes, view a trip summary, and view the selected route on an interactive map.
The system will not allow ordinary passengers to create, change, or negotiate official route and fare information. Route and price information will be maintained by the authorized transport company or administrator. This provides a controlled information source and ensures that the fare displayed by the application corresponds to the fare defined for the selected company route.
1.3 Definitions, Acronyms, and Abbreviations
MOVA: Name of the proposed public transport route and fare information application.
SRS: Software Requirements Specification.
Route: A defined path or service operated by the transport company between specified locations.
Stop: A defined pickup or drop-off location associated with a route.
Fare: The fixed/official amount charged by the transport company for a specified route or journey.
Pickup Point: A location where a passenger can board the company transport service.
Drop-off Point: A location where a passenger can leave the company transport service.
Administrator: An authorized person who manages company routes, stops, fares, and related transport information.
API: Application Programming Interface.
GPS: Global Positioning System used to determine a device location.

1.4 Overview
This SRS follows the supplied COM 311 SRS template. Section 2 gives the general description of MOVA, its product functions, user roles, interfaces, functional requirements, and non-functional requirements. Section 3 describes the . Section 4 describes general constraints and references.
2. General Description
MOVA is intended to solve the information problem identified in the project specification: passengers often lack a centralized source for public transport routes, boarding points, route connections, and fares. The proposed system uses a controlled company-defined dataset so that routes, stops, and fares are explicitly defined rather than being treated as user-generated or negotiated information.
2.1 Product Functions
Detect and display the user current location.
Allow users to log in and log out.
Allow users to search for and select a destination.
Provide real-time search and destination suggestions.
Display company-defined transport routes.
Display route names and route details.
Display company-defined pickup and drop-off points.
Display the fixed/official fare for the selected route.
Allow users to compare available company routes.
Provide a trip summary before travel.
Display the selected route on an interactive map.
Provide route/journey notifications where supported.
Allow authorized administrators to maintain route, stop, and fare information.
2.2 User Characteristics/Roles

Passenger/User
Uses MOVA to search destinations, find company routes, view stops and fares, and plan a journey. The passenger does not change official routes or fares.
Transport Company Administrator
Maintains the official route definitions, route names, stops, transport services, and fixed fares. The administrator is responsible for keeping transport information current.
System Administrator
Manages system-level configuration, user access, security, and technical administration where required.
2.3 External Interface Requirements
User Interface: The application shall provide a mobile-first interface suitable for Android smartphones. The interface should use clear navigation, readable text, route cards, fare information, and map views.
Location Interface: The application shall use the device location services/GPS when the user grants location permission.
Map Interface: The project specification identifies Google Maps/OpenStreetMap API for map-related functionality. The selected map service will be used to display locations and route information.
Development Interface: The project specification identifies Flutter as the development framework and Android Studio for the Android emulator.
2.4 Functional Requirements
2.4.1 Current Location

FR1 – Detect Current Location
The system shall detect the user current location using device location services. This provides the starting point for route planning and nearby transport information.
FR2 – Display Current Location
The system shall display the user current location on the map and relevant journey-planning screens so the passenger can understand where the journey begins.
2.4.2 User Management

FR3 – User Login
The system shall allow registered users to log in using valid authentication credentials.
FR4 – User Logout
The system shall allow logged-in users to securely log out of the application.
2.4.3 Location and Destination

FR5 – Search Destination
The system shall allow users to search for a destination by entering a place name or supported location information.
FR6 – Real-Time Search and Auto-Suggestions
The system shall provide search suggestions while the user enters a destination to help the user locate the intended destination quickly.
FR7 – Select Destination
The system shall allow the user to select a destination from available search results or suggestions.
2.4.4 Company-Defined Routes and Fares

FR8 – Display Available Company Routes
The system shall display routes that have been defined and approved by the transport company or authorized administrator.
FR9 – Display Route Names
The system shall display the official name or identifier of each available company route.
FR10 – Display Route Details
The system shall display details of a selected route, including relevant stops, boarding points, drop-off points, route stages, and other available journey information.
FR11 – Compare Available Routes
The system shall allow users to compare available company-defined routes using information such as fare, travel time, and transfers where such information is available.
FR12 – Display Fixed/Official Fare
The system shall display the fare defined by the transport company for the selected route. The passenger shall not be able to edit or negotiate this fare through the application.
FR13 – Identify Pickup and Drop-off Points
The system shall display company-defined pickup and drop-off points associated with the selected route.
FR14 – Present Trip Summary
The system shall present a summary of the selected journey, including origin, destination, route, official fare, and relevant stops.
FR15 – Provide Route Notifications
The system shall provide route-related notifications where supported, such as changes published by the authorized transport company.
2.4.5   Interactive Map

FR16 – Display Interactive Map
The system shall display an interactive map containing the user location, relevant stops, and company-defined route information.
FR17 – Show Selected Route on Map
The system shall display the selected route visually on the map so the passenger can understand the journey from origin to destination.
2.4.6   Transport Company Administration

FR18 – Manage Routes
The authorized transport company administrator shall be able to create, update, activate, or deactivate official transport routes.
FR19 – Manage Stops
The authorized transport company administrator shall be able to create and update official pickup and drop-off points associated with routes.
FR20 – Manage Fixed Fares
The authorized transport company administrator shall be able to define and update the official fare associated with a route or approved fare category.
FR21 – Publish Transport Information
The system shall make approved route, stop, and fare information available to passengers after it has been published by the authorized administrator.
FR22 – Restrict Passenger Changes
The system shall prevent ordinary passengers from changing official routes, stops, or fares
FR23 Booking
The system must allow user to book for any transport mode of their choice and at their convenient  time
FR 23.1: Search Available Trips
The system shall allow users to search for available trips using departure location, destination, date, and time.
FR 23.2: View Trip Details
The system shall display trip information including route, departure time, arrival time, fare, and available seats.
FR 23.3: Select a Trip
The system shall allow users to select a preferred trip from the available options.
FR 23.4: Select Seat(s)
The system shall allow users to choose one or more available seats.
FR 23.5: Enter Passenger Information
The system shall allow users to provide passenger details such as name, phone number, and identification number.
FR 23.6: Confirm Booking Details
The system shall display a booking summary before submission and allow users to confirm or modify details.
FR 23.7: Calculate Booking Cost
The system shall automatically calculate the total fare based on selected seats and trip information.
FR 23.8: Process Payment
The system shall allow users to pay for the booking through supported payment methods.
FR 23.9: Generate Booking Reference
The system shall generate a unique booking reference number after successful booking.
FR 23.10: Generate Electronic Ticket
The system shall generate an electronic ticket for confirmed bookings.
FR 23.11: Send Booking Confirmation
The system shall send booking confirmation through SMS, email, or in-app notification.
FR 23.12: View Booking History
The system shall allow users to view current and previous bookings.
FR 23.13: Modify Booking
The system shall allow users to update booking details before the travel date, subject to company policies.
FR 23.14: Cancel Booking
The system shall allow users to cancel a booking according to cancellation rules.
FR 23.15: Request Refund
The system shall process refund requests for eligible cancelled bookings.
2.6 Non-Functional Requirements

NFR1 – Reliability
The system shall operate consistently and should not unexpectedly crash during normal route searches, fare viewing, and map use.
NFR2 – Availability
The system should be available when passengers need to plan their journeys, subject to network connectivity and required external services.
NFR3 – Scalability
The system should support growth in passengers, routes, stops, and transport records without significant degradation in normal performance.
NFR4 – Transparency
The system shall clearly identify the official fare and route information provided by the transport company so passengers know that displayed prices are company-defined.
NFR5 – Fairness
The system shall display the same official fare for users selecting the same applicable route and fare category, unless an authorized company update changes the fare.
NFR6 – Security and Privacy
The system shall protect authentication credentials, user information, and location information against unauthorized access.
NFR7 – Interoperability
The system shall integrate with the selected map/location service through the required API and shall exchange the information required to display routes and locations.
NFR8 – Usability
The application shall provide a simple and understandable interface that allows passengers to search destinations and understand route, stop, and fare information without extensive training.
NFR9 – Compatibility
The application shall run on supported Android devices and adapt to supported screen sizes and resolutions.
NFR10 – Maintainability
The system shall allow authorized developers and administrators to maintain route, stop, fare, and other system data without redesigning the entire application.
NFR11 – Accessibility
The application shall use readable text, clear controls, understandable icons, and sufficient visual contrast to support a broad range of passengers.
NFR12 – Data Integrity
The system shall preserve the integrity of official route, stop, and fare data and shall prevent unauthorized modification of company-defined transport information.
4.General Constraints

4.1 Development Platforms
The project shall use Flutter for the mobile frontend and Android Studio for the Android emulator as specified in the course project.
4.2 Mapping Technology
The project shall use Google Maps/OpenStreetMap API for map functionality as specified in the project.
4.3 Controlled Route and Fare Data
Routes, stops, and fares are treated as official company-defined information. Passengers cannot create or modify official route and fare records.
4.4 Fixed Fare Model
For the prototype and defined company scenario, the fare displayed for a route is fixed according to the fare configured by the authorized transport company. Any change must be made by an authorized administrator.
4.5 Network Dependency
Map services, remote route information, and other online functions may require network connectivity.
4.6 Project Scope
The initial project focuses on the frontend/mobile passenger experience and the defined transport information required by the problem statement. Features not included in the approved scope should not be assumed to be implemented.


4.7 References


 Pressman, R. S., & Maxim, B. R. (2019). Software engineering: A practitioner's approach (9th ed.). McGraw-Hill Education.
Sommerville, I. (2016). Software engineering (10th ed.). Pearson.
 Google. (n.d.). Flutter documentation. https://docs.flutter.dev/
 Google. (n.d.). Android Studio. https://developer.android.com/studio
Google. (n.d.). Google Maps Platform documentation. https://developers.google.com/maps/documentation/
OpenStreetMap Foundation. (n.d.). Copyright and licence. https://www.openstreetmap.org/copyright