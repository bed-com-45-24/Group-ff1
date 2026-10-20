import 'package:flutter/material.dart';

import '../../../data/booking_store.dart';
import '../../../models/booking_model.dart';
import '../../../services/auth_service.dart';
import 'booking_summary_screen.dart';

class PassengerDetailsScreen extends StatefulWidget {
  final BookingDraft booking;

  const PassengerDetailsScreen({super.key, required this.booking});

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  final formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController idController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.booking.passengerName);
    emailController = TextEditingController(
      text: widget.booking.passengerEmail,
    );
    phoneController = TextEditingController(text: widget.booking.phoneNumber);
    idController = TextEditingController(
      text: widget.booking.identificationNumber,
    );
    _loadSavedPassengerDetails();
  }

  Future<void> _loadSavedPassengerDetails() async {
    final details = await _authService.getPassengerDetails();
    if (!mounted) return;

    if (nameController.text.isEmpty) {
      nameController.text = details['name'] ?? '';
    }
    if (emailController.text.isEmpty) {
      emailController.text = details['email'] ?? '';
    }
    if (phoneController.text.isEmpty) {
      phoneController.text = details['phoneNumber'] ?? '';
    }
    if (idController.text.isEmpty) {
      idController.text = details['identificationNumber'] ?? '';
    }
  }

  Future<void> _reviewBooking() async {
    if (!formKey.currentState!.validate()) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final identificationNumber = idController.text.trim();

    setState(() => _isSaving = true);
    try {
      await _authService.savePassengerDetails(
        name: name,
        email: email,
        phoneNumber: phone,
        identificationNumber: identificationNumber,
      );
      if (!mounted) return;

      widget.booking.passengerName = name;
      widget.booking.passengerEmail = email;
      widget.booking.phoneNumber = phone;
      widget.booking.identificationNumber = identificationNumber;
      BookingStore.instance.addBooking(widget.booking);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSummaryScreen(booking: widget.booking),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save passenger details. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
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
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your full name'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email address',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isNotEmpty && !email.contains('@')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
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
              validator: (value) => value == null || value.trim().length < 7
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
              onPressed: _isSaving ? null : _reviewBooking,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Review Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
