import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import 'profile_screen.dart';

class MapScreen extends StatefulWidget {
  final LatLng? origin;
  final LatLng? destination;
  final List<LatLng>? routePoints;

  const MapScreen({
    super.key,
    this.origin,
    this.destination,
    this.routePoints,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng _initialPosition = const LatLng(-13.9626, 33.7741); // Default: Lilongwe
  String _userInitial = 'U';
  String _locationName = 'Finding location...';
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _detectCurrentLocation();
    _initializeMap();
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

  Future<void> _initializeMap() async {
    // Get user's current location
    Position position = await _determinePosition();
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
    });

    // Add markers for origin and destination if provided
    _addMarkers();
    
    // Add route polyline if provided
    _addRoutePolyline();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _addMarkers() {
    Set<Marker> markers = {};

    // Add user location marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _initialPosition,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Add origin marker if provided
    if (widget.origin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: widget.origin!,
          infoWindow: const InfoWindow(title: 'Origin'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    // Add destination marker if provided
    if (widget.destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination!,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _addRoutePolyline() {
    if (widget.routePoints != null && widget.routePoints!.isNotEmpty) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: widget.routePoints!,
            color: Colors.blue,
            width: 5,
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
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
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 14.0,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Position position = await _determinePosition();
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              15.0,
            ),
          );
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
