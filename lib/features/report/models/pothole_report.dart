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
  final String? fixedMessage;
  final String? fixedByName;

  // AI Analysis Columns
  final String? damageType;
  final String? repairPriority;
  final double? estimatedDiameterCm;
  final double? estimatedDepthCm;
  final int? confidence;
  final String? safetyWarning;
  final String? suggestedAction;
  final bool aiGenerated;
  final DateTime? generatedAt;

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
    this.fixedMessage,
    this.fixedByName,
    this.damageType,
    this.repairPriority,
    this.estimatedDiameterCm,
    this.estimatedDepthCm,
    this.confidence,
    this.safetyWarning,
    this.suggestedAction,
    this.aiGenerated = false,
    this.generatedAt,
  });

  factory PotholeReport.fromJson(Map<String, dynamic> json) {
    return PotholeReport(
      id: json['id'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      upvotes: json['upvotes'] as int? ?? 0,
      status: PotholeStatusExtension.fromString(
        json['status'] as String? ?? 'reported',
      ),
      severity: PotholeSeverityExtension.fromString(
        json['severity'] as String? ?? 'low',
      ),
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      upvotedBy: json['upvoted_by'] != null
          ? List<String>.from(json['upvoted_by'] as List)
          : const [],
      address: json['address'] as String?,
      userName: json['user_name'] as String?,
      userPhone: json['user_phone'] as String?,
      fixedMessage: json['fixed_message'] as String?,
      fixedByName: json['fixed_by_name'] as String?,
      damageType: json['damage_type'] as String?,
      repairPriority: json['repair_priority'] as String?,
      estimatedDiameterCm: (json['estimated_diameter_cm'] as num?)?.toDouble(),
      estimatedDepthCm: (json['estimated_depth_cm'] as num?)?.toDouble(),
      confidence: json['confidence'] as int?,
      safetyWarning: json['safety_warning'] as String?,
      suggestedAction: json['suggested_action'] as String?,
      aiGenerated: json['ai_generated'] as bool? ?? false,
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'user_id': userId,
      'upvotes': upvotes,
      'status': status.value,
      'severity': severity.value,
      'created_at': timestamp.toUtc().toIso8601String(),
      'upvoted_by': upvotedBy,
      'address': address,
      'user_name': userName,
      'user_phone': userPhone,
      if (fixedMessage != null) 'fixed_message': fixedMessage,
      if (fixedByName != null) 'fixed_by_name': fixedByName,
      if (damageType != null) 'damage_type': damageType,
      if (repairPriority != null) 'repair_priority': repairPriority,
      if (estimatedDiameterCm != null)
        'estimated_diameter_cm': estimatedDiameterCm,
      if (estimatedDepthCm != null) 'estimated_depth_cm': estimatedDepthCm,
      if (confidence != null) 'confidence': confidence,
      if (safetyWarning != null) 'safety_warning': safetyWarning,
      if (suggestedAction != null) 'suggested_action': suggestedAction,
      'ai_generated': aiGenerated,
      if (generatedAt != null)
        'generated_at': generatedAt!.toUtc().toIso8601String(),
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
    String? fixedMessage,
    String? fixedByName,
    String? damageType,
    String? repairPriority,
    double? estimatedDiameterCm,
    double? estimatedDepthCm,
    int? confidence,
    String? safetyWarning,
    String? suggestedAction,
    bool? aiGenerated,
    DateTime? generatedAt,
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
      fixedMessage: fixedMessage ?? this.fixedMessage,
      fixedByName: fixedByName ?? this.fixedByName,
      damageType: damageType ?? this.damageType,
      repairPriority: repairPriority ?? this.repairPriority,
      estimatedDiameterCm: estimatedDiameterCm ?? this.estimatedDiameterCm,
      estimatedDepthCm: estimatedDepthCm ?? this.estimatedDepthCm,
      confidence: confidence ?? this.confidence,
      safetyWarning: safetyWarning ?? this.safetyWarning,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
