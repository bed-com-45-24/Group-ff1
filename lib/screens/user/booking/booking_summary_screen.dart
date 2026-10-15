//import 'package:flutter/material.dart';
//import '../../models/route_model.dart';
import 'package:flutter/material.dart';
import '../../../models/route_model.dart';


class BookingSummaryScreen extends StatelessWidget {
  final RouteModel route;

  const BookingSummaryScreen({
    super.key,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MOVA Trip Summary'),
      ),
      body: Center(
        child: Text(
          '${route.origin} → ${route.destination}\n'
          'Fare: MWK ${route.fare.toStringAsFixed(0)}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}