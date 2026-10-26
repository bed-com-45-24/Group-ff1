import 'package:flutter/material.dart';

import '../../../data/booking_service.dart';
import '../../../models/booking_model.dart';
import 'payment_success_screen.dart';
import 'payment_failed_screen.dart';

class PaymentProcessingScreen extends StatefulWidget {
  final BookingDraft booking;
  final bool simulateFailure;
  final String paymentMethod;
  final String paymentReference;

  const PaymentProcessingScreen({
    super.key,
    required this.booking,
    required this.paymentMethod,
    required this.paymentReference,
    this.simulateFailure = false,
  });

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  @override
  void initState() {
    super.initState();
    _processPayment();
  }

  Future<void> _processPayment() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (widget.simulateFailure) {
      _showFailedPayment('Your demo payment was not completed.');
      return;
    }

    try {
      final confirmedBooking = await BookingService.instance.completePayment(
        reference: widget.booking.reference,
        paymentMethod: widget.paymentMethod,
        paymentReference: widget.paymentReference,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(booking: confirmedBooking),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showFailedPayment('Booking could not be confirmed: $error');
    }
  }

  void _showFailedPayment(String message) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PaymentFailedScreen(booking: widget.booking, message: message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Processing Payment')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text(
                'Processing your demo payment...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait. Do not close the app.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
