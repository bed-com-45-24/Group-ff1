
import 'package:flutter/material.dart';

class FaresScreen extends StatefulWidget {
  const FaresScreen({super.key});

  @override
  State<FaresScreen> createState() => _FaresScreenState();
}

class _FaresScreenState extends State<FaresScreen> {
  final List<Map<String, dynamic>> routes = [
    {'name': 'Area 25 → City Centre', 'fare': 1500},
    {'name': 'Area 25 → City Centre', 'fare': 1000},
    {'name': 'Blantyre CBD → Limbe', 'fare': 2000},
  ];

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void editFare(int index) {
    final controller = TextEditingController(
      text: routes[index]['fare'].toString(),
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update route fare'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Fare in MWK',
            prefixText: 'MK ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              controller.dispose();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final fare = int.tryParse(
                controller.text.trim(),
              );

              if (fare == null || fare < 0) {
                showMessage('Enter a valid fare.');
                return;
              }

              setState(() {
                routes[index]['fare'] = fare;
              });

              Navigator.pop(dialogContext);
              controller.dispose();
              showMessage('Fare updated.');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage fares',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text('Tap a route to update its fare'),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.builder(
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 14),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        title: Text(
                          routes[index]['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text('Tap to edit'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'MK ${routes[index]['fare']}',
                              style: const TextStyle(
                                color: Color(0xFFE87916),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => editFare(index),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    showMessage(
                      'Sample changes are not connected to a database.',
                    );
                  },
                  icon: const Icon(Icons.publish),
                  label: const Text('Publish changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
