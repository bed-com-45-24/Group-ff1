import 'package:flutter/material.dart';

import '../../../models/booking_model.dart';
import 'payment_method_screen.dart';

class PaymentFailedScreen extends StatelessWidget {
  final BookingDraft booking;
  final String message;

  const PaymentFailedScreen({
    super.key,
    required this.booking,
    this.message = 'Your demo payment was not completed. Please try again or select another method.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Failed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 90),
              const SizedBox(height: 20),
              const Text(
                'Payment Unsuccessful',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentMethodScreen(booking: booking),
                      ),
                    );
                  },
                  child: const Text('Try Again'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
