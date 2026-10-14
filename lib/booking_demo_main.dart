
import 'package:flutter/material.dart';
import 'screens/user/booking/select_trip_screen.dart';

void main() {
  runApp(const MovaBookingDemo());
}

class MovaBookingDemo extends StatelessWidget {
  const MovaBookingDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOVA Booking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
        useMaterial3: true,
      ),
      home: const SelectTripScreen(),
    );
  }
}
