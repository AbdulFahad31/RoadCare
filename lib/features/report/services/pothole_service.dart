import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../report/models/pothole_report.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/utils/retry_utils.dart';

class PotholeService {
  final SupabaseClient _supabase;

  PotholeService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Stream of all pothole reports ordered by created_at descending (Realtime)
  Stream<List<PotholeReport>> watchAllPotholes() {
    return _supabase
        .from('reports')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((list) =>
            list.map((json) => PotholeReport.fromJson(json)).toList());
  }

  /// Stream of pothole reports for a specific user ordered by created_at descending
  Stream<List<PotholeReport>> watchUserPotholes(String userId) {
    return _supabase
        .from('reports')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((list) =>
            list.map((json) => PotholeReport.fromJson(json)).toList());
  }

  /// Stream of nearby potholes within radius
  Stream<List<PotholeReport>> watchNearbyPotholes(
    double lat,
    double lng, {
    double radiusKm = AppConstants.nearbyRadiusKm,
  }) {
    return watchAllPotholes().map((reports) {
      return reports.where((r) {
        return GeoUtils.distanceInKm(lat, lng, r.latitude, r.longitude) <=
            radiusKm;
      }).toList();
    });
  }

  /// Get a single pothole by ID
  Future<PotholeReport?> getPothole(String id) async {
    try {
      final data = await RetryUtils.retry(
        operationName: 'getPothole',
        operation: () =>
            _supabase.from('reports').select().eq('id', id).maybeSingle(),
      );
      if (data == null) return null;
      return PotholeReport.fromJson(data);
    } catch (e) {
      throw FirestoreException(e.toString());
    }
  }

  /// Check if a duplicate report exists within radius (excluding fixed ones)
  Future<bool> hasDuplicateNearby(double lat, double lng) async {
    try {
      final response = await RetryUtils.retry(
        operationName: 'hasDuplicateNearby',
        operation: () => _supabase
            .from('reports')
            .select('id, latitude, longitude, status')
            .neq('status', 'fixed'),
      );

      final reports = (response as List)
          .map((json) => PotholeReport.fromJson(json))
          .toList();

      for (final report in reports) {
        if (GeoUtils.isWithinRadius(
          lat,
          lng,
          report.latitude,
          report.longitude,
          AppConstants.duplicateRadiusMeters,
        )) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Add a new pothole report
  Future<String> addPothole(PotholeReport report) async {
    try {
      final isDuplicate = await hasDuplicateNearby(
        report.latitude,
        report.longitude,
      );
      if (isDuplicate) throw const DuplicateReportException();

      // Convert to JSON and remove 'id' if empty to let PostgreSQL generate a UUID
      final reportData = report.toJson();
      if (report.id.isEmpty) {
        reportData.remove('id');
      }

      final response = await RetryUtils.retry(
        operationName: 'addPothole',
        operation: () =>
            _supabase.from('reports').insert(reportData).select('id').single(),
      );

      return response['id'] as String;
    } on DuplicateReportException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to add report: ${e.toString()}');
    }
  }

  /// Upvote or cancel upvote for a pothole
  Future<void> upvotePothole(String potholeId, String userId) async {
    try {
      final report = await getPothole(potholeId);
      if (report == null) return;

      final alreadyVoted = report.upvotedBy.contains(userId);
      final List<String> newUpvotedBy;
      final int newUpvotes;

      if (alreadyVoted) {
        newUpvotedBy = List<String>.from(report.upvotedBy)..remove(userId);
        newUpvotes = report.upvotes - 1;
      } else {
        newUpvotedBy = List<String>.from(report.upvotedBy)..add(userId);
        newUpvotes = report.upvotes + 1;
      }

      await RetryUtils.retry(
        operationName: 'upvotePothole',
        operation: () => _supabase.from('reports').update({
          'upvotes': newUpvotes,
          'upvoted_by': newUpvotedBy,
        }).eq('id', potholeId),
      );
    } catch (e) {
      throw FirestoreException('Failed to upvote: ${e.toString()}');
    }
  }

  /// Update pothole status (admin only)
  Future<void> updateStatus(String potholeId, PotholeStatus status) async {
    try {
      await RetryUtils.retry(
        operationName: 'updateStatus',
        operation: () => _supabase.from('reports').update({
          'status': status.value,
        }).eq('id', potholeId),
      );
    } catch (e) {
      throw FirestoreException('Failed to update status: ${e.toString()}');
    }
  }

  /// Update pothole severity (admin only)
  Future<void> updateSeverity(
      String potholeId, PotholeSeverity severity) async {
    try {
      await RetryUtils.retry(
        operationName: 'updateSeverity',
        operation: () => _supabase.from('reports').update({
          'severity': severity.value,
        }).eq('id', potholeId),
      );
    } catch (e) {
      throw FirestoreException('Failed to update severity: ${e.toString()}');
    }
  }

  /// Delete a pothole report
  Future<void> deletePothole(String potholeId) async {
    try {
      await RetryUtils.retry(
        operationName: 'deletePothole',
        operation: () => _supabase.from('reports').delete().eq('id', potholeId),
      );
    } catch (e) {
      throw FirestoreException('Failed to delete report: ${e.toString()}');
    }
  }

  /// Mark pothole as fixed with a message and builder name
  Future<void> markAsFixed({
    required String potholeId,
    required String fixedMessage,
    required String fixedByName,
  }) async {
    try {
      await RetryUtils.retry(
        operationName: 'markAsFixed',
        operation: () => _supabase.from('reports').update({
          'status': 'fixed',
          'fixed_message': fixedMessage,
          'fixed_by_name': fixedByName,
        }).eq('id', potholeId),
      );
    } catch (e) {
      throw FirestoreException('Failed to mark as fixed: ${e.toString()}');
    }
  }

  /// Get reports sorted by upvotes for admin
  Future<List<PotholeReport>> getReportsSortedByUpvotes() async {
    try {
      final response = await RetryUtils.retry(
        operationName: 'getReportsSortedByUpvotes',
        operation: () => _supabase
            .from('reports')
            .select()
            .order('upvotes', ascending: false),
      );

      return (response as List)
          .map((json) => PotholeReport.fromJson(json))
          .toList();
    } catch (e) {
      throw FirestoreException('Failed to fetch reports: ${e.toString()}');
    }
  }
}
