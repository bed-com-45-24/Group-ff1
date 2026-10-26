import 'package:flutter/material.dart';

import '../../data/route_store.dart';
import '../../models/route_model.dart';
import '../../services/openstreetmap_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/route_card.dart';
import 'map_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'route_directions_details_screen.dart';
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
  final _routeStore = RouteStore.instance;
  String _userInitial = 'U';
  String _currentLocation = 'Detecting location...';
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _routeStore.changes.addListener(_refreshRoutes);
    _routeStore.load();
    _loadUserInfo();
    _loadCurrentLocation();
  }

  void _refreshRoutes() {
    if (mounted) setState(() {});
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
    _routeStore.changes.removeListener(_refreshRoutes);
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
    return RouteStore.instance.routes
        .where((route) => route.active && featuredIds.contains(route.id))
        .toList();
  }
}

class AllPopularRoutesScreen extends StatefulWidget {
  const AllPopularRoutesScreen({super.key});

  @override
  State<AllPopularRoutesScreen> createState() => _AllPopularRoutesScreenState();
}

class _AllPopularRoutesScreenState extends State<AllPopularRoutesScreen> {
  final _store = RouteStore.instance;
  final _openStreetMap = OpenStreetMapService();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  bool _searchingRoute = false;
  String? _routeSearchError;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _searchRoute() async {
    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();
    if (origin.isEmpty || destination.isEmpty) {
      setState(() {
        _routeSearchError = 'Enter both a starting point and destination.';
      });
      return;
    }

    setState(() {
      _searchingRoute = true;
      _routeSearchError = null;
    });

    try {
      final routes = await _openStreetMap.findRoutesBetweenPlaces(
        origin: origin,
        destination: destination,
      );
      if (!mounted) return;
      final route = routes.first;
      final estimatedFare = ((route.distanceMeters / 1000) * 220).roundToDouble();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RouteDirectionsDetailsScreen(
            route: route,
            origin: origin,
            destination: destination,
            estimatedFare: estimatedFare,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _routeSearchError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _searchingRoute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All routes'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: _store.changes,
        builder: (context, _, _) {
          final routes = _store.routes.where((route) => route.active).toList();
          if (!_store.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildRouteSearchCard(context),
              if (routes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No saved routes are available yet. Search any origin and destination above.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ...routes.map(
                (route) => RouteCard(
                  route: route,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteDetailsScreen(route: route),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRouteSearchCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Find a route',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose any starting point and destination to view the route on a map.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _originController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'From',
                prefixIcon: Icon(Icons.trip_origin),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _destinationController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchingRoute ? null : _searchRoute(),
              decoration: const InputDecoration(
                labelText: 'To',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            if (_routeSearchError != null) ...[
              const SizedBox(height: 8),
              Text(
                _routeSearchError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _searchingRoute ? null : _searchRoute,
              icon: _searchingRoute
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.map_outlined),
              label: Text(_searchingRoute ? 'Finding route...' : 'Search route'),
            ),
          ],
        ),
      ),
    );
  }
}
