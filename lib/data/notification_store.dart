import 'package:flutter/foundation.dart';

class NotificationItem {
  final String title;
  final String message;
  final String category;

  const NotificationItem({
    required this.title,
    required this.message,
    required this.category,
  });
}

class NotificationStore {
  NotificationStore._();

  static final NotificationStore instance = NotificationStore._();

  final List<NotificationItem> _items = [];
  final ValueNotifier<int> changes = ValueNotifier(0);

  List<NotificationItem> get items => List.unmodifiable(_items);

  void addPaymentConfirmation({
    required String paymentMethod,
    required String paymentReference,
    required double amount,
  }) {
    _items.insert(
      0,
      NotificationItem(
        title: 'Payment completed',
        message:
            'Your payment of MWK ${amount.toStringAsFixed(0)} via '
            '$paymentMethod is complete. Reference: $paymentReference.',
        category: 'Payment confirmation',
      ),
    );
    changes.value++;
  }
}
