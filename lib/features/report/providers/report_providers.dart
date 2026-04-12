import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../report/models/pothole_report.dart';
import '../services/pothole_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../../../features/auth/providers/auth_providers.dart';

// Services
final potholeServiceProvider =
    Provider<PotholeService>((ref) => PotholeService());

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

// Streams
final allPotholesProvider = StreamProvider<List<PotholeReport>>((ref) {
  return ref.watch(potholeServiceProvider).watchAllPotholes();
});

final nearbyPotholesProvider =
    StreamProvider.family<List<PotholeReport>, ({double lat, double lng})>(
        (ref, args) {
  return ref
      .watch(potholeServiceProvider)
      .watchNearbyPotholes(args.lat, args.lng);
});

// Location Provider
final currentLocationProvider =
    StateNotifierProvider<LocationNotifier, AsyncValue<Position?>>((ref) {
  return LocationNotifier(ref.watch(locationServiceProvider));
});

class LocationNotifier extends StateNotifier<AsyncValue<Position?>> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(const AsyncValue.data(null));

  Future<void> fetchLocation() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _locationService.getCurrentPosition());
  }
}

// Report Submission Provider
class ReportSubmissionState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final File? selectedImage;
  final Position? location;
  final String? description;
  final PotholeSeverity severity;
  final String? userName;
  final String? userPhone;

  const ReportSubmissionState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.selectedImage,
    this.location,
    this.description,
    this.severity = PotholeSeverity.medium,
    this.userName,
    this.userPhone,
  });

  ReportSubmissionState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    File? selectedImage,
    Position? location,
    String? description,
    PotholeSeverity? severity,
    String? userName,
    String? userPhone,
    bool clearError = false,
    bool clearImage = false,
  }) {
    return ReportSubmissionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSuccess: isSuccess ?? this.isSuccess,
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
      location: location ?? this.location,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
    );
  }
}

class ReportSubmissionNotifier extends StateNotifier<ReportSubmissionState> {
  final PotholeService _potholeService;
  final StorageService _storageService;
  final LocationService _locationService;
  final Ref _ref;

  ReportSubmissionNotifier(
    this._potholeService,
    this._storageService,
    this._locationService,
    this._ref,
  ) : super(const ReportSubmissionState());

  void setImage(File image) {
    state = state.copyWith(selectedImage: image);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  void setSeverity(PotholeSeverity severity) {
    state = state.copyWith(severity: severity);
  }

  void setUserInfo(String? name, String? phone) {
    state = state.copyWith(userName: name, userPhone: phone);
  }

  Future<void> fetchLocation() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final position = await _locationService.getCurrentPosition();
      state = state.copyWith(location: position, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> submitReport() async {
    if (state.selectedImage == null) {
      state = state.copyWith(error: 'Please select an image');
      return;
    }
    if (state.location == null) {
      state = state.copyWith(error: 'Please get your location first');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final userId = _ref.read(authServiceProvider).userId;

      // Upload image
      final imageUrl =
          await _storageService.uploadPotholeImage(state.selectedImage!);

      // Create report
      final report = PotholeReport(
        id: '',
        imageUrl: imageUrl,
        latitude: state.location!.latitude,
        longitude: state.location!.longitude,
        description: state.description ?? '',
        userId: userId,
        upvotes: 0,
        status: PotholeStatus.reported,
        severity: state.severity,
        timestamp: DateTime.now(),
        upvotedBy: const [],
        userName: state.userName ?? _ref.read(authServiceProvider).displayName,
        userPhone: state.userPhone ??
            _ref.read(authServiceProvider).currentUser?.phoneNumber,
      );

      await _potholeService.addPothole(report);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void reset() {
    state = const ReportSubmissionState();
  }
}

final reportSubmissionProvider = StateNotifierProvider.autoDispose<
    ReportSubmissionNotifier, ReportSubmissionState>((ref) {
  return ReportSubmissionNotifier(
    ref.watch(potholeServiceProvider),
    ref.watch(storageServiceProvider),
    ref.watch(locationServiceProvider),
    ref,
  );
});

// Upvote action
class UpvoteNotifier extends StateNotifier<AsyncValue<void>> {
  final PotholeService _service;
  final String _userId;

  UpvoteNotifier(this._service, this._userId)
      : super(const AsyncValue.data(null));

  Future<void> toggle(String potholeId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _service.upvotePothole(potholeId, _userId));
  }
}

final upvoteProvider =
    StateNotifierProvider.family<UpvoteNotifier, AsyncValue<void>, String>(
        (ref, potholeId) {
  final userId = ref.watch(authServiceProvider).userId;
  return UpvoteNotifier(ref.watch(potholeServiceProvider), userId);
});

// Filter/Sort for Admin
enum AdminSortOrder { byDate, byUpvotes, bySeverity }

final adminSortOrderProvider =
    StateProvider<AdminSortOrder>((ref) => AdminSortOrder.byDate);

final adminStatusFilterProvider = StateProvider<PotholeStatus?>((ref) => null);

final filteredAdminReportsProvider =
    Provider<AsyncValue<List<PotholeReport>>>((ref) {
  final allReports = ref.watch(allPotholesProvider);
  final sortOrder = ref.watch(adminSortOrderProvider);
  final statusFilter = ref.watch(adminStatusFilterProvider);

  return allReports.whenData((reports) {
    var filtered = List<PotholeReport>.from(reports);

    if (statusFilter != null) {
      filtered = filtered.where((r) => r.status == statusFilter).toList();
    }

    switch (sortOrder) {
      case AdminSortOrder.byUpvotes:
        filtered.sort((a, b) => b.upvotes.compareTo(a.upvotes));
      case AdminSortOrder.bySeverity:
        filtered.sort((a, b) => b.severity.index.compareTo(a.severity.index));
      default:
        filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    return filtered;
  });
});
