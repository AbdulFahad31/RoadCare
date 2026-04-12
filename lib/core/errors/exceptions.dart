/// Base class for app-specific exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection'])
      : super(code: 'network_error');
}

class LocationException extends AppException {
  const LocationException([super.message = 'Unable to get location'])
      : super(code: 'location_error');
}

class PermissionException extends AppException {
  const PermissionException([super.message = 'Permission denied'])
      : super(code: 'permission_denied');
}

class StorageException extends AppException {
  const StorageException([super.message = 'Failed to upload image'])
      : super(code: 'storage_error');
}

class FirestoreException extends AppException {
  const FirestoreException([super.message = 'Database operation failed'])
      : super(code: 'firestore_error');
}

class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed'])
      : super(code: 'auth_error');
}

class DuplicateReportException extends AppException {
  const DuplicateReportException()
      : super(
          'A pothole has already been reported nearby. Please check existing reports.',
          code: 'duplicate_report',
        );
}
