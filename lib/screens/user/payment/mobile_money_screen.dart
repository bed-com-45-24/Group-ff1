
import 'package:flutter/material.dart';
import '../../../models/booking_model.dart';
import 'payment_processing_screen.dart';

class MobileMoneyScreen extends StatefulWidget {
  final BookingDraft booking;

  const MobileMoneyScreen({
    super.key,
    required this.booking,
  });

  @override
  State<MobileMoneyScreen> createState() =>
      _MobileMoneyScreenState();
}

class _MobileMoneyScreenState extends State<MobileMoneyScreen> {
  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();

  String provider = 'Airtel Money';

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile Money')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(
              Icons.phone_android,
              size: 70,
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            Text(
              'Amount: MWK ${widget.booking.total.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: provider,
              decoration: const InputDecoration(
                labelText: 'Mobile Money provider',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Airtel Money',
                  child: Text('Airtel Money'),
                ),
                DropdownMenuItem(
                  value: 'TNM Mpamba',
                  child: Text('TNM Mpamba'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => provider = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Money phone number',
                hintText: 'Enter your phone number',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().length < 7
                      ? 'Enter a valid phone number'
                      : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                widget.booking.paymentMethod = provider;
                widget.booking.paymentReference =
                    'DEMO-${DateTime.now().millisecondsSinceEpoch}';

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentProcessingScreen(
                      booking: widget.booking,
                    ),
                  ),
                );
              },
              child: const Text('Pay Now'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Demonstration only. This does not contact Airtel Money '
              'or TNM Mpamba.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
