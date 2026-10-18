import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _districtName = 'Finding location...';
  String _userName = 'User Name';
  String _userEmail = 'user@example.com';
  String _userInitial = 'U';
  bool _isLoading = false;
  final _authService = AuthService();
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _detectCurrentLocation();
  }

  Future<void> _loadUserInfo() async {
    final userName = await _authService.getUserName();
    final userEmail = await _authService.getUserEmail();
    if (mounted) {
      setState(() {
        _userName = userName ?? 'User Name';
        _userEmail = userEmail ?? 'user@example.com';
        _userInitial = (_userName.isNotEmpty ? _userName : _userEmail).substring(0, 1).toUpperCase();
      });
    }
  }

  Future<void> _detectCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _districtName = 'Finding location...';
    });

    final locationName = await _locationService.getCurrentLocationName();
    _updateLocation(locationName);
  }

  void _updateLocation(String district) {
    if (!mounted) return;

    setState(() {
      _districtName = district;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                SizedBox(
                  width: 100,
                  child: Text(
                    _districtName,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      _userInitial,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userEmail,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Current location
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.deepPurple,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Current Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _districtName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent journeys
            _buildMenuSection(
              icon: Icons.history,
              title: 'Recent Journeys',
              subtitle: 'View your travel history',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recent journeys feature coming soon'),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Notifications
            _buildMenuSection(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'View your notifications',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications feature coming soon'),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Saved routes
            _buildMenuSection(
              icon: Icons.bookmark,
              title: 'Saved Routes',
              subtitle: 'View your saved routes',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Saved routes feature coming soon'),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _authService.logout();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.deepPurple,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
