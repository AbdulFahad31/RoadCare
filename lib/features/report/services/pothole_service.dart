import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../report/models/pothole_report.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/geo_utils.dart';

class PotholeService {
  final FirebaseFirestore _firestore;

  PotholeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'roadcare31');

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.potholeCollection);

  /// Stream of all pothole reports ordered by timestamp
  Stream<List<PotholeReport>> watchAllPotholes() {
    return _collection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PotholeReport.fromFirestore).toList());
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
      final doc = await _collection.doc(id).get();
      if (!doc.exists) return null;
      return PotholeReport.fromFirestore(doc);
    } catch (e) {
      throw FirestoreException(e.toString());
    }
  }

  /// Check if a duplicate report exists within radius
  Future<bool> hasDuplicateNearby(double lat, double lng) async {
    try {
      final reports =
          await _collection.where('status', whereNotIn: ['fixed']).get();
      for (final doc in reports.docs) {
        final report = PotholeReport.fromFirestore(doc);
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

      final docRef = await _collection.add(report.toFirestore());
      return docRef.id;
    } on DuplicateReportException {
      rethrow;
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to add report');
    }
  }

  /// Upvote a pothole
  Future<void> upvotePothole(String potholeId, String userId) async {
    try {
      final doc = await _collection.doc(potholeId).get();
      if (!doc.exists) return;

      final report = PotholeReport.fromFirestore(doc);
      final alreadyVoted = report.upvotedBy.contains(userId);

      if (alreadyVoted) {
        await _collection.doc(potholeId).update({
          'upvotes': FieldValue.increment(-1),
          'upvotedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        await _collection.doc(potholeId).update({
          'upvotes': FieldValue.increment(1),
          'upvotedBy': FieldValue.arrayUnion([userId]),
        });
      }
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to upvote');
    }
  }

  /// Update pothole status (admin only)
  Future<void> updateStatus(String potholeId, PotholeStatus status) async {
    try {
      await _collection.doc(potholeId).update({'status': status.value});
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to update status');
    }
  }

  /// Update pothole severity (admin only)
  Future<void> updateSeverity(
      String potholeId, PotholeSeverity severity) async {
    try {
      await _collection.doc(potholeId).update({'severity': severity.value});
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to update severity');
    }
  }

  /// Delete a pothole report
  Future<void> deletePothole(String potholeId) async {
    try {
      await _collection.doc(potholeId).delete();
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to delete report');
    }
  }

  /// Get reports sorted by upvotes for admin
  Future<List<PotholeReport>> getReportsSortedByUpvotes() async {
    try {
      final snap = await _collection.orderBy('upvotes', descending: true).get();
      return snap.docs.map(PotholeReport.fromFirestore).toList();
    } catch (e) {
      throw FirestoreException(e.toString());
    }
  }
}
