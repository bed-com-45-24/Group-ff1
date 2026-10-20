import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../models/route_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/route_card.dart';
import 'map_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'route_details_screen.dart';
import 'trips_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _HomeTab(),
      const AllPopularRoutesScreen(),
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
            label: 'Bookings',
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
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _authService = AuthService();
  String _userInitial = 'U';
  String _currentLocation = 'Detecting location...';
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserInfo();
    _loadCurrentLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isLoadingLocation) {
      _loadCurrentLocation();
    }
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

  Future<void> _loadCurrentLocation() async {
    if (_isLoadingLocation) return;
    setState(() => _isLoadingLocation = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _currentLocation = 'Zomba';
      _isLoadingLocation = false;
    });
  }

  Future<void> _refreshLocation() async {
    if (_isLoadingLocation) return;
    await _loadCurrentLocation();
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

  void _openSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
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
                      'Search for a destination and compare your route options.',
                      style: TextStyle(color: Colors.black54, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Refresh detected location',
                          visualDensity: VisualDensity.compact,
                          onPressed: _isLoadingLocation
                              ? null
                              : _refreshLocation,
                          icon: const Icon(
                            Icons.my_location,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _isLoadingLocation
                                ? 'Detecting location...'
                                : _currentLocation,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      readOnly: true,
                      onTap: _openSearchPage,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search destination',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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

class AllPopularRoutesScreen extends StatelessWidget {
  const AllPopularRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All routes'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sampleRoutes.length,
        itemBuilder: (context, index) {
          final route = sampleRoutes[index];
          return RouteCard(
            route: route,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RouteDetailsScreen(route: route),
              ),
            ),
          );
        },
      ),
    );
  }
}
