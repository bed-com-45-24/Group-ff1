import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  Timer? _debounceTimer;

  List<Map<String, dynamic>> _destinations = [];

  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedDestination;

  Future<void> _searchDestinations(String query) async {
    _debounceTimer?.cancel();

    if (query.trim().length < 2) {
      setState(() {
        _destinations = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    _debounceTimer = Timer(
      const Duration(milliseconds: 500),
      () async {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        try {
          final uri = Uri.https(
            'nominatim.openstreetmap.org',
            '/search',
            {
              'q': query.trim(),
              'format': 'jsonv2',
              'addressdetails': '1',
              'limit': '8',
              'countrycodes': 'mw',
            },
          );

          final response = await http.get(
            uri,
            headers: {
              'User-Agent': 'GroupFF1FlutterApp/1.0',
            },
          );

          if (response.statusCode != 200) {
            throw Exception('Search request failed.');
          }

          final List<dynamic> results =
              jsonDecode(response.body) as List<dynamic>;

          if (!mounted) return;

          setState(() {
            _destinations = results
                .map((item) => item as Map<String, dynamic>)
                .toList();
            _isLoading = false;

            if (_destinations.isEmpty) {
              _errorMessage = 'No destinations found.';
            }
          });
        } catch (e) {
          if (!mounted) return;

          setState(() {
            _isLoading = false;
            _errorMessage =
                'Unable to search right now. Please try again.';
          });
        }
      },
    );
  }

  void _selectDestination(Map<String, dynamic> destination) {
    final name = destination['display_name']?.toString() ??
        'Unknown destination';

    setState(() {
      _selectedDestination = name;
      _searchController.text = name;
      _destinations = [];
      _errorMessage = null;
    });

    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Destination'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Where do you want to go?',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Enter a place name or destination in Malawi.',
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _searchController,
              onChanged: _searchDestinations,
              decoration: InputDecoration(
                hintText: 'Search for a destination',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _destinations = [];
                      _selectedDestination = null;
                      _errorMessage = null;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            Expanded(
              child: ListView.builder(
                itemCount: _destinations.length,
                itemBuilder: (context, index) {
                  final destination = _destinations[index];

                  final name =
                      destination['display_name']?.toString() ??
                          'Unknown destination';

                  return ListTile(
                    leading: const Icon(
                      Icons.location_on_outlined,
                    ),
                    title: Text(name),
                    onTap: () =>
                        _selectDestination(destination),
                  );
                },
              ),
            ),

            if (_selectedDestination != null)
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  title: const Text('Selected destination'),
                  subtitle: Text(_selectedDestination!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}