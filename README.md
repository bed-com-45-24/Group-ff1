# mova

    lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/app_colors.dart
│   ├── constants/app_strings.dart
│   ├── theme/app_theme.dart
│   └── widgets/bottom_nav.dart
│
├── data/
│   ├── mock_data/
│   │   ├── routes_mock.dart      // 10 fake routes in Lilongwe
│   │   ├── stops_mock.dart       // All bus stops
│   │   ├── search_mock.dart      // Suggestions
│   │   └── fares_mock.dart       // K500, K1000, K1500
│   └── models/
│       ├── route_model.dart
│       ├── stop_model.dart
│       └── trip_model.dart
│
├── features/
│   ├── current_location/
│   │   └── presentation/widgets/current_location_widget.dart  <- YOU ARE HERE (FR1/2)
│   │
│   ├── search/
│   │   └── presentation/widgets/search_bar_widget.dart        <- FR5/6/7
│   │
│   ├── route_list/
│   │   └── presentation/widgets/route_card.dart              <- FR8/9/10
│   │
│   ├── stop_list/
│   │   └── presentation/widgets/stop_timeline.dart           <- FR13
│   │
│   ├── fare/
│   │   └── presentation/widgets/fare_badge.dart              <- FR12
│   │
│   ├── compare/
│   │   └── presentation/screens/compare_screen.dart          <- FR11
│   │
│   ├── trip_summary/
│   │   └── presentation/screens/trip_summary_screen.dart     <- FR14
│   │
│   └── map/
│       └── presentation/widgets/interactive_map_widget.dart  <- FR16/17
│
└── screens/
    └── home_screen.dart  // Combines current_location + search + route_list