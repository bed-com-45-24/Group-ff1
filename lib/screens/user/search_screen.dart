
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';
=======
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import 'profile_screen.dart';
>>>>>>> origin/maps

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounceTimer;

  List<Map<String, dynamic>> _destinations = [];
  List<String> _recentSearches = [];

  bool _isLoading = false;
  bool _showSearchResults = false;

  String? _errorMessage;
  String? _selectedDestination;
<<<<<<< HEAD
  String? _selectedAddress;
=======
  String _userInitial = 'U';
  String _locationName = 'Finding location...';
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _detectCurrentLocation();
  }

  Future<void> _loadUserInfo() async {
    final authService = AuthService();
    final userName = await authService.getUserName();
    final userEmail = await authService.getUserEmail();
    if (mounted) {
      setState(() {
        _userInitial = (userName ?? userEmail ?? 'U').substring(0, 1).toUpperCase();
      });
    }
  }

  Future<void> _detectCurrentLocation() async {
    final locationName = await _locationService.getCurrentLocationName();
    _updateLocation(locationName);
  }

  void _updateLocation(String location) {
    if (!mounted) return;
    setState(() {
      _locationName = location;
    });
  }
>>>>>>> origin/maps

  int _searchRequestId = 0;

  // Suggested places shown when the screen opens.
  // These are recommendations, not recent searches.
  final List<Map<String, String>> _suggestedPlaces = [
    {
      'name': 'Lilongwe City Centre',
      'address': 'Lilongwe, Malawi',
    },
    {
      'name': 'Area 47 Shopping Centre',
      'address': 'Area 47, Lilongwe',
    },
    {
      'name': 'Kamuzu Central Hospital',
      'address': 'Lilongwe, Malawi',
    },
    {
      'name': 'Limbe Market',
      'address': 'Limbe, Blantyre',
    },
    {
      'name': 'Mzuzu Bus Depot',
      'address': 'Mzuzu, Malawi',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  // Load searches saved on this device.
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();

    final searches =
        prefs.getStringList('mova_recent_searches') ?? [];

    if (!mounted) return;

    setState(() {
      _recentSearches = searches;
    });
  }

  // Save a destination the user actually selects.
  Future<void> _saveRecentSearch(String destination) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> searches =
        prefs.getStringList('mova_recent_searches') ?? [];

    searches.remove(destination);
    searches.insert(0, destination);

    if (searches.length > 5) {
      searches = searches.take(5).toList();
    }

    await prefs.setStringList(
      'mova_recent_searches',
      searches,
    );

    if (!mounted) return;

    setState(() {
      _recentSearches = searches;
    });
  }

  // Clear saved recent searches.
  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('mova_recent_searches');

    if (!mounted) return;

    setState(() {
      _recentSearches.clear();
    });
  }

  // FR5 and FR6: Search Malawi destinations with autocomplete.
  Future<void> _searchDestinations(String query) async {
    _debounceTimer?.cancel();

    final int requestId = ++_searchRequestId;

    if (query.trim().length < 2) {
      setState(() {
        _destinations = [];
        _isLoading = false;
        _showSearchResults = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _showSearchResults = true;
      _isLoading = true;
      _errorMessage = null;
      _selectedDestination = null;
      _selectedAddress = null;
    });

    _debounceTimer = Timer(
      const Duration(milliseconds: 600),
      () async {
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
              'User-Agent': 'MOVAFlutterApp/1.0',
              'Accept': 'application/json',
            },
          ).timeout(const Duration(seconds: 15));

          if (response.statusCode != 200) {
            throw Exception('Search request failed');
          }

          final List<dynamic> results =
              jsonDecode(response.body) as List<dynamic>;

          if (!mounted || requestId != _searchRequestId) {
            return;
          }

          final List<Map<String, dynamic>> matches = results
              .map((item) => item as Map<String, dynamic>)
              .toList();

          setState(() {
            _destinations = matches;
            _isLoading = false;

            if (matches.isEmpty) {
              _errorMessage =
                  'No matching places found. Try another name.';
            }
          });
        } catch (e) {
          if (!mounted || requestId != _searchRequestId) {
            return;
          }

          setState(() {
            _isLoading = false;
            _errorMessage =
                'Unable to search right now. Check your internet and try again.';
          });
        }
      },
    );
  }

  // FR7: Select a destination.
  Future<void> _selectDestination({
    required String name,
    String? address,
  }) async {
    final String destination = name.trim();

    if (destination.isEmpty) return;

    _debounceTimer?.cancel();
    _searchRequestId++;

    final String destinationAddress =
        address?.trim().isNotEmpty == true
            ? address!.trim()
            : destination;

    setState(() {
      _selectedDestination = destination;
      _selectedAddress = destinationAddress;
      _searchController.text = destination;
      _destinations = [];
      _isLoading = false;
      _showSearchResults = false;
      _errorMessage = null;
    });

    _searchFocusNode.unfocus();

    await _saveRecentSearch(destination);
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchRequestId++;

    _searchController.clear();

    setState(() {
      _destinations = [];
      _isLoading = false;
      _showSearchResults = false;
      _errorMessage = null;
      _selectedDestination = null;
      _selectedAddress = null;
    });
  }

  // Continue to the existing ResultsScreen.
  void _continueToResults() {
    if (_selectedDestination == null) return;

    Navigator.pushNamed(
      context,
      '/results',
      arguments: {
        'name': _selectedDestination!,
        'address': _selectedAddress ?? _selectedDestination!,
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  void _searchTrips() {
    final from = _fromController.text.trim().toLowerCase();
    final to = _toController.text.trim().toLowerCase();

    setState(() {
      _searched = true;

      _results = sampleTrips.where((trip) {
        final matchesFrom =
            from.isEmpty || trip.origin.toLowerCase().contains(from);

        final matchesTo =
            to.isEmpty || trip.destination.toLowerCase().contains(to);

        final matchesDate = _travelDate == null ||
            _sameDate(trip.departureTime, _travelDate!);

        return matchesFrom &&
            matchesTo &&
            matchesDate &&
            trip.availableSeats > 0;
      }).toList();
    });
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _travelDate ?? today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 2, 12, 31),
    );

    if (selected != null && mounted) {
      setState(() {
        _travelDate = selected;
      });
    }
  }

  String _dateText(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _timeText(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: const Color(0xFFF2F6FB),
      body: SafeArea(
=======
      appBar: AppBar(
        title: const Text('Search Destination'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                SizedBox(
                  width: 100,
                  child: Text(
                    _locationName,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _userInitial,
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
>>>>>>> origin/maps
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search destination',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Where are you heading?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main white search panel
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search input
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _searchDestinations,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search a place or landmark',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: _clearSearch,
                                icon: const Icon(Icons.close),
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF0F1F3),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Colors.green,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Display live search results while typing.
                    if (_showSearchResults) ...[
                      const Text(
                        'SEARCH RESULTS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.green,
                            ),
                          ),
                        ),

                      if (!_isLoading && _errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),

                      if (!_isLoading && _destinations.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            itemCount: _destinations.length,
                            itemBuilder: (context, index) {
                              final destination =
                                  _destinations[index];

                              final name =
                                  destination['name']?.toString();

                              final displayName =
                                  destination['display_name']
                                      ?.toString() ??
                                  'Unknown destination';

                              final address =
                                  destination['display_name']
                                      ?.toString() ??
                                  displayName;

                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 3,
                                ),
                                leading: const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.green,
                                ),
                                title: Text(
                                  name != null && name.isNotEmpty
                                      ? name
                                      : displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: name != null &&
                                        name.isNotEmpty
                                    ? Text(
                                        displayName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                onTap: () {
                                  _selectDestination(
                                    name: displayName,
                                    address: address,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ] else ...[
                      // Recent searches: only destinations actually selected.
                      if (_recentSearches.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'RECENT SEARCHES',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Colors.grey,
                              ),
                            ),
                            TextButton(
                              onPressed: _clearRecentSearches,
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),

                        ..._recentSearches.map(
                          (destination) => ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 0,
                            ),
                            leading: Icon(
                              Icons.circle,
                              size: 9,
                              color: Colors.grey.shade400,
                            ),
                            title: Text(
                              destination,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              _selectDestination(
                                name: destination,
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],

                      // Suggested places
                      const Text(
                        'SUGGESTED PLACES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Expanded(
                        child: ListView.builder(
                          itemCount: _suggestedPlaces.length,
                          itemBuilder: (context, index) {
                            final place = _suggestedPlaces[index];

                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 7,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                  size: 21,
                                ),
                              ),
                              title: Text(
                                place['name']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Padding(
                                padding:
                                    const EdgeInsets.only(top: 5),
                                child: Text(
                                  place['address']!,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              onTap: () {
                                _selectDestination(
                                  name: place['name']!,
                                  address: place['address']!,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],

                    // Selected destination confirmation
                    if (_selectedDestination != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Selected destination',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedDestination!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _continueToResults,
                              icon: const Icon(
                                Icons.arrow_forward,
                                color: Colors.green,
                              ),
                              tooltip: 'Continue',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
