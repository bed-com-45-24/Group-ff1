import 'package:flutter/material.dart';

import '../../../models/booking_model.dart';
import 'mobile_money_screen.dart';
import 'card_payment_screen.dart';

class PaymentMethodScreen extends StatelessWidget {
  final BookingDraft booking;

  const PaymentMethodScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Method')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose how you want to pay',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Total payable: MWK ${booking.total.toStringAsFixed(0)}'),
            if (booking.trip.fareIsEstimate) ...[
              const SizedBox(height: 8),
              const Text(
                'This total uses a map-distance fare estimate, not a '
                'published operator fare. Confirm the final fare before travel.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.phone_android,
                  color: Colors.teal,
                  size: 36,
                ),
                title: const Text('Mobile Money'),
                subtitle: const Text('Pay using your mobile wallet'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MobileMoneyScreen(booking: booking),
                    ),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.credit_card,
                  color: Colors.teal,
                  size: 36,
                ),
                title: const Text('Bank Card'),
                subtitle: const Text('Pay using a debit or credit card'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CardPaymentScreen(booking: booking),
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            const Text(
              'Demo only: no real payment will be taken.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
