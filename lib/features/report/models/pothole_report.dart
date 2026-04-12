import 'package:cloud_firestore/cloud_firestore.dart';

enum PotholeStatus { reported, inProgress, fixed }

enum PotholeSeverity { low, medium, high }

extension PotholeStatusExtension on PotholeStatus {
  String get value {
    switch (this) {
      case PotholeStatus.inProgress:
        return 'in_progress';
      case PotholeStatus.fixed:
        return 'fixed';
      default:
        return 'reported';
    }
  }

  String get label {
    switch (this) {
      case PotholeStatus.inProgress:
        return 'In Progress';
      case PotholeStatus.fixed:
        return 'Fixed';
      default:
        return 'Reported';
    }
  }

  static PotholeStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return PotholeStatus.inProgress;
      case 'fixed':
        return PotholeStatus.fixed;
      default:
        return PotholeStatus.reported;
    }
  }
}

extension PotholeSeverityExtension on PotholeSeverity {
  String get value {
    switch (this) {
      case PotholeSeverity.high:
        return 'high';
      case PotholeSeverity.medium:
        return 'medium';
      default:
        return 'low';
    }
  }

  String get label {
    switch (this) {
      case PotholeSeverity.high:
        return 'High';
      case PotholeSeverity.medium:
        return 'Medium';
      default:
        return 'Low';
    }
  }

  static PotholeSeverity fromString(String value) {
    switch (value) {
      case 'high':
        return PotholeSeverity.high;
      case 'medium':
        return PotholeSeverity.medium;
      default:
        return PotholeSeverity.low;
    }
  }
}

class PotholeReport {
  final String id;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String description;
  final String userId;
  final int upvotes;
  final PotholeStatus status;
  final PotholeSeverity severity;
  final DateTime timestamp;
  final List<String> upvotedBy;
  final String? address;
  final String? userName;
  final String? userPhone;

  const PotholeReport({
    required this.id,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.userId,
    required this.upvotes,
    required this.status,
    required this.severity,
    required this.timestamp,
    required this.upvotedBy,
    this.address,
    this.userName,
    this.userPhone,
  });

  factory PotholeReport.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return PotholeReport(
      id: doc.id,
      imageUrl: data['imageUrl'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      upvotes: data['upvotes'] as int? ?? 0,
      status: PotholeStatusExtension.fromString(
        data['status'] as String? ?? 'reported',
      ),
      severity: PotholeSeverityExtension.fromString(
        data['severity'] as String? ?? 'low',
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      upvotedBy: List<String>.from(data['upvotedBy'] as List? ?? []),
      address: data['address'] as String?,
      userName: data['userName'] as String?,
      userPhone: data['userPhone'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'userId': userId,
      'upvotes': upvotes,
      'status': status.value,
      'severity': severity.value,
      'timestamp': Timestamp.fromDate(timestamp),
      'upvotedBy': upvotedBy,
      'address': address,
      'userName': userName,
      'userPhone': userPhone,
    };
  }

  PotholeReport copyWith({
    String? id,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? description,
    String? userId,
    int? upvotes,
    PotholeStatus? status,
    PotholeSeverity? severity,
    DateTime? timestamp,
    List<String>? upvotedBy,
    String? address,
    String? userName,
    String? userPhone,
  }) {
    return PotholeReport(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      upvotes: upvotes ?? this.upvotes,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      upvotedBy: upvotedBy ?? this.upvotedBy,
      address: address ?? this.address,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
    );
  }
}
