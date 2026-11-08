import 'package:flutter/material.dart';
import '../../data/sample_data.dart';
import '../../data/notification_store.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Notifications'),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: NotificationStore.instance.changes,
        builder: (context, _, _) {
          final paymentNotifications = NotificationStore.instance.items;
          if (sampleNotifications.isEmpty && paymentNotifications.isEmpty) {
            return const Center(
              child: Text('No notifications available.'),
            );
          }

          return ListView(
            children: [
              ...paymentNotifications.map(
                (notification) => Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    title: Text(notification.title),
                    subtitle: Text(notification.message),
                    isThreeLine: true,
                  ),
                ),
              ),
              ...sampleNotifications.map(
                (notification) => Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.notifications_active_outlined,
                    ),
                    title: Text(notification),
                    subtitle: const Text('Route update'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}