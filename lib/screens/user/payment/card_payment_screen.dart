import 'package:flutter/material.dart';

import '../../../models/booking_model.dart';
import 'payment_processing_screen.dart';

class CardPaymentScreen extends StatefulWidget {
  final BookingDraft booking;

  const CardPaymentScreen({super.key, required this.booking});

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final formKey = GlobalKey<FormState>();
  final cardNumberController = TextEditingController();
  final nameController = TextEditingController();
  final expiryController = TextEditingController();
  final pinController = TextEditingController();

  @override
  void dispose() {
    cardNumberController.dispose();
    nameController.dispose();
    expiryController.dispose();
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank Card')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.credit_card, size: 70, color: Colors.teal),
            const SizedBox(height: 12),
            Text(
              'Amount: MWK ${widget.booking.total.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Cardholder name (demo)',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: cardNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Test card number',
                hintText: 'Use fictional test data only',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().length < 12
                  ? 'Enter a demo card number'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: expiryController,
              decoration: const InputDecoration(
                labelText: 'Expiry (MM/YY)',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter an expiry value'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Payment PIN (demo)',
                hintText: 'Enter a 4-digit demo PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              validator: (value) =>
                  value == null || !RegExp(r'^\d{4}$').hasMatch(value.trim())
                  ? 'Enter a 4-digit demo PIN'
                  : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final paymentReference =
                    'DEMO-${DateTime.now().millisecondsSinceEpoch}';
                pinController.clear();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentProcessingScreen(
                      booking: widget.booking,
                      paymentMethod: 'Bank Card (Demo)',
                      paymentReference: paymentReference,
                    ),
                  ),
                );
              },
              child: const Text('Continue to Demo Payment'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Demo only: never enter real card details or your real bank PIN. '
              'The demo PIN is not saved or sent.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
