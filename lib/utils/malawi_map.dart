import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

final LatLngBounds malawiBounds = LatLngBounds(
  const LatLng(-17.13, 32.67),
  const LatLng(-9.37, 35.92),
);

const LatLng malawiCenter = LatLng(-13.25, 34.30);

bool isWithinMalawi(LatLng point) =>
    point.latitude >= malawiBounds.south &&
    point.latitude <= malawiBounds.north &&
    point.longitude >= malawiBounds.west &&
    point.longitude <= malawiBounds.east;
