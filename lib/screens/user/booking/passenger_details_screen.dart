
import 'package:flutter/material.dart';
import '../../../models/booking_model.dart';
import 'booking_summary_screen.dart';

class PassengerDetailsScreen extends StatefulWidget {
  final BookingDraft booking;

  const PassengerDetailsScreen({
    super.key,
    required this.booking,
  });

  @override
  State<PassengerDetailsScreen> createState() =>
      _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState
    extends State<PassengerDetailsScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController idController;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.booking.passengerName);
    phoneController =
        TextEditingController(text: widget.booking.phoneNumber);
    idController = TextEditingController(
      text: widget.booking.identificationNumber,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passenger Details')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter your full name'
                      : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: 'e.g. 0991234567',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().length < 7
                      ? 'Enter a valid phone number'
                      : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'Identification number (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                widget.booking.passengerName =
                    nameController.text.trim();
                widget.booking.phoneNumber =
                    phoneController.text.trim();
                widget.booking.identificationNumber =
                    idController.text.trim();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingSummaryScreen(
                      booking: widget.booking,
                    ),
                  ),
                );
              },
              child: const Text('Review Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
