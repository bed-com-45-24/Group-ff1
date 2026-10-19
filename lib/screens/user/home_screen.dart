import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../models/route_model.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../widgets/route_card.dart';
import 'map_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'results_screen.dart';
import 'route_details_screen.dart';
import 'trips_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _origin = '';
  String _destination = '';

  void _showRoutes(String origin, String destination) {
    setState(() {
      _origin = origin;
      _destination = destination;
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(onShowRoutes: _showRoutes),
      ResultsScreen(
        key: ValueKey('$_origin|$_destination'),
        origin: _origin,
        destination: _destination,
      ),
      const TripsScreen(),
      const MapScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: Colors.deepPurple.shade100,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? Colors.deepPurple
                : Colors.black54,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined),
            selectedIcon: Icon(Icons.alt_route),
            label: 'Routes',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final void Function(String origin, String destination) onShowRoutes;

  const _HomeTab({required this.onShowRoutes});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _authService = AuthService();
  final _locationService = LocationService();
  String _userInitial = 'U';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userName = await _authService.getUserName();
    final userEmail = await _authService.getUserEmail();
    if (!mounted) return;

    final name = (userName ?? userEmail ?? '').trim();
    setState(() {
      _userInitial = name.isEmpty ? 'U' : name[0].toUpperCase();
    });
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openRoute(RouteModel route) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RouteDetailsScreen(route: route)),
    );
  }

  Future<void> _useCurrentLocation() async {
    final location = await _locationService.getCurrentLocationName();
    if (!mounted) return;
    _originController.text = location;
  }

  void _searchRoutes() {
    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();
    if (origin.isEmpty || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter both From and To locations.')),
      );
      return;
    }
    widget.onShowRoutes(origin, destination);
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text(
          'MOVA',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: _openNotifications,
            icon: const Icon(Icons.notifications_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _openProfile,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _userInitial,
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          key: const ValueKey('home-content'),
          width: MediaQuery.sizeOf(context).width > 430
              ? 430
              : MediaQuery.sizeOf(context).width,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plan your journey',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose where you are travelling from and to.',
                      style: TextStyle(color: Colors.black54, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _originController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'From',
                        prefixIcon: const Icon(Icons.trip_origin),
                        suffixIcon: IconButton(
                          tooltip: 'Use my current location',
                          onPressed: _useCurrentLocation,
                          icon: const Icon(Icons.my_location),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _destinationController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchRoutes(),
                      decoration: InputDecoration(
                        labelText: 'To',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _searchRoutes,
                        icon: const Icon(Icons.search),
                        label: const Text('Find routes'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Popular routes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => widget.onShowRoutes('', ''),
                    child: const Text('View all'),
                  ),
                ],
              ),
              ..._featuredRoutes.map(
                (route) =>
                    RouteCard(route: route, onTap: () => _openRoute(route)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<RouteModel> get _featuredRoutes {
    const featuredIds = {'R002', 'R007', 'R010', 'R017', 'R025', 'R029'};
    return sampleRoutes
        .where((route) => featuredIds.contains(route.id))
        .toList();
  }
}
