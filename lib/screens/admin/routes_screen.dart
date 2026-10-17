
import 'package:flutter/material.dart';

const Color appBlue = Color(0xFF2189E5);
const Color appBackground = Color(0xFFF5F6FA);
const Color activeGreen = Color(0xFF2E7D32);
const Color mutedText = Color(0xFF858585);

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final TextEditingController routeController =
      TextEditingController();

  final List<Map<String, dynamic>> routes = [
    {
      'name': 'Area 25 → City Centre',
      'fare': 1500,
      'active': true,
      'stops': 4,
    },
    {
      'name': 'Area 25 → City Centre',
      'fare': 1000,
      'active': true,
      'stops': 4,
    },
    {
      'name': 'Blantyre CBD → Limbe',
      'fare': 2000,
      'active': true,
      'stops': 4,
    },
  ];

  @override
  void dispose() {
    routeController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void addRoute() {
    final name = routeController.text.trim();

    if (name.isEmpty) {
      showMessage('Enter a route name first.');
      return;
    }

    setState(() {
      routes.add({
        'name': name,
        'fare': 0,
        'active': true,
        'stops': 0,
      });
      routeController.clear();
    });

    FocusScope.of(context).unfocus();
    showMessage('Route added.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage routes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Create and manage official routes',
                style: TextStyle(color: mutedText),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.builder(
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    final bool active = route['active'];

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    route['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    '${route['stops']} stops · '
                                    'MK ${route['fare']}',
                                    style: const TextStyle(
                                      color: mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: active
                                    ? activeGreen
                                    : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  route['active'] = !active;
                                });
                              },
                              child: Text(
                                active ? 'Active' : 'Inactive',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: routeController,
                      decoration: InputDecoration(
                        hintText: 'New route name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => addRoute(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: addRoute,
                    style: FilledButton.styleFrom(
                      backgroundColor: appBlue,
                    ),
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
