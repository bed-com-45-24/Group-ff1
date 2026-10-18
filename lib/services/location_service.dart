import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Get the current location name with improved field prioritization
  Future<String> getCurrentLocationName() async {
    try {
      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Enable location';
      }

      // Check and request location permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return 'Permission denied';
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Try to get placemark with multiple attempts
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          
          // Build a comprehensive location name with better field prioritization
          String locationName = _buildLocationName(place);
          
          // If we still got a generic name, try with more specific options
          if (locationName.isEmpty || locationName == 'Unknown Location') {
            locationName = _buildAlternativeLocationName(place);
          }
          
          return locationName.isNotEmpty ? locationName : 'Unknown Location';
        }
      } catch (e) {
        // If geocoding fails, try one more time with different approach
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          
          if (placemarks.isNotEmpty) {
            return _buildLocationName(placemarks[0]);
          }
        } catch (e2) {
          // Second attempt also failed
          return 'Location detected';
        }
      }
      
      return 'Unknown Location';
    } catch (e) {
      return 'Unable to detect location';
    }
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
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      return null;
    }
  }
}
