import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Get the current location name with improved field prioritization
  Future<String> getCurrentLocationName() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Turn on device location';
    }

    if (!await _hasLocationPermission()) {
      return 'Allow location access';
    }

    final position = await _readCurrentPosition();
    if (position == null) return 'Location unavailable';

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 10));
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final name = _buildLocationName(place);
        if (name.isNotEmpty && name != 'Unknown Location') return name;

        final alternativeName = _buildAlternativeLocationName(place);
        if (alternativeName.isNotEmpty) return alternativeName;
      }
    } on Exception {
      // Coordinates still provide the detected device location if reverse
      // geocoding is unavailable.
    }

    return _formatCoordinates(position.latitude, position.longitude);
  }

  String _formatCoordinates(double latitude, double longitude) {
    final latDirection = latitude < 0 ? 'S' : 'N';
    final lonDirection = longitude < 0 ? 'W' : 'E';
    return '${latitude.abs().toStringAsFixed(4)}° $latDirection, '
        '${longitude.abs().toStringAsFixed(4)}° $lonDirection';
  }

  /// Build location name with primary field prioritization
  String _buildLocationName(Placemark place) {
    // Try to get the most specific location name first
    final name = place.name?.trim() ?? '';
    final street = place.street?.trim() ?? '';
    final subLocality = place.subLocality?.trim() ?? '';
    final locality = place.locality?.trim() ?? '';
    final subAdministrativeArea = place.subAdministrativeArea?.trim() ?? '';
    final administrativeArea = place.administrativeArea?.trim() ?? '';

    // Combine relevant fields for a meaningful location name
    List<String> parts = [];

    // Add street or name if available
    if (name.isNotEmpty && name != street) {
      parts.add(name);
    }
    if (street.isNotEmpty) {
      parts.add(street);
    }

    // Add neighborhood/sub-locality
    if (subLocality.isNotEmpty) {
      parts.add(subLocality);
    }

    // Add city/locality
    if (locality.isNotEmpty) {
      parts.add(locality);
    }

    // Add district/sub-administrative area
    if (subAdministrativeArea.isNotEmpty) {
      parts.add(subAdministrativeArea);
    }

    // Add state/administrative area
    if (administrativeArea.isNotEmpty) {
      parts.add(administrativeArea);
    }

    // Build the final location string
    if (parts.isNotEmpty) {
      // Take first 2-3 most relevant parts to avoid too long strings
      final relevantParts = parts.take(3).join(', ');
      return relevantParts;
    }

    // Fallback to just the name if nothing else works
    if (name.isNotEmpty) {
      return name;
    }

    return 'Unknown Location';
  }

  /// Build alternative location name with different field combination
  String _buildAlternativeLocationName(Placemark place) {
    final locality = place.locality?.trim() ?? '';
    final administrativeArea = place.administrativeArea?.trim() ?? '';
    final country = place.country?.trim() ?? '';
    final subAdministrativeArea = place.subAdministrativeArea?.trim() ?? '';

    // Try different combinations
    if (locality.isNotEmpty && administrativeArea.isNotEmpty) {
      return '$locality, $administrativeArea';
    }

    if (subAdministrativeArea.isNotEmpty && administrativeArea.isNotEmpty) {
      return '$subAdministrativeArea, $administrativeArea';
    }

    if (locality.isNotEmpty) {
      return locality;
    }

    if (administrativeArea.isNotEmpty) {
      return administrativeArea;
    }

    if (country.isNotEmpty) {
      return country;
    }

    return '';
  }

  /// Get just the coordinates without geocoding
  Future<Position?> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    if (!await _hasLocationPermission()) return null;
    return _readCurrentPosition();
  }

  Future<bool> openSettingsIfNeeded() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return Geolocator.openLocationSettings();
    }
    if (await Geolocator.checkPermission() ==
        LocationPermission.deniedForever) {
      return Geolocator.openAppSettings();
    }
    return false;
  }

  Future<bool> _hasLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<Position?> _readCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on Exception catch (error, stackTrace) {
      Position? lastKnownPosition;
      try {
        lastKnownPosition = await Geolocator.getLastKnownPosition();
      } on Exception {
        // Preserve the current-position error when no fallback is available.
      }
      if (lastKnownPosition != null) return lastKnownPosition;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
