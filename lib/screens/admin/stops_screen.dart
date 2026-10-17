
import 'package:flutter/material.dart';

class StopsScreen extends StatefulWidget {
  const StopsScreen({super.key});

  @override
  State<StopsScreen> createState() => _StopsScreenState();
}

class _StopsScreenState extends State<StopsScreen> {
  final TextEditingController stopController =
      TextEditingController();

  int selectedRoute = 0;

  final List<Map<String, dynamic>> routes = [
    {
      'name': 'Area 25 → City Centre',
      'stops': <String>[
        'Area 25 Stand',
        'Kawale Turn-off',
        'Area 18 Roundabout',
        'City Centre Bus Bay',
      ],
    },
    {
      'name': 'Blantyre CBD → Limbe',
      'stops': <String>[
        'Blantyre CBD',
        'Chichiri',
        'Kameza',
        'Limbe Bus Depot',
      ],
    },
  ];

  @override
  void dispose() {
    stopController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void addStop() {
    final name = stopController.text.trim();

    if (name.isEmpty) {
      showMessage('Enter a stop name first.');
      return;
    }

    setState(() {
      (routes[selectedRoute]['stops'] as List<String>)
          .add(name);
      stopController.clear();
    });

    FocusScope.of(context).unfocus();
    showMessage('Stop added.');
  }

  void removeStop(int index) {
    final stops =
        routes[selectedRoute]['stops'] as List<String>;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove stop?'),
        content: Text('Remove "${stops[index]}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              setState(() => stops.removeAt(index));
              Navigator.pop(dialogContext);
              showMessage('Stop removed.');
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stops =
        routes[selectedRoute]['stops'] as List<String>;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage stops',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text('Manage pickup and drop-off points'),
              const SizedBox(height: 18),
              DropdownButtonFormField<int>(
                value: selectedRoute,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: List.generate(
                  routes.length,
                  (index) => DropdownMenuItem<int>(
                    value: index,
                    child: Text(
                      routes[index]['name'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedRoute = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  color: Colors.white,
                  child: stops.isEmpty
                      ? const Center(
                          child: Text('No stops added yet.'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: stops.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: index == 0
                                    ? const Color(0xFF2189E5)
                                    : const Color(0xFF2E7D32),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              title: Text(stops[index]),
                              trailing: IconButton(
                                onPressed: () => removeStop(index),
                                icon: const Icon(
                                  Icons.delete_outline,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stopController,
                      decoration: InputDecoration(
                        hintText: 'New pickup / drop-off point',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => addStop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: addStop,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
