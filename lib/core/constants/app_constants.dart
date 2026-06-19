class AppConstants {
  // Supabase Tables
  static const String reportsTable = 'reports';
  static const String profilesTable = 'profiles';

  // Storage Buckets
  static const String storageBucket = 'road-images';

  // Geo
  static const double duplicateRadiusMeters = 50.0;
  static const double nearbyRadiusKm = 5.0;

  // Map
  static const double defaultZoom = 14.0;
  static const double defaultLat = 20.5937;
  static const double defaultLng = 78.9629;

  // Severity
  static const List<String> severityLevels = ['low', 'medium', 'high'];

  // Status
  static const String statusReported = 'reported';
  static const String statusInProgress = 'in_progress';
  static const String statusFixed = 'fixed';
}
