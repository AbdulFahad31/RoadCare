import 'package:latlong2/latlong.dart';

class GeoUtils {
  static const Distance _distance = Distance();

  /// Returns distance in meters between two coordinates
  static double distanceInMeters(
      double lat1, double lng1, double lat2, double lng2) {
    return _distance.as(
      LengthUnit.Meter,
      LatLng(lat1, lng1),
      LatLng(lat2, lng2),
    );
  }

  /// Returns distance in kilometers
  static double distanceInKm(
      double lat1, double lng1, double lat2, double lng2) {
    return _distance.as(
      LengthUnit.Kilometer,
      LatLng(lat1, lng1),
      LatLng(lat2, lng2),
    );
  }

  /// Check if two coordinates are within a given radius (meters)
  static bool isWithinRadius(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
    double radiusMeters,
  ) {
    return distanceInMeters(lat1, lng1, lat2, lng2) <= radiusMeters;
  }

  static String formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toStringAsFixed(0)}m away';
    }
    return '${km.toStringAsFixed(1)} km away';
  }
}
