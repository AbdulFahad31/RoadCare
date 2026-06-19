import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../report/models/pothole_report.dart';
import '../services/pothole_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/ai_analysis_service.dart';
import '../services/offline_sync_service.dart';
import '../models/ai_analysis.dart';
import '../../../core/utils/retry_utils.dart';
import '../../../features/auth/providers/auth_providers.dart';

// Services
final potholeServiceProvider =
    Provider<PotholeService>((ref) => PotholeService());

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

final aiAnalysisServiceProvider =
    Provider<AiAnalysisService>((ref) => AiAnalysisService());

// Streams
final allPotholesProvider = StreamProvider<List<PotholeReport>>((ref) {
  return ref.watch(potholeServiceProvider).watchAllPotholes();
});

final userPotholesProvider =
    StreamProvider.family<List<PotholeReport>, String>((ref, userId) {
  return ref.watch(potholeServiceProvider).watchUserPotholes(userId);
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

  // AI analysis state fields
  final bool isAnalyzing;
  final AiAnalysis? aiAnalysis;
  final String? aiError;

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
    this.isAnalyzing = false,
    this.aiAnalysis,
    this.aiError,
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
    bool? isAnalyzing,
    AiAnalysis? aiAnalysis,
    String? aiError,
    bool clearError = false,
    bool clearImage = false,
    bool clearAiError = false,
    bool clearAiAnalysis = false,
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
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      aiAnalysis: clearAiAnalysis ? null : (aiAnalysis ?? this.aiAnalysis),
      aiError: clearAiError ? null : (aiError ?? this.aiError),
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
    // Reset AI state when a new image is selected
    state = state.copyWith(
      selectedImage: image,
      clearAiAnalysis: true,
      clearAiError: true,
    );
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

  /// Triggers AI analysis on the currently selected image
  Future<void> analyzeImageWithAi() async {
    if (state.isAnalyzing) return; // Concurrency guard
    if (state.selectedImage == null) {
      state = state.copyWith(error: 'Please select an image first.');
      return;
    }

    state = state.copyWith(
      isAnalyzing: true,
      clearAiError: true,
      clearError: true,
    );

    final stopwatch = Stopwatch()..start();

    try {
      final aiService = _ref.read(aiAnalysisServiceProvider);
      final analysis = await aiService.analyzeImage(state.selectedImage!);

      // Map AI severity to local PotholeSeverity enum
      final mappedSeverity = PotholeSeverityExtension.fromString(
        analysis.severity.toLowerCase(),
      );

      stopwatch.stop();
      if (kDebugMode) {
        debugPrint(
            '⏱️ AI analysis completed in ${stopwatch.elapsedMilliseconds}ms');
      }

      state = state.copyWith(
        isAnalyzing: false,
        aiAnalysis: analysis,
        severity: mappedSeverity,
        description: analysis.description,
      );
    } catch (e) {
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint(
            '⏱️ AI analysis failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      }

      // AI analysis fails, but we don't block manual report submission
      state = state.copyWith(
        isAnalyzing: false,
        aiError: 'AI analysis failed: $e',
      );
    }
  }

  Future<void> submitReport() async {
    if (state.isLoading) return; // Concurrency guard
    if (state.selectedImage == null) {
      state = state.copyWith(error: 'Please select an image');
      return;
    }
    if (state.location == null) {
      state = state.copyWith(error: 'Please get your location first');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    // Check connectivity first
    try {
      final connectivity = Connectivity();
      final results = await connectivity.checkConnectivity();
      final hasInternet =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);

      if (!hasInternet) {
        final offlineReport = OfflineReport(
          latitude: state.location!.latitude,
          longitude: state.location!.longitude,
          description: state.description ?? '',
          severity: state.severity.value,
          userName:
              state.userName ?? _ref.read(authServiceProvider).displayName,
          userPhone: state.userPhone ??
              _ref.read(authServiceProvider).currentUser?.phone,
          localImagePath: state.selectedImage!.path,
          timestamp: DateTime.now(),
          damageType: state.aiAnalysis?.damageType,
          repairPriority: state.aiAnalysis?.repairPriority,
          estimatedDiameterCm: state.aiAnalysis?.estimatedDiameterCm,
          estimatedDepthCm: state.aiAnalysis?.estimatedDepthCm,
          confidence: state.aiAnalysis?.confidence,
          safetyWarning: state.aiAnalysis?.safetyWarning,
          suggestedAction: state.aiAnalysis?.suggestedAction,
          aiGenerated: state.aiAnalysis != null,
        );

        await _ref
            .read(offlineSyncServiceProvider.notifier)
            .queueReport(offlineReport);
        state = state.copyWith(isLoading: false, isSuccess: true);
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking connectivity, trying normal upload: $e');
      }
    }

    try {
      final userId = _ref.read(authServiceProvider).userId;

      final uploadStopwatch = Stopwatch()..start();
      // Upload image
      final imageUrl = await RetryUtils.retry(
        operationName: 'uploadPotholeImage',
        operation: () =>
            _storageService.uploadPotholeImage(state.selectedImage!),
      );
      uploadStopwatch.stop();
      if (kDebugMode) {
        debugPrint(
            '⏱️ Image upload took ${uploadStopwatch.elapsedMilliseconds}ms');
      }

      final submitStopwatch = Stopwatch()..start();
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
            _ref.read(authServiceProvider).currentUser?.phone,

        // AI analysis fields (optional, populated only if AI analysis completed successfully)
        damageType: state.aiAnalysis?.damageType,
        repairPriority: state.aiAnalysis?.repairPriority,
        estimatedDiameterCm: state.aiAnalysis?.estimatedDiameterCm,
        estimatedDepthCm: state.aiAnalysis?.estimatedDepthCm,
        confidence: state.aiAnalysis?.confidence,
        safetyWarning: state.aiAnalysis?.safetyWarning,
        suggestedAction: state.aiAnalysis?.suggestedAction,
        aiGenerated: state.aiAnalysis != null,
        generatedAt: state.aiAnalysis != null ? DateTime.now() : null,
      );

      await _potholeService.addPothole(report);
      submitStopwatch.stop();
      if (kDebugMode) {
        debugPrint(
            '⏱️ Report submission took ${submitStopwatch.elapsedMilliseconds}ms');
      }

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
