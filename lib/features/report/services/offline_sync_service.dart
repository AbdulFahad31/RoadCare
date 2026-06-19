import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pothole_report.dart';
import '../providers/report_providers.dart';
import 'pothole_service.dart';
import 'storage_service.dart';

class OfflineReport {
  final double latitude;
  final double longitude;
  final String description;
  final String severity;
  final String? userName;
  final String? userPhone;
  final String localImagePath;
  final DateTime timestamp;

  // AI fields
  final String? damageType;
  final String? repairPriority;
  final double? estimatedDiameterCm;
  final double? estimatedDepthCm;
  final int? confidence;
  final String? safetyWarning;
  final String? suggestedAction;
  final bool aiGenerated;

  OfflineReport({
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.severity,
    this.userName,
    this.userPhone,
    required this.localImagePath,
    required this.timestamp,
    this.damageType,
    this.repairPriority,
    this.estimatedDiameterCm,
    this.estimatedDepthCm,
    this.confidence,
    this.safetyWarning,
    this.suggestedAction,
    this.aiGenerated = false,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'severity': severity,
        'user_name': userName,
        'user_phone': userPhone,
        'local_image_path': localImagePath,
        'timestamp': timestamp.toIso8601String(),
        'damage_type': damageType,
        'repair_priority': repairPriority,
        'estimated_diameter_cm': estimatedDiameterCm,
        'estimated_depth_cm': estimatedDepthCm,
        'confidence': confidence,
        'safety_warning': safetyWarning,
        'suggested_action': suggestedAction,
        'ai_generated': aiGenerated,
      };

  factory OfflineReport.fromJson(Map<String, dynamic> json) => OfflineReport(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        description: json['description'] as String? ?? '',
        severity: json['severity'] as String? ?? 'medium',
        userName: json['user_name'] as String?,
        userPhone: json['user_phone'] as String?,
        localImagePath: json['local_image_path'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        damageType: json['damage_type'] as String?,
        repairPriority: json['repair_priority'] as String?,
        estimatedDiameterCm:
            (json['estimated_diameter_cm'] as num?)?.toDouble(),
        estimatedDepthCm: (json['estimated_depth_cm'] as num?)?.toDouble(),
        confidence: json['confidence'] as int?,
        safetyWarning: json['safety_warning'] as String?,
        suggestedAction: json['suggested_action'] as String?,
        aiGenerated: json['ai_generated'] as bool? ?? false,
      );
}

class OfflineSyncState {
  final bool isSyncing;
  final int pendingCount;
  final String? syncError;

  const OfflineSyncState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.syncError,
  });

  OfflineSyncState copyWith({
    bool? isSyncing,
    int? pendingCount,
    String? syncError,
    bool clearError = false,
  }) {
    return OfflineSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      syncError: clearError ? null : (syncError ?? this.syncError),
    );
  }
}

class OfflineSyncService extends StateNotifier<OfflineSyncState> {
  final PotholeService _potholeService;
  final StorageService _storageService;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static const String _prefKey = 'offline_reports_queue';

  OfflineSyncService(
    this._potholeService,
    this._storageService, {
    Connectivity? connectivity,
  })  : _connectivity = connectivity ?? Connectivity(),
        super(const OfflineSyncState()) {
    _init();
  }

  Future<void> _init() async {
    // Load initial pending count
    final count = await getPendingCount();
    if (!mounted) return;
    state = state.copyWith(pendingCount: count);

    // Listen to network status changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      if (!mounted) return;
      final hasInternet =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      if (hasInternet) {
        syncPendingReports();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Get the current number of pending offline reports
  Future<int> getPendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKey);
      return list?.length ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Queue a report locally when offline
  Future<void> queueReport(OfflineReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKey) ?? [];
      list.add(jsonEncode(report.toJson()));
      await prefs.setStringList(_prefKey, list);

      if (!mounted) return;
      state = state.copyWith(pendingCount: list.length);

      if (kDebugMode) {
        debugPrint(
            '💾 Report saved to offline queue. Total pending: ${list.length}');
      }

      // Try to sync immediately if we happen to have connection
      final results = await _connectivity.checkConnectivity();
      final hasInternet =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      if (hasInternet) {
        syncPendingReports();
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(syncError: 'Failed to save report offline: $e');
      }
    }
  }

  /// Trigger synchronization of all pending reports to Supabase
  Future<void> syncPendingReports() async {
    if (state.isSyncing) return;

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefKey) ?? [];
    if (list.isEmpty) return;

    if (!mounted) return;
    state = state.copyWith(isSyncing: true, clearError: true);

    if (kDebugMode) {
      debugPrint(
          '🔄 Starting synchronization of ${list.length} offline reports...');
    }

    final List<String> remainingList = [];
    bool hasFailure = false;
    String? lastError;

    for (final rawReport in list) {
      if (hasFailure) {
        remainingList.add(rawReport);
        continue;
      }

      try {
        final offlineData = OfflineReport.fromJson(
            jsonDecode(rawReport) as Map<String, dynamic>);
        final imageFile = File(offlineData.localImagePath);

        if (!await imageFile.exists()) {
          // If the file does not exist locally anymore, skip it to avoid getting stuck
          if (kDebugMode) {
            debugPrint(
                '⚠️ Local image file not found at ${offlineData.localImagePath}. Skipping report.');
          }
          continue;
        }

        // 1. Upload the image to Supabase storage
        final imageUrl = await _storageService.uploadPotholeImage(imageFile);

        // 2. Submit the report to PostgreSQL
        final report = PotholeReport(
          id: '',
          imageUrl: imageUrl,
          latitude: offlineData.latitude,
          longitude: offlineData.longitude,
          description: offlineData.description,
          userId: '', // Will be resolved by the service/JWT
          upvotes: 0,
          status: PotholeStatus.reported,
          severity: PotholeSeverityExtension.fromString(offlineData.severity),
          timestamp: offlineData.timestamp,
          upvotedBy: const [],
          userName: offlineData.userName,
          userPhone: offlineData.userPhone,
          damageType: offlineData.damageType,
          repairPriority: offlineData.repairPriority,
          estimatedDiameterCm: offlineData.estimatedDiameterCm,
          estimatedDepthCm: offlineData.estimatedDepthCm,
          confidence: offlineData.confidence,
          safetyWarning: offlineData.safetyWarning,
          suggestedAction: offlineData.suggestedAction,
          aiGenerated: offlineData.aiGenerated,
          generatedAt: offlineData.aiGenerated ? offlineData.timestamp : null,
        );

        await _potholeService.addPothole(report);

        // Delete local image file to free up device space
        try {
          await imageFile.delete();
        } catch (_) {}
      } catch (e) {
        hasFailure = true;
        lastError = e.toString();
        remainingList.add(rawReport);
      }
    }

    if (!mounted) return;
    await prefs.setStringList(_prefKey, remainingList);
    state = state.copyWith(
      isSyncing: false,
      pendingCount: remainingList.length,
      syncError: lastError,
    );

    if (kDebugMode) {
      if (remainingList.isEmpty) {
        debugPrint('✅ Offline reports synchronized successfully!');
      } else {
        debugPrint(
            '⚠️ Sync completed with failures. Remaining pending: ${remainingList.length}. Error: $lastError');
      }
    }
  }
}

// Riverpod Provider
final offlineSyncServiceProvider =
    StateNotifierProvider<OfflineSyncService, OfflineSyncState>((ref) {
  return OfflineSyncService(
    ref.watch(potholeServiceProvider),
    ref.watch(storageServiceProvider),
  );
});
