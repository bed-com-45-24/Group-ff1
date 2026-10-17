import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, String> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;

    final String destinationName = args['name'] ?? 'Unknown';
    final String destinationAddress = args['address'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selected Destination'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Destination Selected:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              color: Colors.green[50],
              child: ListTile(
                leading: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                ),
                title: Text(
                  destinationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(destinationAddress),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Next step: Route Planning goes here...',
              style: TextStyle(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}