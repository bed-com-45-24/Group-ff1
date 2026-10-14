import 'package:flutter/material.dart';
import '../../data/sample_data.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Notifications'),
      ),
      body: sampleNotifications.isEmpty
          ? const Center(
              child: Text('No route notifications available.'),
            )
          : ListView.builder(
              itemCount: sampleNotifications.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.notifications_active_outlined,
                    ),
                    title: Text(
                      sampleNotifications[index],
                    ),
                    subtitle: const Text('Route update'),
                  ),
                );
              },
            ),
    );
  }
}