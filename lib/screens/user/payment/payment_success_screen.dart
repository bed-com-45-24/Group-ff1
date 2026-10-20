import 'package:flutter/material.dart';

import '../../../models/booking_model.dart';
import '../../../data/booking_store.dart';
import '../../../data/notification_store.dart';
import '../../../data/trip_store.dart';
import '../booking/booking_confirmation_screen.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final BookingDraft booking;

  const PaymentSuccessScreen({super.key, required this.booking});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  @override
  void initState() {
    super.initState();
    final booking = widget.booking;
    booking.paid = true;
    BookingStore.instance.addBooking(booking);
    TripStore.instance.markSeatsBooked(booking);
    NotificationStore.instance.addPaymentConfirmation(
      paymentMethod: booking.paymentMethod,
      paymentReference: booking.paymentReference,
      amount: booking.total,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Successful')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 90),
              const SizedBox(height: 20),
              const Text(
                'Payment Successful!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Demo payment reference:\n${widget.booking.paymentReference}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text('Amount: MWK ${widget.booking.total.toStringAsFixed(0)}'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingConfirmationScreen(booking: widget.booking),
                      ),
                    );
                  },
                  child: const Text('View E-Ticket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
