class AiAnalysis {
  final String damageType;
  final String severity;
  final String repairPriority;
  final double estimatedDiameterCm;
  final double? estimatedDepthCm;
  final int confidence;
  final String description;
  final String safetyWarning;
  final String suggestedAction;

  const AiAnalysis({
    required this.damageType,
    required this.severity,
    required this.repairPriority,
    required this.estimatedDiameterCm,
    this.estimatedDepthCm,
    required this.confidence,
    required this.description,
    required this.safetyWarning,
    required this.suggestedAction,
  });

  factory AiAnalysis.fromJson(Map<String, dynamic> json) {
    return AiAnalysis(
      damageType: json['damage_type'] as String? ?? 'Unknown',
      severity: json['severity'] as String? ?? 'Medium',
      repairPriority: json['repair_priority'] as String? ?? 'Medium',
      estimatedDiameterCm:
          (json['estimated_diameter_cm'] as num?)?.toDouble() ?? 0.0,
      estimatedDepthCm: (json['estimated_depth_cm'] as num?)?.toDouble(),
      confidence: _parseConfidence(json['confidence']),
      description: json['description'] as String? ?? '',
      safetyWarning: json['safety_warning'] as String? ?? '',
      suggestedAction: json['suggested_action'] as String? ?? 'Monitor',
    );
  }

  static int _parseConfidence(dynamic value) {
    if (value == null) return 0;
    if (value is num) {
      if (value >= 0.0 && value <= 1.0) {
        return (value * 100).round();
      }
      return value.round();
    }
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) {
        if (parsed >= 0.0 && parsed <= 1.0) {
          return (parsed * 100).round();
        }
        return parsed.round();
      }
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'damage_type': damageType,
      'severity': severity,
      'repair_priority': repairPriority,
      'estimated_diameter_cm': estimatedDiameterCm,
      if (estimatedDepthCm != null) 'estimated_depth_cm': estimatedDepthCm,
      'confidence': confidence,
      'description': description,
      'safety_warning': safetyWarning,
      'suggested_action': suggestedAction,
    };
  }
}
